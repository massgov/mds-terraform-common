import { createNodeMiddleware } from "@octokit/webhooks";
import { createServer } from 'http'
import ConfigurableParams from "./types/ConfigurableParams";
import ConfigurableParamsReader from "./lib/params/ConfigurableParamsReader";
import EnvConfigBuilder from "./lib/config/EnvConfigBuilder";
import Config from "./types/Config";
import createWebhookHandler from "./lib/createWebhookHandler";
import ConsoleLogger from "./lib/log/ConsoleLogger";

function main() {
  const configBuilder = new EnvConfigBuilder()
  const config = configBuilder.build()
  const logger = new ConsoleLogger(config.minLogLevel)

  if (config.sendToTeams) {
    logger.log("Important!! We're going to send messages to Teams!!")
  }

  logger.debug(`Reading SSM parameters (${config.paramPrefix}*)...`)
  const paramReader = new ConfigurableParamsReader(config)
  paramReader.getConfig()
    .then(params => {
      startServer(config, params, logger)
    })
    .catch(e => {
      logger.error(e);
    })
}

function startServer(config: Config, params: ConfigurableParams, logger: ConsoleLogger) {
  const webhooks = createWebhookHandler({config, params, logger})

  // Add some verbose output.
  webhooks.onAny((event) => {
    logger.debug("Event received:", event);
  });

  // It receives webhook events at http://localhost:3000/api/github/webhooks
  const port = 3000;
  logger.log(`Starting the listener on http://localhost:${port}/api/github/webhooks...`);
  createServer(createNodeMiddleware(webhooks)).listen(port);
}

main();
