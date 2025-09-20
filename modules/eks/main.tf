# IAM Role for EKS cluster

# resource "aws_iam_role" "eks-cluster-role" {
#   name = "${var.eks_cluster_name}-eks-cluster-role"

#   assume_role_policy = jsonencode(
#     {
#       Version = "2012-10-17",

#       Statement = [{
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#       }]
#     }
#   )
# }

# Attach EKS cluster policy to Cluster Role

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}


resource "aws_eks_cluster" "main-eks-cluster" {
  name     = var.eks_cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks-cluster-role.arn

  vpc_config {
    subnet_ids = var.subnet_id
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]
}

# IAM role for Worker Node

# resource "aws_iam_role" "eks-node-role" {
#   name = "${var.eks_cluster_name}-node-role"

#   assume_role_policy = jsonencode(
#     {
#       Version = "2012-10-17",

#       Statement = [{
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }]
#     }
#   )
# }


# Attach Required Policies to Worker Node role

resource "aws_iam_role_policy_attachment" "eks-node-policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  policy_arn = each.value
  role       = aws_iam_role.eks-node-role.name
}


# Create EKS Managed Node Group

resource "aws_eks_node_group" "eks-worker-node" {

  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main-eks-cluster.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = var.subnet_id

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-node-policy
  ]
}
