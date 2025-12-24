include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-catalog/modules/github-oidc"
}

inputs = {
  environment  = values.environment
  github_repo  = values.github_repo
  policy_arns  = try(values.policy_arns, ["arn:aws:iam::aws:policy/AdministratorAccess"])
}
