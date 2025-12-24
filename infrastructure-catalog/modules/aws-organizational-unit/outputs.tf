output "id" {
  description = "Organizational unit ID"
  value       = aws_organizations_organizational_unit.ou.id
}

output "arn" {
  description = "Organizational unit ARN"
  value       = aws_organizations_organizational_unit.ou.arn
}
