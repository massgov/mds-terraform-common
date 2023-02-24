import { Webhooks } from "@octokit/webhooks";
import TeamsWebhookPayload from "../types/TeamsWebhookPayload";
import convertDependabotAlert from "./convertDependabotAlert";
import sendToTeams from "./sendToTeams";
import Config from "../types/Config";
import ConfigurableParams from "../types/ConfigurableParams";
import ConsoleLogger from "./log/ConsoleLogger";

interface Args {
  config: Config
  params: ConfigurableParams
  logger: ConsoleLogger
}

const createWebhookHandler = ({
  config,
  params,
  logger,
}: Args): Webhooks => {
  const webhooks = new Webhooks({
    secret: params.githubSecret,
  });

  webhooks.onError((event) => {
    logger.error('Event failed:', event);
  })

  webhooks.on([
    'dependabot_alert.reintroduced',
    'dependabot_alert.created',
    'dependabot_alert.reopened',
  ], async ({payload}) => {
    let teamsPayload: TeamsWebhookPayload = {}
    try {
      teamsPayload = convertDependabotAlert(payload)
    }
    catch (e) {
      logger.error('Unable to convert the GitHub webhook payload into Teams payload.', e)
      return;
    }

    if (!config.sendToTeams) {
      logger.log('Teams payload: ', JSON.stringify(teamsPayload, undefined, 2))
      return;
    }

    const url = params.teamsWebhookUrl;
    try {
      await sendToTeams(url, teamsPayload)
      logger.debug('The payload was sent to Teams.')
    }
    catch (e) {
      logger.error('Unable to send the payload to Teams:', e)
    }
  });

  return webhooks;
}

export default createWebhookHandler;
