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
  name      = "flux-instance"
  chart     = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance"
  namespace = "flux-system"

  values = [
    yamlencode({
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
    })
  ]

  depends_on = [
    helm_release.flux_operator,
    kubernetes_secret_v1.flux_github_app
  ]
}

# Wait for FluxCD CRDs to be available
resource "null_resource" "wait_for_flux_crds" {
  count = length(data.aws_eks_cluster.cluster) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for FluxCD CRDs to be available..."
      for i in {1..30}; do
        if kubectl get crd gitrepositories.source.toolkit.fluxcd.io --context=arn:aws:eks:${var.aws_region}:${var.account_id}:cluster/${var.cluster_name} 2>/dev/null; then
          echo "GitRepository CRD is available"
          exit 0
        fi
        echo "Attempt $i: GitRepository CRD not yet available, waiting 10 seconds..."
        sleep 10
      done
      echo "Timeout waiting for GitRepository CRD"
      exit 1
    EOT
  }

  depends_on = [helm_release.flux_instance]
}

# Create GitRepository and Kustomizations via Kubernetes manifests
resource "kubernetes_manifest" "platform_git_repo" {
  count = length(data.aws_eks_cluster.cluster) > 0 ? 1 : 0
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = "platform-apps"
      namespace = "flux-system"
    }
    spec = {
      interval = "5s"
      url      = var.git_repo_url
      ref = {
        branch = "main"
      }
      provider = var.github_app_id != "" ? "github" : null
      secretRef = var.github_app_id != "" ? {
        name = "flux-system"
      } : null
    }
  }

  depends_on = [
    null_resource.wait_for_flux_crds,
    kubernetes_secret_v1.flux_github_app
  ]
}

resource "kubernetes_manifest" "infrastructure_kustomization" {
  count = length(data.aws_eks_cluster.cluster) > 0 ? 1 : 0
  manifest = {
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "infrastructure"
      namespace = "flux-system"
    }
    spec = {
      interval = "10s"
      sourceRef = {
        kind = "GitRepository"
        name = "platform-apps"
      }
      path  = "./flux-config/infrastructure"
      prune = true
      wait  = true
    }
  }

  depends_on = [kubernetes_manifest.platform_git_repo]
}

resource "kubernetes_manifest" "apps_kustomization" {
  count = length(data.aws_eks_cluster.cluster) > 0 ? 1 : 0
  manifest = {
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "apps"
      namespace = "flux-system"
    }
    spec = {
      interval = "10s"
      sourceRef = {
        kind = "GitRepository"
        name = "platform-apps"
      }
      path  = "./flux-config/apps"
      prune = true
      dependsOn = [
        {
          name = "infrastructure"
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.infrastructure_kustomization]
}
