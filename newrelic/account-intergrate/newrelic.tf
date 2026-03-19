

resource "newrelic_cloud_aws_link_account" "main" {
  depends_on             = [aws_iam_role.newrelic_integration_role]
  arn                    = var.newrelic_iam_role_arn != null ? var.newrelic_iam_role_arn : aws_iam_role.newrelic_integration_role[0].arn
  metric_collection_mode = "PULL"
  name                   = var.aws_account_name
}

resource "newrelic_cloud_aws_integrations" "this" {
  linked_account_id = newrelic_cloud_aws_link_account.main.id

  dynamic "billing" {
    for_each = try(local.integrations["billing"], null) != null ? [local.integrations["billing"]] : []
    content {
      metrics_polling_interval = billing.value.metrics_polling_interval
    }
  }
  dynamic "health" {
    for_each = try(local.integrations["health"], null) != null ? [local.integrations["health"]] : []
    content {
      metrics_polling_interval = health.value.metrics_polling_interval
    }
  }
  dynamic "trusted_advisor" {
    for_each = try(local.integrations["trusted_advisor"], null) != null ? [local.integrations["trusted_advisor"]] : []
    content {
      metrics_polling_interval = trusted_advisor.value.metrics_polling_interval
    }
  }
  dynamic "cloudtrail" {
    for_each = try(local.integrations["cloudtrail"], null) != null ? [local.integrations["cloudtrail"]] : []
    content {
      metrics_polling_interval = cloudtrail.value.metrics_polling_interval
      aws_regions              = cloudtrail.value.aws_regions
    }
  }
  dynamic "vpc" {
    for_each = try(local.integrations["vpc"], null) != null ? [local.integrations["vpc"]] : []
    content {
      metrics_polling_interval = vpc.value.metrics_polling_interval
      aws_regions              = vpc.value.aws_regions
      tag_key                  = vpc.value.tag_key
      tag_value                = vpc.value.tag_value
      fetch_nat_gateway        = try(vpc.value.fetch_nat_gateway, true)
      fetch_vpn                = try(vpc.value.fetch_vpn, false)
    }
  }
  dynamic "x_ray" {
    for_each = try(local.integrations["x_ray"], null) != null ? [local.integrations["x_ray"]] : []
    content {
      metrics_polling_interval = x_ray.value.metrics_polling_interval
      aws_regions              = x_ray.value.aws_regions
    }
  }
  dynamic "s3" {
    for_each = try(local.integrations["s3"], null) != null ? [local.integrations["s3"]] : []
    content {
      metrics_polling_interval = s3.value.metrics_polling_interval
    }
  }
  dynamic "doc_db" {
    for_each = try(local.integrations["doc_db"], null) != null ? [local.integrations["doc_db"]] : []
    content {
      metrics_polling_interval = doc_db.value.metrics_polling_interval
    }
  }
  dynamic "sqs" {
    for_each = try(local.integrations["sqs"], null) != null ? [local.integrations["sqs"]] : []
    content {
      metrics_polling_interval = sqs.value.metrics_polling_interval
      aws_regions              = sqs.value.aws_regions
      tag_key                  = sqs.value.tag_key
      tag_value                = sqs.value.tag_value
      fetch_extended_inventory = try(sqs.value.fetch_extended_inventory, true)
      fetch_tags               = try(sqs.value.fetch_tags, true)
      queue_prefixes           = try(sqs.value.queue_prefixes, [])
    }
  }
  dynamic "ebs" {
    for_each = try(local.integrations["ebs"], null) != null ? [local.integrations["ebs"]] : []
    content {
      metrics_polling_interval = ebs.value.metrics_polling_interval
      aws_regions              = ebs.value.aws_regions
      tag_key                  = ebs.value.tag_key
      tag_value                = ebs.value.tag_value
      fetch_extended_inventory = try(ebs.value.fetch_extended_inventory, true)
    }
  }
  dynamic "alb" {
    for_each = try(local.integrations["alb"], null) != null ? [local.integrations["alb"]] : []
    content {
      metrics_polling_interval = alb.value.metrics_polling_interval
      aws_regions              = alb.value.aws_regions
      tag_key                  = alb.value.tag_key
      tag_value                = alb.value.tag_value
      fetch_extended_inventory = try(alb.value.fetch_extended_inventory, true)
      fetch_tags               = try(alb.value.fetch_tags, true)
      load_balancer_prefixes   = try(alb.value.load_balancer_prefixes, [])
    }
  }
  dynamic "elasticache" {
    for_each = try(local.integrations["elasticache"], null) != null ? [local.integrations["elasticache"]] : []
    content {
      metrics_polling_interval = elasticache.value.metrics_polling_interval
      aws_regions              = elasticache.value.aws_regions
      tag_key                  = elasticache.value.tag_key
      tag_value                = elasticache.value.tag_value
      fetch_tags               = try(elasticache.value.fetch_tags, true)
    }
  }
  dynamic "api_gateway" {
    for_each = try(local.integrations["api_gateway"], null) != null ? [local.integrations["api_gateway"]] : []
    content {
      metrics_polling_interval = api_gateway.value.metrics_polling_interval
      aws_regions              = api_gateway.value.aws_regions
      stage_prefixes           = try(api_gateway.value.stage_prefixes, [])
      tag_key                  = api_gateway.value.tag_key
      tag_value                = api_gateway.value.tag_value
    }
  }
  dynamic "auto_scaling" {
    for_each = try(local.integrations["auto_scaling"], null) != null ? [local.integrations["auto_scaling"]] : []
    content {
      metrics_polling_interval = auto_scaling.value.metrics_polling_interval
      aws_regions              = auto_scaling.value.aws_regions
    }
  }
  dynamic "aws_app_sync" {
    for_each = try(local.integrations["aws_app_sync"], null) != null ? [local.integrations["aws_app_sync"]] : []
    content {
      metrics_polling_interval = aws_app_sync.value.metrics_polling_interval
      aws_regions              = aws_app_sync.value.aws_regions
    }
  }
  dynamic "aws_athena" {
    for_each = try(local.integrations["aws_athena"], null) != null ? [local.integrations["aws_athena"]] : []
    content {
      metrics_polling_interval = aws_athena.value.metrics_polling_interval
      aws_regions              = aws_athena.value.aws_regions
    }
  }
  dynamic "aws_cognito" {
    for_each = try(local.integrations["aws_cognito"], null) != null ? [local.integrations["aws_cognito"]] : []
    content {
      metrics_polling_interval = aws_cognito.value.metrics_polling_interval
      aws_regions              = aws_cognito.value.aws_regions
    }
  }
  dynamic "aws_connect" {
    for_each = try(local.integrations["aws_connect"], null) != null ? [local.integrations["aws_connect"]] : []
    content {
      metrics_polling_interval = aws_connect.value.metrics_polling_interval
      aws_regions              = aws_connect.value.aws_regions
    }
  }
  dynamic "aws_direct_connect" {
    for_each = try(local.integrations["aws_direct_connect"], null) != null ? [local.integrations["aws_direct_connect"]] : []
    content {
      metrics_polling_interval = aws_direct_connect.value.metrics_polling_interval
      aws_regions              = aws_direct_connect.value.aws_regions
    }
  }
  dynamic "aws_fsx" {
    for_each = try(local.integrations["aws_fsx"], null) != null ? [local.integrations["aws_fsx"]] : []
    content {
      metrics_polling_interval = aws_fsx.value.metrics_polling_interval
      aws_regions              = aws_fsx.value.aws_regions
    }
  }
  dynamic "aws_glue" {
    for_each = try(local.integrations["aws_glue"], null) != null ? [local.integrations["aws_glue"]] : []
    content {
      metrics_polling_interval = aws_glue.value.metrics_polling_interval
      aws_regions              = aws_glue.value.aws_regions
    }
  }
  dynamic "aws_kinesis_analytics" {
    for_each = try(local.integrations["aws_kinesis_analytics"], null) != null ? [local.integrations["aws_kinesis_analytics"]] : []
    content {
      metrics_polling_interval = aws_kinesis_analytics.value.metrics_polling_interval
      aws_regions              = aws_kinesis_analytics.value.aws_regions
    }
  }
  dynamic "aws_media_convert" {
    for_each = try(local.integrations["aws_media_convert"], null) != null ? [local.integrations["aws_media_convert"]] : []
    content {
      metrics_polling_interval = aws_media_convert.value.metrics_polling_interval
      aws_regions              = aws_media_convert.value.aws_regions
    }
  }
  dynamic "aws_media_package_vod" {
    for_each = try(local.integrations["aws_media_package_vod"], null) != null ? [local.integrations["aws_media_package_vod"]] : []
    content {
      metrics_polling_interval = aws_media_package_vod.value.metrics_polling_interval
      aws_regions              = aws_media_package_vod.value.aws_regions
    }
  }
  dynamic "aws_mq" {
    for_each = try(local.integrations["aws_mq"], null) != null ? [local.integrations["aws_mq"]] : []
    content {
      metrics_polling_interval = aws_mq.value.metrics_polling_interval
      aws_regions              = aws_mq.value.aws_regions
    }
  }
  dynamic "aws_msk" {
    for_each = try(local.integrations["aws_msk"], null) != null ? [local.integrations["aws_msk"]] : []
    content {
      metrics_polling_interval = aws_msk.value.metrics_polling_interval
      aws_regions              = aws_msk.value.aws_regions
    }
  }
  dynamic "aws_neptune" {
    for_each = try(local.integrations["aws_neptune"], null) != null ? [local.integrations["aws_neptune"]] : []
    content {
      metrics_polling_interval = aws_neptune.value.metrics_polling_interval
      aws_regions              = aws_neptune.value.aws_regions
    }
  }
  dynamic "aws_qldb" {
    for_each = try(local.integrations["aws_qldb"], null) != null ? [local.integrations["aws_qldb"]] : []
    content {
      metrics_polling_interval = aws_qldb.value.metrics_polling_interval
      aws_regions              = aws_qldb.value.aws_regions
    }
  }
  dynamic "aws_route53resolver" {
    for_each = try(local.integrations["aws_route53resolver"], null) != null ? [local.integrations["aws_route53resolver"]] : []
    content {
      metrics_polling_interval = aws_route53resolver.value.metrics_polling_interval
      aws_regions              = aws_route53resolver.value.aws_regions
    }
  }
  dynamic "aws_states" {
    for_each = try(local.integrations["aws_states"], null) != null ? [local.integrations["aws_states"]] : []
    content {
      metrics_polling_interval = aws_states.value.metrics_polling_interval
      aws_regions              = aws_states.value.aws_regions
    }
  }
  dynamic "aws_transit_gateway" {
    for_each = try(local.integrations["aws_transit_gateway"], null) != null ? [local.integrations["aws_transit_gateway"]] : []
    content {
      metrics_polling_interval = aws_transit_gateway.value.metrics_polling_interval
      aws_regions              = aws_transit_gateway.value.aws_regions
    }
  }
  dynamic "aws_waf" {
    for_each = try(local.integrations["aws_waf"], null) != null ? [local.integrations["aws_waf"]] : []
    content {
      metrics_polling_interval = aws_waf.value.metrics_polling_interval
      aws_regions              = aws_waf.value.aws_regions
    }
  }
  dynamic "aws_wafv2" {
    for_each = try(local.integrations["aws_wafv2"], null) != null ? [local.integrations["aws_wafv2"]] : []
    content {
      metrics_polling_interval = aws_wafv2.value.metrics_polling_interval
      aws_regions              = aws_wafv2.value.aws_regions
    }
  }
  dynamic "cloudfront" {
    for_each = try(local.integrations["cloudfront"], null) != null ? [local.integrations["cloudfront"]] : []
    content {
      metrics_polling_interval = cloudfront.value.metrics_polling_interval
      tag_key                  = cloudfront.value.tag_key
      tag_value                = cloudfront.value.tag_value
      fetch_lambdas_at_edge    = try(cloudfront.value.fetch_lambdas_at_edge, false)
      fetch_tags               = try(cloudfront.value.fetch_tags, true)
    }
  }
  dynamic "dynamodb" {
    for_each = try(local.integrations["dynamodb"], null) != null ? [local.integrations["dynamodb"]] : []
    content {
      metrics_polling_interval = dynamodb.value.metrics_polling_interval
      aws_regions              = dynamodb.value.aws_regions
      tag_key                  = dynamodb.value.tag_key
      tag_value                = dynamodb.value.tag_value
      fetch_extended_inventory = try(dynamodb.value.fetch_extended_inventory, true)
      fetch_tags               = try(dynamodb.value.fetch_tags, true)
    }
  }
  dynamic "ec2" {
    for_each = try(local.integrations["ec2"], null) != null ? [local.integrations["ec2"]] : []
    content {
      metrics_polling_interval = ec2.value.metrics_polling_interval
      aws_regions              = ec2.value.aws_regions
      tag_key                  = ec2.value.tag_key
      tag_value                = ec2.value.tag_value
      fetch_ip_addresses       = try(ec2.value.fetch_ip_addresses, true)
      duplicate_ec2_tags       = try(ec2.value.duplicate_ec2_tags, false)
    }
  }
  dynamic "ecs" {
    for_each = try(local.integrations["ecs"], null) != null ? [local.integrations["ecs"]] : []
    content {
      metrics_polling_interval = ecs.value.metrics_polling_interval
      aws_regions              = ecs.value.aws_regions
      tag_key                  = ecs.value.tag_key
      tag_value                = ecs.value.tag_value
      fetch_tags               = try(ecs.value.fetch_tags, true)
    }
  }
  dynamic "efs" {
    for_each = try(local.integrations["efs"], null) != null ? [local.integrations["efs"]] : []
    content {
      metrics_polling_interval = efs.value.metrics_polling_interval
      aws_regions              = efs.value.aws_regions
      tag_key                  = efs.value.tag_key
      tag_value                = efs.value.tag_value
      fetch_tags               = try(efs.value.fetch_tags, true)
    }
  }
  dynamic "elasticbeanstalk" {
    for_each = try(local.integrations["elasticbeanstalk"], null) != null ? [local.integrations["elasticbeanstalk"]] : []
    content {
      metrics_polling_interval = elasticbeanstalk.value.metrics_polling_interval
      aws_regions              = elasticbeanstalk.value.aws_regions
      tag_key                  = elasticbeanstalk.value.tag_key
      tag_value                = elasticbeanstalk.value.tag_value
      fetch_extended_inventory = try(elasticbeanstalk.value.fetch_extended_inventory, true)
      fetch_tags               = try(elasticbeanstalk.value.fetch_tags, true)
    }
  }
  dynamic "elasticsearch" {
    for_each = try(local.integrations["elasticsearch"], null) != null ? [local.integrations["elasticsearch"]] : []
    content {
      metrics_polling_interval = elasticsearch.value.metrics_polling_interval
      aws_regions              = elasticsearch.value.aws_regions
      tag_key                  = elasticsearch.value.tag_key
      tag_value                = elasticsearch.value.tag_value
      fetch_nodes              = try(elasticsearch.value.fetch_nodes, true)
    }
  }
  dynamic "elb" {
    for_each = try(local.integrations["elb"], null) != null ? [local.integrations["elb"]] : []
    content {
      metrics_polling_interval = elb.value.metrics_polling_interval
      aws_regions              = elb.value.aws_regions
      fetch_extended_inventory = try(elb.value.fetch_extended_inventory, true)
      fetch_tags               = try(elb.value.fetch_tags, true)
    }
  }
  dynamic "emr" {
    for_each = try(local.integrations["emr"], null) != null ? [local.integrations["emr"]] : []
    content {
      metrics_polling_interval = emr.value.metrics_polling_interval
      aws_regions              = emr.value.aws_regions
      tag_key                  = emr.value.tag_key
      tag_value                = emr.value.tag_value
      fetch_tags               = try(emr.value.fetch_tags, true)
    }
  }
  dynamic "iam" {
    for_each = try(local.integrations["iam"], null) != null ? [local.integrations["iam"]] : []
    content {
      metrics_polling_interval = iam.value.metrics_polling_interval
      tag_key                  = iam.value.tag_key
      tag_value                = iam.value.tag_value
    }
  }
  dynamic "iot" {
    for_each = try(local.integrations["iot"], null) != null ? [local.integrations["iot"]] : []
    content {
      metrics_polling_interval = iot.value.metrics_polling_interval
      aws_regions              = iot.value.aws_regions
    }
  }
  dynamic "kinesis" {
    for_each = try(local.integrations["kinesis"], null) != null ? [local.integrations["kinesis"]] : []
    content {
      metrics_polling_interval = kinesis.value.metrics_polling_interval
      aws_regions              = kinesis.value.aws_regions
      tag_key                  = kinesis.value.tag_key
      tag_value                = kinesis.value.tag_value
      fetch_shards             = try(kinesis.value.fetch_shards, true)
      fetch_tags               = try(kinesis.value.fetch_tags, true)
    }
  }
  dynamic "kinesis_firehose" {
    for_each = try(local.integrations["kinesis_firehose"], null) != null ? [local.integrations["kinesis_firehose"]] : []
    content {
      metrics_polling_interval = kinesis_firehose.value.metrics_polling_interval
      aws_regions              = kinesis_firehose.value.aws_regions
    }
  }
  dynamic "lambda" {
    for_each = try(local.integrations["lambda"], null) != null ? [local.integrations["lambda"]] : []
    content {
      metrics_polling_interval = lambda.value.metrics_polling_interval
      aws_regions              = lambda.value.aws_regions
      tag_key                  = lambda.value.tag_key
      tag_value                = lambda.value.tag_value
      fetch_tags               = try(lambda.value.fetch_tags, true)
    }
  }
  dynamic "rds" {
    for_each = try(local.integrations["rds"], null) != null ? [local.integrations["rds"]] : []
    content {
      metrics_polling_interval = rds.value.metrics_polling_interval
      aws_regions              = rds.value.aws_regions
      tag_key                  = rds.value.tag_key
      tag_value                = rds.value.tag_value
      fetch_tags               = try(rds.value.fetch_tags, true)
    }
  }
  dynamic "redshift" {
    for_each = try(local.integrations["redshift"], null) != null ? [local.integrations["redshift"]] : []
    content {
      metrics_polling_interval = redshift.value.metrics_polling_interval
      aws_regions              = redshift.value.aws_regions
      tag_key                  = redshift.value.tag_key
      tag_value                = redshift.value.tag_value
    }
  }
  dynamic "route53" {
    for_each = try(local.integrations["route53"], null) != null ? [local.integrations["route53"]] : []
    content {
      metrics_polling_interval = route53.value.metrics_polling_interval
      fetch_extended_inventory = try(route53.value.fetch_extended_inventory, true)
    }
  }
  dynamic "ses" {
    for_each = try(local.integrations["ses"], null) != null ? [local.integrations["ses"]] : []
    content {
      metrics_polling_interval = ses.value.metrics_polling_interval
      aws_regions              = ses.value.aws_regions
    }
  }
  dynamic "sns" {
    for_each = try(local.integrations["sns"], null) != null ? [local.integrations["sns"]] : []
    content {
      metrics_polling_interval = sns.value.metrics_polling_interval
      aws_regions              = sns.value.aws_regions
      fetch_extended_inventory = try(sns.value.fetch_extended_inventory, true)
    }
  }
  dynamic "security_hub" {
    for_each = try(local.integrations["security_hub"], null) != null ? [local.integrations["security_hub"]] : []
    content {
      metrics_polling_interval = security_hub.value.metrics_polling_interval
      aws_regions              = security_hub.value.aws_regions
    }
  }
}
