output "patch_target_configurations" {
  value = {
    for batch_key, target_values in local.patch_environment_batches :
    batch_key => {
      target_key    = "tag:environment"
      target_values = target_values
    }
  }
}

output "patch_association_ids" {
  value = {
    for batch_key, association in aws_ssm_association.extended_patching :
    batch_key => association.association_id
  }
}

output "patch_association_arns" {
  value = {
    for batch_key, association in aws_ssm_association.extended_patching :
    batch_key => association.arn
  }
}

output "container_host_guard_document" {
  value = aws_ssm_document.container_host_guard.name
}
