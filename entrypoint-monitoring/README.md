Entrypoint Monitor
=================

The module defines a lambda function that monitors services in the AWS account that point to non-existent domain names and IP addresses.
For example, it looks for DNS records that point to CloudFront distributions that don't exist anymore.

## Supported services 

The lambda scans the following services and entrypoints:

* Route53 Record Sets:
  * Defined domain names
  * Targets of default records
  * Targets of alias records
* CloudFront Distributions
  * Auto-generated domain names
  * Origins
* REST API Gateways
  * Default execution endpoints
  * Custom domain names
* HTTP API Gateways
  * Default execution endpoints
* S3 Buckets
  * Website entrypoint
  * Unconditional redirects
  * Routing rules
  * Alias names used by CloudFront to point to a bucket
* Load Balancers (entrypoint domain names only)
  * Application Load Balancers
  * Network Load Balancers
  * Gateway Load Balancers (not tested yet)

## Allowed external entrypoints

A service could point to a valid external domain name or an IP address.
We don't want this external address to appear on the report over and over again.
All known and valid domain names & IP addresses must be added to this list.

The monitor reads the list of valid external entrypoints from an SSM parameter.
By default, the parameter name is `/infrastructure/entrypoint-monitoring/allowed-points` but could be configured per AWS account.
Its value is a comma-separated list of valid entrypoints, for example:
```
8.8.8.8,example.com
```

## Scheduled execution

By default, the scanner is executed early morning every Monday. But, this could be configured per AWS account.

## Local development

Follow the following steps in order to set up local development environment:

* Copy the run script and provide AWS credentials:
```shell
cp lambda/run.example.sh lambda/run.ENV.sh
```

* Copy the config and populate it with relevant settings:
```shell
cp lambda/src/config.example.ts lambda/src/config.ts
```

* Run the scanner and check the report:
```shell
./lambda/run.ENV.sh
```

## Build instructions

**Important!!** The following must be done before committing any changes to the lambda code.

Run the following commands to bundle the lambda code into a single JS file that could be deployed to AWS:
```shell
cd lambda
npm run build
```

Then, commit everything including the bundled code in the `lambda/dist` folder.
