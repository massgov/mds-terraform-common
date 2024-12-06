resource "aws_opensearchserverless_security_policy" "main" {
  for_each = toset(var.environments)

  name        = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-os-encrypt"
  type        = "encryption"
  description = "Custom encryption policy created by Amazon Bedrock Knowledge Base service to allow a created IAM role to have permissions on Amazon Open Search collections and indexes"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          join("/", ["collection", aws_opensearchserverless_collection.main[each.key].name])
        ],
        "ResourceType" = "collection"

      }
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  for_each = toset(var.environments)

  name        = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-os-network"
  type        = "network"
  description = "Custom network policy created by Amazon Bedrock Knowledge Base service to allow a created IAM role to have permissions on Amazon Open Search collections and indexes."
  policy = jsonencode([
    {
      Description : "",
      Rules : [
        {
          ResourceType : "collection",
          Resource = [
            join("/", ["collection", aws_opensearchserverless_collection.main[each.key].name])
          ]
        },
        {
          ResourceType : "dashboard",
          Resource = [
            join("/", ["collection", aws_opensearchserverless_collection.main[each.key].name])
          ]
        }
      ],
      AllowFromPublic : true
    }
  ])
}

resource "aws_opensearchserverless_access_policy" "main" {
  for_each = toset(var.environments)

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
            join("/", ["collection", aws_opensearchserverless_collection.main[each.key].name])
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
            join("/", ["index", aws_opensearchserverless_collection.main[each.key].name, "*"])
          ],
          Permission = [
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument",
            "aoss:CreateIndex"
          ]
        }
      ],
      Principal = [
        data.aws_caller_identity.current.arn,
        aws_iam_role.bedrock[each.key].arn
      ]
    }
  ])
}

resource "aws_opensearchserverless_collection" "main" {
  for_each = toset(var.environments)

  name        = "${lower(each.key != "" ? "${each.key}-" : "")}${lower(var.prefix)}-os"
  type        = "VECTORSEARCH"
  description = "Default collection created by Amazon Bedrock Knowledge base"
}


