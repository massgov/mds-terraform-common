<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.26 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.26 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs_cluster_image_scan"></a> [ecs\_cluster\_image\_scan](#module\_ecs\_cluster\_image\_scan) | github.com/massgov/mds-terraform-common//lambda | 1.0.88 |
| <a name="module_github_inactive_user_reminder"></a> [github\_inactive\_user\_reminder](#module\_github\_inactive\_user\_reminder) | ./modules/github_inactive_user_reminder | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.ecr_image_scan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.maintenance_ecs_scan_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.maintenance_logs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.maintenance_publish_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.maintenance_run_automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.rds_backups_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.maintenance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.rds_backups_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecr_image_scan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.maintenance_logs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.maintenance_publish_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.maintenance_run_automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.maintenance_window](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.rds_backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.rds_backups_maintenance_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.rds_backups_publish_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.maintenance_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.maintenance_logs_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.maintenance_logs_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.maintenance_logs_owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.maintenance_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.maintenance_logs_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_sns_topic.maintenance_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_ssm_document.ssr_clean_up_rds_snapshots](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.ssr_create_rds_snapshot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.ssr_scan_ecr_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_maintenance_window.ecr_image_scan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window) | resource |
| [aws_ssm_maintenance_window.rds_backups_window](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window) | resource |
| [aws_ssm_maintenance_window_task.ecr_image_scan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_ssm_maintenance_window_task.rds_create_backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_ssm_maintenance_window_task.rds_destroy_backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_maintenance_window_task) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_db_instances.dbinstance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_instances) | data source |
| [aws_iam_policy_document.ecr_image_scan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.maintenance_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.maintenance_ecs_scan_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.maintenance_logs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.maintenance_publish_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.maintenance_run_automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.rds_backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_github_inactive_user_reminder"></a> [create\_github\_inactive\_user\_reminder](#input\_create\_github\_inactive\_user\_reminder) | Determines if the inactive github user reminder will be created | `bool` | `false` | no |
| <a name="input_maintenance_logs_bucket"></a> [maintenance\_logs\_bucket](#input\_maintenance\_logs\_bucket) | Name of the S3 bucket to store maintenance logs | `string` | n/a | yes |
| <a name="input_maintenance_sns_display_name"></a> [maintenance\_sns\_display\_name](#input\_maintenance\_sns\_display\_name) | (Optional) Display name for the maintenance notifications SNS topic | `string` | `null` | no |
| <a name="input_maintenance_sns_topic"></a> [maintenance\_sns\_topic](#input\_maintenance\_sns\_topic) | Name of the SNS topic to use for maintenance notifications | `string` | n/a | yes |
| <a name="input_rds_instance_names"></a> [rds\_instance\_names](#input\_rds\_instance\_names) | A list of RDS instance names we want to manage backups for | `list(string)` | `null` | no |
| <a name="input_scan_ecr_repositories"></a> [scan\_ecr\_repositories](#input\_scan\_ecr\_repositories) | Map relating project titles to a list of ECR repository names which ought to be scanned periodically | <pre>map(<br>    list(string)<br>  )</pre> | `{}` | no |
| <a name="input_scan_ecs_clusters"></a> [scan\_ecs\_clusters](#input\_scan\_ecs\_clusters) | Map relating project titles to a list of ECS cluster names which ought to be scanned periodically | <pre>map(<br>    list(string)<br>  )</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_notifications_topic_arn"></a> [notifications\_topic\_arn](#output\_notifications\_topic\_arn) | n/a |
<!-- END_TF_DOCS -->