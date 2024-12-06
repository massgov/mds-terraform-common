resource "aws_cloudwatch_log_group" "conversations" {
  count             = var.lex_separate_env ? length(var.environments) : 1
  name              = "${var.lex_separate_env ? "${var.environments[count.index]}-${var.prefix}" : "${var.prefix}"}-conversations"
  retention_in_days = 395
}