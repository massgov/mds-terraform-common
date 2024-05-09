# Changelog

## [1.0.92] - 2024-05-09

- [Github to Teams] Upgrade lambda runtime to node20
- [Teams Alerts] Upgrade lambda runtime to node20
- [Entrypoint Monitor] Upgrade lambda runtime to node20
- [RDS] Upgrade backup and cleanup lambda runtimes to node20

## [1.0.91] - 2024-04-25

- [Golden AMI Lookup] Update regex to look up SSR Image Builder AMI instead

## [1.0.90] - 2024-04-25

- [Golden AMI Builder] Adds new module which sets up an Image Builder pipeline for creating an EOTSS-compliant Golden AMI.

## [1.0.89] - 2024-04-16

- [Entrypoint Monitor] Update so CloudFront S3 uses regional endpoint

## [1.0.88] - 2024-01-20

- [Golden AMI Lookup] Fix an incorrectly quoted variable type.

## [1.0.87] - 2024-01-17

- [New Relic] Add module for certificate check monitors.

## [1.0.86] - 2024-01-16

- [New Relic] Added modules for synthetics alerts.

## [1.0.85] - 2023-12-20

- [New Relic] Fix memory alert for containers with soft memory limit.
- [New Relic] Allow excluding volumes from storage alert by mount point.

## [1.0.84] - 2023-12-06

- [New Relic] Add separate thresholds for EC2 alert module.

## [1.0.83] - 2023-12-04

- [New Relic] Improve naming for all alert conditions.

## [1.0.82] - 2023-12-01

- [CloudFront Geo Restriction] Mark country codes as nonsensitive in terraform.

## [1.0.81] - 2023-11-29

- [Golden AMI Backup] Adds a reusable Lambda function for making automated copies of Golden AMIs

## [1.0.80] - 2023-11-21

- [New Relic] Add Lambda alerts

## [1.0.79] - 2023-11-17

- [Static Site] Use domain-certificate module (DRY)

## [1.0.78] - 2023-11-13

- [RDS] Allow consumers to turn off cleanup lambda

## [1.0.77] - 2023-11-08

- [VPC Read] Upgrade to latest syntax for subnet ID lists

## [1.0.76] - 2023-11-07

- [Entrypoint Monitor] Upgrade vulnerable package versions

## [1.0.75] - 2023-11-07

- [RDS] Upgrade vulnerable package versions for backup and cleanup lambdas

## [1.0.74] - 2023-11-06

- [Slack Alerts] Upgrade vulnerable package versions and archive

## [1.0.73] - 2023-11-03

- [Github to Teams] Upgrade vulnerable package versions

## [1.0.71] - 2023-11-02

- [New Relic] Add ECS Container alerts
- [New Relic] Add RDS Database alerts

## [1.0.70] - 2023-11-02

- [New Relic] Add option to use NR agent metrics for EC2 alerts.

## [1.0.69] - 2023-10-18

- [New Relic] Fix EC2 cloudconfig template.

## [1.0.68] - 2023-10-17

- [New Relic] Add New Relic EC2 agent cloudconfig template.

## [1.0.67] - 2023-10-16

- [New Relic] Add New Relic ECS Cluster alerts.

## [1.0.66] - 2023-10-11

- [ECS Cluster] Remove default ami.
- [Golden AMI Lookup] Add module to look up golden ami id.

## [1.0.65] - 2023-09-28

- [ASG] Fix ASG AWS version bounds.
- [New Relic] Add New Relic CloudFront events.
- [New Relic] Split EC2 loss of signal into separate alert.

## [1.0.64] - 2023-09-26

- [ECS Cluster] Expose custom cloud-init config variable

## [1.0.63] - 2023-09-21

- [Static Site] Expose CloudFront min/max TTL variables

## [1.0.62] - 2023-09-13

- [New Relic] Add New Relic integration.
- [New Relic] Add generic alert condition for EC2.

## [1.0.61] - 2023-08-30

- [GHA Pipeline] Add ability to restrict ECR policies to specific resources.

## [1.0.60] - 2023-08-21

- [GHA Pipeline] Add module for deployment through GitHub Actions

## [1.0.59] - 2023-08-15

- [ECS Cluster] Update user data to reconfigure docker data dir off of the root EBS volume

## [1.0.58] - 2023-08-10

- [ECS Cluster] Update to use AMI ID parameter maintained by SSR team

## [1.0.57] - 2023-07-17

- [AMI Block Device Reader] Add a module to read and manipulate block devices from an AMI.
- [ECS Cluster] Replace block device lookup with new module.

## [1.0.56] - 2023-07-13

- [ASG] Replace `volume_encryption` and `volume_size` variables with `block_devices` variable
- [ECS Cluster] Add `include_ami_device_names` variable to allow importing block device specifications from AMI.
- [ECS Cluster] Add `ami_volumes_delete_on_termination` variable to allow forcing `delete_on_termination` to true on block devices imported from AMI.

## [1.0.55] - 2023-07-12

- [Pipelines] Correct pipeline trigger issues

## [1.0.54] - 2023-06-26

- [RDS] Fix monthly snapshot cleanup

## [1.0.53] - 2023-06-15

- [ECS Cluster] Update module to use the Golden AMI by default.

## [1.0.52] - 2023-05-03

- [CloudFront Geo-Restriction V2] Implements geo-fencing as a WAFv2 web ACL
- [Cloudfront] Add argument enabling users to attach WAF web ACL to distribution

## [1.0.51] - 2023-05-02

- [RDS] Implemented manual snapshot backup/cleanup functionality

## [1.0.50] - 2023-04-20

- [SNS To Teams] Fixed some message formatting issues, made 'View Logs' button work

## [1.0.49] - 2023-04-18

- [Private Bucket] Add a module to contain our commonly duplicated private bucket code.

## [1.0.48] - 2023-04-18

- [Static Site] Remove AWS provider from module.

## [1.0.47] - 2023-03-28

- [Github to Teams] Upgrade to node16 runtime
- [SNS to Slack] Upgrade to node16 runtime, convert to typescript

## [1.0.46] - 2023-03-17

- [Entrypoint Monitor] Upgrade to node16 runtime, aws provider 4.8.0
- [SNS to Teams] Upgrade to node16 runtime, aws provider 4.8.0

## [1.0.45] - 2023-03-16

- [Domain] Fix static-site module for hashicorp/aws versions >= 3.

## [1.0.44] - 2023-03-15

- [Domain] Fix domain module for hashicorp/aws versions >= 3.

## [1.0.43] - 2023-03-15

- [ALL] Upgrade all modules to require terraform 0.13.
- [ALL] Add minimum provider version constraints to all modules.

## [1.0.42] - 2023-03-03

- [SNS to Teams] Add a module for subscribing Microsoft Teams incoming webhooks to SNS topics.

## [1.0.41] - 2023-02-21

- [GitHub to Teams] Add a module that converts GitHub webhooks into Teams channel messages.

## [1.0.40] - 2023-02-09

- [Entrypoint Monitor] Add support for S3 alias records to the Route53 scanner.

## [1.0.39] - 2023-02-02

- [Pipelines] - Switch from `branch_filter` to `filter_group`.

## [1.0.38] - 2022-12-21

- [Entrypoint Monitor] Grant read access to the SSM parameter.
- [Entrypoint Monitor] Let the lambda fail if the SSM parameter can't be read.

## [1.0.37] - 2022-12-21

- [Entrypoint Monitor] Properly discover default endpoints on HTTP APIs.

## [1.0.36] - 2022-12-20

- [Entrypoint Monitor] Improve formatting of the report message.

## [1.0.35] - 2022-12-14

- [Static Site] Output S3 bucket and Cloudfront distribution arns.

## [1.0.34] - 2022-11-14

- [Entrypoint Monitor] Add module with an entrypoint monitoring lambda.

## [1.0.33] - 2022-10-05

- [Lambda] Add `invoke_arn` output.
- [Lambda] Add `publish` variable to control whether a new version is published.
- [Lambda] Add `layers` variable to allow attachment of additional layers (created externally) to the function.

## [1.0.32] - 2022-07-22

- [Domain Certificate] Add standalone module for domain certificates.

## [1.0.31] - 2022-07-22

- [Static Site] Add ability to override expose_headers.

## [1.0.30] - 2022-07-08

- [CloudFront Geo-Restriction] Add helper module for projects and other modules that define CloudFront distributions.
- [Domain] Add geo-restriction.
- [Static Site] Add geo-restriction.

## [1.0.28] - 2022-06-24

- [LAMBDA] Allow configuration of ephemeral storage.

## [1.0.26] - 2020-01-25

- [SLACKALERTS] Recreated slackalerts Lambda.

## [1.0.25] - 2020-01-21

- [SLACKALERTS] Add special handling for formatting ClamAV alerts' subject and message.

## [1.0.24] - 2020-06-16

- [RDS] Add `backup_retention_period` and `performance_insights_enabled` and `performance_insights_retention_period` as RDS options

## [1.0.21] - 2020-06-16

- [Static Site] Add Cloudfront invalidation permission to the created policy.

## [1.0.20] - 2020-04-01

### Changed

- [ASG, ECS Cluster] Bump AMIs to more recent versions.

## [1.0.19] - 2020-03-31

### Added

- [Lambda] Allow setting Lambda function memory.

## [1.0.18] - 2020-02-04

### Changed

- [SLACKALERTS] Update runtime to nodejs10.x.

## [1.0.17] - 2020-01-29

### Added

- [ECS] Add `policies` as input.

## [1.0.16] - 2019-11-26

### Added

- [RDS] Added the following RDS options
  -- monitoring_interval (default 0)
  -- auto_minor_version_upgrade (default false)
  -- allow_major_version_upgrade (default false)
  -- apply_immediately (default false)

## [1.0.15] - 2019-09-19

### Added

- [ASG] Add EC2 instance connect to the default AMI.
- [ECS Cluster] Add EC2 instance connect to the default AMI.

## [1.0.14] - 2019-09-17

### Added

- [ASG] Make ASG launch with the updated AmazonSSMManagedInstanceCore policy instead of the old SSM policy.

## [1.0.13] - 2019-09-17

### Added

- [ASG] Make ASG launch template EBS optimized.

## [1.0.10] - 2019-08-28

### Fixed

- [Pipelines] Add region and account ID variables to pipeline module.

### Changed

- [All] Remove BLESS CA from packer build and update asg and ecscluster AMIs.

## [1.0.9] - 2019-08-22

### Added

- [Pipelines] Implement CI pipelines module to allow for flexible Codebuild Pipelines to apply infrastructure-as-code changes.

## [1.0.8] - 2019-08-22

### Added

- [Slack Alerts] Added Slack Alerts lambda module to fire Slack alerts based on SNS topic messages.

## [1.0.6] - 2019-07-24

### Added

- [RDS Instance] Output RDS instance ID and ARN.

## [1.0.5] - 2019-07-05

### Added

- [RDS Instance] Add ability to toggle IAM authentication for the database.

## [1.0.4] - 2019-07-03

- [ECS Cluster, ASG] Rebuilt AMI to add EC2 Instance Connect agent.

## [1.0.3] - 2019-07-01

### BREAKING

- [Static Site] Added environments to static site module to allow specifying prod and non-prod environments as part of the same invocation of the module.

## [1.0.2] - 2019-06-24

### Fixed

- [RDS Instance] Fix security group flattening issue from 0.12 upgrade.

## [1.0.1] - 2019-06-20

### Fixed

- [Domain] Fix domain count issue from 0.12 upgrade.
- [ECS Cluster] Fix security group flattening issue from 0.12 upgrade.

## [1.0.0] - 2019-06-19

### Added

- [VPC Read] Added a Terraform module to obtain data about a VPC and its subnets.

### Changed

- [ALL] Updated all Terraform modules for Terraform 0.12. Other than updating the using code to 0.12 syntax, no other changes should be required. We've likely introduced some bugs here, which we'll work through in the coming releases.s

## [0.23.0] - 2019-06-17

### Changed

- [ASG] Rebuilt AMI for updated version of SSM agent, Amazon Linux 2
- [ECS Cluster] Rebuilt AMI for updated version of SSM agent, Amazon Linux 2, ECS Agent.

## [0.22.0] - 2019-06-11

### Added

- [Developer Policy] Added developer policy module to manage developer level access to resources that can be controlled with tags.
- [Lambda] Added developer policy output for allowing developers to manipulate the function.

## [0.21.0] - 2019-05-31

### Changed

- [RDS Instance] Use performance insights

## [0.20.0] - 2019-05-13

### Added

- [Chamber Policy] Added a chamber policy generation module to automatically build secure read and read/write IAM policies for chamber namespaces.

## [0.19.0] - 2019-04-17

### Changed

- [Lambda] Use human readable names for Cloudwatch alarm name/description.

## [0.18.1] - 2019-03-28

### Fixed

- [Static] Add `Name` tag to the S3 bucket being used for the static site.

## [0.18.0] - 2019-03-28

### Fixed

- [Static] Apply tags to created S3 bucket.

### Changed

- [ECS Cluster, ASG] Allow specification of EBS volume properties (as long as the AMI you're using uses /dev/xvda as the root volume).
- [RDS Instance] Allow specification of a parameter group.

## [0.17.0] - 2019-03-22

### Fixed

- [Static] Add unique `origin_id` variable to enable CloudFront distribution provisioning.

### Changed

- [Static] Switch cloudfront distribution to use `aws_s3_bucket.bucket_regional_domain_name` instead of `aws_s3_bucket.website_endpoint`

## [0.16.0] - 2019-03-04

### Changed

- [ECS Cluster] Use AMI that trusts BLESS keys by default. This can be overridden.
- [ASG] Use AMI that trusts BLESS keys by default. This can be overridden.

## [0.15.0] - 2019-03-04

### Changed

- [RDS Instance] Only specify minor engine version to allow for point version updates.

## [0.13.0] - 2019-02-20

### Added

- [ASG] Add `target_group_arns` and `load_balancers` properties to ASG module to support NLB usage.

## [0.11.0] - 2019-02-01

### BREAKING

- [Lambda] Remove `environment_variables` option. It's been replaced by `environment`.

### Added

- [Lambda] Add `environment` option for lambda. This is the new way to specify environment variables for a Lambda function. The old way would not allow us to have no environment variables (required for Lambda@Edge).

### Changed

- [Lambda] Allow lambda@edge to assume the created Lambda role.
- [Lambda] Use function versioning.

## [0.10.0] - 2019-01-30

### Fixed

- [Lambda] Fix an error that was causing the lambda module to fail when invoked with an empty schedule ({}).

## [0.9.0] - 2018-12-13

### Changed

- [RDS Instance] Set sane defaults for the maintenance window, snapshot tagging, and deletion protection.
- [RDS Instance] Allow storage to be optionally encrypted.

## [0.8.0] - 2018-12-12

### Added

- [ECS Cluster] Add `schedule`, `schedule_down` and `schedule_up` properties, which control instance scheduling using the ASG scheduler. Until we receive a config exception from EOTSS, these should be used in addition to the `schedulev2` tag (`instance_schedule` property). Once the exception is granted, we should use `na` for the `schedulev2` tag, and exclusively use the ASG scheduling for all ASG instances.

## [0.7.0] - 2018-12-11

### Added

- [ASG] Add `schedule`, `schedule_down` and `schedule_up` properties, which control instance scheduling using the ASG scheduler. Until we receive a config exception from EOTSS, these should be used in addition to the `schedulev2` tag (`instance_schedule` property). Once the exception is granted, we should use `na` for the `schedulev2` tag, and exclusively use the ASG scheduling for all ASG instances.

## [0.6.0] - 2018-12-10

### Added

- [RDS Instance] Added RDS instance module to instantiate a single RDS instance (not appropriate for Aurora).

## [0.5.0] - 2018-12-05

### Added

- [Static] Static site module to manage an S3 static site that is only accessible via Cloudfront.

### Changed

- [ECS Cluster] Bump AMI to latest Amazon Linux 2 ECS Optimized + SSM
- [ASG] Bump AMI to latest Amazon Linux 2

## [0.4.0] - 2018-11-26

### Changed

- [Lambda] Create log group as part of Lambda module so we are able to specify the retention policy. Note: This will require that existing log groups are deleted or imported (using `terraform import`) before applying.

## [0.3.0] - 2018-11-19

### Changed

- [ASG] Update to schedulerv2 tags to support EOTSS requirements.

## [0.2.0] - 2018-10-31

### Added

- [Lambda] Add outputs for `function_name` and `function_arn`.
- [Lambda] Add option SNS alerts on Lambda error by passing in SNS topic ARNs to `error_topics`.

## [0.1.0] - 2018-10-30

### Changed

- [ECS Cluster] Update to Amazon 2 ECS optimized AMI.
- [ECS Cluster] Use custom AMI based on Amazon 2 ECS optimized that includes SSM.
