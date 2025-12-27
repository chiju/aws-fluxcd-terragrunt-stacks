# Wait for EKS cluster to be ready
data "aws_eks_cluster" "cluster" {
  count = var.cluster_endpoint != null && var.cluster_endpoint != "https://mock-endpoint" ? 1 : 0
  name  = var.cluster_name
}

# Install Flux Operator using Helm
resource "helm_release" "flux_operator" {
  name             = "flux-operator"
  repository       = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart            = "flux-operator"
  version          = "0.38.1"
  namespace        = "flux-system"
  create_namespace = true

  depends_on = [data.aws_eks_cluster.cluster]
}

# Create GitHub App secret
resource "kubernetes_secret_v1" "flux_github_app" {
  count = var.github_app_id != "" ? 1 : 0

  metadata {
    name      = "flux-system"
    namespace = "flux-system"
  }

  data = {
    githubAppID             = var.github_app_id
    githubAppInstallationID = var.github_app_installation_id
    githubAppPrivateKey     = var.github_app_private_key
  }

  type = "Opaque"

  depends_on = [helm_release.flux_operator]
}

# Create FluxInstance for GitOps
resource "kubernetes_manifest" "flux_instance" {
  manifest = {
    apiVersion = "fluxcd.controlplane.io/v1"
    kind       = "FluxInstance"
    metadata = {
      name      = "flux"
      namespace = "flux-system"
    }
    spec = {
      distribution = {
        version  = "2.7.5"
        registry = "ghcr.io/fluxcd"
      }
      components = [
        "source-controller",
        "kustomize-controller",
        "helm-controller",
        "notification-controller"
      ]
      cluster = {
        type          = "kubernetes"
        multitenant   = false
        networkPolicy = true
        domain        = "cluster.local"
      }
      sync = {
        kind       = "GitRepository"
        provider   = "github"
        url        = var.git_repo_url
        ref        = "refs/heads/main"
        path       = var.target_path
        pullSecret = var.github_app_id != "" ? "flux-system" : null
      }
    }
  }

  depends_on = [kubernetes_secret_v1.flux_github_app]
}


