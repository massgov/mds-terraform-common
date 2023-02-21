Webhook converter: GitHub to MS Teams
=================

The module defines a lambda function with a publicly accessible URL that accepts .
For example, it looks for DNS records that point to CloudFront distributions that don't exist anymore.

## Local development

### Setup

Follow the following steps in order to set up local development environment:
```shell
cd lambda
npm i
cp .env.example .env
```

### Receiving webhooks

GitHub recommends Ngrok for delivering webhooks to the local server, see the corresponding [documentation page](https://docs.github.com/en/webhooks-and-events/webhooks/creating-webhooks#exposing-localhost-to-the-internet).
GitHub CLI forwarding looks promising too.

In order to work with webhooks locally, start `ngrok` to receive webhooks:
```shell
ngrok http 3000
```

Copy the provided public URL, add the `/api/github/webhooks` path to it and use it for a GitHub webhook on a test repository.

### Run it

Start the local server:
```shell
npm run dev
```

**Important!** You have to restart the server on any changes to the code.

**@TODO:** Provide automatic reloading on code changes.

## Build instructions

**Important!!** The following must be done before committing any changes to the lambda code.

Run the following commands to bundle the lambda code into a single JS file that could be deployed to AWS:
```shell
cd lambda
npm run build
```

Then, commit everything including the bundled code in the `lambda/dist` folder.

## Configuration

### Runtime parameters

The app uses SSM patameters for runtime configuration.
The parameter name prefix is defined as a Terraform module parameter (`ssm_parameter_prefix`).
By default, it's `/infrastructure/github-to-teams-webhook`.
Below is the list of parameters and their purpose:

* `[PREFIX]/teams-webhook` - full URL of the incoming webhook configured in Teams.
* `[PREFIX]/github-secret` - the webhook secret shared between the lambda and GitHub.

### Adding new repository

* Use Lambda URL as a webhook URL in GitHub.
* Specify the secret stored in the SSM parameter (see the section above) as a webhook secret.
* Enable just Dependabot alerts for the webhook.
* Try to reopen existing alerts in order to test it. The alert should appear in the corresponding Teams channel.

## Adaptive Cards

The lambda uses the [Adaptive Card](https://adaptivecards.io/) format to deliver formatted messages to a Teams channel.
There is a [online visual designer](https://adaptivecards.io/designer/) for such cards.
[Reference documentation](https://adaptivecards.io/explorer/) is available too.
See a [card example](./lambda/docs/card-example.json) for a complete JSON that could be used in the above visual designer.

**@TODO:** Provide an NPM command to generate an example card, so that we don't have to manually sync it with code.

## Lambda URL

Configuration of a lambda URL is not available in the 2.x version of the AWS provider.
So, you must configure it manually in order to invoke the lambda through its URL.
