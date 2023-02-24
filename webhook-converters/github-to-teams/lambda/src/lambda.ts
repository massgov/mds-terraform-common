import EnvConfigBuilder from "./lib/config/EnvConfigBuilder";
import ConfigurableParamsReader from "./lib/params/ConfigurableParamsReader";
import { APIGatewayProxyResultV2, APIGatewayProxyEventV2 } from 'aws-lambda';
import createWebhookHandler from "./lib/createWebhookHandler";
import ConsoleLogger from "./lib/log/ConsoleLogger";
import { WebhookLambdaInputSchema } from "./types/WebhookLambdaInput";
import validateToken from "./lib/validateToken";

const handler = async (event: APIGatewayProxyEventV2): Promise<APIGatewayProxyResultV2> => {
  const configBuilder = new EnvConfigBuilder()
  const config = configBuilder.build()
  const logger = new ConsoleLogger(config.minLogLevel);
  logger.debug('Config: ', config);

  // Validate the token passed in the path before anything else.
  const tokenInput = event.rawPath.slice(1);
  logger.debug('Validating the token: ', tokenInput);
  const isTokenValid = validateToken({
    key: config.token,
    input: tokenInput,
  })
  if (!isTokenValid) {
    return {
      statusCode: 404,
    }
  }

  logger.debug('Checking the input...');
  let input;
  try {
    input = WebhookLambdaInputSchema.parse({
      id: event.headers["x-github-delivery"],
      name: event.headers["x-github-event"],
      payload: event.body,
      signature: event.headers["x-hub-signature-256"],
    })
  }
  catch (e) {
    console.error('Invalid input: ', e)
    return {
      statusCode: 400,
    }
  }

  logger.debug(`Reading SSM parameters (${config.paramPrefix}*)...`)
  const paramReader = new ConfigurableParamsReader(config)
  const params = await paramReader.getConfig()

  logger.debug('Creating a webhook processor...')
  const webhooks = createWebhookHandler({config, params, logger})

  logger.debug('Verifying and processing the webhook payload...')
  await webhooks.verifyAndReceive(input)

  logger.debug('Returning the result to Github.')
  return {
    statusCode: 200,
    body: ''
  }
}

export default handler;
