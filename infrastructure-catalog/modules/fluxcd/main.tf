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

  # Wait for operator to be ready (includes CRDs)
  wait          = true
  wait_for_jobs = true
  timeout       = 600 # 10 minutes

  values = [
    yamlencode({
      livenessProbe  = null
      readinessProbe = null

      # Required fields based on schema
      multitenancy = {
        enabled                               = false
        defaultServiceAccount                 = "flux-operator"
        enabledForWorkloadIdentity            = false
        defaultWorkloadIdentityServiceAccount = "flux-operator"
      }

      reporting = {
        interval = "5m"
      }
    })
  ]

  depends_on = [data.aws_eks_cluster.cluster]
}

# Create GitHub App secret with correct FluxCD field names
resource "kubernetes_secret_v1" "flux_github_app" {
  count = length(data.aws_eks_cluster.cluster) > 0 ? 1 : 0

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

# Install FluxInstance with GitOps sync configuration
resource "helm_release" "flux_instance" {
  count = length(data.aws_eks_cluster.cluster) > 0 ? 1 : 0

  name       = "flux-instance"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"
  version    = "0.38.1"
  namespace  = "flux-system"

  values = [
    yamlencode({
      fluxInstance = {
        distribution = {
          version  = "2.x"
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
          path       = "flux-config/clusters/dev"
          pullSecret = "flux-system"
        }
      }
    })
  ]

  depends_on = [
    helm_release.flux_operator,
    kubernetes_secret_v1.flux_github_app
  ]
}
