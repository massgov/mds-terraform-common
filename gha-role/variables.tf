# The ARN of the Github Actions OIDC provider.
variable "oidc_provider_arn" {
  type = string
}

# The name of the role to create.
variable "role_name" {
  type = string
}

# The path for the role.
variable "role_path" {
  type    = string
  default = "/soe/"
}

# The name of the organization that owns the repository.
variable "gh_org" {
  type = string
}

# The name of the repository.
variable "gh_repo" {
  type = string
}

# IAM policies to attach to the role.
variable "policy_arns" {
  // Use list instead of set; with set, terraform wants anything this variable
  // depends on to be deployed separately before it is used here, which would
  // complicate the deployment process.
  type = list(string)
}

# Additional filters to use for who can assume the role.
# You can filter by branch, tag, or environment.
variable "oidc_subject_claims" {
  // This module always filters on the repository given, but you can use this
  // variable to additionally filter on a specific branch, tag, or environment,
  // as well as on pull request events.
  // To use a branch name (for example `develop`), use "ref:refs/heads/develop"
  type    = list(string)
  default = ["*"]
}

# OIDC subject claim formats:
# Legacy: repo:octo-org/octo-repo:ref:refs/heads/main
# Immutable: repo:octo-org@${org_id}/octo-repo@${repo_id}:ref:refs/heads/main

# Repos created after 07-15-2026 emit an immutable subject claim
# Set allow_legacy_subject to false for new repos created after this date or if opting in to use new immutable claims
# Immutable claims require org_id and repo_id
# https://github.com/aws-actions/configure-aws-credentials/tree/v6/#immutable-subject-claims
variable "allow_legacy_subject" {
  type        = bool
  description = "Accept the legacy OIDC subject claim (repo:ORG/REPO:...)"
  default     = true
}

variable "org_id" {
  type        = string
  description = "GitHub organization ID, required unless allow_legacy_subject is true"
  default     = ""
}

variable "repo_id" {
  type        = string
  description = "Github repository ID, required unless allow_legacy_subject is true"
  default     = ""
}

# Variable validation blocks can't reference other variables before version Terraform 1.9
# so we have to use this precondition
resource "terraform_data" "validate_subject_config" {
  lifecycle {
    precondition {
      condition     = var.allow_legacy_subject || (var.org_id != "" && var.repo_id != "")
      error_message = "org_id and repo_id are required when allow_legacy_subject is false."
    }
  }
}

# if templated (default) trust policy will not be used
variable "custom_policy_json" {
  type        = string
  description = "IAM policy document to attach inline to the role, use jsonencode() to convert Terraform language expressions to JSON"
  default     = ""
}
