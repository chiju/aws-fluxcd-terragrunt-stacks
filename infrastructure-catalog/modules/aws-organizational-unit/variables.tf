variable "name" {
  description = "Name of the organizational unit"
  type        = string
}

variable "parent_id" {
  description = "Parent ID for the organizational unit"
  type        = string
}

variable "tags" {
  description = "Tags for the organizational unit"
  type        = map(string)
  default     = {}
}
