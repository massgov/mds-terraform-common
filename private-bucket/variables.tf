variable "bucket_name" {
  type = string
  default = null
}

variable "data_classification" {
  type = string
  default = "na"
}

variable "tags" {
  type = map(string)
  default = {}
}
