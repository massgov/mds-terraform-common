import os
import json
import fnmatch
import logging
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

iam = boto3.client("iam")
sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
WARNING_DAYS  = int(os.environ.get("WARNING_DAYS", "80"))
ALERT_DAYS    = int(os.environ.get("ALERT_DAYS",   "90"))
NAME_PATTERN  = os.environ.get("NAME_PATTERN", "*")
TAG_KEY       = os.environ.get("TAG_KEY", "")
TAG_VALUE     = os.environ.get("TAG_VALUE", "")


def _list_all_users():
    paginator = iam.get_paginator("list_users")
    for page in paginator.paginate():
        yield from page["Users"]


def _user_has_tag(username: str, key: str, value: str) -> bool:
    resp = iam.list_user_tags(UserName=username)
    tags = {t["Key"]: t["Value"] for t in resp.get("Tags", [])}
    return tags.get(key) == value


def _get_active_keys(username: str):
    resp = iam.list_access_keys(UserName=username)
    return [k for k in resp["AccessKeyMetadata"] if k["Status"] == "Active"]


def _key_age_days(key_meta: dict) -> int:
    created = key_meta["CreateDate"]
    now = datetime.now(timezone.utc)
    return (now - created).days


def _publish(level: str, username: str, key_id: str, age_days: int):
    subject = f"[IAM Key {level}] {username} – key {key_id} is {age_days} days old"
    message = json.dumps(
        {
            "level":     level,       # "WARNING" | "ALERT"
            "username":  username,
            "key_id":    key_id,
            "age_days":  age_days,
            "threshold": WARNING_DAYS if level == "WARNING" else ALERT_DAYS,
            "message": (
                f"IAM access key {key_id} for user '{username}' is {age_days} days old. "
                f"This exceeds the {level} threshold of "
                f"{WARNING_DAYS if level == 'WARNING' else ALERT_DAYS} days. "
                "Please rotate this key."
            ),
        },
        indent=2,
    )
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=subject,
        Message=message,
        MessageAttributes={
            "level": {
                "DataType": "String",
                "StringValue": level,
            },
            "username": {
                "DataType": "String",
                "StringValue": username,
            },
        },
    )
    logger.info("Published %s for user=%s key=%s age=%d", level, username, key_id, age_days)


def lambda_handler(event, context):
    logger.info(
        "Starting IAM key age check | pattern=%s warning=%d alert=%d",
        NAME_PATTERN, WARNING_DAYS, ALERT_DAYS,
    )

    checked_users  = 0
    checked_keys   = 0
    notifications  = 0

    for user in _list_all_users():
        username = user["UserName"]

        if not fnmatch.fnmatch(username, NAME_PATTERN):
            continue

        if TAG_KEY:
            if not _user_has_tag(username, TAG_KEY, TAG_VALUE):
                continue

        checked_users += 1
        keys = _get_active_keys(username)

        for key in keys:
            key_id   = key["AccessKeyId"]
            age_days = _key_age_days(key)
            checked_keys += 1

            logger.info("user=%s key=%s age=%d days", username, key_id, age_days)

            if age_days >= ALERT_DAYS:
                _publish("ALERT", username, key_id, age_days)
                notifications += 1
            elif age_days >= WARNING_DAYS:
                _publish("WARNING", username, key_id, age_days)
                notifications += 1

    summary = {
        "checked_users": checked_users,
        "checked_keys":  checked_keys,
        "notifications": notifications,
    }
    logger.info("Done: %s", summary)
    return summary