# Tagging

> [!WARNING]
> Though it is public, it isn't advised that this module be used outside of the [massgov](https://github.com/massgov) GitHub organization. It will not work as expected if used by the general public.

Terraform module for providing managed tags to your terraform project.

## Usage

```hcl
// init.tf

module "tagging" {
  source = "github.com/massgov/mds-terraform-common//tagging?ref=1.x"
  org    = "massgov"
  repo   = "my-cool-repository"
  additional_tags = {
    environment           = "prod"
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = module.tagging.tags
  }
}
```