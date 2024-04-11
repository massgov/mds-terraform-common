output "image_builder_log_bucket" {
  description = "Identifier of bucket where Image Builder logs will be sent"
  value       = module.image_builder_logs.bucket_id
}