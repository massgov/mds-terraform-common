## ECS Fargate Alerting for New Relic

This sub-module is intended to provide alerting primarily for ECS clusters with running in Fargate.

### Prerequisites

The alerting conditions created by this module rely on [Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html) being enabled for all clusters specified by the [filter\_cluster\_names](#input\_filter\_cluster\_names) variable. Trying to use this module for clusters not shipping Container Insights metrics to New Relic may produce unexpected behavior.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_newrelic"></a> [newrelic](#requirement\_newrelic) | >= 2.44 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cpu"></a> [cpu](#module\_cpu) | ../nrql-alert | n/a |
| <a name="module_memory"></a> [memory](#module\_memory) | ../nrql-alert | n/a |
| <a name="module_task_count"></a> [task\_count](#module\_task\_count) | ../nrql-alert | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The account number for the New Relic account. | `string` | n/a | yes |
| <a name="input_aggregation_window"></a> [aggregation\_window](#input\_aggregation\_window) | See newrelic\_nrql\_alert\_condition.aggregation\_window. | `number` | `60` | no |
| <a name="input_alert_policy_id"></a> [alert\_policy\_id](#input\_alert\_policy\_id) | The id of the New Relic alert policy. | `string` | n/a | yes |
| <a name="input_cpu_threshold"></a> [cpu\_threshold](#input\_cpu\_threshold) | Maximum CPU percentage allowed before triggering alert. | `number` | `90` | no |
| <a name="input_critical_threshold_duration"></a> [critical\_threshold\_duration](#input\_critical\_threshold\_duration) | See newrelic\_nrql\_alert\_condition.critical.threshold\_duration. | `number` | `300` | no |
| <a name="input_filter_aws_accounts"></a> [filter\_aws\_accounts](#input\_filter\_aws\_accounts) | List of AWS account ids to monitor. | `list(string)` | `[]` | no |
| <a name="input_filter_cluster_names"></a> [filter\_cluster\_names](#input\_filter\_cluster\_names) | List of ECS cluster names to monitor. Note that the clusters being monitored must have Container Insights enabled. | `list(string)` | `[]` | no |
| <a name="input_memory_threshold"></a> [memory\_threshold](#input\_memory\_threshold) | Maximum memory percentage allowed before triggering alert. | `number` | `90` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Name prefix for the alert condition | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the alert conditions. Tag values can either be a single string or a list of strings. | `map(any)` | `{}` | no |
| <a name="input_task_count_threshold"></a> [task\_count\_threshold](#input\_task\_count\_threshold) | Minimum number of tasks in cluster before triggering alert | `number` | `3` | no |
| <a name="input_task_count_threshold_duration"></a> [task\_count\_threshold\_duration](#input\_task\_count\_threshold\_duration) | See newrelic\_nrql\_alert\_condition.critical.threshold\_duration. | `number` | `600` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->