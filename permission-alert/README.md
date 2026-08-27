# IAM Role Admin Privilege Monitor

This project provides an automated way to **monitor IAM roles for privilege escalation**. It leverages AWS EventBridge, Lambda, and SNS to detect when IAM role permissions change and sends an alert if administrative privileges are added.

---

## Overview

- **Input:** One or more IAM role names to monitor.
- **Event Trigger:** AWS EventBridge rule that listens for `IAM Role Policy` changes.
- **Detection:** A Lambda function (written in TypeScript) inspects the target role’s:
  - Inline policies
  - Attached custom policies
  - Attached managed policies
- **Alerting:** If the role gains `AdministratorAccess` or wildcard permissions (`*` actions/resources), the Lambda publishes a message to the specified SNS topic.

This helps prevent **unauthorized privilege escalation** in AWS accounts.

---

## Architecture

1. **Terraform Module**
   - Creates EventBridge rule for IAM role policy changes
   - Provisions a Lambda function with detection logic
   - Grants Lambda necessary IAM permissions
   - Connects Lambda to SNS topic for alerts

2. **Lambda Function (TypeScript)**
   - Fetches IAM role policy details
   - Detects admin-like privileges
   - Publishes findings to SNS

---

## Project Structure

.
├── main.tf # Root module entrypoint
├── iam.tf # IAM permissions for Lambda
├── lambda.tf # Lambda packaging and deployment
├── cw_events.tf # CloudWatch / EventBridge rules
├── outputs.tf # Module outputs
├── variables.tf # Input variables
├── versions.tf # Provider versions
└── lambda/

---

## Inputs

| Variable        | Type           | Description                                                     |
| --------------- | -------------- | --------------------------------------------------------------- |
| `role_names`    | `list(string)` | List of IAM role names to monitor (e.g. `["role_A", "role_B"]`) |
| `sns_topic_arn` | `string`       | ARN of an existing SNS topic to publish alerts                  |

---

## Outputs

| Output        | Description                                          |
| ------------- | ---------------------------------------------------- |
| `lambda_name` | Name of the monitoring Lambda function               |
| `rule_arn`    | ARN of the EventBridge rule that triggers the Lambda |

---

## Usage

Example Terraform configuration:

```hcl
module "iam_role_alerts" {
  source        = "<path_to_this_repository_and_version>"
  sns_topic_arn = aws_sns_topic.role_policy_alerts.arn
  role_names    = ["my-infra-apply-role", "my-infra-plan-role"]
}
```
