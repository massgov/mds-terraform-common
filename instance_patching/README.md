# Instance Patching

This Terraform module schedules AWS Systems Manager patching for EC2 instances selected by their `environment` tag. Each association targets up to five environment tag values. A host guard blocks detected ECS and Kubernetes/EKS workers before any package installation.

Each association uses a custom wrapper document to:

- Block patching when the target appears to be an ECS or Kubernetes/EKS worker.
- Install missing `zstd`, `xz`, and `unzip` prerequisites on DNF-based Linux hosts before scanning.
- Invoke the AWS-managed `AWS-RunPatchBaselineWithHooks` document to scan, install baseline updates, run the extended native update hook, and reboot when required.

The extended update pass is best effort. Its errors are written to the SSM command output while the parent patch association is allowed to continue to its reboot and compliance-reporting steps.

## Usage

Example shows once a month starting with nonprod evironments, then 1 week after nonprod, prod will run.
These are for all tags with 'environment = prod', 'environment = development', etc., etc.

```terraform
module "instance_patching" {
  source = "./instance_patching"

  patch_environments        = ["development", "staging"]
  patch_schedule_expression = "cron(0 3 ? * SUN#1 *)" #this patches 1st Sunday of the month
}

module "instance_patching_prod" {
  source = "./instance_patching"

  patch_environments        = ["prod", "production"]
  patch_schedule_expression = "cron(0 3 ? * SUN#2 *)" #this patches 2nd Sunday of the month (week later)
}
```

The AWS provider must be configured by the calling module. The caller is responsible for ensuring that target instances are managed by Systems Manager and have an IAM instance profile with the permissions required by SSM and the patch documents.

## Selection and Safety

- An instance must have an `environment` tag whose value is in `patch_environments`.
- The host guard blocks detected ECS or Kubernetes/EKS workers before installing prerequisites and again before patch installation.
- The schedule expression is passed to each SSM association with `apply_only_at_cron_interval = true`.
- Associations use a maximum concurrency of `25%` and allow errors up to `5%`.

The module creates no associations when `patch_environments` is empty.

## Requirements

| Name         | Version |
| ------------ | ------- |
| Terraform    | >= 1.7  |
| AWS provider | ~> 6.0  |
| SSM Agent    | >= 3.0.502 |

## Inputs

| Name                                 | Description                                                                                                                                           | Type          | Default | Required |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ------- | :------: |
| `patch_environments`                 | Existing environment tag values that are eligible for patching.                                                                                       | `set(string)` | n/a     |   yes    |
| `patch_schedule_expression`          | AWS Systems Manager State Manager schedule expression.                                                                                                | `string`      | n/a     |   yes    |

## Outputs

| Name                              | Description                                                                                |
| --------------------------------- | ------------------------------------------------------------------------------------------ |
| `patch_target_configurations` | Environment tag targets for each association batch. |
| `patch_association_ids` | Association IDs keyed by batch. |
| `patch_association_arns` | Association ARNs keyed by batch. |
| `container_host_guard_document` | Name of the container-host guard document. |

## Resources Created

- One `aws_ssm_association` per batch of up to five environment tag values.
- An SSM wrapper document that checks the host and installs patch prerequisites before invoking AWS patching.
- An SSM document that prevents in-place patching of detected ECS or Kubernetes/EKS hosts.
- An SSM document that performs extended native package updates on Linux and Windows.
