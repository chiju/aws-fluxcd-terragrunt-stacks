unit "vpc" {
  source = "${get_repo_root()}/infrastructure-catalog/modules/vpc"
  path   = "vpc"
  
  values = {
    name        = "fluxcd-dev"
    environment = "dev"
    cidr_block  = "10.0.0.0/16"
    
    # Cost optimization for dev
    single_nat_gateway = true
    
    # Database subnets for RDS
    create_database_subnets = true
    
    # VPC endpoints for cost savings
    enable_s3_endpoint = true
    interface_vpc_endpoints = {
      "ecr.dkr" = "ECR Docker endpoint"
      "ecr.api" = "ECR API endpoint"
      "logs"    = "CloudWatch Logs endpoint"
    }
  }
}
