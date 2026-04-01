# Tenable Security Resources Module

This Terraform module takes care of security group management and scanner access for EC2 instances automatically. Basically, it makes sure your Tenable scanners can access all your instances without you having to touch every single repo.

## What does it do?

- **Auto-attaches security groups** - Watches for new EC2 instances via EventBridge and slaps on the right scanner security group based on which VPC they're in
- **IAM policy management** - Automatically gives instance roles permission to read scanner secrets from Parameter Store (works for both existing instances when you deploy, and new ones as they spin up)
- **Creates scanner users** - Drops an SSH user on each instance with the right public key and sudo access
- **All via SSM** - Uses Systems Manager to do the bootstrapping, so no need for direct SSH access

## How it's set up

The module uses a few moving parts:

1. **EventBridge rules** watch for:
   - New instances launching (`RunInstances`)
   - Security group changes (`ModifyInstanceAttribute`, `ModifyNetworkInterfaceAttribute`)

2. **Lambda function** handles the automation:
   - Figures out which security group to attach based on VPC name
   - Attaches security groups to instance network interfaces
   - Adds the scanner IAM policy to the instance's role
   - Kicks off the SSM document to create the scanner user

3. **Terraform data sources** (at deployment time):
   - Scans for all running EC2 instances
   - Grabs their IAM roles
   - Attaches the scanner policy to everything it finds

4. **SSM Document** does the actual work on each instance:
   - Pulls the SSH public key from Parameter Store
   - Creates the scanner user with proper permissions

## Usage

Pretty straightforward - just point it at your VPC/security group mappings and the Parameter Store path:

```hcl
module "tenable_security" {
  source = "./tenable-security-resources"

  vpc_sg_mappings = {
    "VPC-NonProd" = "scanners-sg-VPC-NonProd"
    "VPC-Prod"    = "scanners-sg-VPC-Prod"
    "VPC-Mgt"     = "scanners-sg-VPC-Mgt"
  }

  scanner_secret_parameter_name = "/scanner/prod/api-token"
  scanner_username              = "scanner-user-mydigital"

  # Optional stuff if you want to customize:
  # lambda_function_name = "instance-sg-remediator"
  # ssm_document_name    = "scanner-bootstrap-setup"
  # kms_key_arn          = "*"
}
```

**And you're done!** Once deployed, the module handles everything:
- Immediately attaches the scanner policy to all your existing instances' IAM roles
- Keeps doing it automatically for every new instance that launches

No need to touch anything in your other repos.

### What happens when you deploy

When you run `terraform apply`, the module will:
- Find all running EC2 instances in the region
- Pull their instance profile and IAM role names
- Attach the `ec2-scanner-secret-access` policy to each role
- Show you what it found in the outputs

You can check what got updated:
```bash
terraform output discovered_role_names
# Output: ["app-server-role", "web-server-role", "database-server-role"]
```

## Prerequisites

A few things need to be in place before you deploy this:

1. **CloudTrail needs to be on** - The EventBridge rules listen for CloudTrail events. Make sure CloudTrail is:
   - Running in your region
   - Logging management events
   - Capturing EC2 API calls

2. **Create the SSH key in Parameter Store** - Stash your scanner's public key:
   ```bash
   aws ssm put-parameter \
     --name "/scanner/prod/api-token" \
     --type "SecureString" \
     --value "ssh-rsa AAAAB3... your-public-key"
   ```

3. **IAM permissions (handled automatically!)** - Don't worry about this one. The module takes care of attaching the right IAM policy to your instance roles. It happens both when you deploy and whenever new instances launch.

   The policy gives instances access to:
   - Read the SSH key from Parameter Store (`ssm:GetParameter`)
   - Decrypt it with KMS (`kms:Decrypt`)

4. **Your instances need SSM basics**:
   - SSM Agent installed and running (already there on Amazon Linux 2, AL2023, etc.)
   - An IAM instance profile with `AmazonSSMManagedInstanceCore` policy
   - AWS CLI installed (so the bootstrap script can pull the key from Parameter Store)

5. **Security groups must exist** - The security groups you list in `vpc_sg_mappings` should already be created with the right scanner access rules.

6. **VPC tags matter** - Your VPCs need a `Name` tag that matches what you put in `vpc_sg_mappings`.

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vpc_sg_mappings` | Map VPC names to their scanner security groups | `map(string)` | n/a | yes |
| `scanner_secret_parameter_name` | Path to the SSH public key in Parameter Store (needs to start with `/`) | `string` | n/a | yes |
| `kms_key_arn` | KMS key for decrypting the secret - use `*` for any key or specify one | `string` | `*` | no |
| `scanner_username` | What to name the scanner user on instances | `string` | `nessus-user-massdigital` | no |
| `lambda_function_name` | Lambda function name | `string` | `ec2-scanner-sg-remediator` | no |
| `ssm_document_name` | SSM document name | `string` | `scanner-bootstrap-setup` | no |
| `region` | AWS region | `string` | `us-east-1` | no |

## Outputs

| Name | Description |
|------|-------------|
| `lambda_name` | Lambda function name |
| `lambda_arn` | Lambda function ARN |
| `ssm_document_name` | SSM document name |
| `runinstances_rule_name` | EventBridge rule that watches for new instances |
| `sg_change_rule_name` | EventBridge rule that watches for security group changes |
| `ec2_scanner_policy_arn` | ARN of the scanner IAM policy (in case you need it) |
| `ec2_scanner_policy_json` | The actual policy document in JSON |
| `discovered_instance_profile_names` | Instance profiles that were found when you deployed |
| `discovered_role_names` | IAM roles that got the scanner policy attached during deployment |

## How It Works

### IAM Policy Attachment (the whole point)

**During Terraform apply:**
- Queries all running EC2 instances
- Grabs each instance's IAM role
- Attaches the scanner policy to each unique role
- Spits out a list so you can see what got updated

**When new instances launch:**
- EventBridge catches the launch event and triggers Lambda
- Lambda looks at the new instance and finds its IAM role
- Checks if the scanner policy is already attached
- If not, attaches it
- Now the instance can pull the scanner secret from Parameter Store

### Security Group Attachment

- EventBridge sees a new instance or security group change
- Lambda wakes up and looks at the instance's VPC
- Matches the VPC name to your mappings
- Attaches the right security group to the instance's network interfaces

### Scanner Bootstrap Process

Once the security groups and IAM policy are sorted:
- Lambda waits for the instance to be fully running
- Waits for SSM Agent to come online
- Kicks off the SSM document
- The document runs on the instance and:
  - Uses AWS CLI to grab the SSH public key from Parameter Store
  - Creates the scanner user with the key
  - Sets up passwordless sudo
  - Makes sure file permissions are correct

## Security Notes

- The SSH public key lives in Parameter Store as a SecureString (encrypted with KMS)
- EC2 instances pull the key directly during bootstrap - Lambda never sees it
- Lambda only passes the parameter name, not the actual secret
- The scanner user gets sudo access (needed for vulnerability scanning to work)
- Everything gets logged to CloudWatch
- You can lock down KMS access by setting `kms_key_arn` to a specific key instead of `*`

## Troubleshooting

### Security group not showing up on an instance
- Check if the VPC has a `Name` tag
- Make sure the VPC name matches something in your `vpc_sg_mappings`
- Verify the security group actually exists
- Look at Lambda's CloudWatch logs for errors

### Scanner user didn't get created
- Is SSM Agent running on the instance?
- Does the instance's IAM role have permission to read from Parameter Store? (Should be automatic, but check the outputs to see if the role got the policy)
- Is AWS CLI installed on the instance?
- Check SSM command history in the AWS console
- Look at SSM logs on the instance itself: `/var/log/amazon/ssm/`
- Maybe Lambda didn't wait long enough for SSM to be ready (check the logs)

### Permission errors
- Lambda needs:
  - EC2 read permissions (describe instances, VPCs, security groups, network interfaces)
  - Permission to modify network interface attributes
  - SSM SendCommand permissions
  - IAM permissions to attach policies to roles
- EC2 instances need:
  - `ssm:GetParameter` to read the scanner secret
  - `kms:Decrypt` to decrypt it
  - Basic SSM permissions (`AmazonSSMManagedInstanceCore`)
