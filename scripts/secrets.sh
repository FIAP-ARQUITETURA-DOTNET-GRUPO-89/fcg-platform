#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Publica as credenciais da FCG Platform a partir de um arquivo .env
# (nenhuma senha fica versionada no repositório).
#
#   bash scripts/secrets.sh k8s   [arquivo]  Secrets no cluster do contexto atual
#                                            do kubectl (Kubernetes local)
#   bash scripts/secrets.sh aws   [arquivo]  Parâmetros SecureString no AWS
#                                            Systems Manager Parameter Store
#                                            (lidos pelo External Secrets no EKS)
#   bash scripts/secrets.sh print [arquivo]  Lista o que seria gerado, sem valores
#
# Arquivo padrão: .env para k8s/print e .env.aws para aws.
# Modelo: .env.example (copie, preencha e NÃO versione).
# ---------------------------------------------------------------------------
set -euo pipefail

# Git Bash (Windows): não converter "/fcg-platform/..." em caminho do Windows.
export MSYS_NO_PATHCONV=1

CALLER_DIR="$PWD"
cd "$(dirname "$0")/.."

TARGET="${1:-}"
case "$TARGET" in
  k8s | print) ENV_FILE="${2:-.env}" ;;
  aws)         ENV_FILE="${2:-.env.aws}" ;;
  *)
    echo "Uso: bash scripts/secrets.sh k8s|aws|print [arquivo-env]" >&2
    exit 1
    ;;
esac

die() { echo "❌ $*" >&2; exit 1; }

# Arquivo informado pelo usuário: relativo à pasta de onde o script foi chamado.
if [ -n "${2:-}" ] && [[ "$ENV_FILE" != /* && ! "$ENV_FILE" =~ ^[A-Za-z]: ]]; then
  ENV_FILE="$CALLER_DIR/$ENV_FILE"
fi

[ -f "$ENV_FILE" ] || die "Arquivo $ENV_FILE não encontrado. Copie .env.example para $ENV_FILE e preencha."

# Lê o .env como o Docker Compose: CHAVE=VALOR por linha, sem executar nada.
# Aceita CRLF (arquivo editado no Windows), comentários e aspas simples/duplas.
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%$'\r'}"
  [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
  [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] \
    || die "Linha inválida em $ENV_FILE: $line"
  key="${BASH_REMATCH[2]}"
  val="${BASH_REMATCH[3]}"
  if [[ "$val" =~ ^\"(.*)\"$ || "$val" =~ ^\'(.*)\'$ ]]; then
    val="${BASH_REMATCH[1]}"
  fi
  export "$key=$val"
done < "$ENV_FILE"

PARAMETER_PREFIX="${PARAMETER_PREFIX:-/fcg-platform}"
AWS_REGION="${AWS_REGION:-us-east-1}"
MONGO_CONNECTION="${MONGO_CONNECTION:-mongodb://mongodb:27017}"
OPENSEARCH_URL="${OPENSEARCH_URL:-http://fcg-opensearch:9200}"
OPENSEARCH_USERNAME="${OPENSEARCH_USERNAME:-}"
OPENSEARCH_PASSWORD="${OPENSEARCH_PASSWORD:-}"

# --- validação ----------------------------------------------------------------
for v in POSTGRES_USER POSTGRES_PASSWORD RABBITMQ_USER RABBITMQ_PASSWORD \
         RABBITMQ_ERLANG_COOKIE JWT_SECRET PGADMIN_EMAIL PGADMIN_PASSWORD \
         GRAFANA_ADMIN_USER GRAFANA_ADMIN_PASSWORD; do
  [ -n "${!v:-}" ] || die "Defina $v em $ENV_FILE."
done

# Esses valores entram em connection strings, URLs amqp:// e no kong.yml:
# aceitamos apenas caracteres que não precisam de escape.
for v in POSTGRES_USER POSTGRES_PASSWORD RABBITMQ_USER RABBITMQ_PASSWORD JWT_SECRET; do
  [[ "${!v}" =~ ^[A-Za-z0-9._~-]+$ ]] \
    || die "$v deve conter só letras, números e . _ ~ - (sugestão: openssl rand -hex 24)."
done

# HS256 exige chave de pelo menos 256 bits (32 bytes).
[ "${#JWT_SECRET}" -ge 32 ] || die "JWT_SECRET precisa ter pelo menos 32 caracteres (sugestão: openssl rand -hex 32)."

# --- valores derivados ----------------------------------------------------------
pg() {
  echo "Host=postgres;Port=5432;Database=$1;Username=${POSTGRES_USER};Password=${POSTGRES_PASSWORD}"
}
RABBITMQ_CONNECTION="amqp://${RABBITMQ_USER}:${RABBITMQ_PASSWORD}@rabbitmq:5672"

kong_yml() {
  sed "s|{{ .jwtSecret }}|${JWT_SECRET}|" k8s/infrastructure/kong/kong.tmpl.yml | tr -d '\r'
}

# --- destinos --------------------------------------------------------------------
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# secret <namespace> <nome-do-secret> <parametro> CHAVE=VALOR ...
secret() {
  local ns="$1" name="$2" param="$3"
  shift 3

  case "$TARGET" in
    print)
      local keys=()
      for kv in "$@"; do keys+=("${kv%%=*}"); done
      printf '%-14s %-34s <- %s/%s\n               chaves: %s\n' \
        "$ns" "$name" "$PARAMETER_PREFIX" "$param" "${keys[*]}"
      ;;

    k8s)
      local args=()
      for kv in "$@"; do args+=("--from-literal=$kv"); done
      kubectl create secret generic "$name" -n "$ns" "${args[@]}" \
        --dry-run=client -o yaml | kubectl apply -f - >/dev/null
      echo "✅ secret $ns/$name ($# chaves)"
      ;;

    aws)
      local json="{" k v
      for kv in "$@"; do
        k="${kv%%=*}"
        v="${kv#*=}"
        json+="\"$(json_escape "$k")\":\"$(json_escape "$v")\","
      done
      json="${json%,}}"

      local version
      version=$(aws ssm put-parameter \
        --region "$AWS_REGION" \
        --name "$PARAMETER_PREFIX/$param" \
        --type SecureString \
        --tier Standard \
        --overwrite \
        --value "$json" \
        --query Version --output text)
      echo "✅ $PARAMETER_PREFIX/$param (versão $version, $# chaves)"
      ;;
  esac
}

# O Kong recebe o kong.yml inteiro: localmente montamos o arquivo aqui; na AWS
# guardamos só a chave e o External Secrets aplica o template.
kong() {
  case "$TARGET" in
    print) secret fcg-platform kong-config kong "JWT_SECRET=" ;;
    k8s)
      kubectl create secret generic kong-config -n fcg-platform \
        --from-literal=kong.yml="$(kong_yml)" \
        --dry-run=client -o yaml | kubectl apply -f - >/dev/null
      echo "✅ secret fcg-platform/kong-config (kong.yml gerado do template)"
      ;;
    aws) secret fcg-platform kong-config kong "JWT_SECRET=$JWT_SECRET" ;;
  esac
}

# Ferramentas necessárias (falha cedo, antes de gravar qualquer coisa).
if [ "$TARGET" = "k8s" ]; then
  command -v kubectl >/dev/null 2>&1 || die "kubectl não encontrado no PATH."
fi
if [ "$TARGET" = "aws" ]; then
  if ! command -v aws >/dev/null 2>&1; then
    # Instalação padrão da AWS CLI v2 no Windows, nem sempre presente no PATH do Git Bash.
    for dir in "/c/Program Files/Amazon/AWSCLIV2" "$HOME/AppData/Local/Programs/Amazon/AWSCLIV2"; do
      [ -x "$dir/aws.exe" ] && PATH="$PATH:$dir" && break
    done
  fi
  command -v aws >/dev/null 2>&1 \
    || die "AWS CLI não encontrada. Instale a AWS CLI v2 (https://aws.amazon.com/cli/) e reabra o terminal."
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) \
    || die "Não foi possível autenticar na AWS. Rode 'aws login' (ou 'aws configure') e tente de novo."
fi

if [ "$TARGET" = "k8s" ]; then
  echo "🔐 Criando Secrets no contexto: $(kubectl config current-context)"
  for ns in fcg-platform observability; do
    kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
  done
elif [ "$TARGET" = "aws" ]; then
  echo "🔐 Publicando parâmetros em $PARAMETER_PREFIX ($AWS_REGION) na conta $ACCOUNT_ID"
fi

# --- definição dos segredos (fonte única para local e AWS) -----------------------
secret fcg-platform postgres-secret postgres \
  "POSTGRES_USER=$POSTGRES_USER" \
  "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"

secret fcg-platform rabbitmq-secret rabbitmq \
  "RABBITMQ_DEFAULT_USER=$RABBITMQ_USER" \
  "RABBITMQ_DEFAULT_PASS=$RABBITMQ_PASSWORD" \
  "RABBITMQ_ERLANG_COOKIE=$RABBITMQ_ERLANG_COOKIE"

secret fcg-platform pgadmin-secret pgadmin \
  "PGADMIN_DEFAULT_EMAIL=$PGADMIN_EMAIL" \
  "PGADMIN_DEFAULT_PASSWORD=$PGADMIN_PASSWORD"

secret fcg-platform fcg-users-api-secret fcg-users-api \
  "ConnectionStrings__Default=$(pg fcgusers-db)" \
  "ConnectionStrings__Rabbitmq=$RABBITMQ_CONNECTION" \
  "JwtSettings__SecurityKey=$JWT_SECRET"

secret fcg-platform fcg-catalog-api-secret fcg-catalog-api \
  "ConnectionStrings__Default=$(pg fcgcatalog-db)" \
  "ConnectionStrings__fcg-catalog-db=$MONGO_CONNECTION" \
  "ConnectionStrings__Rabbitmq=$RABBITMQ_CONNECTION" \
  "JwtSettings__SecurityKey=$JWT_SECRET" \
  "OpenSearch__Url=$OPENSEARCH_URL" \
  "OpenSearch__Username=$OPENSEARCH_USERNAME" \
  "OpenSearch__Password=$OPENSEARCH_PASSWORD"

secret fcg-platform fcg-catalog-worker-secret fcg-catalog-worker \
  "ConnectionStrings__Default=$(pg fcgcatalog-db)" \
  "ConnectionStrings__Rabbitmq=$RABBITMQ_CONNECTION"

secret fcg-platform fcg-payments-api-secret fcg-payments-api \
  "ConnectionStrings__Default=$(pg fcgpayments-db)" \
  "ConnectionStrings__Rabbitmq=$RABBITMQ_CONNECTION" \
  "JwtSettings__SecurityKey=$JWT_SECRET"

secret fcg-platform fcg-payments-worker-secret fcg-payments-worker \
  "ConnectionStrings__Default=$(pg fcgpayments-db)" \
  "ConnectionStrings__Rabbitmq=$RABBITMQ_CONNECTION"

secret fcg-platform fcg-notifications-worker-secret fcg-notifications-worker \
  "ConnectionStrings__Default=$(pg fcgnotifications-db)" \
  "ConnectionStrings__Rabbitmq=$RABBITMQ_CONNECTION"

secret observability kube-prom-grafana grafana \
  "admin-user=$GRAFANA_ADMIN_USER" \
  "admin-password=$GRAFANA_ADMIN_PASSWORD"

kong

echo ""
echo "Concluído."
