resource "aws_dynamodb_table" "lock" {
  name         = var.lock_table_name
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = var.lock_table_name
  }
}
