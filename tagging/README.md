# Tagging

> [!WARNING]
> Though it is public, it isn't advised that this module be used outside of the [massgov](https://github.com/massgov) GitHub organization. It will not work as expected if used by the general public.

Terraform module for providing [managed tags](https://ssr-tagging.secure.digital.mass.gov/) to your terraform project.

## Usage

```hcl
// init.tf

module "tagging" {
  source          = "github.com/massgov/mds-terraform-common//tagging?ref=1.x"
  org             = "massgov"
  repo            = "my-cool-repository"
  manifest        = "../../docs.manifest"
  additional_tags = {
    environment = "prod"
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

| Name | Description                                                                       | Type | Default | Required |
|------|-----------------------------------------------------------------------------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Tags which will be merged into the managed tags provided by the module            | `map(string)` | `{}` |    no    |
| <a name="input_org"></a> [org](#input\_org) | The name of the GitHub organization where calling code lives                      | `string` | `"massgov"` |    no    |
| <a name="input_repo"></a> [repo](#input\_repo) | The name of the GitHub repository where calling code lives                        | `string` | n/a |   yes    |
| <a name="input_manifest"></a> [manifest](#input\_manifest) | File path to docs.manifest file. See  [Manifest File](#manifest_file) for details | `string` | n/a |     no   |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tags"></a> [tags](#output\_tags) | Mapping of tag names to tag values |
<!-- END_TF_DOCS -->


## Manifest File

This is a file that will find and upload to S3 Bucket. These files are then downloaded at build of doc/tagging site for central display. 

Files to be added are from reference of the manifest file. 

Example:

`manifest = "../../docs.manifest"`

Contents: 
```
./infra/README.md
README.md
```
