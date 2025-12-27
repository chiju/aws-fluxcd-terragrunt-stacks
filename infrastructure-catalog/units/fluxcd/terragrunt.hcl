include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-catalog/modules/fluxcd"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_id       = "mock-cluster"
    cluster_endpoint = "https://mock-endpoint"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "fmt"]
}

inputs = {
  cluster_name     = dependency.eks.outputs.cluster_id
  cluster_endpoint = dependency.eks.outputs.cluster_endpoint
  environment      = values.environment

  # Git repository configuration
  git_repo_url = values.git_repo_url
  target_path  = "flux-config/clusters/${values.environment}"

  # GitHub App authentication
  github_app_id              = values.github_app_id
  github_app_installation_id = values.github_app_installation_id
  github_app_private_key     = values.github_app_private_key
}
