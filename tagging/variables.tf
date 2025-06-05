variable "additional_tags" {
  type    = map(string)
  default = {}
}

variable "repo" {
  type = string
}

variable "org" {
  type    = string
  default = "massgov"
}