import { Webhooks, createNodeMiddleware } from "@octokit/webhooks";
import { createServer } from 'http'
import convertDependabotAlert from "./lib/convertDependabotAlert";
import sendToTeams from "./lib/sendToTeams";
import TeamsWebhookPayload from "./types/TeamsWebhookPayload";
import ConfigurableParams from "./types/ConfigurableParams";
import ConfigurableParamsReader from "./lib/params/ConfigurableParamsReader";
import EnvConfigBuilder from "./lib/config/EnvConfigBuilder";
import Config from "./types/Config";

function main() {
  const configBuilder = new EnvConfigBuilder()
  const config = configBuilder.build()

  if (config.sendToTeams) {
    console.warn("Important!! We're going to send messages to Teams!!")
  }

  console.log(`Reading SSM parameters (${config.paramPrefix}*)...`)
  const paramReader = new ConfigurableParamsReader(config)
  paramReader.getConfig()
    .then(params => {
      startServer(config, params)
    })
    .catch(e => {
      console.error(e);
    })
}

function startServer(config: Config, params: ConfigurableParams) {
  const webhooks = new Webhooks({
    secret: params.githubSecret,
  });

  webhooks.onAny((event) => {
    console.log("Event received:", event);
  });

  webhooks.onError((event) => {
    console.error('Event failed:', event);
  })

  webhooks.on('dependabot_alert', ({payload}) => {
    let teamsPayload: TeamsWebhookPayload = {}
    try {
      teamsPayload = convertDependabotAlert(payload)
    }
    catch (e) {
      console.error('Unable to convert the GitHub webhook payload into Teams payload.')
      return;
    }

    if (!config.sendToTeams) {
      console.log('Teams payload: ', JSON.stringify(teamsPayload, undefined, 2))
      return;
    }

    const url = params.teamsWebhookUrl;
    sendToTeams(url, teamsPayload)
      .then(() => {
        console.log('The payload was sent to Teams.')
      })
      .catch((e) => {
        console.error('Unable to send the payload to Teams:', e)
      })
  })

  // It receives webhook events at http://localhost:3000/api/github/webhooks
  const port = 3000;
  console.log(`Starting the listener on http://localhost:${port}/api/github/webhooks...`);
  createServer(createNodeMiddleware(webhooks)).listen(port);
}

main();
