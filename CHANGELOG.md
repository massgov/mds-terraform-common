Changelog
=========

## [Unreleased]

## [0.11.0] - 2019-02-01
### BREAKING
- [Lambda] Remove `environment_variables` option.  It's been replaced by `environment`.
### Added
- [Lambda] Add `environment` option for lambda.  This is the new way to specify environment variables for a Lambda function.  The old way would not allow us to have no environment variables (required for Lambda@Edge).
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
- [ECS Cluster] Add `schedule`, `schedule_down` and `schedule_up` properties, which control instance scheduling using the ASG scheduler.  Until we receive a config exception from EOTSS, these should be used in addition to the `schedulev2` tag (`instance_schedule` property).  Once the exception is granted, we should use `na` for the `schedulev2` tag, and exclusively use the ASG scheduling for all ASG instances. 

## [0.7.0] - 2018-12-11
### Added
- [ASG] Add `schedule`, `schedule_down` and `schedule_up` properties, which control instance scheduling using the ASG scheduler.  Until we receive a config exception from EOTSS, these should be used in addition to the `schedulev2` tag (`instance_schedule` property).  Once the exception is granted, we should use `na` for the `schedulev2` tag, and exclusively use the ASG scheduling for all ASG instances. 

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
- [Lambda] Create log group as part of Lambda module so we are able to specify the retention policy.  Note: This will require that existing log groups are deleted or imported (using `terraform import`) before applying.

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
