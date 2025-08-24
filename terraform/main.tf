provider "aws" {
  region = var.aws_region
}

# -------------------------------------------
# ECR Repository
# -------------------------------------------
resource "aws_ecr_repository" "msdemo_dev_ecr" {

  for_each = toset(var.ecr_repositories)

  name = each.key
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    environment = "dev"
  }
}

# --------------------------------------------
# EKS CLUSTER
# --------------------------------------------
resource "aws_eks_cluster" "msdemo_dev_eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.msdemo_dev_cluster_role.arn

  vpc_config {
    subnet_ids = module.vpc.public_subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.msdemo_dev_eks_cluster_policy,
    aws_iam_role_policy_attachment.msdemo_dev_eks_vpc_controller,
  ]
}

resource "aws_iam_role" "msdemo_dev_cluster_role" {
  name = "msdemo-dev-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "msdemo_dev_eks_cluster_policy" {
  role       = aws_iam_role.msdemo_dev_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "msdemo_dev_eks_vpc_controller" {
  role       = aws_iam_role.msdemo_dev_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# --------------------------------------------
# NODE GROUP
# --------------------------------------------
resource "aws_eks_node_group" "msdemo_dev_node_group" {
  cluster_name    = aws_eks_cluster.msdemo_dev_eks.name
  node_group_name = "msdemo-dev-node-group"
  node_role_arn   = aws_iam_role.msdemo_dev_node_role.arn
  subnet_ids      = module.vpc.public_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.msdemo_dev_node_worker,
    aws_iam_role_policy_attachment.msdemo_dev_node_cni,
    aws_iam_role_policy_attachment.msdemo_dev_node_ecr
  ]
}

resource "aws_iam_role" "msdemo_dev_node_role" {
  name = "msdemo-dev-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "msdemo_dev_node_worker" {
  role       = aws_iam_role.msdemo_dev_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "msdemo_dev_node_cni" {
  role       = aws_iam_role.msdemo_dev_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "msdemo_dev_node_ecr" {
  role       = aws_iam_role.msdemo_dev_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# --------------------------------------------
# VPC MODULE
# --------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "msdemo-dev-eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway      = true
  single_nat_gateway      = true
  map_public_ip_on_launch = true

  tags = {
    Name = "msdemo-dev-eks-vpc"
  }
}

# --------------------------------------------
# OIDC PROVIDER FOR IRSA
# --------------------------------------------
# OIDC vom Cluster ableiten (du nutzt ja bereits aws_eks_cluster.msdemo_dev_eks)
locals {
  oidc_url      = aws_eks_cluster.msdemo_dev_eks.identity[0].oidc[0].issuer         # https://oidc.eks.eu-central-1.amazonaws.com/id/XXXX
  oidc_hostpath = replace(local.oidc_url, "https://", "")                            # oidc.eks.eu-central-1.amazonaws.com/id/XXXX
}

data "tls_certificate" "msdemo_dev_eks" {
  url = local.oidc_url
}

resource "aws_iam_openid_connect_provider" "msdemo_dev_eks_oidc" {
  url             = local.oidc_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.msdemo_dev_eks.certificates[0].sha1_fingerprint]
}

resource "aws_iam_role" "msdemo_dev_external_secrets_role" {
  name = "msdemo-dev-external-secrets-role"

  # WICHTIG: Principal.Federated -> auf den hier erstellten OIDC-Provider verweisen
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "sts:AssumeRoleWithWebIdentity",
      Principal = {
        Federated = aws_iam_openid_connect_provider.msdemo_dev_eks_oidc.arn
      },
      Condition = {
        StringEquals = {
          # Beide Bedingungen setzen: aud + sub
          "${local.oidc_hostpath}:aud" = "sts.amazonaws.com",
          "${local.oidc_hostpath}:sub" = "system:serviceaccount:external-secrets:external-secrets-sa"
        }
      }
    }]
  })
}

# Für reines Lesen genügt eine minimalere Policy.
# (Deine Attach-Variante mit SecretsManagerReadWrite funktioniert zwar, ist aber sehr weitreichend.)
resource "aws_iam_role_policy" "msdemo_dev_external_secrets_read" {
  name = "eso-secretsmanager-read"
  role = aws_iam_role.msdemo_dev_external_secrets_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
      Resource = "arn:aws:secretsmanager:eu-central-1:${data.aws_caller_identity.current.account_id}:secret:app-secrets*"
    }]
  })
}

data "aws_caller_identity" "current" {}
