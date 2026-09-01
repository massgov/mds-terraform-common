# Instance Patching

This Terraform module schedules AWS Systems Manager patching for running EC2 instances within a defined environment via tags. Instances are selected by their `environment` tag, ECS and Kubernetes/EKS container hosts are excluded, and selected instances are processed in batches of up to 50.

Each batch uses the AWS-managed `AWS-RunPatchBaselineWithHooks` document to:

- Install the AWS Patch Baseline updates.
- Reboot when required.
- Run an extended native package-update pass for Linux and Windows.
- Block patching when the target appears to be an ECS or Kubernetes/EKS worker.

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

- Only running instances are considered.
- An instance must have an `environment` tag whose value is in `patch_environments`.
- Instances with the AWS ECS tag keys `AmazonECSCreated`, `AmazonECSManaged`, or `aws:ecs:clusterName` are excluded before associations are created.
- The pre-install hook also checks Linux and Windows hosts for ECS or Kubernetes/EKS indicators and exits with code `42` when a container host is detected.
- The schedule expression is passed to each SSM association with `apply_only_at_cron_interval = true`.
- Associations use a maximum concurrency of `25%` and allow errors up to `5%`.

The module creates no associations when no matching running instances are found.

## Requirements

| Name         | Version |
| ------------ | ------- |
| Terraform    | >= 1.7  |
| AWS provider | ~> 6.0  |

## Inputs

| Name                                 | Description                                                                                                                                           | Type          | Default | Required |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ------- | :------: |
| `patch_environments`                 | Existing environment tag values that are eligible for patching.                                                                                       | `set(string)` | n/a     |   yes    |
| `patch_schedule_expression`          | AWS Systems Manager State Manager schedule expression.                                                                                                | `string`      | n/a     |   yes    |

## Outputs

| Name                              | Description                                                                                |
| --------------------------------- | ------------------------------------------------------------------------------------------ |
| `instances_selected_for_patching` | Sorted IDs of running instances selected for patching after container-host tag exclusions. |
| `ecs_instances_excluded`          | Sorted IDs of running instances excluded because they have an ECS-related tag key.         |

## Resources Created

- One `aws_ssm_association` per batch of up to 50 selected instance IDs.
- An SSM document that prevents in-place patching of detected ECS or Kubernetes/EKS hosts.
- An SSM document that performs extended native package updates on Linux and Windows.
