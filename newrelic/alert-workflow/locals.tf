locals {
  default_webhook_payload = jsonencode({
    id              = "{{issueId}}"
    title           = "{{issueTitle}}"
    priority        = "{{priority}}"
    state           = "{{state}}"
    url             = "{{issuePageUrl}}"
    created_at      = "{{createdAt}}"
    updated_at      = "{{updatedAt}}"
    closed_at       = "{{closedAt}}"
    account_id      = "{{nrAccountId}}"
    policy_names    = "{{labels.policyNames}}"
    condition_names = "{{labels.conditionNames}}"
    entity_names    = "{{entitiesData.names}}"
    entity_types    = "{{entitiesData.types}}"
    description     = "{{issueDescription}}"
  })

  teams_adaptive_card_payload = trimspace(<<-EOT
  {
    "type": "message",
    "attachments": [
      {
        "contentType": "application/vnd.microsoft.card.adaptive",
        "contentUrl": null,
        "content": {
          "$schema": "https://adaptivecards.io/schemas/adaptive-card.json",
          "type": "AdaptiveCard",
          "version": "1.2",
          "msteams": { "width": "full" },
          "body": [
            {
              "type": "ColumnSet",
              "columns": [
                {
                  "type": "Column",
                  "items": [{
                    "type": "Image",
                    "style": "Person",
                    "url": "https://avatars.slack-edge.com/2022-06-02/3611814361970_f6a28959c2e7258660ea_512.png",
                    "size": "Small"
                  }],
                  "width": "auto"
                },
                {
                  "type": "Column",
                  "items": [
                    {
                      "type": "TextBlock",
                      "size": "large",
                      "weight": "bolder",
                      "text": "New Relic Alert - {{#if accumulations.tag.account.[0]}}{{ accumulations.tag.account.[0] }}{{else}}Account{{/if}} ({{ nrAccountId }})"
                    },
                    {
                      "type": "TextBlock",
                      "size": "medium",
                      "weight": "bolder",
                      "text": "{{ priorityText }} priority issue is {{#if issueClosedAt}}CLOSED{{else}}{{#if issueAcknowledgedAt}}ACKNOWLEDGED{{else}}ACTIVATED{{/if}}{{/if}}"
                    },
                    {
                      "type": "TextBlock",
                      "size": "medium",
                      "wrap": true,
                      "maxLines": 2,
                      "text": "[{{ issueTitle }}]({{ issuePageUrl }})"
                    }
                  ],
                  "width": "stretch"
                }
              ]
            },
            {
              "type": "TextBlock",
              "text": "Incident created at {{ createdAt }}",
              "wrap": true,
              "size": "small"
            },
            {{#if accumulations.conditionDescription.[0]}}
            {
              "type": "TextBlock",
              "text": {{ json accumulations.conditionDescription.[0] }},
              "wrap": true
            },
            {{/if}}
            {{#eq violationChartUrl "Not Available"}}
            {{else}}
            {
              "type": "Image",
              "url": {{ json violationChartUrl }}
            },
            {{/eq}}
            {
              "type": "FactSet",
              "facts": [
                { "title": "Severity:",              "value": "{{ priority }}" },
                { "title": "Impacted entities:",     "value": "{{#each entitiesData.names}}{{#lt @index 5}}{{this}}{{#unless @last}}, {{/unless}}{{/lt}}{{/each}}" },
                {{#if accumulations.policyName.[0]}}
                { "title": "Policy:",                "value": {{ json accumulations.policyName.[0] }} },
                {{/if}}
                {{#if accumulations.conditionName.[0]}}
                { "title": "Condition:",             "value": {{ json accumulations.conditionName.[0] }} },
                {{/if}}
                { "title": "Event Details:",         "value": "Policy: '{{#if accumulations.policyName.[0]}}{{ accumulations.policyName.[0] }}{{else}}N/A{{/if}}'. Condition: '{{#if accumulations.conditionName.[0]}}{{ accumulations.conditionName.[0] }}{{else}}N/A{{/if}}'" },
                { "title": "Num. Open Violations:",  "value": "{{ totalIncidents }}" },
                { "title": "Chart Link:",            "value": "[incident_chart]({{ violationChartUrl }})" },
                { "title": "Trigger:",               "value": "{{ priority }} - {{#if accumulations.conditionName.[0]}}{{ accumulations.conditionName.[0] }}{{else}}N/A{{/if}}" },
                { "title": "Status:",                "value": "{{#if issueClosedAt}}Closed{{else}}{{#if issueAcknowledgedAt}}Acknowledged{{else}}Open{{/if}}{{/if}}" },
                { "title": "Issue:",                 "value": "[{{ issueId }}]({{ issuePageUrl }})" },
                {{#unless (eq impactedEntitiesCount 1)}}
                { "title": "Total Incidents:",       "value": "{{ impactedEntitiesCount }}" },
                {{/unless}}
                { "title": "Workflow Name:",         "value": {{ json workflowName }} }
              ]
            },
            {
              "type": "ActionSet",
              "actions": [
                { "type": "Action.OpenUrl", "title": "📥 Acknowledge", "url": {{ json issueAckUrl }} },
                { "type": "Action.OpenUrl", "title": "✔️ Close",       "url": {{ json issueCloseUrl }} },
                { "type": "Action.OpenUrl", "title": "Go To Incident", "url": {{ json issuePageUrl }} },
                { "type": "Action.OpenUrl", "title": "Go To Policy",   "url": {{ json policyUrl }} }
                {{#if accumulations.deepLinkUrl.[0]}}
                ,{ "type": "Action.OpenUrl", "title": "🔎 View Query",   "url": {{ json accumulations.deepLinkUrl.[0] }} }
                {{/if}}
                {{#if accumulations.runbookUrl.[0]}}
                ,{ "type": "Action.OpenUrl", "title": "📕 View Runbook", "url": {{ json accumulations.runbookUrl.[0] }} }
                {{/if}}
              ]
            }
          ]
        }
      }
    ]
  }
  EOT
  )
}
