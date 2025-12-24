variable "name" {
  description = "Name prefix for VPC resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "create_database_subnets" {
  description = "Whether to create database subnets"
  type        = bool
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (cost optimization)"
  type        = bool
}

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC Endpoint"
  type        = bool
}

variable "interface_vpc_endpoints" {
  description = "Interface VPC endpoints to create"
  type        = map(string)
}

terraform {
  source = "${get_repo_root()}/infrastructure-catalog/modules/vpc"
}

inputs = {
  name        = var.name
  environment = var.environment

  # VPC Configuration
  cidr_block = var.cidr_block

  # Auto-generate subnets based on available AZs (best practice)
  # Leave empty to auto-generate across all AZs
  public_subnet_cidrs  = []
  private_subnet_cidrs = []

  # Database subnets (optional)
  create_database_subnets = var.create_database_subnets
  database_subnet_cidrs   = []

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  # VPC Flow Logs
  enable_flow_logs        = true
  flow_log_retention_days = 30

  # VPC Endpoints
  enable_s3_endpoint       = var.enable_s3_endpoint
  enable_dynamodb_endpoint = false
  interface_vpc_endpoints  = var.interface_vpc_endpoints

  # Subnet tags for EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = var.name
  }

  tags = {
    Project     = "FluxCD-Terragrunt-Stacks"
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Stack       = "vpc"
  }
}
