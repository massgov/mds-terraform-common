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
  description = "Object to create Task Def"
  type = object({
    execution_role_arn = string
    task_role_arn      = string
    cpu                = number
    memory             = number
    family             = string
    containers = list(object({
      container_name = string
      log_group_name = string
      environment_vars = list(object({
        name  = string
        value = string
      }))
      secret_vars = list(object({
        name      = string
        valueFrom = string
      }))
      image_name = string
      port_mappings = list(object({
        containerPort = number
        protocol      = string
      }))
    }))

  })
  /*
    default = {
      execution_role_arn : "arn:aws:iam::748039698304:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS",
      task_role_arn : "arn:aws:iam::748039698304:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS",
      cpu : 1024,
      memory : 1024,
      family : "family",
      containers : [{
        container_name : "string",
        log_group_name : "string"
        environment_vars : [{
          name : "string",
          value : "string"
        }]
        secret_vars : [
          {
            name : "string",
            valueFrom : "string"
          }
        ]
        image_name : "string",
        port_mappings : [{
          containerPort : 80,
          protocol : "tcp"
          },
          {
            containerPort : 8080,
            protocol : "tcp"
        }]
      }]
    }
  */
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
  type = map(map(object(
    {
      container_port = number
      tls            = bool
      conditions = object({
        host_header = list(string)
      })
    }
  )))

  /*
    default = {
      alb = {
        test-service1 = {
          container_port = 8081
          tls            = false
          health_check_path = "/custom"
          conditions     = {
            host_header = ["google.com"]
            http_header = {
              values           = []
              http_header_name = ""
            }
            http_request_method = []
            path_pattern        = []
            query_string        = ""
            source_ip           = []
          }
        }
        test-service2 = {
          container_port = 8081
          tls            = false
          conditions = {
            host_header = ["google.com"]
            http_header = {
              values           = []
              http_header_name = ""
            }
            http_request_method = []
            path_pattern        = []
            query_string        = ""
            source_ip           = []
          }
        }
      }
    }

   */
}

variable "ecs_compute_config" {
  description = "Fargate Compute Configuration: "
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