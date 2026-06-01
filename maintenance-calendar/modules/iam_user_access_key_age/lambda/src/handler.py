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
NAME_PATTERN  = os.environ.get("NAME_PATTERN", "") # Default to no user to avoid accidental
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


def _publish_consolidated(issues: list):
    if not issues:
        logger.info("No issues to report")
        return

    total_issues = len(issues)
    subject = f"[ACCESS_KEY] - {total_issues} issue(s) found"

    # Build message lines
    message_lines = []
    for issue in issues:
        line = f"[{issue['level']}] - {issue['username']}: Key {issue['key_id']} is {issue['age_days']} days old (threshold: {issue['threshold']} days)"
        message_lines.append(line)

    message = "\n".join(message_lines)

    # Prepare JSON payload
    payload = {
        "report_type": "consolidated_access_key_audit",
        "total_issues": total_issues,
        "issues": issues,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    if DRY_RUN:
        logger.info("[DRY_RUN] SNS PUBLISH: subject=%s | total_issues=%d", subject, total_issues)
        logger.info("[DRY_RUN] Message:\n%s", message)
        logger.debug("[DRY_RUN] JSON Payload: %s", json.dumps(payload, indent=2))
    else:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message,
            MessageAttributes={
                "total_issues": {
                    "DataType": "Number",
                    "StringValue": str(total_issues),
                },
                "report_type": {
                    "DataType": "String",
                    "StringValue": "consolidated_access_key_audit",
                },
            },
        )
        logger.info("Published consolidated notification for %d issue(s)", total_issues)


def lambda_handler(event, context):
    logger.info(
        "Starting IAM key age check | pattern=%s warning=%d alert=%d disable=%d pre_warn=%d auto_disable=%s dry_run=%s",
        NAME_PATTERN, WARNING_DAYS, ALERT_DAYS, DISABLE_DAYS, PRE_WARN_DAYS, AUTO_DISABLE, DRY_RUN,
    )

    checked_users = 0
    checked_keys = 0
    disabled_keys = 0
    issues = []

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
                        disabled_keys += 1

                issue = {
                    "level": "DISABLED",
                    "username": username,
                    "key_id": key_id,
                    "age_days": age_days,
                    "threshold": DISABLE_DAYS,
                }
                issues.append(issue)

            elif age_days >= pre_disable_threshold:
                logger.warning(
                    "Pre-disable warning for key %s (user %s, age: %d days)",
                    key_id, username, age_days
                )
                issue = {
                    "level": "PRE_DISABLE",
                    "username": username,
                    "key_id": key_id,
                    "age_days": age_days,
                    "threshold": pre_disable_threshold,
                }
                issues.append(issue)

            # Standard warning/alert thresholds
            elif age_days >= ALERT_DAYS:
                issue = {
                    "level": "ALERT",
                    "username": username,
                    "key_id": key_id,
                    "age_days": age_days,
                    "threshold": ALERT_DAYS,
                }
                issues.append(issue)
            elif age_days >= WARNING_DAYS:
                issue = {
                    "level": "WARNING",
                    "username": username,
                    "key_id": key_id,
                    "age_days": age_days,
                    "threshold": WARNING_DAYS,
                }
                issues.append(issue)

    if issues:
        _publish_consolidated(issues)

    summary = {
        "checked_users": checked_users,
        "checked_keys": checked_keys,
        "issues_found": len(issues),
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