import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    # PC utilization monitoring was removed pending a redesign - see
    # README.md ("Out of scope for this POC"). This function currently has no
    # ssm_parameter, permission, or Provisioned Concurrency config in
    # envs/dev/locals.tf, so it has nothing to check yet.
    logger.info("pc_monitor invoked - no monitoring logic configured yet.")
    return {
        "statusCode": 200,
        "body": json.dumps(
            {"message": "pc_monitor is a placeholder - monitoring logic not yet implemented"}
        ),
    }
