variable "name" {
  description = "Name of the EKS cluster"
  type        = string
}


variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34"
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block (optional, will query from AWS if not provided)"
  type        = string
  default     = null
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS cluster control plane"
  type        = list(string)
}

variable "node_group_subnets" {
  description = "List of subnet IDs for EKS node groups"
  type        = list(string)
}

variable "instance_types" {
  description = "List of instance types for node groups"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_capacity" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "authentication_mode" {
  description = "Authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "max_capacity" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}



variable "cluster_log_types" {
  description = "List of control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

variable "node_group_ami_type" {
  description = "AMI type for node groups"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_group_capacity_type" {
  description = "Capacity type for node groups"
  type        = string
  default     = "ON_DEMAND"
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler tags"
  type        = bool
  default     = true
}

variable "github_role_arn" {
  description = "GitHub Actions role ARN for EKS access"
  type        = string
  default     = null
}

variable "org_access_role_arn" {
  description = "Organization account access role ARN for EKS access"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
