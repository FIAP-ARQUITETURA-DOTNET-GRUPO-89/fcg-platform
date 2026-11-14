variable "aws_region" {
  description = "Região AWS onde o cluster será criado."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nome do cluster EKS."
  type        = string
  default     = "fcg-platform"
}

variable "ebs_csi_role_name" {
  description = "Nome da role IAM usada pelo EBS CSI Driver."
  type        = string
  default     = "AmazonEKS_EBS_CSI_DriverRole"
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes usada pelo cluster EKS."
  type        = string
  default     = "1.37"
}

variable "node_group_name" {
  description = "Nome do grupo gerenciado de nós."
  type        = string
  default     = "fcg-workers"
}

variable "node_instance_types" {
  description = "Tipos de instância EC2 usados pelos nós."
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "node_disk_size" {
  description = "Tamanho do disco EBS de cada nó, em GiB."
  type        = number
  default     = 20
}

variable "node_min_size" {
  description = "Quantidade mínima de nós."
  type        = number
  default     = 1
}

variable "node_desired_size" {
  description = "Quantidade desejada de nós."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Quantidade máxima de nós."
  type        = number
  default     = 1
}

variable "cluster_public_access_cidrs" {
  description = "CIDRs autorizados no endpoint público do EKS."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags aplicadas aos recursos gerenciados pelo provider."
  type        = map(string)
  default = {
    Project = "FCG"
  }
}
