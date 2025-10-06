# AWS IAM User accesskeys rotation

This solution rotates IAM user access keys for only the users defined in the `targeted_users` variable. If a user is not listed in `targeted_users`, no rotation or modification will take place for that user.

## Overview

- Access keys and secret keys are rotated for IAM users listed in `targeted_users` if created on or after `<x>` days (defaults to 30 days unless specified).
- Keys are stored in AWS Secrets Manager. After a user retrieves their secret key, you can delete the secret, but it will be re-created upon the next rotation.
- If a user has only **INACTIVE** keys, no rotation or modification takes place; that user is skipped.
- If a user has **NO** keys, they are skipped.
- If a user has two **ACTIVE** access keys, the oldest active key will always be rotated with a new access key (IAM allows only two keys max at a time).

## How it Works

This deployment uses two Lambda functions to rotate IAM user access keys for every `x` days (default is 30 days, configurable via the `days_to_rotate` variable):

1. **Scheduled EventBridge Event** triggers the `remove_inactive_accesskeys` Lambda function daily.
2. This Lambda checks the IAM access keys for users in `targeted_users` and removes inactive keys according to the `days_to_remove_inactive` variable (default is 15 days of being inactive). The user must also have an ACTIVE access key for this to work.
3. The `remove_inactive_accesskeys` Lambda then invokes the `iam_user_rotate_accesskeys` Lambda function for each targeted user.
4. The rotation Lambda:
   - Sets expired access keys to INACTIVE.
   - Creates a new access key and writes the new access key and secret key into AWS Secrets Manager.
   - Updates the secret if it already exists, or creates it if not.
   - Attaches a policy to the secret so only the admin and the specific user can view their own secret.

## Usage

- The solution is compiled and ready to deploy (the `.zip` files must remain).
- Requires Terraform version 1.0.5 or higher.
- Change variables in `terraform.tfvars` to suit your rotation schedule and targeted users.
- Run `terraform init` and `terraform apply` to deploy.

## Summary

- Variables for 'days till rotation', 'region', and 'days till inactive' are found in `terraform.tfvars` and can be changed.
- Only IAM users listed in `targeted_users` will have their keys rotated.
- Inactive keys older than the configured threshold are deleted.
- Only users with at least one ACTIVE key are processed.
- Keys older than the configured rotation threshold are deactivated and replaced.
- Secrets are stored in Secrets Manager with user-specific access policies.

## Modifying or Packaging Lambda Functions with PowerShell (cross-platform:pwsh)

To package or make modifications to your Lambda functions written in PowerShell, follow these steps:

1. Install the AWS Lambda PowerShell module:
   ```powershell
   Install-Module AWSLambdaPSCore -Force
   ```

2. Import the module:
   ```powershell
   Import-Module AWSLambdaPSCore
   ```
   
3. Navigate to the directory containing the raw PowerShell scripts (e.g., `raw/remove_inactive_keys.ps1` , `raw/secret_rotation_lambda.ps1`) and make any necessary changes to your code, and save the updated files.

4. Package your PowerShell script for Lambda deployment (this is used in the terraform resource):
   ```powershell
   New-AWSPowerShellLambdaPackage `
     -ScriptPath .\remove_inactive_keys.ps1 `
     -OutputPackage .\remove_inactive_keys.zip
   ```

The resulting `.zip` file can be used for deployment with Terraform.