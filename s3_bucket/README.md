# Overview

Sets up S3 Bucket, with many features/switches and default bucket policy for SSL/TLS only (if default not changed.)

## Usage

Add the following content in the file `main.tf` from the root folder or in your own root project folders:

```terraform

# add to versions/providers.tf
provider "aws" {
    region = "us-east-1"
}

# add to main.tf
module "an_s3_bucket" {
    source                  = "./modules/s3_bucket"

    bucket_region           = "us-east-1"
    bucket_name             = "my-super-secure-bucket-thingamabob"
    bucket_tags             = {
        # add below OR add provider default/module tag variables.
               Tag1    = "something1"
               Tag2    = "something2"
    }
}

# add to outputs.tf
output "full_bucket_name" {
    value = "${module.an_s3_bucket.full_bucket_name}"
}

output "full_bucket_arn" {
  value = aws_s3_bucket.my_bucket.arn
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.s3_key_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.s3_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.default_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.log_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.log_bucket_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_logging.default_bucket_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_policy.default_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.permit_non_ssl_requests](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.s3_aes_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.s3_sse_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.default_bucket_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [random_id.bucket_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_caller_identity.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.default_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.default_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.permit_non_ssl_requests](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the backet (random numbers will be appended at the end). | `string` | `"default-bucket"` | no |
| <a name="input_bucket_region"></a> [bucket\_region](#input\_bucket\_region) | Location of the bucket, such as `us-west-2` or `ca-central-1`. | `string` | `"us-east-1"` | no |
| <a name="input_bucket_tags"></a> [bucket\_tags](#input\_bucket\_tags) | Optional tags for the bucket | `map(string)` | `{}` | no |
| <a name="input_custom_policy"></a> [custom\_policy](#input\_custom\_policy) | Optional custom bucket policy in JSON (as a string). If this is provided, it will override the default policy that is created. | `string` | `""` | no |
| <a name="input_deletion_window_in_days"></a> [deletion\_window\_in\_days](#input\_deletion\_window\_in\_days) | Length of time (in days) the KMS key will be retained when a deletion is scheduled. Only used if a new KMS key is created by this module. | `number` | `30` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Should access logging be enabled for this bucket? | `bool` | `false` | no |
| <a name="input_guarantee_uniqueness"></a> [guarantee\_uniqueness](#input\_guarantee\_uniqueness) | Append some random characters to the bucket name in order to guarantee global uniqueness? | `bool` | `false` | no |
| <a name="input_important"></a> [important](#input\_important) | Should the bucket have versioning enabled, force\_destroy disabled, and any other future protections due to its importance? | `bool` | `false` | no |
| <a name="input_kms_encrypted"></a> [kms\_encrypted](#input\_kms\_encrypted) | Should the bucket objects be server-side encrypted? | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional KMS Key ARN to use for S3 bucket encryption. If blank, and if var.encrypted == true, then this module will create a new KMS Key to encrypt the S3 bucket. | `string` | `""` | no |
| <a name="input_kms_policy"></a> [kms\_policy](#input\_kms\_policy) | The KMS key policy JSON | `string` | `""` | no |
| <a name="input_log_prefix"></a> [log\_prefix](#input\_log\_prefix) | A prefix for all log object keys. | `string` | `"log/"` | no |
| <a name="input_permit_non_ssl_requests"></a> [permit\_non\_ssl\_requests](#input\_permit\_non\_ssl\_requests) | Allow non-SSL requests? Default is false (only allow SSL). CAUTION: Only disable SSL if you have a very good reason! | `bool` | `false` | no |
| <a name="input_public"></a> [public](#input\_public) | Should this bucket be publicly accessible? Default is false. Note that configuring<br/>    a bucket as public with NOT affect bucket policy, but merely allow callers to grant<br/>    public access using the custom\_policy variable. CAUTION: Only things like CSS/JS<br/>    assets for a public web site should ever be publicly accessible! Use locked-down/private<br/>    S3 buckets by default! | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_full_bucket_arn"></a> [full\_bucket\_arn](#output\_full\_bucket\_arn) | Full bucket ARN |
| <a name="output_full_bucket_name"></a> [full\_bucket\_name](#output\_full\_bucket\_name) | Full bucket name, including random characters if var.guarantee\_uniqueness is used. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | n/a |
| <a name="output_log_bucket_arn"></a> [log\_bucket\_arn](#output\_log\_bucket\_arn) | n/a |
| <a name="output_log_bucket_name"></a> [log\_bucket\_name](#output\_log\_bucket\_name) | n/a |
<!-- END_TF_DOCS -->