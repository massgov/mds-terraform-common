variable "name" {
  type        = string
  description = "The certificate name for AWS only."
}

variable "domain_names" {
  type        = list(string)
  description = "The list of domain names. Primary domain should be the first in the list."
}

variable "zone_id" {
  type        = string
  description = "ID of the DNS zone the domain names belong to."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the certificate."
}
