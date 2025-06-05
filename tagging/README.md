# Tagging

> [!WARNING]
> Though it is public, it isn't advised that this module be used outside of the [massgov](https://github.com/massgov) GitHub organization. It will not work as expected if used by the general public.

Terraform module for providing [managed tags](https://ssr-tagging.secure.digital.mass.gov/) to your terraform project.

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
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.87.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [terraform_remote_state.tags](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_org"></a> [org](#input\_org) | n/a | `string` | `"massgov"` | no |
| <a name="input_repo"></a> [repo](#input\_repo) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tags"></a> [tags](#output\_tags) | n/a |
<!-- END_TF_DOCS -->