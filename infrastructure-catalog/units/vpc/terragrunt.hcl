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
  public_subnet_cidrs   = []
  private_subnet_cidrs  = []
  
  # Database subnets (optional)
  create_database_subnets = var.create_database_subnets
  database_subnet_cidrs   = []
  
  # NAT Gateway configuration
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  
  # VPC Flow Logs
  enable_flow_logs        = var.enable_flow_logs
  flow_log_retention_days = var.flow_log_retention_days
  
  # VPC Endpoints
  enable_s3_endpoint       = var.enable_s3_endpoint
  enable_dynamodb_endpoint = var.enable_dynamodb_endpoint
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
