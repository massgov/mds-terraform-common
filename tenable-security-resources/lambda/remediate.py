import json
import logging
import os
import time

import boto3

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
VPC_SG_MAPPINGS = json.loads(os.environ["VPC_SG_MAPPINGS"])
SCANNER_SECRET_PARAMETER_NAME = os.environ["SCANNER_SECRET_PARAMETER_NAME"]
SCANNER_USERNAME = os.environ["SCANNER_USERNAME"]
SSM_DOCUMENT_NAME = os.environ["SSM_DOCUMENT_NAME"]
SCANNER_POLICY_ARN = os.environ["SCANNER_POLICY_ARN"]

logging.basicConfig(level=LOG_LEVEL)
logger = logging.getLogger(__name__)

ec2 = boto3.client("ec2")
ssm = boto3.client("ssm")
iam = boto3.client("iam")

_sg_cache = {}
_vpc_name_cache = {}


def handler(event, context):
    logger.info("=" * 80)
    logger.info("LAMBDA EXECUTION STARTED - Request ID: %s", context.request_id)
    logger.info("Received event: %s", json.dumps(event))
    logger.info("=" * 80)

    detail_type = event.get("detail-type")
    detail = event.get("detail", {})

    try:
        if detail_type == "EC2 Instance State-change Notification":
            instance_id = detail.get("instance-id")
            state = detail.get("state")

            if state == "running" and instance_id:
                logger.info("▶ PROCESSING: New instance in running state: %s", instance_id)

                results = {
                    "instance_id": instance_id,
                    "iam_policy_attached": False,
                    "security_group_attached": False,
                    "ssm_bootstrap_sent": False,
                }

                # Attach scanner policy to instance role (non-critical - instance may not have a role)
                logger.info("Attempting to attach scanner policy to instance role...")
                policy_attached = ensure_scanner_policy_on_instance_role(instance_id)
                results["iam_policy_attached"] = policy_attached
                if policy_attached:
                    logger.info("SUCCESS: Scanner policy attached to instance role")
                else:
                    logger.warning("SKIPPED: Scanner policy not attached (instance may not have IAM role)")

                # Ensure security groups are attached (CRITICAL)
                logger.info("Attempting to attach required security group...")
                sg_result = ensure_required_sg_on_all_enis(instance_id)
                results["security_group_attached"] = sg_result
                if sg_result is False:
                    error_msg = f"FAILURE: Failed to ensure required security group on instance {instance_id}"
                    logger.error(error_msg)
                    logger.error("=" * 80)
                    logger.error("LAMBDA EXECUTION FAILED - Request ID: %s", context.request_id)
                    logger.error("=" * 80)
                    raise RuntimeError(error_msg)
                logger.info("SUCCESS: Required security group attached")

                # Wait for SSM and bootstrap (non-critical - instance may not have SSM agent)
                logger.info("Waiting for SSM agent to come online...")
                if wait_for_ssm_online(instance_id):
                    logger.info("SUCCESS: SSM agent is online")
                    logger.info("Sending bootstrap script via SSM...")
                    command_id = run_bootstrap_script(instance_id)
                    results["ssm_bootstrap_sent"] = True
                    logger.info("SUCCESS: Bootstrap script sent (Command ID: %s)", command_id)
                else:
                    logger.warning("TIMEOUT: Instance %s never became SSM-online; skipped bootstrap script", instance_id)

                logger.info("=" * 80)
                logger.info("LAMBDA EXECUTION COMPLETED SUCCESSFULLY - Request ID: %s", context.request_id)
                logger.info("Summary: %s", json.dumps(results, indent=2))
                logger.info("=" * 80)
            else:
                logger.info("Ignoring state change to '%s' for instance %s", state, instance_id)

        elif detail_type == "AWS API Call via CloudTrail":
            event_name = detail.get("eventName")

            if event_name in ("ModifyInstanceAttribute", "ModifyNetworkInterfaceAttribute"):
                instance_ids = extract_modified_instance_ids(detail)
                logger.info("▶ PROCESSING: Security group remediation for %d instance(s)", len(instance_ids))

                successful_instances = []
                failed_instances = []

                for instance_id in instance_ids:
                    logger.info("Remediating security group for instance: %s", instance_id)
                    sg_result = ensure_required_sg_on_all_enis(instance_id)
                    if sg_result is False:
                        failed_instances.append(instance_id)
                        logger.error("FAILURE: Security group remediation failed for instance %s", instance_id)
                    else:
                        successful_instances.append(instance_id)
                        logger.info("SUCCESS: Security group remediation completed for instance %s", instance_id)

                if failed_instances:
                    error_msg = f"FAILURE: Failed to remediate security groups on {len(failed_instances)} instance(s): {', '.join(failed_instances)}"
                    logger.error("=" * 80)
                    logger.error("LAMBDA EXECUTION FAILED - Request ID: %s", context.request_id)
                    logger.error("Successful: %s", successful_instances)
                    logger.error("Failed: %s", failed_instances)
                    logger.error("=" * 80)
                    raise RuntimeError(error_msg)

                logger.info("=" * 80)
                logger.info("LAMBDA EXECUTION COMPLETED SUCCESSFULLY - Request ID: %s", context.request_id)
                logger.info("Successfully remediated %d instance(s): %s", len(successful_instances), successful_instances)
                logger.info("=" * 80)
            else:
                logger.info("Ignoring CloudTrail event: %s", event_name)

        else:
            logger.info("Ignoring event type: %s", detail_type)

        return {"ok": True}

    except Exception as e:
        logger.error("=" * 80)
        logger.error("LAMBDA EXECUTION FAILED WITH EXCEPTION - Request ID: %s", context.request_id)
        logger.error("Error: %s", str(e))
        logger.error("=" * 80)
        raise


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


def get_vpc_name(vpc_id):
    """Get VPC name from tags, with caching."""
    if vpc_id in _vpc_name_cache:
        return _vpc_name_cache[vpc_id]

    try:
        resp = ec2.describe_vpcs(VpcIds=[vpc_id])
        vpcs = resp.get("Vpcs", [])

        if not vpcs:
            logger.warning("VPC %s not found", vpc_id)
            return None

        vpc = vpcs[0]
        tags = vpc.get("Tags", [])

        # Look for Name tag
        for tag in tags:
            if tag.get("Key") == "Name":
                vpc_name = tag.get("Value", "")
                _vpc_name_cache[vpc_id] = vpc_name
                logger.info("VPC %s has name: %s", vpc_id, vpc_name)
                return vpc_name

        logger.warning("VPC %s has no Name tag", vpc_id)
        _vpc_name_cache[vpc_id] = None
        return None
    except Exception as e:
        logger.error("Error looking up VPC %s: %s", vpc_id, e)
        return None


def get_security_group_id_by_name(sg_name):
    """Look up security group ID by name, with caching."""
    if sg_name in _sg_cache:
        return _sg_cache[sg_name]

    try:
        resp = ec2.describe_security_groups(
            Filters=[{"Name": "group-name", "Values": [sg_name]}]
        )
        security_groups = resp.get("SecurityGroups", [])

        if not security_groups:
            logger.error("Security group '%s' not found", sg_name)
            return None

        sg_id = security_groups[0]["GroupId"]
        _sg_cache[sg_name] = sg_id
        logger.info("Resolved security group '%s' to ID %s", sg_name, sg_id)
        return sg_id
    except Exception as e:
        logger.error("Error looking up security group '%s': %s", sg_name, e)
        return None


def determine_required_sg_for_instance(instance):
    """Determine which security group should be attached based on VPC name mapping."""
    vpc_id = instance.get("VpcId")
    if not vpc_id:
        logger.error("Instance has no VPC ID")
        return None

    vpc_name = get_vpc_name(vpc_id)
    if not vpc_name:
        logger.error("Could not determine VPC name for VPC %s", vpc_id)
        return None

    # Look up security group name from the mapping
    sg_name = VPC_SG_MAPPINGS.get(vpc_name)
    if not sg_name:
        logger.warning(
            "No security group mapping found for VPC '%s'. Available mappings: %s",
            vpc_name,
            list(VPC_SG_MAPPINGS.keys())
        )
        return None

    logger.info("VPC '%s' mapped to security group '%s'", vpc_name, sg_name)
    return get_security_group_id_by_name(sg_name)


def ensure_required_sg_on_all_enis(instance_id):
    try:
        logger.debug("Checking instance %s for required security groups", instance_id)
        instance = describe_instance(instance_id)
        if not instance:
            logger.error("FAILURE: Instance %s not found", instance_id)
            return False

        state = instance.get("State", {}).get("Name")
        if state in ("shutting-down", "terminated"):
            logger.info("Instance %s is %s; skipping security group attachment", instance_id, state)
            return False

        required_sg_id = determine_required_sg_for_instance(instance)
        if not required_sg_id:
            logger.error("FAILURE: Could not determine required security group for instance %s", instance_id)
            return False

        eni_count = len(instance.get("NetworkInterfaces", []))
        logger.debug("Instance %s has %d network interface(s)", instance_id, eni_count)

        changed = False
        enis_modified = []

        for eni in instance.get("NetworkInterfaces", []):
            eni_id = eni["NetworkInterfaceId"]
            current_group_ids = [g["GroupId"] for g in eni.get("Groups", [])]

            if required_sg_id not in current_group_ids:
                new_group_ids = sorted(set(current_group_ids + [required_sg_id]))
                logger.info(
                    "Adding required SG %s to ENI %s on instance %s. Before=%s After=%s",
                    required_sg_id,
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
                enis_modified.append(eni_id)
                logger.info("SUCCESS: Added security group to ENI %s", eni_id)

        if changed:
            logger.info("SUCCESS: Security group %s added to %d ENI(s): %s",
                       required_sg_id, len(enis_modified), enis_modified)
        else:
            logger.info("SUCCESS: Required SG %s already present on all %d ENI(s) for instance %s",
                       required_sg_id, eni_count, instance_id)

        return True

    except Exception as e:
        logger.error("FAILURE: Error ensuring security group on instance %s: %s", instance_id, e, exc_info=True)
        return False


def wait_for_ssm_online(instance_id, attempts=30, delay=10):
    """Wait for SSM agent to pop online (5 min max)."""
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
    """Run the scanner bootstrap SSM document on the instance."""
    try:
        logger.info("Sending SSM command to instance %s (Document: %s)", instance_id, SSM_DOCUMENT_NAME)
        resp = ssm.send_command(
            DocumentName=SSM_DOCUMENT_NAME,
            InstanceIds=[instance_id],
            Parameters={
                "ParameterName": [SCANNER_SECRET_PARAMETER_NAME],
                "Username": [SCANNER_USERNAME],
            },
            Comment="Bootstrap new instance for scanner access after launch and SG remediation",
        )
        command_id = resp["Command"]["CommandId"]
        logger.info("SUCCESS: SSM command sent successfully (Command ID: %s)", command_id)
        return command_id
    except Exception as e:
        logger.error("FAILURE: Failed to send SSM command to instance %s: %s", instance_id, e, exc_info=True)
        raise


def ensure_scanner_policy_on_instance_role(instance_id):
    """Attach the scanner access policy to the instance's IAM role if not already attached."""
    try:
        logger.debug("Checking IAM role for instance %s", instance_id)
        instance = describe_instance(instance_id)
        if not instance:
            logger.warning("WARNING: Cannot attach policy - instance %s not found", instance_id)
            return False

        # Get the instance profile ARN
        iam_instance_profile = instance.get("IamInstanceProfile")
        if not iam_instance_profile:
            logger.info("Instance %s has no IAM instance profile; skipping policy attachment", instance_id)
            return False

        # Extract instance profile name from ARN
        # ARN format: arn:aws:iam::123456789012:instance-profile/my-profile
        profile_arn = iam_instance_profile.get("Arn", "")
        profile_name = profile_arn.split("/")[-1] if profile_arn else None

        if not profile_name:
            logger.error("FAILURE: Could not extract instance profile name from ARN: %s", profile_arn)
            return False

        # Get the IAM role from the instance profile
        logger.debug("Getting IAM role from instance profile: %s", profile_name)
        profile_response = iam.get_instance_profile(InstanceProfileName=profile_name)
        roles = profile_response.get("InstanceProfile", {}).get("Roles", [])

        if not roles:
            logger.warning("WARNING: Instance profile %s has no roles attached", profile_name)
            return False

        role_name = roles[0]["RoleName"]
        logger.info("Instance %s uses IAM role: %s", instance_id, role_name)

        # Check if the policy is already attached
        attached_policies = iam.list_attached_role_policies(RoleName=role_name)
        policy_arns = [p["PolicyArn"] for p in attached_policies.get("AttachedPolicies", [])]

        if SCANNER_POLICY_ARN in policy_arns:
            logger.info("Scanner policy already attached to role %s (no action needed)", role_name)
            return False

        # Attach the policy
        logger.info("Attaching scanner policy %s to role %s", SCANNER_POLICY_ARN, role_name)
        iam.attach_role_policy(RoleName=role_name, PolicyArn=SCANNER_POLICY_ARN)
        logger.info("SUCCESS: Attached scanner policy to role %s for instance %s", role_name, instance_id)
        return True

    except Exception as e:
        logger.error("FAILURE: Error attaching scanner policy to instance %s role: %s", instance_id, e, exc_info=True)
        return False
