# Create the environment
resource "github_repository_environment" "this" {
  environment         = var.name
  repository          = var.repository_name
  can_admins_bypass   = false
  prevent_self_review = false

  reviewers {
    users = toset(var.deployment_reviewers_users)
    teams = toset(var.deployment_reviewers_teams)
  }

  dynamic "deployment_branch_policy" {
    for_each = length(var.branch_restriction_patterns) > 0 ? [1] : []
    content {
      protected_branches     = false
      custom_branch_policies = true
    }
  }
}

# Restrict the environment to the trunk branch
resource "github_repository_environment_deployment_policy" "this" {
  for_each       = toset(var.branch_restriction_patterns)
  environment    = github_repository_environment.this.environment
  repository     = github_repository_environment.this.repository
  branch_pattern = each.value
}

# Environment variables
resource "github_actions_environment_variable" "this" {
  for_each      = var.variables
  repository    = var.repository_name
  environment   = github_repository_environment.this.environment
  variable_name = each.key
  value         = each.value
}
