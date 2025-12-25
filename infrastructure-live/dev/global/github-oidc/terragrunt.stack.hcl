unit "github_oidc" {
  source = "${get_repo_root()}/infrastructure-catalog/units/github-oidc"
  path   = "github-oidc"

  values = {
    environment = "dev"
    github_repo = "chiju/aws-fluxcd-terragrunt-stacks"
    policy_arns = [
      "arn:aws:iam::aws:policy/AdministratorAccess"
    ]
  }
}
