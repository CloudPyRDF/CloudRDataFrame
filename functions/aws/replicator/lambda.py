import array
import base64
import ctypes
import logging
import os

import boto3
import cloudpickle as pickle
import ROOT

logging.basicConfig(level=logging.DEBUG)
bucket = os.getenv("bucket")
krb5ccname = os.getenv("KRB5CCNAME", "/tmp/certs")


def lambda_handler(event, context):
    logging.info(f"event {event}")

    ranges = pickle.loads(base64.b64decode(event["ranges"]))
    cert_file = base64.b64decode(event["cert"])

    logging.info(ranges)

    write_cert(cert_file)
    from collections import namedtuple

    ReplicateRange = namedtuple(
        "ReplicateRange",
        ["start", "length", "source", "destination", "part_number", "id"],
    )
    ranges = [ReplicateRange(*x) for x in ranges]

    try:
        return run(ranges)
    except Exception as e:
        return {"exc": str(e)}


def write_cert(cert_file: bytes):
    with open(f"{krb5ccname}", "wb") as handle:
        handle.write(cert_file)


def run(ranges) -> dict:
    for r in ranges:
        process_range(rep_range=r)

    return {"statusCode": 200}


def process_range(rep_range):
    print(f"Sending {rep_range}")
    part = download_bytes(rep_range)
    print(f"Got part {part[:20]}")
    send_to_s3(part, rep_range)
    print("Sent!")


def download_bytes(rep_range):
    buff = array.array("b", b"\x00" * rep_range.length)
    buffptr = ctypes.c_char_p(buff.buffer_info()[0])
    f = ROOT.TFile.Open(rep_range.source)
    f.ReadBuffer(buffptr, rep_range.start, rep_range.length)
    f.Close()
    return buff.tobytes()


def send_to_s3(part, rep_range):
    s3 = boto3.client("s3")
    s3.upload_part(
        Body=part,
        Bucket=bucket,
        Key=rep_range.destination,
        PartNumber=rep_range.part_number,
        UploadId=rep_range.id,
    )


def wait_on_futures(futures):
    _ = [future.result() for future in futures]
