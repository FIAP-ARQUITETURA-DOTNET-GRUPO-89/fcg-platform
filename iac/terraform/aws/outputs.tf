output "cluster_name" {
  description = "Nome do cluster EKS criado."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint do plano de controle do EKS."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "Security Group criado pelo EKS para o cluster."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_group_name" {
  description = "Nome do grupo gerenciado de nós."
  value       = aws_eks_node_group.this.node_group_name
}

output "subnet_ids" {
  description = "Sub-redes da VPC padrão utilizadas pelo cluster e pelos nós."
  value       = data.aws_subnets.default.ids
}

output "cluster_oidc_issuer" {
  description = "URL do provedor OIDC utilizado pelo EBS CSI Driver."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "ebs_csi_role_arn" {
  description = "ARN da role IAM do EBS CSI Driver."
  value       = aws_iam_role.ebs_csi.arn
}