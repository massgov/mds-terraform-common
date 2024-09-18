<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.26 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The AWS account ID | `string` | n/a | yes |
| <a name="input_publish_alerts_policy"></a> [publish\_alerts\_policy](#input\_publish\_alerts\_policy) | An IAM policy that allows writing to the SNS topic | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | The SNS topic to send the reminder to | `string` | n/a | yes |

## Outputs

No outputs.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.github_soe_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.github_soe_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.github_soe_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github_soe_publish_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_ssm_document.remind_github_inactive_users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_maintenance_window.remind_github_inactive_users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window) | resource |
| [aws_ssm_maintenance_window_task.remind_github_inactive_users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github_soe_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
<!-- END_TF_DOCS -->