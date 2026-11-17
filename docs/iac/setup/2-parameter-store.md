# 🔐 Configuração do AWS Systems Manager Parameter Store

**Projeto:** FIAP FCG  
**Região AWS:** Virgínia do Norte (`us-east-1`)  
**Prefixo dos parâmetros:** `/fcg-platform`  
**Sistema operacional:** Windows  
**Terminais:** PowerShell e Git Bash

Este guia publica as credenciais da plataforma (senhas do PostgreSQL e do RabbitMQ, chave JWT, senhas do pgAdmin e do Grafana) no **AWS Systems Manager Parameter Store**. No cluster EKS, o **External Secrets Operator** lê esses parâmetros e cria os Secrets do Kubernetes usados pelos Deployments. Nenhuma credencial fica nos arquivos do repositório.

```text
.env.aws ──(scripts/secrets.sh aws)──▶ Parameter Store (/fcg-platform/*)
                                              │
                                External Secrets Operator (EKS)
                                              ▼
                       Secrets do Kubernetes ──▶ variáveis de ambiente dos pods
```

## 📋 1. Pré-requisitos

- Ferramentas instaladas e login na AWS feito, conforme [1 - Configuração do ambiente AWS](./1-ambiente-aws.md).
- **Git Bash** (instalado junto com o Git para Windows), usado para executar o script de publicação.
- Repositório `fcg-platform` atualizado.

> **Custo:** parâmetros do tier **Standard** não têm cobrança adicional (até 10.000 parâmetros de até 4 KB por conta e região). O script sempre usa o tier Standard e a chave KMS gerenciada `aws/ssm`.

## 🔎 2. Confirmar a conta e a região

No PowerShell:

```powershell
aws sts get-caller-identity
aws configure get region
```

- O campo `Account` deve ser o ID da conta onde o cluster será criado (no Console AWS, clique no seu nome no canto superior direito para conferir).
- A região deve ser `us-east-1`.

> **Atenção ao Console AWS:** os parâmetros e o cluster ficam em **US East (N. Virginia) `us-east-1`**. Se o seletor de região do console estiver em outra região (por exemplo, São Paulo), os recursos não aparecem.

## 📝 3. Criar o arquivo `.env.aws`

Na raiz do repositório, crie o arquivo a partir do modelo:

```powershell
cd "C:\REPOSITORIO\4. FIAP\fcg-platform"
Copy-Item .env.example .env.aws
```

O `.env.aws` é ignorado pelo Git. **Nunca o adicione ao repositório.**

Gere valores aleatórios no Git Bash e copie cada um para o arquivo:

```bash
openssl rand -hex 24    # para cada senha
openssl rand -hex 32    # para o JWT_SECRET
```

Preencha o `.env.aws`:

| Variável | Descrição | Sugestão |
| -------- | --------- | -------- |
| `POSTGRES_USER` | Usuário do PostgreSQL | `fcg` |
| `POSTGRES_PASSWORD` | Senha do PostgreSQL | `openssl rand -hex 24` |
| `RABBITMQ_USER` | Usuário do RabbitMQ | `fcg` |
| `RABBITMQ_PASSWORD` | Senha do RabbitMQ | `openssl rand -hex 24` |
| `RABBITMQ_ERLANG_COOKIE` | Cookie de cluster do RabbitMQ | `openssl rand -hex 24` |
| `JWT_SECRET` | Chave de assinatura do JWT (Users, Catalog, Payments e Kong) | `openssl rand -hex 32` |
| `PGADMIN_EMAIL` | Login do pgAdmin | `admin@fcg.com` |
| `PGADMIN_PASSWORD` | Senha do pgAdmin | `openssl rand -hex 16` |
| `GRAFANA_ADMIN_USER` | Usuário do Grafana | `admin` |
| `GRAFANA_ADMIN_PASSWORD` | Senha do Grafana | `openssl rand -hex 16` |

Regras:

- Use apenas letras, números e `. _ ~ -` nas senhas do PostgreSQL, do RabbitMQ e no `JWT_SECRET`, pois esses valores entram em connection strings e URLs. O script recusa outros caracteres.
- O `JWT_SECRET` precisa ter **pelo menos 32 caracteres**.
- Guarde uma cópia do `.env.aws` em um gerenciador de senhas.

## 🚀 4. Publicar os parâmetros

Abra o **Git Bash** na raiz do repositório e confira o que será criado (os valores não são exibidos):

```bash
bash scripts/secrets.sh print .env.aws
```

Publique:

```bash
bash scripts/secrets.sh aws
```

Resultado esperado:

```text
🔐 Publicando parâmetros em /fcg-platform (us-east-1) na conta <ID da conta>
✅ /fcg-platform/postgres (versão 1, 2 chaves)
✅ /fcg-platform/rabbitmq (versão 1, 3 chaves)
...
✅ /fcg-platform/kong (versão 1, 1 chaves)

Concluído.
```

Confira na primeira linha se o ID da conta está correto. Executar o script novamente não gera erro: ele grava uma nova versão de cada parâmetro.

## ✅ 5. Validar

No PowerShell:

```powershell
aws ssm describe-parameters --region us-east-1 `
  --parameter-filters "Key=Name,Option=BeginsWith,Values=/fcg-platform/" `
  --query "length(Parameters)"
```

O resultado deve ser `11`.

Pelo Console AWS: **Systems Manager → Parameter Store**, região `us-east-1`. Os parâmetros aparecem com o tipo `SecureString` e o valor oculto.

Para consultar um valor:

```powershell
aws ssm get-parameter --region us-east-1 --name /fcg-platform/kong `
  --with-decryption --query Parameter.Value --output text
```

## 🗺️ 6. Parâmetros criados

| Parâmetro | Secret do Kubernetes | Chaves |
| --------- | -------------------- | ------ |
| `/fcg-platform/postgres` | `postgres-secret` | `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| `/fcg-platform/rabbitmq` | `rabbitmq-secret` | `RABBITMQ_DEFAULT_USER`, `RABBITMQ_DEFAULT_PASS`, `RABBITMQ_ERLANG_COOKIE` |
| `/fcg-platform/pgadmin` | `pgadmin-secret` | `PGADMIN_DEFAULT_EMAIL`, `PGADMIN_DEFAULT_PASSWORD` |
| `/fcg-platform/fcg-users-api` | `fcg-users-api-secret` | `ConnectionStrings__Default`, `ConnectionStrings__Rabbitmq`, `JwtSettings__SecurityKey` |
| `/fcg-platform/fcg-catalog-api` | `fcg-catalog-api-secret` | as 3 acima + `ConnectionStrings__fcg-catalog-db`, `OpenSearch__Url`, `OpenSearch__Username`, `OpenSearch__Password` |
| `/fcg-platform/fcg-catalog-worker` | `fcg-catalog-worker-secret` | `ConnectionStrings__Default`, `ConnectionStrings__Rabbitmq` |
| `/fcg-platform/fcg-payments-api` | `fcg-payments-api-secret` | `ConnectionStrings__Default`, `ConnectionStrings__Rabbitmq`, `JwtSettings__SecurityKey` |
| `/fcg-platform/fcg-payments-worker` | `fcg-payments-worker-secret` | `ConnectionStrings__Default`, `ConnectionStrings__Rabbitmq` |
| `/fcg-platform/fcg-notifications-worker` | `fcg-notifications-worker-secret` | `ConnectionStrings__Default`, `ConnectionStrings__Rabbitmq` |
| `/fcg-platform/grafana` | `kube-prom-grafana` (namespace `observability`) | `admin-user`, `admin-password` |
| `/fcg-platform/kong` | `kong-config` (gera o `kong.yml`) | `JWT_SECRET` |

## 🔄 7. Alterar uma senha

1. Edite o valor no `.env.aws`.
2. Publique novamente no Git Bash: `bash scripts/secrets.sh aws`.
3. Com o cluster no ar, force a sincronização e reinicie os pods:

   ```powershell
   kubectl annotate externalsecret --all -n fcg-platform force-sync="$(Get-Date -UFormat %s)" --overwrite
   kubectl rollout restart deployment -n fcg-platform
   ```

> **Volumes existentes:** o PostgreSQL e o RabbitMQ gravam usuário e senha apenas na primeira inicialização do volume. Para trocar essas senhas em um cluster que já tem dados, é necessário remover os PVCs `postgres-pvc` e `rabbitmq-pvc` (os dados são perdidos).

## 🛠️ 8. Solução de problemas

| Sintoma | Causa provável | Solução |
| ------- | -------------- | ------- |
| `AWS CLI não encontrada` | A AWS CLI não está no `PATH` do Git Bash | Confirme com `aws --version` no PowerShell; se instalada fora de `C:\Program Files\Amazon\AWSCLIV2`, adicione a pasta ao `PATH` |
| `Não foi possível autenticar na AWS` | Sessão expirada ou sem login | `aws login` e `aws sts get-caller-identity` |
| Parâmetros não aparecem no console | Console em outra região ou outra conta | Selecione `us-east-1` e confira o Account ID |
| Nome vira `C:/Program Files/Git/fcg-platform/...` | Conversão de caminhos do Git Bash em comandos `aws` manuais | `export MSYS_NO_PATHCONV=1` antes do comando (o script já faz isso) |
| `ExternalSecret` com `ParameterNotFound` | Parâmetros publicados em outra conta ou região | Refaça os passos 2 e 4 |
| `kong-config` com `SecretSyncedError` | O ConfigMap `kong-config-template` ainda não existe | Normal até o Kong ser implantado (`kubectl apply -k infrastructure/kong/`) |

## 🗑️ 9. Remover os parâmetros

Os parâmetros não geram custo e podem ser mantidos entre um teste e outro. Para removê-los, no Git Bash:

```bash
export MSYS_NO_PATHCONV=1
aws ssm delete-parameters --region us-east-1 --names \
  /fcg-platform/postgres /fcg-platform/rabbitmq /fcg-platform/pgadmin \
  /fcg-platform/fcg-users-api /fcg-platform/fcg-catalog-api /fcg-platform/fcg-catalog-worker \
  /fcg-platform/fcg-payments-api /fcg-platform/fcg-payments-worker \
  /fcg-platform/fcg-notifications-worker /fcg-platform/grafana /fcg-platform/kong
```

## ➡️ 10. Próximo passo

Acesse o [README do Terraform](../terraform/README.md) para criar o cluster EKS. O Terraform também instala o External Secrets Operator e a role IAM que permite ao cluster ler os parâmetros `/fcg-platform/*`.

A conexão do cluster com o Parameter Store é feita no passo **3.0** do guia [1 - Implantação da infraestrutura](../terraform/1-infraestrutura.md).

Visão geral da gestão de segredos (incluindo ambiente local): [Gestão de Segredos](../../secrets.md).
