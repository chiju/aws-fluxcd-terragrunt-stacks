variable "name" {
  description = "Name of the AWS account"
  type        = string
}

variable "email" {
  description = "Email address for the AWS account"
  type        = string
}

variable "parent_id" {
  description = "Parent organizational unit ID"
  type        = string
}

variable "close_on_deletion" {
  description = "Close account on deletion"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for the account"
  type        = map(string)
  default     = {}
}
