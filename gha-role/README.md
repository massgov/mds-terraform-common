# GitHub Actions Role

This module creates an IAM role that can be assumed by GitHub Actions. The role is created with a trust policy that allows the GitHub Actions OIDC provider to assume the role.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.45 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.45 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_policy_document.assume_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gh_org"></a> [gh\_org](#input\_gh\_org) | The name of the organization that owns the repository. | `string` | n/a | yes |
| <a name="input_gh_repo"></a> [gh\_repo](#input\_gh\_repo) | The name of the repository. | `string` | n/a | yes |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | The ARN of the Github Actions OIDC provider. | `string` | n/a | yes |
| <a name="input_oidc_subject_claims"></a> [oidc\_subject\_claims](#input\_oidc\_subject\_claims) | Additional filters to use for who can assume the role. You can filter by branch, tag, or environment. | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| <a name="input_policy_arns"></a> [policy\_arns](#input\_policy\_arns) | IAM policies to attach to the role. | `list(string)` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | The name of the role to create. | `string` | n/a | yes |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | The path for the role. | `string` | `"/soe/"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | n/a |
<!-- END_TF_DOCS -->
