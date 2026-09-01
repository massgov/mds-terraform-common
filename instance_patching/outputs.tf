output "patch_target_configuration" {
  value = {
    target_key    = "tag:environment"
    target_values = sort(tolist(var.patch_environments))
  }
}

output "patch_association_id" {
  value = aws_ssm_association.extended_patching.association_id
}

output "patch_association_arn" {
  value = aws_ssm_association.extended_patching.arn
}

output "container_host_guard_document" {
  value = aws_ssm_document.container_host_guard.name
}
