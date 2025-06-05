# Tags which will be merged into the managed tags provided by the module
variable "additional_tags" {
  type    = map(string)
  default = {}
}

# The name of the GitHub repository where calling code lives
variable "repo" {
  type = string
}

# The name of the GitHub organization where calling code lives
variable "org" {
  type    = string
  default = "massgov"
}