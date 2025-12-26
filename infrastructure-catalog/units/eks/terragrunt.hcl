include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-catalog/modules/eks"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-12345678"
    vpc_cidr_block     = "10.0.0.0/16"
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "fmt"]
}

inputs = {
  name = values.cluster_name

  kubernetes_version = values.kubernetes_version

  # VPC dependency outputs
  vpc_id             = dependency.vpc.outputs.vpc_id
  vpc_cidr           = dependency.vpc.outputs.vpc_cidr_block
  subnet_ids         = dependency.vpc.outputs.private_subnet_ids
  node_group_subnets = dependency.vpc.outputs.private_subnet_ids

  # API endpoint access
  endpoint_public_access = values.endpoint_public_access
  public_access_cidrs    = values.public_access_cidrs

  instance_types   = values.instance_types
  desired_capacity = values.desired_capacity
  min_capacity     = values.min_capacity
  max_capacity     = values.max_capacity

  cluster_log_retention_days = values.cluster_log_retention_days
  enable_irsa                = values.enable_irsa
  enable_cluster_autoscaler  = values.enable_cluster_autoscaler

  # Access entries
  github_role_arn     = values.github_role_arn
  org_access_role_arn = values.org_access_role_arn

  tags = values.tags
}
