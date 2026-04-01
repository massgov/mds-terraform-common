# Tenable Security Resources Module

This Terraform module automatically manages security group attachments and configures scanner access for EC2 instances based on their VPC.

## Features

- **Automatic Security Group Attachment**: Monitors EC2 instance launches and security group modifications via EventBridge/CloudTrail
- **VPC-Based Security Group Mapping**: Attaches the correct scanner security group based on the instance's VPC name
- **Scanner User Bootstrap**: Creates a Nessus scanner user on new instances with SSH key authentication and sudo access
- **SSM Document**: Uses AWS Systems Manager to bootstrap instances with scanner access

## Architecture

1. **EventBridge Rules** monitor:
   - `RunInstances` API calls (new EC2 instances)
   - `ModifyInstanceAttribute` and `ModifyNetworkInterfaceAttribute` (security group changes)

2. **Lambda Function**:
   - Determines the required security group based on VPC name
   - Attaches the security group to all instance ENIs
   - Runs SSM document to create scanner user on new instances

3. **SSM Document**: Creates scanner user with SSH key and sudo access

## Usage

```hcl
module "tenable_security" {
  source = "./tenable-security-resources"

  vpc_sg_mappings = {
    "VPC-NonProd" = "scanners-sg-VPC-NonProd"
    "VPC-Prod"    = "scanners-sg-VPC-Prod"
    "VPC-Mgt"     = "scanners-sg-VPC-Mgt"
  }

  scanner_secret_parameter_name = "/apps/fixer-scanning-public-key"
  scanner_username              = "scanner-user-mydigital"
  lambda_function_name          = "instance-sg-remediator"
  ssm_document_name             = "scanner-bootstrap-setup"
}
```

## Prerequisites

1. **SSM Parameter Store**: Create a SecureString parameter containing the SSH public key for scanner access:
   ```bash
   aws ssm put-parameter \
     --name "/apps/nessus-tenable-scanning-public-key" \
     --type "SecureString" \
     --value "ssh-rsa AAAAB3... your-public-key"
   ```
   **Note**: The Lambda function requires KMS decrypt permissions on the key used to encrypt this parameter. By default, the module allows decryption using any KMS key. To restrict to a specific key, set the `kms_key_arn` variable.

2. **Security Groups**: Ensure the security groups referenced in `vpc_sg_mappings` exist and have the correct rules for scanner access.

3. **VPC Name Tags**: VPCs must have a `Name` tag that matches the keys in `vpc_sg_mappings`.

4. **SSM Agent**: EC2 instances must have SSM Agent installed and running for the bootstrap script to execute.

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vpc_sg_mappings` | Map of VPC names to security group names | `map(string)` | n/a | yes |
| `scanner_secret_parameter_name` | SSM Parameter Store path for SSH public key | `string` | `/apps/nessus-tenable-scanning-public-key` | no |
| `kms_key_arn` | ARN of KMS key to decrypt the scanner secret (use `*` for any key or specify custom key) | `string` | `*` | no |
| `scanner_username` | Username for the scanner user | `string` | `nessus-user-massdigital` | no |
| `lambda_function_name` | Name of the Lambda function | `string` | `ec2-scanner-sg-remediator` | no |
| `ssm_document_name` | Name of the SSM document | `string` | `scanner-bootstrap-setup` | no |
| `region` | AWS region | `string` | `us-east-1` | no |

## Outputs

| Name | Description |
|------|-------------|
| `lambda_name` | Name of the Lambda function |
| `lambda_arn` | ARN of the Lambda function |
| `ssm_document_name` | Name of the SSM document |
| `runinstances_rule_name` | Name of the RunInstances EventBridge rule |
| `sg_change_rule_name` | Name of the security group change EventBridge rule |

## How It Works

### Security Group Attachment

1. EventBridge detects a new EC2 instance or security group modification
2. Lambda function is triggered
3. Lambda looks up the instance's VPC name
4. Lambda matches the VPC name to the configured security group name
5. Lambda attaches the security group to all ENIs on the instance

### Scanner Bootstrap

1. After attaching security groups, Lambda waits for instance to be running
2. Lambda waits for SSM agent to come online
3. Lambda executes the SSM document with the scanner's SSH public key
4. SSM document creates the scanner user with:
   - SSH key authentication
   - Passwordless sudo access
   - Proper file permissions

## Security Considerations

- The SSH public key is stored securely in SSM Parameter Store as a SecureString (encrypted with KMS)
- Lambda has least-privilege permissions to read only the specific parameter and decrypt it with KMS
- Scanner user has sudo access (required for vulnerability scanning)
- All actions are logged to CloudWatch Logs
- KMS key access can be restricted by setting the `kms_key_arn` variable to a specific key ARN

## Troubleshooting

### Security group not attached
- Verify VPC has a `Name` tag
- Check that the VPC name matches a key in `vpc_sg_mappings`
- Verify security group exists with the configured name
- Check Lambda CloudWatch logs for errors

### Scanner user not created
- Verify instance has SSM agent installed and running
- Check that the Lambda can retrieve the SSH public key from Parameter Store
- Review SSM command execution history in AWS Systems Manager
- Verify Lambda has waited long enough for SSM to be online

### Permissions issues
- Lambda requires permissions to:
  - Describe EC2 instances, VPCs, security groups, and network interfaces
  - Modify network interface attributes
  - Send SSM commands
  - Read SSM parameters
  - Decrypt SecureString parameters using KMS
