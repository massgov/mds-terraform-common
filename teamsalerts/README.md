SNS-to-Teams Alerts
===================

Module for subscribing Microsoft Teams incoming webhooks to SNS topics.

## Usage

```hcl
resource "aws_sns_topic" "my_cool_topic" {
  name         = "my-cool-topic"
  display_name = "My Super Cool SNS Topic"
}

module "teams_alerts" {
  source            = "github.com/massgov/mds-terraform-common//teamsalerts?ref=1.0"
  name              = "teams-alerts"
  teams_webhook_url = "https://account.webhook.office.com/webhookb2/0000-1111@2222-3333/IncomingWebhook/abcd-ef01/8080-ffff"
  topic_map = [
    {
      topic_arn     = aws_sns_topic.my_cool_topic.arn
      human_name    = aws_sns_topic.my_cool_topic.display_name 
      icon_url      = "https://img.icons8.com/ios/100/hand-peace--v1.png" # ✌️
    }
  ]
}
```