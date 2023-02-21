import EnvConfigBuilder from "./lib/config/EnvConfigBuilder";
import ConfigurableParamsReader from "./lib/params/ConfigurableParamsReader";
import { APIGatewayProxyResult, APIGatewayEvent } from 'aws-lambda';
import createWebhookHandler from "./lib/createWebhookHandler";
import ConsoleLogger from "./lib/log/ConsoleLogger";
import { WebhookLambdaInputSchema } from "./types/WebhookLambdaInput";

const handler = async (event: APIGatewayEvent): Promise<APIGatewayProxyResult> => {
  const configBuilder = new EnvConfigBuilder()
  const config = configBuilder.build()
  const logger = new ConsoleLogger(config.minLogLevel);
  logger.debug('Config: ', config);

  logger.debug('Checking the input...');
  const input = WebhookLambdaInputSchema.parse({
    id: event.headers["x-github-delivery"],
    name: event.headers["x-github-event"],
    payload: event.body,
    signature: event.headers["x-hub-signature-256"],
  })

  logger.debug(`Reading SSM parameters (${config.paramPrefix}*)...`)
  const paramReader = new ConfigurableParamsReader(config)
  const params = await paramReader.getConfig()

  logger.debug('Creating a webhook processor...')
  const webhooks = createWebhookHandler({config, params, logger})

  logger.debug('Verifying and processing the webhook payload...')
  webhooks.verifyAndReceive(input)
    .then(() => {
      logger.debug('The webhook verification & processing is complete.')
    })
    .catch((e) => {
      logger.error('Unable to verify & receive the webhook payload:', e)
    })

  logger.debug('Returning the result to Github.')
  return {
    statusCode: 200,
    body: ''
  }
}

export default handler;
