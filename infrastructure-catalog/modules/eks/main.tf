
data "aws_vpc" "main" {
  count = var.vpc_cidr == null ? 1 : 0
  id    = var.vpc_id
}

# KMS Key for EKS cluster encryption
resource "aws_kms_key" "eks" {
  description             = "EKS cluster encryption key for ${var.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eks-encryption-key"
    }
  )
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# CloudWatch Log Group for EKS cluster logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.name}/cluster"
  retention_in_days = var.cluster_log_retention_days >= 365 ? var.cluster_log_retention_days : 365
  kms_key_id        = aws_kms_key.eks.arn

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eks-cluster-logs"
    }
  )
}

# EKS Cluster Security Group
resource "aws_security_group" "cluster" {
  name_prefix = "${var.name}-eks-cluster-"
  vpc_id      = var.vpc_id
  description = "Security group for EKS cluster control plane"

  # Allow HTTPS from nodes
  ingress {
    description = "HTTPS from worker nodes"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }

  # Allow communication within VPC
  egress {
    description = "VPC internal communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr != null ? var.vpc_cidr : data.aws_vpc.main[0].cidr_block]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eks-cluster-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Node Group Security Group
resource "aws_security_group" "node_group" {
  name_prefix = "${var.name}-eks-node-group-"
  vpc_id      = var.vpc_id
  description = "Security group for EKS node group"

  # Allow nodes to communicate with each other
  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Allow pods to communicate with cluster API
  ingress {
    description = "Cluster API to node communication"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Allow communication within VPC
  egress {
    description = "VPC internal communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr != null ? var.vpc_cidr : data.aws_vpc.main[0].cidr_block]
  }

  # Allow HTTPS outbound for EKS API and ECR (required for internet)
  # checkov:skip=CKV_AWS_23: EKS nodes require internet access for API server and ECR
  # checkov:skip=AVD-AWS-0104: EKS nodes require HTTPS internet access for functionality
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP outbound only to VPC (for internal services)
  egress {
    description = "HTTP outbound to VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr != null ? var.vpc_cidr : data.aws_vpc.main[0].cidr_block]
  }

  # Allow DNS outbound to VPC
  egress {
    description = "DNS outbound"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr != null ? var.vpc_cidr : data.aws_vpc.main[0].cidr_block]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eks-node-group-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# EKS Cluster
# nosemgrep: terraform.lang.security.eks-public-endpoint-enabled.eks-public-endpoint-enabled
resource "aws_eks_cluster" "main" {
  # checkov:skip=CKV_AWS_339:Kubernetes 1.34 is supported by AWS EKS but not yet recognized by Checkov
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
    security_group_ids      = [aws_security_group.cluster.id]
    
    # Explicitly disable public access when not needed for security
    # semgrep:ignore terraform.lang.security.eks-public-endpoint-enabled.eks-public-endpoint-enabled
  }

  # Set authentication mode for access entries
  access_config {
    authentication_mode = var.authentication_mode
  }

  # Enable cluster logging
  enabled_cluster_log_types = var.cluster_log_types

  # Enable encryption
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.eks_cluster
  ]
}

# EKS Access Entry for GitHub Actions
resource "aws_eks_access_entry" "github_actions" {
  count         = var.github_role_arn != null ? 1 : 0
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.github_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  count         = var.github_role_arn != null ? 1 : 0
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.github_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_actions]
}

# EKS Access Entry for Organization Account Access Role
resource "aws_eks_access_entry" "org_access" {
  count         = var.org_access_role_arn != null ? 1 : 0
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.org_access_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "org_access_admin" {
  count         = var.org_access_role_arn != null ? 1 : 0
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.org_access_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.org_access]
}

# Launch template for node group with additional security groups
resource "aws_launch_template" "node_group" {
  name_prefix = "${var.name}-node-group-"
  
  # Only specify security groups - let EKS manage AMI, instance type, and user data
  vpc_security_group_ids = [
    aws_security_group.node_group.id
  ]

  # IMDS v2 enforcement for security
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.name}-node-group-instance"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-node-group-lt"
    }
  )
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.name}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.node_group_subnets

  capacity_type  = var.node_group_capacity_type
  instance_types = var.instance_types
  ami_type       = var.node_group_ami_type

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  update_config {
    max_unavailable = 1
  }

  # Use launch template with additional security groups
  launch_template {
    id      = aws_launch_template.node_group.id
    version = "$Latest"
  }

  # Tags for cluster autoscaler and node group
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-node-group"
    },
    var.enable_cluster_autoscaler ? {
      "k8s.io/cluster-autoscaler/enabled"     = "true"
      "k8s.io/cluster-autoscaler/${var.name}" = "owned"
    } : {}
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_registry_policy,
  ]
}

# Cross-security group rules (created after both SGs exist)
resource "aws_security_group_rule" "cluster_ingress_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.cluster.id
  description              = "HTTPS from node group"
}

resource "aws_security_group_rule" "nodes_ingress_from_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node_group.id
  description              = "Cluster API to node communication"
}
