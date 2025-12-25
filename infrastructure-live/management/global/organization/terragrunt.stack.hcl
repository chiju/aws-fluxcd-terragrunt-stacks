unit "organization" {
  source = "${get_repo_root()}/infrastructure-catalog/units/aws-organization"
  path   = "organization"

  values = {
    organization_name = "FluxCD Terragrunt Stacks"
    feature_set       = "ALL"
  }
}

unit "platform_ou" {
  source = "${get_repo_root()}/infrastructure-catalog/units/aws-organizational-unit"
  path   = "platform-ou"

  values = {
    name     = "Platform-2"
    vpc_path = "../organization"
  }
}

unit "dev_account" {
  source = "${get_repo_root()}/infrastructure-catalog/units/aws-account"
  path   = "accounts/dev"

  values = {
    name              = "fluxcd-stacks-dev"
    email             = "chiju24dec25+dev@gmail.com"
    ou_path           = "../../platform-ou"
    close_on_deletion = true
  }
}

unit "staging_account" {
  source = "${get_repo_root()}/infrastructure-catalog/units/aws-account"
  path   = "accounts/staging"

  values = {
    name              = "fluxcd-stacks-staging"
    email             = "chiju24dec25+staging@gmail.com"
    ou_path           = "../../platform-ou"
    close_on_deletion = true
  }
}

unit "prod_account" {
  source = "${get_repo_root()}/infrastructure-catalog/units/aws-account"
  path   = "accounts/prod"

  values = {
    name              = "fluxcd-stacks-prod"
    email             = "chiju24dec25+prod@gmail.com"
    ou_path           = "../../platform-ou"
    close_on_deletion = true
  }
}
