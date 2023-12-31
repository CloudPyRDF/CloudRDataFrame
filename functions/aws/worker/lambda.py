import base64
import json
import logging
import os

import boto3
import cloudpickle as pickle
import ROOT
from monitor import CPUAndNetMonitor, EmptyMonitor, monitoring_thread

logging.basicConfig(level=logging.INFO)
bucket = os.getenv("bucket")
debug_command = os.getenv("debug_command", "")
return_after_debug = os.getenv("return_after_debug", "False")

krb5ccname = os.getenv("KRB5CCNAME", "/tmp/certs")
monitoring_on = os.getenv("monitor", "False") == "True"
suffix = os.getenv("suffix", "out")


def lambda_handler(event, context):
    debug_info = handle_debug(event.get("debug_command"))
    if debug_info is not None:
        return debug_info

    print(f"event {event}", flush=True)

    rdf_range = pickle.loads(base64.b64decode(event["range"]))
    mapper = pickle.loads(base64.b64decode(event["script"]))
    headers = pickle.loads(base64.b64decode(event["headers"]))
    prefix = pickle.loads(base64.b64decode(event["prefix"]))
    cert_file = base64.b64decode(event["cert"])
    file_count = pickle.loads(base64.b64decode(event["file_count"]))
    s3_access_key = pickle.loads(base64.b64decode(event["S3_ACCESS_KEY"]))
    s3_secret_key = pickle.loads(base64.b64decode(event["S3_SECRET_KEY"]))
    os.environ["S3_ACCESS_KEY"] = s3_access_key
    os.environ["S3_SECRET_KEY"] = s3_secret_key

    logging.info(rdf_range)

    write_cert(cert_file)
    declare_headers(headers)

    return run(mapper, rdf_range, prefix, file_count)


def handle_debug(debug_command: str | None) -> dict | None:
    if debug_command is None:
        return None

    if return_after_debug:
        return {
            "statusCode": 500,
            "command": debug_command,
            "command_output": os.popen(f"{debug_command}").read(),
        }

    logging.info(debug_command)
    return None


def write_cert(cert_file: bytes):
    with open(f"{krb5ccname}", "wb") as handle:
        handle.write(cert_file)


def declare_headers(headers: list):
    for header_name, header_content in headers:
        header_path = "/tmp/" + header_name
        with open(header_path, "w") as f:
            f.write(header_content)
        logging.info(f"Declaring header: {header_name}")
        try:
            ROOT.gInterpreter.Declare(f'#include "{header_path}"')
        except Exception:
            logging.error(f"Could not declare header {header_name}")


def run(mapper, rdf_range, prefix, file_count) -> dict:
    monitor = get_monitor(rdf_range)

    with monitoring_thread(monitor):
        try:
            hist = mapper(rdf_range)
        except Exception as exception:
            return {
                "statusCode": 500,
                "errorType": json.dumps(type(exception).__name__),
                "errorMessage": json.dumps(str(exception)),
            }

        N = reduce_tree_leafs_count(file_count)
        filename = serialize_and_upload_to_s3(
            hist, prefix, N + rdf_range.id, file_count, suffix=suffix
        )

        if monitoring_on:
            monitoring_results = monitor.get_monitoring_results()
            serialize_and_upload_to_s3(
                monitoring_results, f"monitor-{prefix}", rdf_range.id, file_count
            )
    return {"statusCode": 200, "filename": json.dumps(filename)}


def get_monitor(rdf_range):
    if monitoring_on:
        return CPUAndNetMonitor(rdf_range.id)
    else:
        return EmptyMonitor()


def reduce_tree_leafs_count(file_count):
    return 2 ** (file_count - 1).bit_length()


def serialize_and_upload_to_s3(hist, prefix, rangeid, file_count, suffix=""):
    pickled_hist = pickle.dumps(hist)
    filename = get_unique_filename(prefix, rangeid, file_count, suffix)
    upload_result_to_s3(pickled_hist, filename)
    return filename


def get_unique_filename(prefix, range_id, file_count, suffix):
    return f"output/{prefix}/partial_{range_id}_{file_count}.{suffix}"


def upload_result_to_s3(obj: bytes, filename: str):
    s3_client = boto3.client("s3")
    s3_client.put_object(Body=obj, Bucket=bucket, Key=filename)
