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
    logger.info("Received event: %s", json.dumps(event))

    detail_type = event.get("detail-type")
    detail = event.get("detail", {})

    if detail_type == "EC2 Instance State-change Notification":
        instance_id = detail.get("instance-id")
        state = detail.get("state")

        if state == "running" and instance_id:
            logger.info("Handling new instance in running state: %s", instance_id)

            # Attach scanner policy to instance role
            ensure_scanner_policy_on_instance_role(instance_id)

            # Ensure security groups are attached (instance is already running)
            ensure_required_sg_on_all_enis(instance_id)

            # Wait for SSM and bootstrap
            if wait_for_ssm_online(instance_id):
                command_id = run_bootstrap_script(instance_id)
                logger.info("Sent bootstrap script to %s with command id %s", instance_id, command_id)
            else:
                logger.warning("Instance %s never became SSM-online; skipped bootstrap script", instance_id)
        else:
            logger.info("Ignoring state change to %s for instance %s", state, instance_id)

    elif detail_type == "AWS API Call via CloudTrail":
        event_name = detail.get("eventName")

        if event_name in ("ModifyInstanceAttribute", "ModifyNetworkInterfaceAttribute"):
            instance_ids = extract_modified_instance_ids(detail)

            for instance_id in instance_ids:
                logger.info("Handling SG remediation for instance: %s", instance_id)
                ensure_required_sg_on_all_enis(instance_id)
        else:
            logger.info("Ignoring CloudTrail event: %s", event_name)

    else:
        logger.info("Ignoring event type: %s", detail_type)

    return {"ok": True}


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
    instance = describe_instance(instance_id)
    if not instance:
        logger.warning("Instance %s not found", instance_id)
        return False

    state = instance.get("State", {}).get("Name")
    if state in ("shutting-down", "terminated"):
        logger.info("Instance %s is %s; skipping", instance_id, state)
        return False

    required_sg_id = determine_required_sg_for_instance(instance)
    if not required_sg_id:
        logger.error("Could not determine required security group for instance %s", instance_id)
        return False

    changed = False

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

    if not changed:
        logger.info("Required SG %s already present on all ENIs for %s", required_sg_id, instance_id)

    return changed


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
    """Run the scanner bootstrap SSM document on the instance."""
    resp = ssm.send_command(
        DocumentName=SSM_DOCUMENT_NAME,
        InstanceIds=[instance_id],
        Parameters={
            "ParameterName": [SCANNER_SECRET_PARAMETER_NAME],
            "Username": [SCANNER_USERNAME],
        },
        Comment="Bootstrap new instance for scanner access after launch and SG remediation",
    )
    return resp["Command"]["CommandId"]


def ensure_scanner_policy_on_instance_role(instance_id):
    """Attach the scanner access policy to the instance's IAM role if not already attached."""
    try:
        instance = describe_instance(instance_id)
        if not instance:
            logger.warning("Cannot attach policy - instance %s not found", instance_id)
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
            logger.error("Could not extract instance profile name from ARN: %s", profile_arn)
            return False

        # Get the IAM role from the instance profile
        profile_response = iam.get_instance_profile(InstanceProfileName=profile_name)
        roles = profile_response.get("InstanceProfile", {}).get("Roles", [])

        if not roles:
            logger.warning("Instance profile %s has no roles attached", profile_name)
            return False

        role_name = roles[0]["RoleName"]
        logger.info("Instance %s uses IAM role: %s", instance_id, role_name)

        # Check if the policy is already attached
        attached_policies = iam.list_attached_role_policies(RoleName=role_name)
        policy_arns = [p["PolicyArn"] for p in attached_policies.get("AttachedPolicies", [])]

        if SCANNER_POLICY_ARN in policy_arns:
            logger.info("Scanner policy already attached to role %s", role_name)
            return False

        # Attach the policy
        iam.attach_role_policy(RoleName=role_name, PolicyArn=SCANNER_POLICY_ARN)
        logger.info("Successfully attached scanner policy to role %s for instance %s", role_name, instance_id)
        return True

    except Exception as e:
        logger.error("Error attaching scanner policy to instance %s role: %s", instance_id, e)
        return False
