module "rotate_iam_access_keys" {
  source                  = "./modules/iam_key_rotation"
  days_to_rotate          = var.days_to_rotate
  targeted_usernames      = var.targeted_usernames
  days_to_remove_inactive = var.days_to_remove_inactive
  event_frequency         = var.event_frequency
  sns_alert_emails        = var.sns_alert_emails
}
