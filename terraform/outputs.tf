output "cluster_endpoint" {
  value = aws_eks_cluster.msdemo_dev_eks.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.msdemo_dev_eks.name
}

output "kubeconfig_certificate_authority_data" {
  value = aws_eks_cluster.msdemo_dev_eks.certificate_authority[0].data
}
