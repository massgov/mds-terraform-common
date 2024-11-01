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
