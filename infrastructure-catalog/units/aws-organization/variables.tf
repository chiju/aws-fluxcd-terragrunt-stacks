variable "organization_name" {
  description = "Name of the AWS organization"
  type        = string
}

variable "feature_set" {
  description = "Feature set for the organization"
  type        = string
  default     = "ALL"
}
