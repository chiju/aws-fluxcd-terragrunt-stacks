# Wait for EKS cluster to be ready before deploying FluxCD
data "aws_eks_cluster" "cluster" {
  count = var.cluster_endpoint != null && var.cluster_endpoint != "https://mock-endpoint" ? 1 : 0
  name  = var.cluster_name
}

# Bootstrap FluxCD using the official Terraform provider
resource "flux_bootstrap_git" "main" {
  path = var.target_path
  
  # Repository configuration
  repository_url = var.git_repo_url
  branch         = var.git_branch
  
  # Cluster configuration
  cluster_domain    = var.cluster_domain
  network_policy    = var.network_policy
  
  # Components
  components_extra = var.components_extra
  
  # Namespace
  namespace = var.namespace
  
  # Version
  version = var.flux_version
  
  # Toleration for control plane nodes
  toleration_keys = var.toleration_keys
  
  # Embedded manifests (recommended for GitOps)
  embedded_manifests = true
  
  # GitHub App authentication (if provided)
  secret_name = var.github_app_id != "" ? kubernetes_secret_v1.flux_github_app[0].metadata[0].name : null
  
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

# Create GitHub deploy key (fallback for non-GitHub App setups)
resource "github_repository_deploy_key" "flux" {
  count      = var.create_github_deploy_key && var.github_app_id == "" ? 1 : 0
  title      = "${var.cluster_name}-flux"
  repository = var.github_repository
  key        = flux_bootstrap_git.main.public_key
  read_only  = false
}
