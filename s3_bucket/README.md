# Overview

Sets up S3 Bucket.

## Setup

Add the following content in the file `main.tf` from the root folder:

```terraform
provider "aws" {
    region = "us-east-1"
}

module "an_s3_bucket" {
    source                  = "./modules/s3_bucket"

    bucket_region           = "us-west-2"
    bucket_name             = "my-practice-bucket"
    bucket_tags             = {
               Tag1    = "something1"
               Tag2    = "something2"
    }
}

output "full_bucket_name" {
    value = "${module.an_s3_bucket.full_bucket_name}"
}
```

## Outputs

`full_bucket_name` - full bucket name including the random number
