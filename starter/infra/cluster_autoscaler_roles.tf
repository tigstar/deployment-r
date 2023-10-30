# Policy document allowing Federated Access for IAM Cluster Autoscaler role
data "aws_iam_policy_document" "cluster_autoscaler_sts_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_ca_oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_ca_oidc_provider.arn]
      type        = "Federated"
    }
  }
}
# IAM Role for IAM Cluster Autoscaler
resource "aws_iam_role" "cluster_autoscaler" {
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_sts_policy.json
  name               = "udacity-cluster-autoscaler"
}
# IAM Policy for IAM Cluster Autoscaler role allowing ASG operations
resource "aws_iam_policy" "cluster_autoscaler" {
  name = "udacity-cluster-cluster-autoscaler"
  policy = jsonencode({
    Statement = [{
      Action = "*"
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}
resource "aws_iam_role_policy_attachment" "eks_ca_iam_policy_attach" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn

}

data "aws_eks_cluster" "eks_cluster" {
  name = "udacity-cluster"
}
# Obtain TLS certificate for the OIDC provider
data "tls_certificate" "tls" {
  url = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}
# Create OIDC Provider using TLS certificate
resource "aws_iam_openid_connect_provider" "eks_ca_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.tls.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

output "eks_ca_iam_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
  description = "The IAM role ARN for EKS Cluster Autoscaler"
}