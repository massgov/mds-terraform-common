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
variable "function_testing" {
  type = bool
  default = false
  description = "true/false to set env. var (TESTING) for lambda. When in test, all emails will be sent to Default Email "
}
variable "schedule" {
  type        = map(string)
  description = "Schedule expressions to use to invoke scan (i.e: everyQtr = cron(0 0 1 1,4,7,10 ? *) )"
  default = {
  }
}



