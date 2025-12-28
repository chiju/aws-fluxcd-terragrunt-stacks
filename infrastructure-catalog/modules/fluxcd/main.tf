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

# Create GitHub App secret using null_resource to run flux CLI
resource "null_resource" "flux_github_app_secret" {
  count = var.github_app_id != "" ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      # Write private key to temporary file
      echo "${var.github_app_private_key}" > /tmp/github-app-private-key.pem
      
      # Create secret using flux CLI
      flux create secret githubapp flux-system \
        --app-id="${var.github_app_id}" \
        --app-installation-id="${var.github_app_installation_id}" \
        --app-private-key="/tmp/github-app-private-key.pem" \
        --namespace=flux-system \
        --export > /tmp/flux-github-app-secret.yaml
      
      # Apply the secret
      kubectl apply -f /tmp/flux-github-app-secret.yaml
      
      # Clean up temporary files
      rm -f /tmp/github-app-private-key.pem /tmp/flux-github-app-secret.yaml
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete secret flux-system -n flux-system --ignore-not-found=true"
  }

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
      sync = {
        kind       = "GitRepository"
        provider   = "github"
        url        = var.git_repo_url
        ref        = "refs/heads/main"
        path       = var.target_path
        pullSecret = var.github_app_id != "" ? "flux-system" : null
      }
    })
  ]

  depends_on = [
    helm_release.flux_operator,
    null_resource.flux_github_app_secret
  ]
}

# Create GitRepository and Kustomizations via Kubernetes manifests
resource "kubernetes_manifest" "platform_git_repo" {
  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = "platform-apps"
      namespace = "flux-system"
    }
    spec = {
      interval = "1m"
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

  depends_on = [helm_release.flux_instance, null_resource.flux_github_app_secret]
}

resource "kubernetes_manifest" "infrastructure_kustomization" {
  manifest = {
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "infrastructure"
      namespace = "flux-system"
    }
    spec = {
      interval = "10m"
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
  manifest = {
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "apps"
      namespace = "flux-system"
    }
    spec = {
      interval = "10m"
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


