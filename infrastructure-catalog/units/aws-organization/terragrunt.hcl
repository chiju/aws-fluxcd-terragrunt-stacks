include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-catalog/modules/aws-organization"
}

inputs = {
  organization_name = values.organization_name
  feature_set      = values.feature_set
}
