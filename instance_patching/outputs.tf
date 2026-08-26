output "instances_selected_for_patching" {
  value = local.patch_instance_ids
}

output "ecs_instances_excluded" {
  value = sort(tolist(local.excluded_container_nodes))
}
