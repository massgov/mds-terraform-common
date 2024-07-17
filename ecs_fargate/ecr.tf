
resource "aws_ecr_repository" "main" {
  count = var.create_ecr ? 1 : 0
  name  = var.ecr_name

  // best practice to have enabled, however maybe an issue with SDLC process
  // TODO
  #  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = var.ecr_kms_arn == null ? "AES256" : "KMS"
    kms_key         = var.ecr_kms_arn == null ? "" : var.ecr_kms_arn
  }
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = merge(
    var.tags,
    {
      "Name" = var.ecr_name
    },
  )
}

resource "aws_ecr_replication_configuration" "main" {
  count = var.ecr_replication ? 1 : 0

  replication_configuration {
    rule {
      destination {
        region      = var.secondary_aws_region
        registry_id = data.aws_caller_identity.current.account_id
      }
    }
  }
  lifecycle {
    ignore_changes = [replication_configuration]
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  count      = var.ecr_repo_retention != 0 ? 1 : 0
  repository = aws_ecr_repository.main[0].name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Only keep ${var.ecr_repo_retention} images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.ecr_repo_retention}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
