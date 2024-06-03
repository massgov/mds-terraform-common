########################################################################################################################
# VARIABLES
########################################################################################################################

// Global Vars
variable "secondary_aws_region" {
  description = "Secondary Region"
  type        = string
  default     = "us-west-2"
}
variable "tags" {
  type        = map(string)
  description = "A map of tags to use for created resources"
  default = {
  }
}

// Networking/Compute
variable "vpc_id" {
  description = "Network VPC ID"
  type        = string
}
variable "ec2_alb_arn" {
  description = "ARN for Application Load Balancer to attach ecs service"
  type        = string
  nullable = true
}


// Cloudwatch LogGroup
variable "log_retention_days" {
  description = "How many days to keep logs for? 0 = Never Expire Logs"
  type        = number
  default     = 0
}
variable "cw_kms_key" {
  description = "KMS Key for CloudWatch Log Group"
  type        = string
  default     = ""
}

// ECS var:
variable "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  type        = string
}
variable "ecs_task_def_custom" {
  description = "Custom Task Def Arn"
  type        = string
  default     = ""
}
variable "ecs_task_def" {
  description = <<EOH
  Object to create Task Def:

  Optionals:
    log_group_name  -> if null, will create a log group for the container and place in path of '/ecs/<workspace>/<cluster_name>/<service_name>/<container_name>
    environment_vars -> key, value pair
    secret_vars -> key, value pair (should only include ssm name: prepends 'arn:aws:ssm:<aws_region>:<account_id>:parameter/' to value
    port_mappings -> container ports exposed
  EOH
  type = object({
    execution_role_arn = string
    task_role_arn      = string
    family             = string
    containers = list(object({
      container_name = string
      image_name = string


      # optionals
      port_mappings = optional(list(object({
        containerPort = number
        protocol      = string
      })))
      log_group_name = optional(string)
      environment_vars = optional(list(object({
        name  = string
        value = string
      })))
      secret_vars = optional(list(object({
        name      = string
        valueFrom = string
      })))

    }))
  })
}


variable "ecs_task_volumes" {
  description = "Add EFS Mount to ECS"
  type = list(object({
    name            = string,
    host_path       = string,
    access_point_id = string,
    fs_id           = string
  }))
  default = []
}
variable "ecs_service_name" {
  description = "ECS Service Name"
  type        = string
}
variable "ecs_desire_count" {
  description = "Desire Count of tasks to run under service"
  type        = number
  default     = 0
}
variable "ecs_max_count" {
  description = "Max Count of tasks to run under service"
  type        = number
  default     = 0
}
variable "ecs_min_count" {
  description = "Min Count of tasks to run under service"
  type        = number
  default     = 0
}
variable "ecs_auto_scale_schedule_up" {
  description = "Auto Scaling Time Schedule Up, '0' = disabled"
  type        = string
  default     = "0"
}
variable "ecs_auto_scale_schedule_down" {
  description = "Auto Scaling Time Schedule down, '0' = disabled"
  type        = string
  default     = "0"
}
variable "ecs_auto_scale_memory" {
  description = "Auto Scaling Memory threshold, 0 = disabled"
  type        = number
  default     = 0
}
variable "ecs_auto_scale_cpu" {
  description = "Auto Scaling CPU threshold, 0 = disabled"
  type        = number
  default     = 0
}
variable "ecs_auto_scale_arn" {
  description = "Auto Scaling Role ARN, blank = no scale policy"
  type        = string
  default     = ""
}
variable "ecs_security_group_ids" {
  description = "List of Security Group IDs"
  type        = list(string)
}
variable "ecs_subnet_ids" {
  description = "List of Subnet IDs"
  type        = list(string)
}
variable "ecs_load_balancers" {
  description = "Connect service to load balancer"
  nullable = true
  type = map(map(object(
    {
      container_port = number
      tls            = bool
      conditions = optional(object({
        host_header = optional(list(string))
        path_pattern = optional(list(string))
        http_header = optional(object({
          values           = optional(list(string))
          http_header_name = optional(string)
        }))
      }))
    }
  )))
}

variable "ecs_compute_config" {
  description = <<EOH
    Fargate Compute Configuration:
    .25_.5 = { cpu : 256, memory : 512 }
    .25_1 = { cpu : 256, memory : 1024 }
    .25_2 = { cpu : 256, memory : 2056 }
  EOH
  type        = string
}

variable "ecs_circuit_breaker" {
  description = "Enable Deployment Circuit Breaker. If deployment fails, will revert to previous deployment"
  type        = bool
  default     = false
}
variable "ecs_circuit_breaker_alert_email" {
  description = "SNS Alert Email list for CB alerts"
  type        = list(string)
  default     = []
}
// ECR var:
variable "create_ecr" {
  description = "Create Elastic Container Repo?"
  type        = bool
  default     = true
}
variable "ecr_name" {
  description = "ECR Repo Name, required if creating new"
  type        = string
  default     = ""
}
variable "ecr_kms_arn" {
  type    = string
  default = null
}
variable "ecr_replication" {
  description = "Replicate ECR to secondary region?"
  type        = bool
  default     = false
}
variable "ecr_repo_retention" {
  description = "How many images to keep in ECR Repo? [Default = 0 (disable)]"
  type        = number
  default     = 0
}