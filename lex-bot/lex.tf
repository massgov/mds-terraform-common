resource "aws_lexv2models_bot" "main" {
  count = var.lex_separate_env ? length(var.environments) : 1
  name  = var.lex_separate_env ? "${var.environments[count.index]}-${var.lex_botname}" : var.lex_botname

  data_privacy {
    child_directed = false
  }

  idle_session_ttl_in_seconds = 300
  role_arn                    = aws_iam_role.lex.arn
  description                 = "${var.lex_separate_env ? "${var.environments[count.index]} " : ""}Chatbot for ${var.prefix}"
}


resource "aws_lexv2models_bot_locale" "main" {
  count = var.lex_separate_env ? length(var.environments) : 1

  locale_id                        = "en_US"
  bot_id                           = aws_lexv2models_bot.main[count.index].id
  bot_version                      = "DRAFT"
  n_lu_intent_confidence_threshold = 0.4
}
