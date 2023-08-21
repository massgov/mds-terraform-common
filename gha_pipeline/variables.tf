
variable "oidc_provider_arn" {
  type = string
}
variable "project_name" {
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
  type = list(string)
  default = ["*"]
}
