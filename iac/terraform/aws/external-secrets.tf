# ---------------------------------------------------------------------------
# External Secrets Operator
#
# As credenciais da plataforma ficam no AWS Systems Manager Parameter Store
# (parâmetros SecureString em var.parameter_store_prefix). O External Secrets
# Operator lê esses parâmetros e cria os Secrets do Kubernetes que os
# Deployments já referenciam (postgres-secret, fcg-users-api-secret, ...).
#
# Os valores NÃO passam pelo Terraform (não ficam no tfstate): são publicados
# pelo script scripts/secrets.sh aws.
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# Role IRSA: só a service account do External Secrets pode assumi-la.
data "aws_iam_policy_document" "external_secrets_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.external_secrets_namespace}:external-secrets"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${var.cluster_name}-external-secrets-role"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json
}

# Leitura apenas dos parâmetros da plataforma (menor privilégio).
data "aws_iam_policy_document" "external_secrets_parameter_store" {
  statement {
    sid    = "ReadPlatformParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.parameter_store_prefix}/*",
    ]
  }

  statement {
    sid       = "DescribeParameters"
    effect    = "Allow"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  # SecureString é criptografado com a chave gerenciada aws/ssm.
  statement {
    sid       = "DecryptSecureStringViaSsm"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "external_secrets" {
  name   = "${var.cluster_name}-external-secrets-parameter-store"
  role   = aws_iam_role.external_secrets.id
  policy = data.aws_iam_policy_document.external_secrets_parameter_store.json
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  namespace        = var.external_secrets_namespace
  create_namespace = true

  values = [
    yamlencode({
      installCRDs  = true
      replicaCount = 1

      serviceAccount = {
        create = true
        name   = "external-secrets"

        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets.arn
        }
      }
    })
  ]

  depends_on = [
    aws_eks_node_group.this,
    aws_iam_role_policy.external_secrets
  ]
}
