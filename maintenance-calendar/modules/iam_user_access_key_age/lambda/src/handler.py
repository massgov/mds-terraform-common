import os
import json
import fnmatch
import logging
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

if not logger.handlers:
    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    formatter = logging.Formatter("%(asctime)s %(levelname)s %(message)s")
    ch.setFormatter(formatter)
    logger.addHandler(ch)

iam = boto3.client("iam")
sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")
WARNING_DAYS  = int(os.environ.get("WARNING_DAYS", "80"))
ALERT_DAYS    = int(os.environ.get("ALERT_DAYS",   "90"))
DISABLE_DAYS  = int(os.environ.get("DISABLE_DAYS", "180"))  # Days before disabling keys
PRE_WARN_DAYS = int(os.environ.get("PRE_WARN_DAYS", "7"))   # Days before disable to warn
AUTO_DISABLE  = os.environ.get("AUTO_DISABLE", "false").lower() == "true"  # Enable auto-disable
DRY_RUN       = os.environ.get("DRY_RUN", "true").lower() == "true"  # Enable dry-run mode (no SNS publish, no disable)
NAME_PATTERN  = os.environ.get("NAME_PATTERN", "*") # Default to no user
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


def _get_inactive_keys(username: str):
    resp = iam.list_access_keys(UserName=username)
    return [k for k in resp["AccessKeyMetadata"] if k["Status"] == "Inactive"]


def _key_age_days(key_meta: dict) -> int:
    created = key_meta["CreateDate"]
    now = datetime.now(timezone.utc)
    return (now - created).days


def _publish(level: str, username: str, key_id: str, age_days: int, message: str = None):
    subject = f"[IAM Key {level}] {username} – key {key_id} is {age_days} days old"

    if message is None:
        if level == "PRE_DISABLE":
            message = (
                f"WARNING: IAM access key {key_id} for user '{username}' is {age_days} days old. "
                f"This key will be DISABLED in {PRE_WARN_DAYS} days (on day {DISABLE_DAYS}). "
                f"Please rotate this key immediately to avoid service disruption."
            )
        elif level == "DISABLED":
            message = (
                f"DISABLED: IAM access key {key_id} for user '{username}' has been DISABLED "
                f"(age: {age_days} days, threshold: {DISABLE_DAYS} days). "
                f"Please create a new access key and update your applications/tools."
            )
        elif level == "ALERT":
            message = (
                f"IAM access key {key_id} for user '{username}' is {age_days} days old. "
                f"This exceeds the ALERT threshold of {ALERT_DAYS} days. "
                "Please rotate this key."
            )
        else:  # WARNING
            message = (
                f"IAM access key {key_id} for user '{username}' is {age_days} days old. "
                f"This exceeds the WARNING threshold of {WARNING_DAYS} days. "
                "Please rotate this key soon."
            )

    payload = {
        "level": level,
        "username": username,
        "key_id": key_id,
        "age_days": age_days,
        "threshold": _get_threshold(level),
        "message": message,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    if DRY_RUN:
        logger.info(
            "[DRY_RUN] SNS PUBLISH: level=%s | user=%s | key=%s (age %d days) | subject: %s",
            level, username, key_id, age_days, subject
        )
        logger.debug("[DRY_RUN] SNS message payload: %s", json.dumps(payload, indent=2))
    else:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=json.dumps(payload, indent=2),
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
        logger.info("Published %s for user=%s key=%s age=%d days", level, username, key_id, age_days)


def _get_threshold(level: str) -> int:
    thresholds = {
        "WARNING": WARNING_DAYS,
        "ALERT": ALERT_DAYS,
        "PRE_DISABLE": DISABLE_DAYS - PRE_WARN_DAYS,
        "DISABLED": DISABLE_DAYS,
    }
    return thresholds.get(level, 0)


def _disable_key(username: str, key_id: str):
    if DRY_RUN:
        logger.info("[DRY_RUN] UPDATE_ACCESS_KEY: username=%s | key=%s | status=Inactive", username, key_id)
        return True

    try:
        iam.update_access_key(UserName=username, AccessKeyId=key_id, Status="Inactive")
        logger.info("Disabled key %s for user %s", key_id, username)
        return True
    except Exception as e:
        logger.error("Failed to disable key %s for user %s: %s", key_id, username, str(e))
        return False


def lambda_handler(event, context):
    logger.info(
        "Starting IAM key age check | pattern=%s warning=%d alert=%d disable=%d pre_warn=%d auto_disable=%s dry_run=%s",
        NAME_PATTERN, WARNING_DAYS, ALERT_DAYS, DISABLE_DAYS, PRE_WARN_DAYS, AUTO_DISABLE, DRY_RUN,
    )

    checked_users = 0
    checked_keys = 0
    notifications = 0
    disabled_keys = 0

    pre_disable_threshold = DISABLE_DAYS - PRE_WARN_DAYS

    for user in _list_all_users():
        username = user["UserName"]

        # Filter by name pattern
        if not fnmatch.fnmatch(username, NAME_PATTERN):
            continue

        # Filter by tag if configured
        if TAG_KEY:
            if not _user_has_tag(username, TAG_KEY, TAG_VALUE):
                continue

        checked_users += 1
        keys = _get_active_keys(username)

        for key in keys:
            key_id = key["AccessKeyId"]
            age_days = _key_age_days(key)
            checked_keys += 1

            logger.info("user=%s key=%s age=%d days", username, key_id, age_days)

            # Check if key should be disabled (at or past DISABLE_DAYS)
            if age_days >= DISABLE_DAYS:
                if AUTO_DISABLE:
                    logger.warning(
                        "Disabling key %s for user %s (age: %d days >= %d)",
                        key_id, username, age_days, DISABLE_DAYS
                    )
                    if _disable_key(username, key_id):
                        _publish("DISABLED", username, key_id, age_days)
                        notifications += 1
                        disabled_keys += 1
                else:
                    logger.info(
                        "Key %s for user %s is %d days old (>= %d) but AUTO_DISABLE is false",
                        key_id, username, age_days, DISABLE_DAYS
                    )
                    _publish("DISABLED", username, key_id, age_days)
                    notifications += 1

            # Check if key is approaching disable date (within PRE_WARN_DAYS of DISABLE_DAYS)
            elif age_days >= pre_disable_threshold:
                logger.warning(
                    "Pre-disable warning for key %s (user %s, age: %d days)",
                    key_id, username, age_days
                )
                _publish("PRE_DISABLE", username, key_id, age_days)
                notifications += 1

            # Standard warning/alert thresholds
            elif age_days >= ALERT_DAYS:
                _publish("ALERT", username, key_id, age_days)
                notifications += 1
            elif age_days >= WARNING_DAYS:
                _publish("WARNING", username, key_id, age_days)
                notifications += 1

    summary = {
        "checked_users": checked_users,
        "checked_keys":  checked_keys,
        "notifications": notifications,
        "disabled_keys": disabled_keys,
        "dry_run": DRY_RUN,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    logger.info("Done: %s", summary)
    return summary

# Local run
if __name__ == "__main__":
    logger.info("Running handler in local test mode")
    lambda_handler({}, {})
