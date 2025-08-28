# Overview

Sets up S3 Bucket, with many features/switches and default bucket policy for SSL/TLS only (if default not changed.)

## Setup

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

## Outputs

`full_bucket_name` - full bucket name including the random number
`full_bucket_arn`  - full bucket arn
