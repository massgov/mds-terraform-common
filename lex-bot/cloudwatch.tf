resource "aws_cloudwatch_log_group" "conversations" {
  for_each          = toset(var.environments)
  name              = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-conversations"
  retention_in_days = var.cloudwatch_log_retention
}
