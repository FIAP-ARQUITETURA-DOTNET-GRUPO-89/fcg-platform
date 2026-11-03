# 🖥️ 5º passo: Configuração do pgAdmin no Amazon EKS

**Projeto:** FIAP FCG  
**Cluster:** `fcg-platform`  
**Região AWS:** Virgínia do Norte (`us-east-1`)  
**Namespace Kubernetes:** `fcg-platform`  
**PostgreSQL:** Service `postgres`, porta `5432`  
**pgAdmin:** Service `pgadmin`, porta `80`  
**Acesso local:** `http://localhost:8080`

## 1. Pré-requisitos

Antes de começar, confirme que:

- [ ] O AWS CLI está instalado e autenticado.
- [ ] O `kubectl` está instalado.
- [ ] O cluster EKS está ativo e os nós estão `Ready`.
- [ ] O PostgreSQL já foi implantado e está funcionando no namespace `fcg-platform`.

No PowerShell, acesse a pasta dos manifests:

```powershell
cd "C:\REPOSITORIO\4. FIAP\fcg-platform\k8s"
```

### 1.1. Validar o acesso ao cluster

```powershell
aws sts get-caller-identity

aws eks update-kubeconfig `
  --region us-east-1 `
  --name fcg-platform

kubectl config current-context
kubectl get nodes
```

Confira se o PostgreSQL está disponível:

```powershell
kubectl get pods -n fcg-platform
kubectl get svc postgres -n fcg-platform
```

O Pod do PostgreSQL deve estar `1/1 Running` e o Service `postgres` disponível na porta `5432`.

## 2. Implantar o pgAdmin

Os manifests do pgAdmin estão organizados em:

```text
k8s/
└── infrastructure/
    └── pgadmin/
        ├── deployment.yaml
        ├── secret.yaml
        └── service.yaml
```

Aplique os manifests:

```powershell
kubectl apply -f infrastructure/pgadmin/
```

Aguarde a inicialização:

```powershell
kubectl rollout status deployment/pgadmin `
  -n fcg-platform `
  --timeout=180s
```

Confira os recursos:

```powershell
kubectl get pods -n fcg-platform
kubectl get svc pgadmin -n fcg-platform
```

O Pod do pgAdmin deve apresentar status `1/1 Running`.

## 3. Acessar a interface web

Execute o port-forward:

```powershell
kubectl port-forward svc/pgadmin 8080:80 -n fcg-platform
```

Mantenha o terminal aberto e acesse pelo navegador:

**http://localhost:8080**

Utilize as credenciais configuradas no Secret do pgAdmin:

| Campo | Valor |
| | --------- |
| E-mail | `admin@fcg.com` |
| Senha | Valor configurado no Secret |

Não publique senhas reais no repositório Git.

## 4. Conectar ao PostgreSQL

Na interface do pgAdmin:

1. Clique com o botão direito em **Servers**.
2. Selecione **Register → Server**.
3. Na aba **General**, informe o nome `FCG PostgreSQL`.
4. Na aba **Connection**, preencha:

| Campo                | Valor                                       |
| -------------------- | ------------------------------------------- |
| Host name/address    | `postgres`                                  |
| Port                 | `5432`                                      |
| Maintenance database | `postgres`                                  |
| Username             | Usuário configurado no Secret do PostgreSQL |
| Password             | Senha configurada no Secret do PostgreSQL   |

Marque **Save password?** e clique em **Save**.

**Importante:** utilize `postgres` como hostname porque esse é o nome do Service Kubernetes. Como os dois recursos estão no mesmo namespace, o pgAdmin consegue acessar o PostgreSQL pela rede interna do cluster, sem exposição pública do banco.

### ➡️ Próximo passo

Com o PostgreSQL e o pgAdmin disponíveis, prossiga para [6. Implantação do RabbitMQ](./6-rabbit.md).
