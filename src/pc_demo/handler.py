import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

ssm = boto3.client("ssm")
cloudwatch = boto3.client("cloudwatch")

OWN_SSM_PARAMETER_NAME = os.environ.get("OWN_SSM_PARAMETER_NAME")
GREETING = os.environ.get("GREETING", "hello")


def _own_config():
    if not OWN_SSM_PARAMETER_NAME:
        return None
    response = ssm.get_parameter(Name=OWN_SSM_PARAMETER_NAME)
    return response["Parameter"]["Value"]


def handler(event, context):
    config = _own_config()
    logger.info("%s - own config: %s", GREETING, config)

    cloudwatch.put_metric_data(
        Namespace="homelab-application/pc_demo",
        MetricData=[{"MetricName": "Invocations", "Value": 1, "Unit": "Count"}],
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"message": GREETING, "own_config": config}),
    }
