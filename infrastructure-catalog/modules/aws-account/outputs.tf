output "id" {
  description = "Account ID"
  value       = aws_organizations_account.account.id
}

output "arn" {
  description = "Account ARN"
  value       = aws_organizations_account.account.arn
}

output "email" {
  description = "Account email"
  value       = aws_organizations_account.account.email
}

output "name" {
  description = "Account name"
  value       = aws_organizations_account.account.name
}
