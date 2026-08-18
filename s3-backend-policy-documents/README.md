# S3 Backend Policy Documents

This module creates IAM policy documents to allow access to terraform state files in an S3 bucket.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.45 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.45 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy_document.policy_info](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_kms_key"></a> [bucket\_kms\_key](#input\_bucket\_kms\_key) | Default bucket key for the state bucket. | `string` | n/a | yes |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket used for terraform state. | `string` | n/a | yes |
| <a name="input_state_file_paths"></a> [state\_file\_paths](#input\_state\_file\_paths) | Paths where the state file will be saved. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_apply_policy_json"></a> [apply\_policy\_json](#output\_apply\_policy\_json) | n/a |
| <a name="output_plan_policy_json"></a> [plan\_policy\_json](#output\_plan\_policy\_json) | n/a |
<!-- END_TF_DOCS -->