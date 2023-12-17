import json
import os

import boto3
import botocore

region = os.getenv("region")


def lambda_handler(event, context):
    try:
        return run(event)
    except Exception as e:
        print(e)
        serialized_exception = json.dumps((type(e).__name__, str(e)))
        return dict(statusCode=500, exception=serialized_exception)


def run(event):
    ranges = json.loads(event["ranges"])

    config = botocore.config.Config(
        retries={"total_max_attempts": 1}, read_timeout=900, connect_timeout=900
    )
    client = boto3.client("lambda", region_name=region, config=config)

    payload = dict()
    worker_payload_fields = [
        "script",
        "headers",
        "prefix",
        "cert",
        "file_count",
        "S3_ACCESS_KEY",
        "S3_SECRET_KEY",
    ]

    for f in worker_payload_fields:
        payload[f] = event.get(f)

    for rdf_range in ranges:
        payload["range"] = rdf_range
        client.invoke(
            FunctionName="worker_root_lambda",
            InvocationType="Event",
            Payload=bytes(json.dumps(payload), encoding="utf8"),
        )

    return dict(statusCode=200)
