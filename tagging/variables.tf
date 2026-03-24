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

variable "manifest" {
  type    = string
  default = null
}

locals {
  manifest_path    = var.manifest
  root_level_count = local.manifest_path != null ? length(local.manifest_path) - length(replace(local.manifest_path, "/", "")) : ""
  relative_path    = local.manifest_path != null ? join("", [for i in range(local.root_level_count) : "../"]) : ""
  # Strips out empty lines, which can happen when the file ends in a newline character (posix standard).
  file_list = local.manifest_path != null ? [for f in split("\n", file(var.manifest)) : f if trimspace(f) != ""] : []
}

