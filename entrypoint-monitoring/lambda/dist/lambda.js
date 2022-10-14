var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/lambda.ts
var lambda_exports = {};
__export(lambda_exports, {
  default: () => lambda
});
module.exports = __toCommonJS(lambda_exports);

// src/scanner.ts
var import_client_cloudfront2 = require("@aws-sdk/client-cloudfront");

// src/lib/scanner/DistributionScanner.ts
var import_client_cloudfront = require("@aws-sdk/client-cloudfront");

// src/lib/util/getPaginated.ts
var lastBatchId = 0;
async function* getPaginated(params) {
  const {
    maxRequests = 10,
    input,
    client,
    CommandClass,
    logger,
    reader
  } = params;
  const batchId = lastBatchId++;
  for (let i = 0; i < maxRequests; i++) {
    logger.debug(`Batch #${batchId}: making request #${i + 1} with input: ${JSON.stringify(input)}`);
    const command = new CommandClass(input);
    const data = await client.send(command);
    logger.debug(`Batch #${batchId}: got response from request #${i + 1}`);
    const isComplete = yield* reader(data);
    if (isComplete) {
      logger.debug(`Batch #${batchId}: the job is done, leaving.`);
      return;
    }
  }
  throw new Error("Too much data. Either there is an infinite loop or the limits must be increased.");
}

// src/lib/scanner/BaseScanner.ts
var BaseScanner = class {
  constructor(logger) {
    this.logger = logger;
  }
  async scan(interconnections) {
    await this.doScan(interconnections);
    this.logger.dump();
  }
};

// src/lib/scanner/DistributionScanner.ts
var DistributionScanner = class extends BaseScanner {
  constructor(client, logger) {
    super(logger);
    this.serviceType = "cloudfront";
    this.client = client;
  }
  async doScan(interconnections) {
    var _a;
    this.logger.log("==== Scanning CloudFront Distributions... ====");
    for await (const summary of this.getDistributionSummaries()) {
      if (!summary.Enabled) {
        continue;
      }
      this.logger.debug(`- Distribution: ${summary.Id} (${summary.DomainName}) `);
      const serviceId = summary.Id;
      if (serviceId === void 0) {
        this.logger.error(`CloudFront distribution without an ID!`);
        continue;
      }
      if (summary.DomainName === void 0) {
        this.logger.error(`CloudFront distribution without a domain name!`);
        continue;
      }
      interconnections.addPointToServiceLink(
        summary.DomainName,
        this.serviceType,
        serviceId
      );
      const origins = (_a = summary.Origins) == null ? void 0 : _a.Items;
      if (origins) {
        for (const origin of origins) {
          if (origin.DomainName === void 0) {
            this.logger.error(`CloudFront distribution origin without a domain name: ${summary.Id}!`);
            continue;
          }
          interconnections.addServiceToPointLink(
            this.serviceType,
            serviceId,
            origin.DomainName
          );
          this.logger.debug(`-- Origin: ${origin.DomainName}`);
        }
      } else {
        this.logger.debug("-- No Origins");
      }
    }
    console.log("==== The CloudFront Distribution scan is complete. ====");
  }
  async *getDistributionSummaries() {
    const limit = 50;
    const CommandClass = import_client_cloudfront.ListDistributionsCommand;
    const input = {
      MaxItems: limit
    };
    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function* (data) {
        var _a, _b;
        const distributionSummaries = (_a = data.DistributionList) == null ? void 0 : _a.Items;
        if (!distributionSummaries) {
          throw new Error("Unable to list CloudFront distributions.");
        }
        for (const distSummary of distributionSummaries) {
          yield distSummary;
        }
        if (!((_b = data.DistributionList) == null ? void 0 : _b.IsTruncated)) {
          return true;
        }
        input.Marker = data.DistributionList.NextMarker;
      }
    });
  }
};

// src/scanner.ts
var import_client_route_532 = require("@aws-sdk/client-route-53");

// src/lib/scanner/Route53Scanner.ts
var import_client_route_53 = require("@aws-sdk/client-route-53");
var Route53Scanner = class extends BaseScanner {
  constructor(client, ignoredTypes, logger) {
    super(logger);
    this.serviceType = "route53";
    this.ignoredCnameTarget = /\.(acm-validations\.aws\.|dkim\.amazonses\.com)$/;
    this.client = client;
    this.ignoredTypes = ignoredTypes;
  }
  normalizeDomainName(raw) {
    return raw.replace(/\.+$/, "");
  }
  async doScan(interconnections) {
    this.logger.log("==== Scanning Route53 Record Sets... ====");
    for await (const zone of this.getHostedZones()) {
      if (!zone.Id) {
        this.logger.error(`Zone without ID!`);
        continue;
      }
      this.logger.debug(`- Zone ${zone.Id} (${zone.Name}) ===`);
      for await (const recordSet of this.getRecordSets(zone.Id)) {
        if (recordSet.Type === void 0) {
          this.logger.error(`Route53 record set without a type!`);
          continue;
        }
        if (this.ignoredTypes.has(recordSet.Type)) {
          this.logger.debug(`-- Ignoring ${recordSet.Name} DNS record set of type ${recordSet.Type}.`);
          continue;
        }
        if (recordSet.Name === void 0) {
          this.logger.error(`Route53 record set without a name!`);
          continue;
        }
        const serviceId = recordSet.Name;
        interconnections.addPointToServiceLink(
          this.normalizeDomainName(recordSet.Name),
          this.serviceType,
          serviceId
        );
        this.logger.debug(`-- Record set ${recordSet.Name} `);
        if (recordSet.AliasTarget) {
          if (recordSet.AliasTarget.DNSName === void 0) {
            this.logger.error(`Route53 record set without an alias DNS name!`);
            continue;
          }
          interconnections.addServiceToPointLink(
            this.serviceType,
            serviceId,
            this.normalizeDomainName(recordSet.AliasTarget.DNSName)
          );
          this.logger.debug(`- ${recordSet.AliasTarget.DNSName}`);
        } else if (recordSet.ResourceRecords) {
          for (const record of recordSet.ResourceRecords) {
            if (record.Value === void 0) {
              this.logger.error(`Route53 resource record without a value!`);
              continue;
            }
            if (recordSet.Type === "CNAME" && this.ignoredCnameTarget.test(record.Value)) {
              this.logger.debug(`---- Ignoring a special CNAME record: ${record.Value}`);
              continue;
            }
            interconnections.addServiceToPointLink(
              this.serviceType,
              serviceId,
              this.normalizeDomainName(record.Value)
            );
            this.logger.debug(`---- ${record.Value}`);
          }
        } else {
          this.logger.error(`Unknown record set type!`);
        }
      }
    }
    this.logger.log("==== The Route53 Record Sets scan is complete. ====");
  }
  async *getHostedZones() {
    const limit = 20;
    const CommandClass = import_client_route_53.ListHostedZonesCommand;
    const input = {
      MaxItems: limit
    };
    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function* (data) {
        const hostedZones = data.HostedZones;
        if (!hostedZones) {
          throw new Error("Unable to list Route53 hosted zones.");
        }
        for (const hostedZone of hostedZones) {
          yield hostedZone;
        }
        if (!data.IsTruncated) {
          return true;
        }
        input.Marker = data.Marker;
      }
    });
  }
  async *getRecordSets(hostedZoneId) {
    const limit = 50;
    const CommandClass = import_client_route_53.ListResourceRecordSetsCommand;
    const input = {
      HostedZoneId: hostedZoneId,
      MaxItems: limit
    };
    yield* getPaginated({
      maxRequests: 20,
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function* (data) {
        const recordSets = data.ResourceRecordSets;
        if (!recordSets) {
          throw new Error("Unable to list Route53 record sets.");
        }
        for (const recordSet of recordSets) {
          yield recordSet;
        }
        if (!data.IsTruncated) {
          return true;
        }
        input.StartRecordIdentifier = data.NextRecordIdentifier;
        input.StartRecordName = data.NextRecordName;
        input.StartRecordType = data.NextRecordType;
      }
    });
  }
};

// src/lib/ServiceList.ts
var ServiceList = class {
  constructor() {
    this.map = /* @__PURE__ */ new Map();
  }
  getKey(type, id) {
    return `${type}|${id}`;
  }
  has(type, id) {
    const key = this.getKey(type, id);
    return this.map.has(key);
  }
  get(type, id) {
    const key = this.getKey(type, id);
    return this.map.get(key);
  }
  add(service) {
    const key = this.getKey(service.type, service.id);
    this.map.set(key, service);
    return this;
  }
  isEmpty() {
    return !!this.map.size;
  }
};

// src/lib/Interconnections.ts
var Interconnections = class {
  constructor() {
    this.points = /* @__PURE__ */ new Map();
    this.services = new ServiceList();
  }
  getPoint(name) {
    if (this.points.has(name)) {
      return this.points.get(name);
    }
    const result = {
      name,
      destinations: new ServiceList(),
      sources: new ServiceList()
    };
    this.points.set(name, result);
    return result;
  }
  getService(type, id) {
    if (this.services.has(type, id)) {
      return this.services.get(type, id);
    }
    const result = {
      type,
      id,
      sources: /* @__PURE__ */ new Map()
    };
    this.services.add(result);
    return result;
  }
  addServiceToPointLink(serviceType, serviceId, pointName) {
    const service = this.getService(serviceType, serviceId);
    const point = this.getPoint(pointName);
    point.sources.add(service);
  }
  addPointToServiceLink(pointName, serviceType, serviceId) {
    const service = this.getService(serviceType, serviceId);
    const point = this.getPoint(pointName);
    point.destinations.add(service);
    service.sources.set(point.name, point);
  }
  getOrphanPoints() {
    return Array.from(this.points.values()).filter((point) => !point.destinations.isEmpty());
  }
  hasOrphanPoints() {
    return Array.from(this.points.values()).some((point) => !point.destinations.isEmpty());
  }
};

// src/scanner.ts
var import_client_api_gateway2 = require("@aws-sdk/client-api-gateway");

// src/lib/scanner/RestApiGatewayScanner.ts
var import_client_api_gateway = require("@aws-sdk/client-api-gateway");
var RestApiGatewayScanner = class extends BaseScanner {
  constructor(client, logger) {
    super(logger);
    this.serviceType = "restapi";
    this.client = client;
  }
  async doScan(interconnections) {
    this.logger.log("==== Scanning custom domain names of REST APIs... ====");
    for await (const domainName of this.getCustomDomainNames()) {
      if (!domainName.domainName) {
        this.logger.error("Found a custom domain name for REST APIs without the actual domain name specified.");
        continue;
      }
      this.logger.debug(`- Custom domain name: ${domainName.domainName}`);
      for await (const basePathMapping of this.getBasePathMappings(domainName.domainName)) {
        if (!basePathMapping.restApiId) {
          this.logger.error(`Found a mapping of the ${domainName.domainName} custom domain name that has no REST API specified.`);
          continue;
        }
        if (domainName.distributionDomainName) {
          interconnections.addPointToServiceLink(
            domainName.distributionDomainName,
            this.serviceType,
            basePathMapping.restApiId
          );
          this.logger.debug(`-- Distribution domain name: ${domainName.distributionDomainName}`);
        } else if (domainName.regionalDomainName) {
          interconnections.addPointToServiceLink(
            domainName.regionalDomainName,
            this.serviceType,
            basePathMapping.restApiId
          );
          this.logger.debug(`-- Regional domain name: ${domainName.regionalDomainName}`);
        } else {
          this.logger.error(`Neither distribution nor redional entrypoint is defined on the ${domainName.domainName} custom domain.`);
          continue;
        }
      }
    }
    this.logger.log("==== The custom domain name scan of REST APIs is complete. ====");
    this.logger.log("==== Scanning REST APIs... ====");
    const region = await this.client.config.region();
    for await (const api of this.getApis()) {
      if (!api.id) {
        this.logger.error(`Found REST API without an ID!`);
        continue;
      }
      this.logger.debug(`- REST API: ${api.id}:`);
      if (!api.disableExecuteApiEndpoint) {
        const endpoint = `${api.id}.execute-api.${region}.amazonaws.com`;
        interconnections.addPointToServiceLink(
          endpoint,
          this.serviceType,
          api.id
        );
        this.logger.debug(`-- Default endpoint: ${endpoint}`);
      } else {
        this.logger.debug("-- Default endpoint is disabled.");
      }
    }
    this.logger.log("==== The REST APIs scan is complete. ====");
  }
  async *getCustomDomainNames() {
    const limit = 50;
    const CommandClass = import_client_api_gateway.GetDomainNamesCommand;
    const input = {
      limit
    };
    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function* (data) {
        const domainNames = data.items;
        if (!domainNames) {
          throw new Error("Unable to list custom domain names of REST APIs.");
        }
        for (const domainName of domainNames) {
          yield domainName;
        }
        if (data.position === void 0) {
          return true;
        }
        input.position = data.position;
      }
    });
  }
  async *getBasePathMappings(domainName) {
    const limit = 50;
    const CommandClass = import_client_api_gateway.GetBasePathMappingsCommand;
    const input = {
      domainName,
      limit
    };
    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function* (data) {
        const mappings = data.items;
        if (!mappings) {
          throw new Error("Unable to list mappings of custom domain names for REST APIs.");
        }
        for (const mapping of mappings) {
          yield mapping;
        }
        if (data.position === void 0) {
          return true;
        }
        input.position = data.position;
      }
    });
  }
  async *getApis() {
    const limit = 50;
    const CommandClass = import_client_api_gateway.GetRestApisCommand;
    const input = {
      limit
    };
    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function* (data) {
        const apis = data.items;
        if (!apis) {
          throw new Error("Unable to list REST APIs.");
        }
        for (const api of apis) {
          yield api;
        }
        if (data.position === void 0) {
          return true;
        }
        input.position = data.position;
      }
    });
  }
};

// src/scanner.ts
var import_client_s32 = require("@aws-sdk/client-s3");

// src/lib/scanner/S3Scanner.ts
var import_client_s3 = require("@aws-sdk/client-s3");
var S3Scanner = class extends BaseScanner {
  constructor(client, logger) {
    super(logger);
    this.serviceType = "s3";
    this.client = client;
  }
  async doScan(interconnections) {
    var _a, _b, _c;
    this.logger.log("==== Scanning S3 Buckets... ====");
    const region = await this.client.config.region();
    for await (const bucket of this.getBuckets()) {
      const bucketName = bucket.Name;
      if (bucketName === void 0) {
        this.logger.error(`Bucket without a name!`);
        continue;
      }
      this.logger.debug(`- ${bucketName} bucket.`);
      const cfOriginPoint = `${bucketName}.s3.amazonaws.com`;
      interconnections.addPointToServiceLink(
        cfOriginPoint,
        this.serviceType,
        bucketName
      );
      this.logger.debug(`-- CF-specific entrypoint: ${cfOriginPoint}`);
      const websiteConfig = await this.getBucketWebsiteConfig(bucketName);
      if (websiteConfig === void 0) {
        this.logger.debug("-- No website configuration.");
      } else {
        const websiteEndpoints = [
          `${bucketName}.s3-website.${region}.amazonaws.com`,
          `${bucketName}.s3-website-${region}.amazonaws.com`
        ];
        for (const websiteEndpoint of websiteEndpoints) {
          interconnections.addPointToServiceLink(
            websiteEndpoint,
            this.serviceType,
            bucketName
          );
          this.logger.debug(`-- Website entrypoint: ${websiteEndpoint}`);
        }
        const redirectHostname = (_a = websiteConfig.RedirectAllRequestsTo) == null ? void 0 : _a.HostName;
        if (redirectHostname) {
          interconnections.addServiceToPointLink(
            this.serviceType,
            bucketName,
            redirectHostname
          );
          this.logger.debug(`-- Unconditional redirect to ${redirectHostname}`);
        }
        if ((_b = websiteConfig.RoutingRules) == null ? void 0 : _b.length) {
          this.logger.debug(`-- Routing rules.`);
          for (const routingRule of websiteConfig.RoutingRules) {
            const ruleHostname = (_c = routingRule.Redirect) == null ? void 0 : _c.HostName;
            if (!ruleHostname) {
              continue;
            }
            interconnections.addServiceToPointLink(
              this.serviceType,
              bucketName,
              ruleHostname
            );
            this.logger.debug(`--- Routing rule target: ${ruleHostname}`);
          }
        }
      }
    }
    this.logger.log("==== The S3 Buckets scan is complete. ====");
  }
  async getBucketWebsiteConfig(bucketName) {
    const command = new import_client_s3.GetBucketWebsiteCommand({
      Bucket: bucketName
    });
    let data = void 0;
    try {
      data = await this.client.send(command);
    } catch (e) {
      if (e.name === "NoSuchWebsiteConfiguration") {
        return void 0;
      }
      if (e.name === "PermanentRedirect") {
        this.logger.log(`The ${bucketName} bucket belongs to a different region.`);
        return void 0;
      }
      if (e.name === "AccessDenied") {
        this.logger.error(`Not enough permissions to read website config of the ${bucketName} bucket website config.`);
        return void 0;
      }
      throw e;
    }
    const {
      $metadata: metadata,
      ...result
    } = data;
    if (data.$metadata.httpStatusCode !== 200) {
      return void 0;
    }
    return result;
  }
  async *getBuckets() {
    const CommandClass = import_client_s3.ListBucketsCommand;
    const input = {};
    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function* (data) {
        const buckets = data.Buckets;
        if (!buckets) {
          throw new Error("Unable to list S3 buckets.");
        }
        for (const bucket of buckets) {
          yield bucket;
        }
        return true;
      }
    });
  }
};

// src/scanner.ts
var import_client_elastic_load_balancing_v22 = require("@aws-sdk/client-elastic-load-balancing-v2");

// src/lib/scanner/LoadBalancerScanner.ts
var import_client_elastic_load_balancing_v2 = require("@aws-sdk/client-elastic-load-balancing-v2");
var LoadBalancerScanner = class extends BaseScanner {
  constructor(client, logger) {
    super(logger);
    this.serviceType = "loadbalancer";
    this.client = client;
  }
  async doScan(interconnections) {
    this.logger.log("==== Scanning load balancers... ====");
    for await (const balancer of this.getLoadBalancers()) {
      const balancerName = balancer.LoadBalancerName;
      if (!balancerName) {
        this.logger.error("Found a load balancer without a name!");
        continue;
      }
      this.logger.debug(`- Load balancer (${balancer.Type}): ${balancerName}`);
      const dnsName = balancer.DNSName;
      if (!dnsName) {
        this.logger.error("Found a load balancer without a DNS name!");
        continue;
      }
      interconnections.addPointToServiceLink(
        dnsName,
        this.serviceType,
        balancerName
      );
      this.logger.debug(`-- Entrypoint: ${dnsName}`);
    }
    this.logger.log("==== The load balancer scan is complete. ====");
  }
  async *getLoadBalancers() {
    const limit = 50;
    const CommandClass = import_client_elastic_load_balancing_v2.DescribeLoadBalancersCommand;
    const input = {
      PageSize: limit
    };
    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function* (data) {
        const balancers = data.LoadBalancers;
        if (!balancers) {
          throw new Error("Unable to list load balancers.");
        }
        for (const balancer of balancers) {
          yield balancer;
        }
        if (data.NextMarker === void 0) {
          return true;
        }
        input.Marker = data.NextMarker;
      }
    });
  }
};

// src/scanner.ts
var import_client_apigatewayv22 = require("@aws-sdk/client-apigatewayv2");

// src/lib/scanner/HttpApiGatewayScanner.ts
var import_client_apigatewayv2 = require("@aws-sdk/client-apigatewayv2");
var HttpApiGatewayScanner = class extends BaseScanner {
  constructor(client, logger) {
    super(logger);
    this.serviceType = "httpapi";
    this.client = client;
  }
  async doScan(interconnections) {
    this.logger.log("==== Scanning HTTP APIs... ====");
    for await (const api of this.getApis()) {
      if (!api.ApiId) {
        this.logger.error(`Found HTTP API without an ID!`);
        continue;
      }
      this.logger.debug(`- HTTP API: ${api.ApiId}:`);
      if (!api.DisableExecuteApiEndpoint) {
        const endpoint = api.ApiEndpoint;
        if (!endpoint) {
          this.logger.error(`The ${api.ApiId} HTTP API doesn't have a default endpoint.`);
          continue;
        }
        interconnections.addPointToServiceLink(
          endpoint,
          this.serviceType,
          api.ApiId
        );
        this.logger.debug(`-- Default endpoint: ${endpoint}`);
      } else {
        this.logger.debug("-- Default endpoint is disabled.");
      }
    }
    this.logger.log("==== The HTTP API scan is complete. ====");
  }
  async *getApis() {
    const limit = 50;
    const CommandClass = import_client_apigatewayv2.GetApisCommand;
    const input = {
      MaxResults: limit.toString()
    };
    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function* (data) {
        const apis = data.Items;
        if (!apis) {
          throw new Error("Unable to list HTTP APIs.");
        }
        for (const api of apis) {
          yield api;
        }
        if (data.NextToken === void 0) {
          return true;
        }
        input.NextToken = data.NextToken;
      }
    });
  }
};

// src/lib/ScanLogger.ts
var logLevelNumbers = {
  debug: 1,
  log: 2,
  error: 3
};
var ScanLogger = class {
  constructor(minLevel = "log") {
    this.entries = [];
    this.minLevel = minLevel;
    this.minLevelNumber = logLevelNumbers[minLevel];
  }
  createChildLogger() {
    return new ScanLogger(this.minLevel);
  }
  add(level, args) {
    const levelNumber = logLevelNumbers[level];
    if (levelNumber < this.minLevelNumber) {
      return;
    }
    this.entries.push([level, args]);
  }
  log(...args) {
    this.add("log", args);
  }
  debug(...args) {
    this.add("debug", args);
  }
  error(...args) {
    this.add("error", args);
  }
  dump() {
    for (const [type, args] of this.entries) {
      console[type](...args);
    }
    this.entries = [];
  }
};

// src/lib/scanner/AllowListScanner.ts
var import_client_ssm = require("@aws-sdk/client-ssm");
var AllowListScanner = class extends BaseScanner {
  constructor(client, config, logger) {
    super(logger);
    this.allowed = void 0;
    this.serviceType = "allowed";
    this.client = client;
    this.paramName = config.allowedPointsParamName;
  }
  async readAllowedList() {
    if (this.allowed !== void 0) {
      return;
    }
    this.logger.debug(`- Reading the list of allowed points from the SSM parameter: ${this.paramName}`);
    const param = await this.getParam(this.paramName);
    if (param === void 0) {
      this.logger.log("The SSM parameter is missing, no points will be manually approved.");
      this.allowed = [];
      return;
    }
    const value = param.Value;
    if (!value) {
      this.logger.debug("-- The SSM parameter is empty, no points will be manually approved.");
      this.allowed = [];
      return;
    }
    this.allowed = value.split(",");
  }
  async getParam(name) {
    try {
      const command = new import_client_ssm.GetParameterCommand({
        Name: name
      });
      const data = await this.client.send(command);
      if (!data.Parameter) {
        return void 0;
      }
      return data.Parameter;
    } catch (e) {
      if (e.name !== "ParameterNotFound") {
        this.logger.error(e);
      }
      return void 0;
    }
  }
  async doScan(interconnections) {
    this.logger.log("==== Registering the manually allowed points. ====");
    await this.readAllowedList();
    for (const pointName of this.allowed || []) {
      interconnections.addPointToServiceLink(
        pointName,
        this.serviceType,
        pointName
      );
      this.logger.debug(`- Allowed: ${pointName}`);
    }
    this.logger.log("==== Registration of the manually allowed points is complete. ====");
  }
};

// src/scanner.ts
var import_client_ssm2 = require("@aws-sdk/client-ssm");
async function scanner_default(config) {
  const region = config.region;
  const interconnections = new Interconnections();
  const logger = new ScanLogger(config.minLogLevel);
  const scans = [];
  const ignoredTypes = /* @__PURE__ */ new Set(["NS", "SOA", "TXT", "CAA", "MX"]);
  const r53Client = new import_client_route_532.Route53Client({ region });
  const r53Scanner = new Route53Scanner(r53Client, ignoredTypes, logger.createChildLogger());
  scans.push(r53Scanner.scan(interconnections));
  const cfClient = new import_client_cloudfront2.CloudFrontClient({ region });
  const distScanner = new DistributionScanner(cfClient, logger.createChildLogger());
  scans.push(distScanner.scan(interconnections));
  const restApiClient = new import_client_api_gateway2.APIGatewayClient({ region });
  const restApiScanner = new RestApiGatewayScanner(restApiClient, logger.createChildLogger());
  scans.push(restApiScanner.scan(interconnections));
  const httpApiClient = new import_client_apigatewayv22.ApiGatewayV2Client({ region });
  const httpApiScanner = new HttpApiGatewayScanner(httpApiClient, logger.createChildLogger());
  scans.push(httpApiScanner.scan(interconnections));
  const lbClient = new import_client_elastic_load_balancing_v22.ElasticLoadBalancingV2Client({ region });
  const lbScanner = new LoadBalancerScanner(lbClient, logger.createChildLogger());
  scans.push(lbScanner.scan(interconnections));
  const s3Client = new import_client_s32.S3Client({ region });
  const s3Scanner = new S3Scanner(s3Client, logger.createChildLogger());
  scans.push(s3Scanner.scan(interconnections));
  const ssmClient = new import_client_ssm2.SSMClient({ region });
  const allowedListScanner = new AllowListScanner(ssmClient, config, logger.createChildLogger());
  scans.push(allowedListScanner.scan(interconnections));
  await Promise.all(scans);
  return interconnections;
}

// src/lib/EnvConfigBuilder.ts
var EnvConfigBuilder = class {
  getEnvVar(name) {
    if (process.env[name] === void 0) {
      throw new Error(`The mandatory environment variable is missing: ${name}`);
    }
    return process.env[name];
  }
  getOptionalEnvVar(name) {
    return process.env[name];
  }
  build() {
    return {
      region: this.getEnvVar("AWS_REGION"),
      allowedPointsParamName: this.getOptionalEnvVar("ALLOWED_POINTS_PARAMETER"),
      minLogLevel: this.getEnvVar("MIN_LOG_LEVEL"),
      reportSnsTopic: this.getEnvVar("REPORT_SNS_TOPIC")
    };
  }
};

// src/lib/ScanReportFormatter.ts
var ScanReportFormatter = class {
  formatService(service) {
    const {
      type,
      id
    } = service;
    switch (type) {
      case "loadbalancer":
        return `'${id}' Load Balancer`;
      case "s3":
        return `'${id}' S3 Bucket`;
      case "cloudfront":
        return `'${id}' CloudFront Distribution`;
      case "route53":
        return `'${id}' Route53 Record Set`;
      case "restapi":
        return `'${id}' REST API Gateway`;
      case "httpapi":
        return `'${id}' HTTP API Gateway`;
      default:
        return `'${id}' ${type}`;
    }
  }
  formatOrphanPoints(interconnections) {
    const result = [];
    for (const point of interconnections.getOrphanPoints()) {
      result.push(`* '${point.name}' linked from the following services:`);
      for (const service of Array.from(point.sources.map.values())) {
        result.push(`  * ${this.formatService(service)}`);
      }
    }
    return result.join("\n");
  }
};

// src/lib/SnsNotifier.ts
var import_client_sns = require("@aws-sdk/client-sns");
var SnsNotifier = class {
  constructor(client, config) {
    this.client = client;
    this.config = config;
  }
  async send(message) {
    const command = new import_client_sns.PublishCommand({
      Message: message,
      TopicArn: this.config.reportSnsTopic
    });
    return this.client.send(command);
  }
};

// src/lambda.ts
var import_client_sns2 = require("@aws-sdk/client-sns");
async function lambda() {
  const configBuilder = new EnvConfigBuilder();
  const config = configBuilder.build();
  const interconnections = await scanner_default(config);
  const orphanPoints = interconnections.getOrphanPoints();
  if (!orphanPoints.length) {
    console.log("==== No orphan points found. ====");
    return;
  }
  console.log(`==== Found ${orphanPoints.length} orphan point(s). ====`);
  console.log(`==== Sending the report to the SNS topic... ====`);
  const reportFormatter = new ScanReportFormatter();
  const report = reportFormatter.formatOrphanPoints(interconnections);
  const snsClient = new import_client_sns2.SNSClient({ region: config.region });
  const notifier = new SnsNotifier(snsClient, config);
  await notifier.send(report);
  console.log(`==== The report was sent to the SNS topic. ====`);
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {});
