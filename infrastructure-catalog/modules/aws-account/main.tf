resource "aws_organizations_account" "account" {
  name              = var.name
  email             = var.email
  parent_id         = var.parent_id
  close_on_deletion = var.close_on_deletion

  tags = var.tags

  lifecycle {
    ignore_changes = [role_name]
  }
}
