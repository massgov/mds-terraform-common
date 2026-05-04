resource "aws_ssm_document" "scanner_bootstrap" {
  name            = var.ssm_document_name
  document_type   = "Command"
  document_format = "YAML"

  content = templatefile("${path.module}/scripts/scanner_bootstrap.yaml", {
    scanner_username = var.scanner_username
  })

  tags = {
    Name = "Scanner Bootstrap Document"
  }
}
