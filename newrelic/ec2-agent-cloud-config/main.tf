data "template_file" "cloudconfig" {
  template = file("${path.module}/templates/cloudconfig.yml")
  vars = {
    new_relic_license_key = var.nr_infra_agent_license_key
    name_prefix           = var.name_prefix
  }
}
