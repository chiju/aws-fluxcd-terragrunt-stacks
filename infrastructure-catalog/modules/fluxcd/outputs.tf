output "namespace" {
  description = "FluxCD namespace"
  value       = var.namespace
}

output "flux_version" {
  description = "Deployed FluxCD version"
  value       = var.flux_version
}

output "repository_url" {
  description = "Git repository URL"
  value       = var.git_repo_url
}

output "target_path" {
  description = "Path in Git repository"
  value       = var.target_path
}

output "public_key" {
  description = "FluxCD public key (for deploy key)"
  value       = flux_bootstrap_git.main.public_key
  sensitive   = true
}
