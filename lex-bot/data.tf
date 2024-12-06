data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_bedrock_foundation_model" "titan-v2" {
  model_id = "amazon.titan-embed-text-v2:0"
}
data "aws_bedrock_foundation_model" "titan-v1" {
  model_id = "amazon.titan-embed-text-v1"
}
