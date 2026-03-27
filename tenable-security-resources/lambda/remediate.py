import json
import logging
import os
import time
from pathlib import Path

import boto3

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
REQUIRED_SG_ID = os.environ["REQUIRED_SG_ID"]
SCANNER_SECRET_PARAMETER_NAME = os.environ["SCANNER_SECRET_PARAMETER_NAME"]

logging.basicConfig(level=LOG_LEVEL)
logger = logging.getLogger(__name__)

ec2 = boto3.client("ec2")
ssm = boto3.client("ssm")

SCRIPT_PATH = Path(__file__).with_name("run-scanner-bootstrap.sh")
SCRIPT_LINES = SCRIPT_PATH.read_text().splitlines()

_scanner_secret_cache = None


def get_scanner_secret():
    global _scanner_secret_cache

    if _scanner_secret_cache is None:
        response = ssm.get_parameter(
            Name=SCANNER_SECRET_PARAMETER_NAME,
            WithDecryption=True,
        )
        _scanner_secret_cache = response["Parameter"]["Value"]

    return _scanner_secret_cache


def handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    # fetched at runtime from Parameter Store
    # do not log it
    _ = get_scanner_secret()

    detail_type = event.get("detail-type")
    detail = event.get("detail", {})
    event_name = detail.get("eventName")

    if detail_type == "AWS API Call via CloudTrail" and event_name == "RunInstances":
        instance_ids = extract_runinstances_instance_ids(detail)

        for instance_id in instance_ids:
            logger.info("Handling new instance: %s", instance_id)

            ensure_required_sg_on_all_enis(instance_id)
            wait_for_instance_running(instance_id)
            ensure_required_sg_on_all_enis(instance_id)

            if wait_for_ssm_online(instance_id):
                command_id = run_bootstrap_script(instance_id)
                logger.info("Sent bootstrap script to %s with command id %s", instance_id, command_id)
            else:
                logger.warning("Instance %s never became SSM-online; skipped bootstrap script", instance_id)

    elif detail_type == "AWS API Call via CloudTrail" and event_name in (
        "ModifyInstanceAttribute",
        "ModifyNetworkInterfaceAttribute",
    ):
        instance_ids = extract_modified_instance_ids(detail)

        for instance_id in instance_ids:
            logger.info("Handling SG remediation for instance: %s", instance_id)
            ensure_required_sg_on_all_enis(instance_id)

    else:
        logger.info("Ignoring event type=%s eventName=%s", detail_type, event_name)

    return {"ok": True}


def extract_runinstances_instance_ids(detail):
    ids = []
    response = detail.get("responseElements") or {}
    instances_set = response.get("instancesSet") or {}
    items = instances_set.get("items") or []

    for item in items:
        if isinstance(item, dict):
            instance_id = item.get("instanceId")
            if instance_id:
                ids.append(instance_id)

    return ids


def extract_modified_instance_ids(detail):
    request = detail.get("requestParameters") or {}
    event_name = detail.get("eventName")

    if event_name == "ModifyInstanceAttribute":
        instance_id = request.get("instanceId")
        return [instance_id] if instance_id else []

    if event_name == "ModifyNetworkInterfaceAttribute":
        eni_id = request.get("networkInterfaceId")
        if not eni_id:
            return []

        eni = ec2.describe_network_interfaces(NetworkInterfaceIds=[eni_id])["NetworkInterfaces"][0]
        attachment = eni.get("Attachment") or {}
        instance_id = attachment.get("InstanceId")
        return [instance_id] if instance_id else []

    return []


def describe_instance(instance_id):
    resp = ec2.describe_instances(InstanceIds=[instance_id])
    reservations = resp.get("Reservations", [])
    if not reservations or not reservations[0].get("Instances"):
        return None
    return reservations[0]["Instances"][0]


def ensure_required_sg_on_all_enis(instance_id):
    instance = describe_instance(instance_id)
    if not instance:
        logger.warning("Instance %s not found", instance_id)
        return False

    state = instance.get("State", {}).get("Name")
    if state in ("shutting-down", "terminated"):
        logger.info("Instance %s is %s; skipping", instance_id, state)
        return False

    changed = False

    for eni in instance.get("NetworkInterfaces", []):
        eni_id = eni["NetworkInterfaceId"]
        current_group_ids = [g["GroupId"] for g in eni.get("Groups", [])]

        if REQUIRED_SG_ID not in current_group_ids:
            new_group_ids = sorted(set(current_group_ids + [REQUIRED_SG_ID]))
            logger.info(
                "Adding required SG %s to ENI %s on instance %s. Before=%s After=%s",
                REQUIRED_SG_ID,
                eni_id,
                instance_id,
                current_group_ids,
                new_group_ids,
            )
            ec2.modify_network_interface_attribute(
                NetworkInterfaceId=eni_id,
                Groups=new_group_ids,
            )
            changed = True

    if not changed:
        logger.info("Required SG %s already present on all ENIs for %s", REQUIRED_SG_ID, instance_id)

    return changed


def wait_for_instance_running(instance_id):
    waiter = ec2.get_waiter("instance_running")
    waiter.wait(
        InstanceIds=[instance_id],
        WaiterConfig={"Delay": 5, "MaxAttempts": 60},
    )


def wait_for_ssm_online(instance_id, attempts=60, delay=10):
    for _ in range(attempts):
        resp = ssm.describe_instance_information(
            Filters=[{"Key": "InstanceIds", "Values": [instance_id]}]
        )
        info = resp.get("InstanceInformationList", [])
        if info and info[0].get("PingStatus") == "Online":
            return True
        time.sleep(delay)
    return False


def run_bootstrap_script(instance_id):
    resp = ssm.send_command(
        DocumentName="AWS-RunShellScript",
        InstanceIds=[instance_id],
        Parameters={
            "commands": SCRIPT_LINES,
            "executionTimeout": ["3600"],
        },
        Comment="Bootstrap new instance after launch and SG remediation",
    )
    return resp["Command"]["CommandId"]
