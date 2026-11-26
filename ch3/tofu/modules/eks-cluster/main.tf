locals {
  enable_pod_identity_agent = (
    var.enable_eks_pod_identity_agent ||
    var.enable_aws_load_balancer_controller
  )

  lbc_service_account = "aws-load-balancer-controller"
  lbc_namespace       = "kube-system"
}

# ==================================================
# VPC AND SUBNETS
# ==================================================

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnets" "default_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# ==================================================
# SUBNET TAGGING FOR AWS LOAD BALANCER CONTROLLER
# ==================================================

resource "aws_ec2_tag" "public_subnet_elb" {
  for_each = var.enable_aws_load_balancer_controller ? toset(
    data.aws_subnets.default_public.ids
  ) : toset([])

  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

# ==================================================
# EKS CONTROL PLANE IAM ROLE
# ==================================================

resource "aws_iam_role" "cluster" {
  name               = "${var.name}-control-plane"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
}

data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# ==================================================
# EKS CLUSTER
# ==================================================

resource "aws_eks_cluster" "cluster" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  tags = {
    Name    = var.name
    Ansible = "${var.name}_Ansible"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
  ]
}

# ==================================================
# EKS WORKER NODE IAM ROLE
# ==================================================

resource "aws_iam_role" "node_group" {
  name               = "${var.name}-worker-nodes"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
}

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

# ==================================================
# EKS MANAGED NODE GROUP
# ==================================================

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = var.name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = data.aws_subnets.default.ids
  instance_types  = [var.instance_type]

  scaling_config {
    min_size     = var.min_worker_nodes
    max_size     = var.max_worker_nodes
    desired_size = var.min_worker_nodes
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# ==================================================
# EKS POD IDENTITY AGENT
# ==================================================

resource "aws_eks_addon" "eks_pod_identity_agent" {
  count = local.enable_pod_identity_agent ? 1 : 0

  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [
    aws_eks_node_group.nodes
  ]
}

# ==================================================
# AWS LOAD BALANCER CONTROLLER IAM POLICY
# ==================================================

resource "aws_iam_policy" "load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name        = "${var.name}-load-balancer-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = file("${path.module}/policies/lbc-iam-policy.json")
}

# ==================================================
# AWS LOAD BALANCER CONTROLLER TRUST POLICY
# ==================================================

data "aws_iam_policy_document" "pod_identity" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

# ==================================================
# AWS LOAD BALANCER CONTROLLER IAM ROLE
# ==================================================

resource "aws_iam_role" "load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name               = "${var.name}-load-balancer-controller-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity.json
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  role       = aws_iam_role.load_balancer_controller[0].name
  policy_arn = aws_iam_policy.load_balancer_controller[0].arn
}

# ==================================================
# AWS LOAD BALANCER CONTROLLER POD IDENTITY ASSOCIATION
# ==================================================

resource "aws_eks_pod_identity_association" "load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  cluster_name    = aws_eks_cluster.cluster.name
  namespace       = local.lbc_namespace
  service_account = local.lbc_service_account

  role_arn = aws_iam_role.load_balancer_controller[0].arn

  depends_on = [
    aws_eks_addon.eks_pod_identity_agent,
    aws_iam_role_policy_attachment.load_balancer_controller
  ]
}