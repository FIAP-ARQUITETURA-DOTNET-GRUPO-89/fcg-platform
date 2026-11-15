# 🔐 Gestão de Segredos

Nenhuma senha, connection string ou chave JWT fica versionada no repositório.
Todas as credenciais nascem de **um arquivo `.env` fora do Git** e são injetadas
em tempo de execução:

| Ambiente | Origem das credenciais | Como chegam aos containers |
|---|---|---|
| Docker Compose | `.env` | Interpolação `${VAR}` do Compose |
| Kubernetes local (Docker Desktop) | `.env` | `scripts/secrets.sh k8s` cria os Secrets |
| AWS (EKS) | AWS Systems Manager **Parameter Store** (`SecureString`) | **External Secrets Operator** cria os Secrets |

Os Deployments não mudam entre os ambientes: todos leem os mesmos Secrets
(`envFrom.secretRef`), com os mesmos nomes e as mesmas chaves.

## 📑 Sumário

- [Arquivo .env](#-arquivo-env)
- [Docker Compose](#-docker-compose)
- [Kubernetes local](#️-kubernetes-local)
- [AWS: Parameter Store + External Secrets](#️-aws-parameter-store--external-secrets)
- [Mapa de Secrets e parâmetros](#️-mapa-de-secrets-e-parâmetros)
- [Verificação](#-verificação)

# 📄 Arquivo .env

Na raiz do repositório:

```bash
cp .env.example .env        # ambiente local
cp .env.example .env.aws    # AWS (valores fortes e diferentes do local)
```

Gere valores aleatórios (Git Bash):

```bash
openssl rand -hex 24   # senhas
openssl rand -hex 32   # JWT_SECRET (mínimo 32 caracteres)
```

Regras:

- `.env` e `.env.aws` são ignorados pelo Git. Versione apenas o `.env.example`.
- Use só letras, números e `. _ ~ -` em senhas de banco, RabbitMQ e JWT: os valores entram em connection strings e URLs.
- A **mesma** `JWT_SECRET` é usada por Users, Catalog, Payments e Kong (todos validam o mesmo token).

# 🐳 Docker Compose

```bash
docker compose up -d
```

O Compose lê o `.env` automaticamente. Se alguma variável obrigatória faltar,
ele para com a mensagem `defina <VAR> no .env`.

O Kong gera o `kong.yml` na subida do container a partir de
`docker/infrastructure/kong/kong.tmpl.yml`, preenchendo a chave JWT.

> **Volumes antigos:** o PostgreSQL e o RabbitMQ só gravam usuário e senha na
> primeira inicialização do volume. Ao trocar as credenciais, recrie os volumes
> com `docker compose down -v`.

# ☸️ Kubernetes local

O `scripts/deploy.sh` já executa este passo. Para criar ou atualizar os Secrets
manualmente:

```bash
bash scripts/secrets.sh print   # mostra o que será criado (sem valores)
bash scripts/secrets.sh k8s     # cria/atualiza os Secrets no contexto atual do kubectl
```

O `deploy.sh` ignora qualquer `secret*.yaml` nas pastas dos microsserviços, então
os Secrets criados pelo script nunca são sobrescritos.

# ☁️ AWS: Parameter Store + External Secrets

O Terraform (`iac/terraform/aws/external-secrets.tf`) cria:

- a role IAM `fcg-platform-external-secrets-role` (IRSA), com leitura **apenas** de `/fcg-platform/*` no Parameter Store e `kms:Decrypt` via SSM;
- o External Secrets Operator (Helm) no namespace `external-secrets`, usando essa role.

Os **valores** não passam pelo Terraform (não ficam no `tfstate`). Eles são
publicados pelo script (passo a passo completo em
[Configuração do Parameter Store](iac/setup/2-parameter-store.md)):

```bash
aws sts get-caller-identity          # confira a conta
bash scripts/secrets.sh aws          # lê .env.aws e grava /fcg-platform/* (SecureString)
```

Depois, conecte o cluster ao Parameter Store:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/aws/cluster-secret-store.yaml
kubectl apply -f k8s/aws/external-secrets.yaml
# após criar o namespace observability:
kubectl apply -f k8s/aws/external-secrets-observability.yaml
```

Para trocar uma senha: edite o `.env.aws`, rode `bash scripts/secrets.sh aws` de
novo (gera uma nova versão do parâmetro) e reinicie o Deployment
(`kubectl rollout restart deployment/<nome> -n fcg-platform`). O External Secrets
sincroniza os Secrets a cada 1 hora; para forçar na hora:

```bash
kubectl annotate externalsecret --all -n fcg-platform force-sync=$(date +%s) --overwrite
```

# 🗺️ Mapa de Secrets e parâmetros

| Secret (namespace) | Parâmetro | Chaves |
|---|---|---|
| `postgres-secret` (fcg-platform) | `/fcg-platform/postgres` | `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| `rabbitmq-secret` (fcg-platform) | `/fcg-platform/rabbitmq` | `RABBITMQ_DEFAULT_USER`, `RABBITMQ_DEFAULT_PASS`, `RABBITMQ_ERLANG_COOKIE` |
| `pgadmin-secret` (fcg-platform) | `/fcg-platform/pgadmin` | `PGADMIN_DEFAULT_EMAIL`, `PGADMIN_DEFAULT_PASSWORD` |
| `fcg-users-api-secret` (fcg-platform) | `/fcg-platform/fcg-users-api` | `ConnectionStrings__Default`, `ConnectionStrings__Rabbitmq`, `JwtSettings__SecurityKey` |
| `fcg-catalog-api-secret` (fcg-platform) | `/fcg-platform/fcg-catalog-api` | as 3 acima + `ConnectionStrings__fcg-catalog-db`, `OpenSearch__Url`, `OpenSearch__Username`, `OpenSearch__Password` |
| `fcg-catalog-worker-secret` (fcg-platform) | `/fcg-platform/fcg-catalog-worker` | `ConnectionStrings__Default`, `ConnectionStrings__Rabbitmq` |
| `fcg-payments-api-secret` (fcg-platform) | `/fcg-platform/fcg-payments-api` | `ConnectionStrings__Default`, `ConnectionStrings__Rabbitmq`, `JwtSettings__SecurityKey` |
| `fcg-payments-worker-secret` (fcg-platform) | `/fcg-platform/fcg-payments-worker` | `ConnectionStrings__Default`, `ConnectionStrings__Rabbitmq` |
| `fcg-notifications-worker-secret` (fcg-platform) | `/fcg-platform/fcg-notifications-worker` | `ConnectionStrings__Default`, `ConnectionStrings__Rabbitmq` |
| `kube-prom-grafana` (observability) | `/fcg-platform/grafana` | `admin-user`, `admin-password` |
| `kong-config` (fcg-platform) | `/fcg-platform/kong` | `kong.yml` gerado do template com `JWT_SECRET` |

# ✅ Verificação

Nenhuma credencial versionada (deve voltar vazio):

```bash
git grep -n -I -E "fcg123|Secret_Key_2026|Password=[^$<{;\" ]+|amqps?://[^:\"$ ]+:[^@\"$<{ ]+@" -- ':!*Testing.json'
git ls-files | grep -iE "(^|/)secret[^/]*\.ya?ml$|(^|/)\.env$|tfstate|tfvars$"
```

No EKS:

```bash
kubectl get clustersecretstore                     # READY = True
kubectl get externalsecrets -A                     # STATUS = SecretSynced
kubectl get secret fcg-users-api-secret -n fcg-platform \
  -o jsonpath='{.metadata.ownerReferences[0].kind}' # ExternalSecret
```
