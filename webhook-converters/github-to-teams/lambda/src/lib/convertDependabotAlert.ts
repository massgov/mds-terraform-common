import { DependabotAlertEvent } from "@octokit/webhooks-types";
import TeamsWebhookPayload from "../types/TeamsWebhookPayload";
import Severity from "../types/Severity";

const severityColorMap: Record<Severity, string> = {
  critical: 'attention',
  high: 'attention',
  medium: 'warning',
  low: 'light',
}

function buildTopContainer(event: DependabotAlertEvent): object {
  const title = `Alert #${event.alert.number} was ${event.action}`
  const severity = event.alert.security_vulnerability.severity
  const severityColor = severityColorMap[severity]
  const severityText = severity.toUpperCase()

  return {
    "type": "ColumnSet",
    "columns": [
      {
        "type": "Column",
        "width": "stretch",
        "items": [
          {
            "type": "TextBlock",
            "text": title,
            "wrap": true,
            "size": "large"
          }
        ],
        "verticalContentAlignment": "center"
      },
      {
        "type": "Column",
        "width": "auto",
        "items": [
          {
            "type": "TextBlock",
            "text": severityText,
            "horizontalAlignment": "right",
            "color": severityColor,
            "weight": "bolder"
          }
        ],
        "horizontalAlignment": "right",
        "style": "emphasis",
        "verticalContentAlignment": "center",
        "separator": true
      }
    ],
    "style": "emphasis",
    "horizontalAlignment": "left"
  }
}

function buildBodyContainer(event: DependabotAlertEvent): object {
  return {
    "type": "Container",
    "spacing": "default",
    "items": [
      {
        "type": "FactSet",
        "facts": [
          {
            "title": "Repository",
            "value": event.repository.full_name,
          },
          {
            "title": "Package",
            "value": event.alert.dependency.package.name
          },
          {
            "title": "Versions",
            "value": event.alert.security_vulnerability.vulnerable_version_range
          },
        ]
      },
    ],
  };
}

function buildFooterContainer(event: DependabotAlertEvent): object {
  const alertUrl = event.alert.html_url

  return {
    "type": "Container",
    "spacing": "default",
    "items": [
      {
        "type": "ActionSet",
        "actions": [
          {
            "type": "Action.OpenUrl",
            "title": "View on GitHub",
            "url": alertUrl,
          },
        ],
      },
    ],
    "horizontalAlignment": "left"
  }
}

export default function convertDependabotAlert(event: DependabotAlertEvent): TeamsWebhookPayload {
  return {
    "type":"message",
    "attachments":[
      {
        "contentType": "application/vnd.microsoft.card.adaptive",
        "contentUrl": null,
        "content": {
          "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
          "type": "AdaptiveCard",
          "version": "1.4",
          "body": [
            buildTopContainer(event),
            buildBodyContainer(event),
            buildFooterContainer(event),
          ],
        }
      }
    ]
  }
}
