include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-catalog/modules/aws-organizational-unit"
}

dependency "organization" {
  config_path = "../organization"
}

inputs = {
  name      = values.name
  parent_id = dependency.organization.outputs.roots[0].id
  tags      = try(values.tags, {})
}
