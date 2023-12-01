SSR Automation Documents
===================

Set of modules for creating Simple Systems Manager (SSM) automation documents

## Usage

```hcl
resource "aws_sns_topic" "my_cool_topic" {
  name         = "my-cool-topic"
  display_name = "My Super Cool SNS Topic"
}

module "scan_ecr_images" {
  source                 = "github.com/massgov/mds-terraform-common//ssr-automation-documents/scan-ecr-image?ref=1.x"
  default_alerting_topic = aws_sns_topic.my_cool_topic.arn
}
```