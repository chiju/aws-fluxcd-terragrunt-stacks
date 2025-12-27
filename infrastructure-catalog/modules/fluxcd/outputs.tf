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


