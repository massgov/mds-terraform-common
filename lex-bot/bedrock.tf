resource "time_sleep" "os_index_wait" {
  create_duration = "60s"
  depends_on      = [opensearch_index.main]
}

resource "aws_bedrockagent_knowledge_base" "main" {
  for_each = toset(var.environments)

  depends_on  = [time_sleep.os_index_wait]
  name        = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-knowledge-base"
  description = "Knowledge base for ${join(" ", [each.key, var.prefix])} content"
  role_arn    = aws_iam_role.bedrock[each.key].arn
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.titan-v2.model_arn
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = var.opensearch_arn
      vector_index_name = "bedrock-kb-${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-index"
      field_mapping {

        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
}

resource "aws_bedrockagent_data_source" "main" {
  depends_on           = [aws_s3_bucket.source_bucket]
  for_each             = toset(var.environments)
  knowledge_base_id    = aws_bedrockagent_knowledge_base.main[each.key].id
  name                 = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-knowledge-base-source"
  data_deletion_policy = "RETAIN"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.source_bucket[each.key].arn
    }
  }
}


