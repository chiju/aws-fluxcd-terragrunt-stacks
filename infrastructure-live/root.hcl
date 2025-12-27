# Root Terragrunt configuration
# This file is included by all terragrunt.hcl and terragrunt.stack.hcl files

locals {
  # Parse account and region from path
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl", "account.hcl"))

  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.account_id
  aws_region   = local.region_vars.locals.aws_region
}

# Remote state configuration - S3 backend with automatic bucket creation
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    encrypt = true
    bucket  = "terragrunt-stacks-state-${local.account_name}-${local.aws_region}"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = local.aws_region
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "~> 1.14.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.7.6"
    }
    github = {
      source  = "integrations/github"
      version = "6.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"
  
  default_tags {
    tags = {
      ManagedBy   = "Terragrunt"
      Environment = "${local.account_name}"
      Region      = "${local.aws_region}"
    }
  }
}

provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.cluster[0].endpoint, "")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), "")
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", try(data.aws_eks_cluster.cluster[0].name, "")]
  }
}

provider "github" {
  # Configuration will be provided via environment variables
}

provider "flux" {
  kubernetes = {
    host                   = try(data.aws_eks_cluster.cluster[0].endpoint, "")
    cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data), "")
    
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", try(data.aws_eks_cluster.cluster[0].name, "")]
    }
  }
  
  git = {
    url = "https://github.com/chiju/aws-fluxcd-terragrunt-stacks.git"
    branch = "main"
  }
}
EOF
}

# Common inputs available to all configurations
inputs = merge(
  local.account_vars.locals,
  try(local.region_vars.locals, {}),
  {
    aws_region = local.aws_region
  }
)
