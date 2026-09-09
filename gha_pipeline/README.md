Github Actions Pipeline
=======================

This Terraform module configures an AWS role that is assumable by Github Actions in order to handle deployment pipelines that create/modify AWS resources.

Once the pipeline has been configured, a Github Action can be written that pulls in credentials like so:

```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v1
  with:
    role-to-assume: arn:aws:iam::12345:role/my-project-actions-role
    aws-region: us-east-1
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.26.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.60.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.policy_attachments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.assume_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allow_legacy_subject"></a> [allow\_legacy\_subject](#input\_allow\_legacy\_subject) | Accept the legacy OIDC subject claim (repo:ORG/REPO:...) | `bool` | `true` | no |
| <a name="input_custom_policy_json"></a> [custom\_policy\_json](#input\_custom\_policy\_json) | IAM policy document to attach inline to the role, use jsonencode() to convert Terraform language expressions to JSON | `string` | `""` | no |
| <a name="input_gh_org"></a> [gh\_org](#input\_gh\_org) | n/a | `string` | n/a | yes |
| <a name="input_gh_repo"></a> [gh\_repo](#input\_gh\_repo) | n/a | `string` | n/a | yes |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | n/a | `string` | n/a | yes |
| <a name="input_oidc_subject_claims"></a> [oidc\_subject\_claims](#input\_oidc\_subject\_claims) | n/a | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_org_id"></a> [org\_id](#input\_org\_id) | GitHub organization ID, required unless allow\_legacy\_subject is true | `string` | `""` | no |
| <a name="input_policy_arns"></a> [policy\_arns](#input\_policy\_arns) | n/a | `list(string)` | n/a | yes |
| <a name="input_repo_id"></a> [repo\_id](#input\_repo\_id) | Github repository ID, required unless allow\_legacy\_subject is true | `string` | `""` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the IAM role created for the GitHub Actions pipeline |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | value of the IAM role name created for the GitHub Actions pipeline |
| <a name="output_policy_attachment_ids"></a> [policy\_attachment\_ids](#output\_policy\_attachment\_ids) | List of policy attachment IDs for the IAM role |
<!-- END_TF_DOCS -->