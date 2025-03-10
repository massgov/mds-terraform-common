import re
import boto3
import json
import os
from collections import defaultdict

# Initialize AWS clients
ec2_client = boto3.client('ec2')
rds_client = boto3.client('rds')
ecs_client = boto3.client('ecs')
s3_client = boto3.client('s3')
ses_client = boto3.client('ses')

# Email configuration
SENDER_EMAIL = os.environ['SENDER_EMAIL']
DEFAULT_RECIPIENT = os.environ['DEFAULT_RECIPIENT']
TESTING = os.environ['TESTING']

def is_valid_email(email):
    """Check if the provided email is valid."""
    email_regex = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    return re.match(email_regex, email) is not None

def send_email(recipient, subject, body):

    if TESTING:
        body = f"TEST EMAIL for ${recipient}\n\n" + body
        recipient = DEFAULT_RECIPIENT

    response = ses_client.send_email(
        Source=SENDER_EMAIL,
        Destination={
            'ToAddresses': [recipient],
            'CcAddresses': [DEFAULT_RECIPIENT]
        },
        Message={
            'Subject': {
                'Data': subject,
                'Charset': 'UTF-8'
            },
            'Body': {
                'Text': {
                    'Data': body,
                    'Charset': 'UTF-8'
                }
            }
        }
    )
    return response

def get_ec2_instances():
    instances = ec2_client.describe_instances()
    return instances['Reservations']

def get_rds_instances():
    instances = rds_client.describe_db_instances()
    return instances['DBInstances']

def get_ecs_clusters():
    clusters = ecs_client.list_clusters()
    return clusters['clusterArns']

def get_s3_buckets():
    buckets = s3_client.list_buckets()
    return buckets['Buckets']

def lambda_handler():
    resources_by_business_owner = defaultdict(lambda: defaultdict(list))
    resources_without_tags = []

    # Scan EC2 Instances
    for reservation in get_ec2_instances():
        for instance in reservation['Instances']:
            tags = {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
            business_owner = tags.get('businessowner')
            application = tags.get('application')
            if business_owner:
                if application:
                    resources_by_business_owner[business_owner][application].append(f"EC2 Instance: {instance['InstanceId']}")
                else:
                    resources_without_tags.append(f"EC2 Instance: {instance['InstanceId']}")
            else:
                resources_without_tags.append(f"EC2 Instance: {instance['InstanceId']}")

    # Scan RDS Instances
    for instance in get_rds_instances():
        tags = {tag['Key']: tag['Value'] for tag in instance.get('TagList', [])}
        business_owner = tags.get('businessowner')
        application = tags.get('application')
        if business_owner:
            if application:
                resources_by_business_owner[business_owner][application].append(f"RDS Instance: {instance['DBInstanceIdentifier']}")
            else:
                resources_without_tags.append(f"RDS Instance: {instance['DBInstanceIdentifier']}")
        else:
            resources_without_tags.append(f"RDS Instance: {instance['DBInstanceIdentifier']}")

    # Scan ECS Clusters
    for cluster in get_ecs_clusters():
        services = ecs_client.list_services(cluster=cluster)
        for service in services['serviceArns']:
            service_desc = ecs_client.describe_services(cluster=cluster, services=[service])
            tags = service_desc['services'][0].get('tags', [])
            tags_dict = {tag['key']: tag['value'] for tag in tags}
            business_owner = tags_dict.get('businessowner')
            application = tags_dict.get('application')
            if business_owner:
                if application:
                    resources_by_business_owner[business_owner][application].append(f"ECS Service: {service}")
                else:
                    resources_without_tags.append(f"ECS Service: {service}")
            else:
                resources_without_tags.append(f"ECS Service: {service}")

    # Scan S3 Buckets
    for bucket in get_s3_buckets():
        bucket_name = bucket['Name']
        try:
            tags = s3_client.get_bucket_tagging(Bucket=bucket_name).get('TagSet', [])
            tags_dict = {tag['Key']: tag['Value'] for tag in tags}
            business_owner = tags_dict.get('businessowner')
            application = tags_dict.get('application')
            if business_owner:
                if application:
                    resources_by_business_owner[business_owner][application].append(f"S3 Bucket: {bucket_name}")
                else:
                    resources_without_tags.append(f"S3 Bucket: {bucket_name}")
            else:
                resources_without_tags.append(f"S3 Bucket: {bucket_name}")
        except s3_client.exceptions.ClientError as e:
            # Handle the case where the bucket has no tags
            if e.response['Error']['Code'] == 'NoSuchTagSet':
                resources_without_tags.append(f"S3 Bucket: {bucket_name}")

    # Prepare to send emails to business owners
    for business_owner, applications in resources_by_business_owner.items():
        if not is_valid_email(business_owner):
            business_owner = DEFAULT_RECIPIENT  # Use default email if invalid

        subject = "Resource Ownership Confirmation"
        body = f"Dear Business Owner,\n\nHere are the resources associated with your ownership:\n"

        for application, resources in applications.items():
            body += f"\nApplication: {application}\n\t"
            body += "\n\t".join(resources) + "\n"

        send_email(business_owner, subject, body)

        print("Email", business_owner)
        print("Subject", subject)
        print("Body",  body)
        print("==== END ====")

    # If there are resources without tags, send an email to the default recipient
    if resources_without_tags:
        subject = "Resources Without Business Owner or Application Tags"
        body = "The following resources do not have a business owner or application tags:\n" + "\n\t".join(resources_without_tags)
        #send_email(DEFAULT_RECIPIENT, subject, body)

        print("Email", DEFAULT_RECIPIENT)
        print("Subject", subject)
        print("Body",  body)
        print("==== END ====")

        send_email(business_owner, subject, body)

    return {
        'statusCode': 200,
        'body': json.dumps('Email notifications sent successfully.')
    }



if __name__ == "__main__":
    lambda_handler()