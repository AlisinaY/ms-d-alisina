output "cluster_endpoint" {
  value = aws_eks_cluster.my_eks.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.my_eks.name
}

output "kubeconfig_certificate_authority_data" {
  value = aws_eks_cluster.my_eks.certificate_authority[0].data
}
