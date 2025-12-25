terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_organizations_organizational_unit" "ou" {
  name      = var.name
  parent_id = var.parent_id

  tags = var.tags
}
