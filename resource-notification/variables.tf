variable "sender_email" {
  type = string
  description = "SES Approved Email"
}
variable "default_recipient" {
  type = string
  description = "Default email to send untagged resources to"
}
variable "create_ses_email" {
  type = bool
  default = false
  description = "true/false create a ses identity for send email"
}