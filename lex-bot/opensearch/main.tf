data "aws_caller_identity" "current" {}

variable "environments" {
  type        = list(string)
  description = "List of Environments to create resources for multi env. Defaults to [\"\"], if default; will create for 1 environment with no env prefix on resources"
  default     = ["dv", "pr"]
}

variable "prefix" {
  type        = string
  description = "Prefix name used for resources"
}


resource "aws_opensearchserverless_security_policy" "encryption" {
  name        = "${lower(var.prefix)}-os-encrypt"
  type        = "encryption"
  description = "Custom encryption policy created by Amazon Bedrock Knowledge Base service to allow a created IAM role to have permissions on Amazon Open Search collections and indexes"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          join("/", ["collection", "${lower(var.prefix)}-os"])
        ],
        "ResourceType" = "collection"

      }
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  name        = "${lower(var.prefix)}-os-network"
  type        = "network"
  description = "Custom network policy created by Amazon Bedrock Knowledge Base service to allow a created IAM role to have permissions on Amazon Open Search collections and indexes."
  policy = jsonencode([
    {
      Description : "",
      Rules : [
        {
          ResourceType : "collection",
          Resource = [
            join("/", ["collection", "${lower(var.prefix)}-os"])
          ]
        },
        {
          ResourceType : "dashboard",
          Resource = [
            join("/", ["collection", "${lower(var.prefix)}-os"])
          ]
        }
      ],
      AllowFromPublic : true
    }
  ])
}

resource "aws_opensearchserverless_access_policy" "access" {
  for_each           = toset(var.environments)
  name        = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-os-access"
  description = "Custom data access policy created by Amazon Bedrock Knowledge Base service to allow a created IAM role to have permissions on Amazon Open Search collections and indexes."
  type        = "data"
  policy = jsonencode([
    {
      Description = ""
      Rules = [
        {
          ResourceType = "collection",
          Resource = [
            join("/", ["collection", "${lower(var.prefix)}-os"])
          ],
          Permission = [
            "aoss:DescribeCollectionItems",
            "aoss:CreateCollectionItems",
            "aoss:UpdateCollectionItems"
          ]
        },
        {
          ResourceType = "index",
          Resource = [
            join("/", ["index", "${lower(var.prefix)}-os", "*"])
          ],
          Permission = [
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument",
            "aoss:DeleteIndex",
            "aoss:CreateIndex"
          ]
        }
      ],
      Principal = [
        data.aws_caller_identity.current.arn,
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-bedrock"
      ]
    }
  ])
}

resource "aws_opensearchserverless_collection" "main" {
  depends_on = [aws_opensearchserverless_security_policy.network, aws_opensearchserverless_security_policy.encryption, aws_opensearchserverless_access_policy.access]
  name        = "${lower(var.prefix)}-os"
  type        = "VECTORSEARCH"
  description = "Default collection created by Amazon Bedrock Knowledge base"
}


output "collection_url" {
  value = aws_opensearchserverless_collection.main.collection_endpoint
}
output "collection_arn" {
  value = aws_opensearchserverless_collection.main.arn
}