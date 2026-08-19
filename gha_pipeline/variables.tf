
variable "oidc_provider_arn" {
  type = string
}
variable "role_name" {
  type = string
}
variable "gh_org" {
  type = string
}
variable "gh_repo" {
  type = string
}
variable "policy_arns" {
  // Use list instead of set; with set, terraform wants anything this variable
  // depends on to be deployed separately before it is used here, which would
  // complicate the deployment process.
  type = list(string)
}
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
  validation {
    condition     = var.allow_legacy_subject || var.org_id != ""
    error_message = "org_id is required when allow_legacy_subject is false."
  }
}

variable "repo_id" {
  type        = string
  description = "Github repository ID, required unless allow_legacy_subject is true"
  default     = ""
  validation {
    condition     = var.allow_legacy_subject || var.repo_id != ""
    error_message = "repo_id is required when allow_legacy_subject is false."
  }
}

# if templated (default) trust policy will not be used
variable "custom_policy_json" {
  type        = string
  description = "IAM policy document to attach inline to the role, use jsonencode() to convert Terraform language expressions to JSON"
  default     = ""
}
