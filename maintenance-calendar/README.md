<!-- BEGIN_TF_DOCS -->


## Example

```hcl
  module "calendar" {
  source = "example.com/maintenance-calendar"

  maintenance_sns_topic   = "testsnstopic"
  maintenance_logs_bucket = "12345-maintenance-logs"

  create_github_inactive_user_reminder = true
  create_ecs_scans                     = true
  create_rds_snapshots                 = true

  scan_ecs_clusters = {
    foo = [
      "bar",
      "baz"
    ]
  }
  scan_ecr_repositories = {
    foo = [
      "bar",
      "baz"
    ]
  }
  rds_instance_names = [
    "database-1",
    "database-2"
  ]
}
```
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.26 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs_scans"></a> [ecs\_scans](#module\_ecs\_scans) | ./modules/ecs_scans | n/a |
| <a name="module_github_inactive_user_reminder"></a> [github\_inactive\_user\_reminder](#module\_github\_inactive\_user\_reminder) | ./modules/github_inactive_user_reminder | n/a |
| <a name="module_rds_snapshots"></a> [rds\_snapshots](#module\_rds\_snapshots) | ./modules/rds_snapshots | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_maintenance_logs_bucket"></a> [maintenance\_logs\_bucket](#input\_maintenance\_logs\_bucket) | Name of the S3 bucket to store maintenance logs | `string` | n/a | yes |
| <a name="input_maintenance_sns_topic"></a> [maintenance\_sns\_topic](#input\_maintenance\_sns\_topic) | Name of the SNS topic to use for maintenance notifications | `string` | n/a | yes |
| <a name="input_create_ecs_scans"></a> [create\_ecs\_scans](#input\_create\_ecs\_scans) | Determines if maintenance calendar tasks for ECS/ECR scanning will be created | `bool` | `false` | no |
| <a name="input_create_github_inactive_user_reminder"></a> [create\_github\_inactive\_user\_reminder](#input\_create\_github\_inactive\_user\_reminder) | Determines if the inactive github user reminder will be created | `bool` | `false` | no |
| <a name="input_create_rds_snapshots"></a> [create\_rds\_snapshots](#input\_create\_rds\_snapshots) | Determines if maintenance calendar tasks for managaing RDS snapshots will be created | `bool` | `false` | no |
| <a name="input_maintenance_sns_display_name"></a> [maintenance\_sns\_display\_name](#input\_maintenance\_sns\_display\_name) | (Optional) Display name for the maintenance notifications SNS topic | `string` | `null` | no |
| <a name="input_rds_instance_names"></a> [rds\_instance\_names](#input\_rds\_instance\_names) | A list of RDS instance names we want to manage snapshots for | `list(string)` | `null` | no |
| <a name="input_scan_ecr_repositories"></a> [scan\_ecr\_repositories](#input\_scan\_ecr\_repositories) | Map relating project titles to a list of ECR repository names which ought to be scanned periodically | <pre>map(<br>    list(string)<br>  )</pre> | `{}` | no |
| <a name="input_scan_ecs_clusters"></a> [scan\_ecs\_clusters](#input\_scan\_ecs\_clusters) | Map relating project titles to a list of ECS cluster names which ought to be scanned periodically | <pre>map(<br>    list(string)<br>  )</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_notifications_topic_arn"></a> [notifications\_topic\_arn](#output\_notifications\_topic\_arn) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.maintenance_logs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.maintenance_publish_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.maintenance_logs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.maintenance_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.maintenance_logs_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.maintenance_logs_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.maintenance_logs_owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.maintenance_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.maintenance_logs_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_sns_topic.maintenance_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.maintenance_logs_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.maintenance_publish_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
<!-- END_TF_DOCS -->