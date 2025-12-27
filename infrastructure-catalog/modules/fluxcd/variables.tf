variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name"
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

variable "git_branch" {
  description = "Git branch"
  type        = string
  default     = "main"
}

variable "cluster_domain" {
  description = "Cluster domain"
  type        = string
  default     = "cluster.local"
}

variable "network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}

variable "components_extra" {
  description = "Extra FluxCD components to install"
  type        = list(string)
  default     = ["image-reflector-controller", "image-automation-controller"]
}

variable "toleration_keys" {
  description = "Toleration keys for FluxCD pods"
  type        = list(string)
  default     = ["node-type"]
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

# Fallback deploy key option
variable "create_github_deploy_key" {
  description = "Create GitHub deploy key (fallback if not using GitHub App)"
  type        = bool
  default     = false
}

variable "github_repository" {
  description = "GitHub repository name (for deploy key)"
  type        = string
  default     = ""
}
