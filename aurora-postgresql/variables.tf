variable "name" {
  description = "Name used for the cluster identifier and all supporting resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC the cluster is deployed into."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the cluster, spanning at least two availability zones."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnets in different availability zones are required."
  }
}

variable "database_name" {
  description = "Name of the initial database created in the cluster."
  type        = string
}

variable "master_username" {
  description = "Master username. The password is always managed by RDS in Secrets Manager."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version. A major version alone lets AWS select the minor."
  type        = string
  default     = "17"
}

variable "storage_type" {
  description = "Cluster storage configuration: aurora for standard, aurora-iopt1 for I/O-Optimized."
  type        = string
  default     = "aurora"

  validation {
    condition     = contains(["aurora", "aurora-iopt1"], var.storage_type)
    error_message = "storage_type must be aurora or aurora-iopt1."
  }
}

variable "instance_class" {
  description = "Instance class used by any group that does not set its own. Sized for non-production; production clusters should choose a memory optimized class."
  type        = string
  default     = "db.t4g.medium"
}

variable "instance_groups" {
  description = "Cluster instances, grouped by workload. Instances in a group share an instance class, a failover priority, and optionally a custom endpoint."
  type = map(object({
    count           = optional(number, 1)
    instance_class  = optional(string)
    promotion_tier  = optional(number, 1)
    custom_endpoint = optional(bool, false)
  }))
  default = {
    main = {
      count          = 1
      promotion_tier = 0
    }
  }

  validation {
    condition     = length(var.instance_groups) > 0
    error_message = "At least one instance group is required."
  }

  validation {
    condition     = alltrue([for name in keys(var.instance_groups) : can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", name))])
    error_message = "Instance group names must be lowercase alphanumeric characters and hyphens, and must not start or end with a hyphen."
  }

  validation {
    condition     = alltrue([for group in var.instance_groups : group.count >= 1])
    error_message = "Each instance group must contain at least one instance."
  }

  validation {
    condition     = alltrue([for group in var.instance_groups : group.promotion_tier >= 0 && group.promotion_tier <= 15])
    error_message = "promotion_tier must be between 0 and 15."
  }

  validation {
    condition     = alltrue([for group in var.instance_groups : group.count >= 1 if group.custom_endpoint])
    error_message = "An instance group with a custom endpoint must contain at least one instance."
  }
}

variable "minimum_availability_zones" {
  description = "Availability zones the subnets should cover before a multi-instance cluster warns."
  type        = number
  default     = 2
}

variable "port" {
  description = "Port the cluster listens on."
  type        = number
  default     = 5432
}

variable "security_group_ids" {
  description = "Additional security groups attached to the cluster instances."
  type        = list(string)
  default     = []
}

variable "backup_retention_period" {
  description = "Days of continuous backup retained for point-in-time recovery."
  type        = number
  default     = 35
}

variable "preferred_backup_window" {
  description = "Daily UTC window for the backup snapshot."
  type        = string
  default     = "05:10-06:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly UTC window for engine maintenance."
  type        = string
  default     = "wed:04:00-wed:05:00"
}

variable "auto_minor_version_upgrade" {
  description = "Apply minor engine upgrades during the maintenance window."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply modifications immediately rather than during the maintenance window."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Block deletion of the cluster."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot when the cluster is destroyed."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Identifier for the final snapshot. Defaults to the cluster name with a -final suffix."
  type        = string
  default     = null
}

variable "account_id" {
  description = "Account ID used in the created KMS key policy. Looked up when not supplied and a key is created."
  type        = string
  default     = null
}

variable "create_kms_key" {
  description = "Create a customer managed KMS key for the storage volume and the master password secret."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "ARN of an existing KMS key to encrypt the storage volume and the master password secret. Defaults to the AWS managed keys."
  type        = string
  default     = null
}

variable "kms_key_deletion_window_in_days" {
  description = "Waiting period before a created KMS key is destroyed."
  type        = number
  default     = 30
}

variable "iam_database_authentication_enabled" {
  description = "Allow database roles granted rds_iam to authenticate with short lived IAM tokens."
  type        = bool
  default     = true
}

variable "force_ssl" {
  description = "Reject connections that do not use TLS."
  type        = bool
  default     = true
}

variable "ca_cert_identifier" {
  description = "Certificate authority for the instance server certificates. Defaults to the current AWS default."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource in the module."
  type        = map(string)
  default     = {}
}
