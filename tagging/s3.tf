

# Define your S3 bucket
data "aws_s3_bucket" "docs" {
  bucket = "itd-mgt-ssr-tagging.secure.digital.mass.gov"
}

# Upload each file listed in the manifest to S3
resource "aws_s3_object" "files" {
  for_each = toset(local.file_list)

  bucket = data.aws_s3_bucket.docs.id
  key    = "documentation/${var.repo}/${replace(replace(each.value, "../", ""), "./", "")}"
  source = "${local.relative_path}${replace(replace(each.value, "../", ""), "./", "")}" # Update with the path to your files
}

resource "aws_s3_object" "category" {
  count  = local.manifest_path != null ? 1 : 0
  bucket = data.aws_s3_bucket.docs.id
  key    = "documentation/${var.repo}/_category_.json"
  content = jsonencode({
    "label" : var.repo,
    "position" : 1,
    "link" : {
      "type" : "generated-index",
      "description" : var.repo
    }
  })
}




