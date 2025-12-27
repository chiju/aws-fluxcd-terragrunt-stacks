unit "vpc" {
  source = "${get_repo_root()}/infrastructure-catalog/units/vpc"
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
      "eks"     = "EKS API endpoint"
    }

    # Enable NAT Gateway for internet access (required for ghcr.io)
    enable_nat_gateway = true
  }
}

unit "eks" {
  source = "${get_repo_root()}/infrastructure-catalog/units/eks"
  path   = "eks"

  values = {
    cluster_name = "fluxcd-dev"

    kubernetes_version = "1.34"

    # API endpoint access
    endpoint_public_access = true
    public_access_cidrs    = ["0.0.0.0/0"]

    # Node configuration
    instance_types   = ["t3.medium"]
    desired_capacity = 2
    min_capacity     = 1
    max_capacity     = 4

    # Security and logging
    cluster_log_retention_days = 7
    enable_irsa                = true
    enable_cluster_autoscaler  = true

    # GitHub Actions access
    github_role_arn = get_env("AWS_GITHUB_ROLE_ARN_DEV")

    # Organization access
    org_access_role_arn = "arn:aws:iam::${get_env("AWS_ACCOUNT_ID_DEV")}:role/OrganizationAccountAccessRole"

    tags = {
      Environment = "dev"
      Project     = "fluxcd"
      ManagedBy   = "terragrunt"
    }
  }
}

unit "fluxcd" {
  source = "${get_repo_root()}/infrastructure-catalog/units/fluxcd"
  path   = "fluxcd"

  values = {
    environment = "dev"

    # Git repository configuration
    git_repo_url = "https://github.com/chiju/aws-fluxcd-terragrunt-stacks.git"

    # GitHub App authentication
    github_app_id              = get_env("FLUXCD_APP_ID")
    github_app_installation_id = get_env("FLUXCD_APP_INSTALLATION_ID")
    github_app_private_key     = get_env("FLUXCD_APP_PRIVATE_KEY")
  }
}
