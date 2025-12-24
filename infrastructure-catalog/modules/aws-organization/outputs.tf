output "id" {
  description = "Organization ID"
  value       = aws_organizations_organization.org.id
}

output "arn" {
  description = "Organization ARN"
  value       = aws_organizations_organization.org.arn
}

output "roots" {
  description = "Organization roots"
  value       = aws_organizations_organization.org.roots
}

output "master_account_id" {
  description = "Master account ID"
  value       = aws_organizations_organization.org.master_account_id
}
