terraform {
  source = "${get_repo_root()}/infrastructure-catalog/modules/vpc"
}

inputs = {
  name        = "fluxcd-dev"
  environment = "dev"

  # VPC Configuration
  cidr_block = "10.0.0.0/16"

  # Auto-generate subnets based on available AZs (best practice)
  # Leave empty to auto-generate across all AZs
  public_subnet_cidrs  = []
  private_subnet_cidrs = []

  # Database subnets (optional)
  create_database_subnets = true
  database_subnet_cidrs   = []

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = true

  # VPC Flow Logs
  enable_flow_logs        = true
  flow_log_retention_days = 30

  # VPC Endpoints
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = false
  interface_vpc_endpoints = {
    "ecr.dkr" = "ECR Docker endpoint"
    "ecr.api" = "ECR API endpoint"
    "logs"    = "CloudWatch Logs endpoint"
  }

  # Subnet tags for EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = "fluxcd-dev"
  }

  tags = {
    Project     = "FluxCD-Terragrunt-Stacks"
    Environment = "dev"
    ManagedBy   = "OpenTofu"
    Stack       = "vpc"
  }
}
