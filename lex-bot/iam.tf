
data "aws_iam_policy_document" "unauthenticated" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.main.id]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["unauthenticated"]
    }
  }
}

//TODO restrict permissions
data "aws_iam_policy_document" "unauthenticated_role_policy" {
  statement {
    effect    = "Allow"
    actions   = ["Lex:*"]
    resources = ["*"]
  }
}
data "aws_iam_policy_document" "lex" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lex.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
data "aws_iam_policy_document" "bedrock" {
  statement {
    effect = "Allow"
    sid    = "AmazonBedrockKnowledgeBaseTrustPolicy"
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_iam_role" "unauthenticated" {
  name               = "${var.prefix}-cognito-default-unauthenticated"
  assume_role_policy = data.aws_iam_policy_document.unauthenticated.json
}
resource "aws_iam_role_policy" "unauthenticated" {
  name   = "${var.prefix}-cognito-default-unauthenticated-policy"
  role   = aws_iam_role.unauthenticated.id
  policy = data.aws_iam_policy_document.unauthenticated_role_policy.json
}

resource "aws_iam_role" "lex" {
  name               = "${var.prefix}-lex-role"
  path               = "/service-role/lex.amazonaws.com/"
  assume_role_policy = data.aws_iam_policy_document.lex.json
  inline_policy {
    name = "AmazonLexServicePolicy-BedrockFMNonStreamingPolicy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "bedrock:InvokeModel"
          ],
          "Resource" : [
            "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-instant-v1",
            "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-3-haiku-20240307-v1:0",
            "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
            "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/anthropic.claude-v2"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "bedrock:ApplyGuardrail"
          ],
          "Resource" : [
            values(aws_bedrock_guardrail.main)[*].guardrail_arn
          ]
        }
      ]
    })
  }
  inline_policy {
    name = "AmazonLexServicePolicy-BedrockKnowledgeStoreReadPolicy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Sid" : "BedrockKnowledgeBaseQueryPolicy",
          "Action" : [
            "bedrock:Retrieve"
          ],
          "Resource" : [
            values(aws_bedrockagent_knowledge_base.main)[*].arn
          ]
        }
      ]
    })
  }
  inline_policy {
    name = "AmazonLexServicePolicy-CloudWatchPolicy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "CloudWatchPolicyID",
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            aws_cloudwatch_log_group.conversations[*].arn
          ]
        }
      ]
    })
  }
  inline_policy {
    name = "AmazonLexServicePolicy-ComprehendPolicy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "comprehend:DetectSentiment"
          ],
          "Resource" : [
            "*"
          ]
        }
      ]
    })
  }

  tags = {}
}


resource "aws_iam_policy" "AmazonBedrockFoundationModelPolicyForKnowledgeBase" {
  for_each = toset(var.environments)
  name     = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-bedrock-model"
  path     = "/service-role/"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "BedrockInvokeModelStatement",
        "Effect" : "Allow",
        "Action" : [
          "bedrock:InvokeModel"
        ],
        "Resource" : [
          data.aws_bedrock_foundation_model.titan-v2.model_arn
        ]
      }
    ]
  })
}
resource "aws_iam_policy" "AmazonBedrockOSSPolicyForKnowledgeBase" {
  for_each   = toset(var.environments)
  depends_on = [aws_opensearchserverless_collection.main]

  name = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-bedrock-oss"
  path = "/service-role/"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "OpenSearchServerlessAPIAccessAllStatement",
        "Effect" : "Allow",
        "Action" : [
          "aoss:APIAccessAll"
        ],
        "Resource" : [
          join("/", [aws_opensearchserverless_collection.main[each.key].arn, "*"])
        ]
      }
    ]
  })
}
resource "aws_iam_policy" "AmazonBedrockS3PolicyForKnowledgeBase" {
  for_each = toset(var.environments)
  name     = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-bedrock-knowledgebase-s3"
  path     = "/service-role/"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "S3ListBucketStatement",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : [
          aws_s3_bucket.source_bucket[each.key].arn
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : [
              "${data.aws_caller_identity.current.account_id}"
            ]
          }
        }
      },
      {
        "Sid" : "S3GetObjectStatement",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : [
          join("/", [aws_s3_bucket.source_bucket[each.key].arn, "*"])
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceAccount" : [
              "${data.aws_caller_identity.current.account_id}"
            ]
          }
        }
      }
    ]
  })
}
resource "aws_iam_policy" "AmazonBedrockS3PolicyForGuardrail" {
  for_each = toset(var.environments)
  name     = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-bedrock-guardrail"
  path     = "/service-role/"
  policy = jsonencode({
    Statement = [
      {
        Action = "bedrock:ApplyGuardrail"
        Effect = "Allow"
        Resource = [
          aws_bedrock_guardrail.main[each.key].guardrail_arn
        ]
        Sid = "AmazonBedrockAgentBedrockApplyGuardrailPolicyProd"
      },
    ]
    Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role" "bedrock" {
  for_each           = toset(var.environments)
  name               = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-bedrock"
  path               = "/service-role/"
  description        = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)} Bedrock Knowledge Base access"
  assume_role_policy = data.aws_iam_policy_document.bedrock.json
  managed_policy_arns = [
    aws_iam_policy.AmazonBedrockFoundationModelPolicyForKnowledgeBase[each.key].arn,
    aws_iam_policy.AmazonBedrockOSSPolicyForKnowledgeBase[each.key].arn,
    aws_iam_policy.AmazonBedrockS3PolicyForKnowledgeBase[each.key].arn,
    aws_iam_policy.AmazonBedrockS3PolicyForGuardrail[each.key].arn
  ]
  tags = {}
}