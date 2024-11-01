variable "name" {
  description = "The name of the environment"
  type        = string
}

variable "repository_name" {
  description = "The name of the GitHub repository"
  type        = string
}

variable "deployment_reviewers_users" {
  description = "Specify users that may approve workflow runs when they access this environment"
  type        = list(string)
  default     = []
}

variable "deployment_reviewers_teams" {
  description = "Specify teams that may approve workflow runs when they access this environment"
  type        = list(string)
  default     = []
}

variable "branch_restriction_patterns" {
  description = "Specify branch restrictions for the environment"
  type        = list(string)
  default     = []
}

variable "variables" {
  description = "GitHub Actions variables to set on the environment"
  type        = map(string)
  default     = {}
}
