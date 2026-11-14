# 🔎 OpenSearch

Este documento descreve o **OpenSearch** usado como motor de busca avançada do catálogo de jogos da plataforma FCG.

## 📑 Sumário

- [🎯 Objetivo](#-objetivo)
- [🏗️ Arquitetura](#️-arquitetura)
- [⚙️ Configuração](#️-configuração)
- [🚀 Deploy](#-deploy)
- [🔎 Validação](#-validação)
- [☁️ Produção (Amazon OpenSearch Service)](#️-produção-amazon-opensearch-service)
- [🧹 Remoção](#-remoção)

# 🎯 Objetivo

O OpenSearch é um fork open source do Elasticsearch com API compatível. Ele dá ao **FCG Catalog** uma busca **independente do PostgreSQL**, com:

- **Fuzzy Search**: tolera erros de digitação (`zeldda` encontra `Zelda`);
- **Ordenação por relevância** (`_score`, algoritmo BM25);
- análise de texto em português (minúsculas, sem acentos e com stemming leve).

# 🏗️ Arquitetura

```text
POST/PUT/PATCH/DELETE /api/games ──► PostgreSQL (fonte da verdade)
                                 └─► OpenSearch (índice fcg-games)

GET /api/games/search?q=...      ──► OpenSearch (fuzzy + _score)
POST /api/games/search/reindex   ──► recria o índice a partir do PostgreSQL
```

- A indexação acontece na **CatalogAPI**, logo após o `SaveChangesAsync` dos handlers de criação, edição, alteração de preço e inativação.
- Uma falha no OpenSearch **não** derruba o CRUD: o erro é registrado em log e o índice pode ser corrigido pela reindexação.
- Leituras e escritas usam o alias `fcg-games`. A reindexação monta um índice novo (`fcg-games-{timestamp}`) e troca o alias de forma atômica, sem deixar a busca fora do ar.
- Na inicialização, a CatalogAPI reconstrói o índice se ele não existir ou estiver fora de sincronia com o PostgreSQL. Ela tenta novamente até conseguir.
- O health check `opensearch` reporta **Degraded** (e não Unhealthy) quando o motor de busca está fora, para não reiniciar o pod da API. Nessa situação, `/api/games/search` responde **503**.

# ⚙️ Configuração

Os manifests ficam em:

```text
k8s/infrastructure/opensearch/
├── deployment.yaml
└── service.yaml
```

- Imagem `opensearchproject/opensearch:2.19.1`, nó único (`discovery.type=single-node`), heap de 512 MB.
- O plugin de segurança fica desabilitado nesta configuração inicial e o
  Service permanece interno (`ClusterIP`).
- Os dados ficam no PVC `fcg-opensearch-pvc`, provisionado pelo EBS CSI Driver.
  Se o índice precisar ser reconstruído, use `POST /api/games/search/reindex`.

Variáveis lidas pela CatalogAPI:

| Variável | Onde | Exemplo |
|---|---|---|
| `OpenSearch__Url` | Secret | `http://fcg-opensearch:9200` |
| `OpenSearch__Username` | Secret | vazio no local |
| `OpenSearch__Password` | Secret | vazio no local |
| `OpenSearch__IndexName` | ConfigMap | `fcg-games` |
| `OpenSearch__NumberOfReplicas` | ConfigMap | `0` |

# 🚀 Deploy

```bash
kubectl apply -f k8s/infrastructure/opensearch/
kubectl rollout status deployment/fcg-opensearch -n fcg-platform
```

O `scripts/deploy.sh` já inclui esses passos. No EKS, confirme antes que o
addon EBS CSI esteja ativo e que a StorageClass `gp2` exista.

# 🔎 Validação

```bash
kubectl port-forward svc/fcg-opensearch 9200:9200 -n fcg-platform
curl http://localhost:9200/_cluster/health
curl "http://localhost:9200/_cat/aliases/fcg-games?v"
curl "http://localhost:9200/fcg-games/_count"
```

Pela API (token de cliente):

```bash
curl -H "Authorization: Bearer $TOKEN" "http://localhost:8000/api/games/search?q=zeldda"
```

# ☁️ Produção com OpenSearch self-managed no EKS

Na AWS, este manifesto pode ser aplicado como instalação self-managed de nó
único para o ambiente acadêmico. Para produção, habilite o Security plugin,
TLS e autenticação, restrinja o Service com NetworkPolicy e aumente para um
cluster com múltiplos nós e volumes persistentes separados.

# 🧹 Remoção

```bash
kubectl delete -f k8s/infrastructure/opensearch/ --ignore-not-found
```
