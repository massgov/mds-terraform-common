<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.26 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs_cluster_image_scan"></a> [ecs\_cluster\_image\_scan](#module\_ecs\_cluster\_image\_scan) | github.com/massgov/mds-terraform-common//lambda | 1.0.88 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The AWS account ID | `string` | n/a | yes |
| <a name="input_publish_alerts_policy"></a> [publish\_alerts\_policy](#input\_publish\_alerts\_policy) | An IAM policy that allows writing to the SNS topic | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | The SNS topic to send alerts to | `string` | n/a | yes |
| <a name="input_scan_ecr_repositories"></a> [scan\_ecr\_repositories](#input\_scan\_ecr\_repositories) | Map relating project titles to a list of ECR repository names which ought to be scanned periodically | <pre>map(<br>    list(string)<br>  )</pre> | `{}` | no |
| <a name="input_scan_ecs_clusters"></a> [scan\_ecs\_clusters](#input\_scan\_ecs\_clusters) | Map relating project titles to a list of ECS cluster names which ought to be scanned periodically | <pre>map(<br>    list(string)<br>  )</pre> | `{}` | no |

## Outputs

No outputs.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.ecs_scans_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.maintenance_ecs_scan_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_scans_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_scans](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_scans_publish_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_ssm_document.ssr_scan_ecr_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_maintenance_window.ecr_image_scan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window) | resource |
| [aws_ssm_maintenance_window_task.ecr_image_scan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_scans](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.maintenance_ecs_scan_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
<!-- END_TF_DOCS -->