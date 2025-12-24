include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infrastructure-catalog/modules/aws-account"
}

dependency "ou" {
  config_path = values.ou_path

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    id = "ou-root-wcum123456" # Valid OU ID format
  }
}

inputs = {
  name              = values.name
  email             = values.email
  parent_id         = dependency.ou.outputs.id
  close_on_deletion = values.close_on_deletion
  tags              = try(values.tags, {})
}
