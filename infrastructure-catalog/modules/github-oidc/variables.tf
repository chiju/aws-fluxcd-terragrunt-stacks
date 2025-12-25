variable "environment" {
  description = "Environment name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository (owner/repo)"
  type        = string
}

variable "policy_arns" {
  description = "List of policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}
