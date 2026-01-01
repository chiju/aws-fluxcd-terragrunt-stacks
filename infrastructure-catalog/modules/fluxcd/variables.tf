variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}



variable "namespace" {
  description = "Kubernetes namespace for FluxCD"
  type        = string
  default     = "flux-system"
}

variable "flux_version" {
  description = "FluxCD version"
  type        = string
  default     = "v2.7.5"
}

variable "target_path" {
  description = "Path in Git repository for FluxCD manifests"
  type        = string
  default     = "flux-config/clusters"
}

variable "git_repo_url" {
  description = "Git repository URL"
  type        = string
}


# GitHub App authentication (following ArgoCD pattern)
variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
  default     = ""
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
  default     = ""
}

variable "github_app_private_key" {
  description = "GitHub App Private Key"
  type        = string
  sensitive   = true
  default     = ""
}


