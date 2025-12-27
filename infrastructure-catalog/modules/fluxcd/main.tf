# Wait for EKS cluster to be ready
data "aws_eks_cluster" "cluster" {
  count = var.cluster_endpoint != null && var.cluster_endpoint != "https://mock-endpoint" ? 1 : 0
  name  = var.cluster_name
}

# Bootstrap FluxCD using the official Terraform provider
resource "flux_bootstrap_git" "main" {
  path = var.target_path

  depends_on = [data.aws_eks_cluster.cluster]
}

# Create GitHub App secret for repository access (following ArgoCD pattern)
resource "kubernetes_secret_v1" "flux_github_app" {
  count = var.github_app_id != "" ? 1 : 0

  metadata {
    name      = "flux-github-app"
    namespace = var.namespace
  }

  data = {
    githubAppID             = var.github_app_id
    githubAppInstallationID = var.github_app_installation_id
    githubAppPrivateKey     = var.github_app_private_key
  }

  type = "Opaque"

  depends_on = [flux_bootstrap_git.main]
}


