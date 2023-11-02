output "cloudconfig_rendered" {
  value = data.template_file.cloudconfig.rendered
}
