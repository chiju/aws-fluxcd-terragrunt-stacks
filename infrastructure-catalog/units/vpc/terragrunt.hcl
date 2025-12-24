terraform {
  source = "${get_repo_root()}/infrastructure-catalog/modules/vpc"
}

inputs = {
  name        = stack.values.name
  environment = stack.values.environment

  # VPC Configuration
  cidr_block = stack.values.cidr_block

  # Auto-generate subnets based on available AZs (best practice)
  # Leave empty to auto-generate across all AZs
  public_subnet_cidrs  = []
  private_subnet_cidrs = []

  # Database subnets (optional)
  create_database_subnets = stack.values.create_database_subnets
  database_subnet_cidrs   = []

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = stack.values.single_nat_gateway

  # VPC Flow Logs
  enable_flow_logs        = true
  flow_log_retention_days = 30

  # VPC Endpoints
  enable_s3_endpoint       = stack.values.enable_s3_endpoint
  enable_dynamodb_endpoint = false
  interface_vpc_endpoints  = stack.values.interface_vpc_endpoints

  # Subnet tags for EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = stack.values.name
  }

  tags = {
    Project     = "FluxCD-Terragrunt-Stacks"
    Environment = stack.values.environment
    ManagedBy   = "OpenTofu"
    Stack       = "vpc"
  }
}
