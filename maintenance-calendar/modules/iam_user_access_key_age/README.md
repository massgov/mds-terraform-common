# iam-key-rotation-notifier

Terraform module that monitors IAM access key ages for filtered users and publishes SNS **WARNING** / **ALERT** notifications when keys exceed configurable thresholds.

**What it creates:**

- An **SNS topic** *(optional — skip by passing `sns_topic_arn`)* with optional e-mail subscriptions
- A **Lambda function** (Python 3.12) that scans IAM users by name glob and optional tag, checks each active key's age, and publishes structured JSON alerts
- An **EventBridge rule** that invokes the Lambda on a configurable schedule (default: daily)
- A least-privilege **IAM execution role** (`iam:ListUsers`, `iam:ListAccessKeys`, `iam:ListUserTags`, `sns:Publish`, CloudWatch Logs)
- A **CloudWatch Log Group** with configurable retention

**SNS message format:**

```json
{
  "level":     "WARNING | ALERT",
  "username":  "jane.doe",
  "key_id":    "AKIAIOSFODNN7EXAMPLE",
  "age_days":  85,
  "threshold": 80,
  "message":   "IAM access key AKIAIOSFODNN7EXAMPLE for user 'jane.doe' is 85 days old. ..."
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Short prefix used to name every resource created by this module (e.g. `"myapp"`). | `string` | n/a | yes |
| <a name="input_alert_days"></a> [alert\_days](#input\_alert\_days) | Publish an ALERT notification when a key is this many days old. Must be >= `warning_days`. | `number` | `90` | no |
| <a name="input_lambda_log_retention_days"></a> [lambda\_log\_retention\_days](#input\_lambda\_log\_retention\_days) | CloudWatch log group retention in days. | `number` | `14` | no |
| <a name="input_lambda_memory_mb"></a> [lambda\_memory\_mb](#input\_lambda\_memory\_mb) | Lambda function memory in MB. | `number` | `128` | no |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Lambda function timeout in seconds. | `number` | `300` | no |
| <a name="input_name_pattern"></a> [name\_pattern](#input\_name\_pattern) | Glob pattern matched against IAM usernames (e.g. `"*Example*"`). Defaults to all users. | `string` | `"*"` | no |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | EventBridge schedule expression. Defaults to once per day. | `string` | `"rate(1 day)"` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | ARN of an existing SNS topic. When set, no topic is created and `sns_email_subscriptions` is ignored. | `string` | `null` | no |
| <a name="input_sns_email_subscriptions"></a> [sns\_email\_subscriptions](#input\_sns\_email\_subscriptions) | E-mail addresses to subscribe to the SNS topic created by this module. Ignored when `sns_topic_arn` is provided. | `list(string)` | `[]` | no |
| <a name="input_tag_key"></a> [tag\_key](#input\_tag\_key) | Optional IAM tag key. When set, only users that carry this tag (with `tag_value`) are checked. | `string` | `""` | no |
| <a name="input_tag_value"></a> [tag\_value](#input\_tag\_value) | Optional IAM tag value paired with `tag_key`. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags applied to every resource. | `map(string)` | `{}` | no |
| <a name="input_warning_days"></a> [warning\_days](#input\_warning\_days) | Publish a WARNING notification when a key is this many days old. | `number` | `80` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eventbridge_rule_arn"></a> [eventbridge\_rule\_arn](#output\_eventbridge\_rule\_arn) | ARN of the EventBridge rule that triggers the Lambda. |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda function. |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the Lambda function. |
| <a name="output_lambda_iam_role_arn"></a> [lambda\_iam\_role\_arn](#output\_lambda\_iam\_role\_arn) | ARN of the IAM execution role used by the Lambda function. |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | ARN of the SNS topic used for key-age notifications (created by this module or passed in via `sns_topic_arn`). |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [archive_file.lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.lambda_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
<!-- END_TF_DOCS -->

## Usage

```hcl
module "iam_key_notifier" {
  source = "path/to/iam-key-rotation-notifier"

  name_prefix  = "myapp"
  name_pattern = "*Example*"   # glob filter on IAM usernames

  warning_days = 80
  alert_days   = 90

  sns_email_subscriptions = ["security@example.com"]

  schedule_expression = "cron(0 8 * * ? *)"  # 08:00 UTC daily

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

To also filter by IAM tag:

```hcl
module "iam_key_notifier" {
  source = "path/to/iam-key-rotation-notifier"

  name_prefix  = "myapp"
  name_pattern = "*ServiceAccount*"
  tag_key      = "Environment"
  tag_value    = "prod"

  warning_days = 60
  alert_days   = 75

  sns_email_subscriptions = ["ops@example.com"]
}
```

After running `terraform apply`, confirm the SNS subscription via the confirmation e-mail AWS sends to each address in `sns_email_subscriptions`.

### Bring your own SNS topic

Pass an existing topic ARN — no topic or subscriptions will be created:

```hcl
module "iam_key_notifier" {
  source = "path/to/iam-key-rotation-notifier"

  name_prefix   = "myapp"
  name_pattern  = "*Example*"
  sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:my-existing-topic"

  warning_days = 80
  alert_days   = 90
}
```
