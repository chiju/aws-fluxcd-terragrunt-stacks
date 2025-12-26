include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-catalog/modules/vpc"
}

inputs = {
  name        = values.name
  environment = values.environment

  # VPC Configuration
  cidr_block = values.cidr_block

  # DNS Configuration (required for EKS)
  enable_dns_support   = true
  enable_dns_hostnames = true

  # Auto-generate subnets based on available AZs (best practice)
  # Leave empty to auto-generate across all AZs
  public_subnet_cidrs  = try(values.public_subnet_cidrs, [])
  private_subnet_cidrs = try(values.private_subnet_cidrs, [])

  # Database subnets (optional)
  create_database_subnets = try(values.create_database_subnets, true)
  database_subnet_cidrs   = try(values.database_subnet_cidrs, [])

  # NAT Gateway configuration
  enable_nat_gateway = try(values.enable_nat_gateway, true)
  single_nat_gateway = try(values.single_nat_gateway, true)

  # VPC Flow Logs
  enable_flow_logs        = try(values.enable_flow_logs, true)
  flow_log_retention_days = try(values.flow_log_retention_days, 30)

  # VPC Endpoints
  enable_s3_endpoint       = try(values.enable_s3_endpoint, true)
  enable_dynamodb_endpoint = try(values.enable_dynamodb_endpoint, false)
  interface_vpc_endpoints = try(values.interface_vpc_endpoints, {
    "ecr.dkr" = "ECR Docker endpoint"
    "ecr.api" = "ECR API endpoint"
    "logs"    = "CloudWatch Logs endpoint"
    "eks"     = "EKS endpoint"
  })

  # Subnet tags for EKS
  public_subnet_tags = try(values.public_subnet_tags, {
    "kubernetes.io/role/elb" = "1"
  })

  private_subnet_tags = try(values.private_subnet_tags, {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = values.name
  })

  tags = try(values.tags, {
    Project     = "FluxCD-Terragrunt-Stacks"
    Environment = values.environment
    ManagedBy   = "OpenTofu"
    Stack       = "vpc"
  })
}
