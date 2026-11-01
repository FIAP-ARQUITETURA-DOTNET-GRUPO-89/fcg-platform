# 🐘 PostgreSQL + pgAdmin no AWS EKS

## 📋 Objetivo

Documentar o procedimento para iniciar o PostgreSQL e o pgAdmin no cluster EKS do projeto FCG, permitindo administrar o banco de dados pelo navegador.

**Configurações do ambiente:**

| Configuração | Valor                   |
| ------------ | ----------------------- |
| Cluster EKS  | `fcg-platform`          |
| Região AWS   | `sa-east-1`             |
| Namespace    | `fcg-platform`          |
| PostgreSQL   | Porta `5432`            |
| pgAdmin      | Porta `80`              |
| Acesso local | `http://localhost:8080` |

Os manifests Kubernetes já estão versionados no repositório.

---

## 1. 🚀 Preparar o acesso ao EKS

Abrir o PowerShell na pasta `k8s`:

```powershell
cd "C:\REPOSITORIO\4. FIAP\fcg-platform\k8s"
```

Verificar a autenticação AWS:

```powershell
aws sts get-caller-identity
```

Atualizar o contexto Kubernetes:

```powershell
aws eks update-kubeconfig `
  --region sa-east-1 `
  --name fcg-platform
```

Verificar a conexão:

```powershell
kubectl get nodes
```

O node deve apresentar status `Ready`.

---

## 2. 🐘 Subir o PostgreSQL

Aplicar os manifests:

```powershell
kubectl apply -f infrastructure/postgres/
```

Aguardar a inicialização:

```powershell
kubectl rollout status deployment/postgres `
  -n fcg-platform `
  --timeout=180s
```

Verificar os recursos:

```powershell
kubectl get pods -n fcg-platform
kubectl get pvc -n fcg-platform
kubectl get svc -n fcg-platform
```

**Resultado esperado:**

- Pod PostgreSQL: `1/1 Running`.
- PVC: `Bound`.
- Service: `postgres`, porta `5432`.

O PVC provisiona o volume persistente utilizado pelo PostgreSQL.

---

## 3. 🖥️ Subir o pgAdmin

Aplicar os manifests:

```powershell
kubectl apply -f infrastructure/pgadmin/
```

Aguardar a inicialização:

```powershell
kubectl rollout status deployment/pgadmin `
  -n fcg-platform `
  --timeout=180s
```

Verificar:

```powershell
kubectl get pods -n fcg-platform
kubectl get svc -n fcg-platform
```

O Pod do pgAdmin deve apresentar `1/1 Running`.

---

## 4. 🌐 Acessar o pgAdmin

Executar o port-forward:

```powershell
kubectl port-forward svc/pgadmin 8080:80 -n fcg-platform
```

Manter o terminal aberto e acessar:

**http://localhost:8080**

Credenciais de acesso configuradas no Secret do pgAdmin:

| Campo  | Valor           |
| ------ | --------------- |
| E-mail | `admin@fcg.com` |
| Senha  | `admin123`      |

---

## 5. 🔗 Conectar ao PostgreSQL

Na interface do pgAdmin:

1. Clicar com o botão direito em **Servers**.
2. Selecionar **Register → Server**.
3. Na aba **General**, informar o nome `FCG PostgreSQL`.
4. Na aba **Connection**, preencher:

| Campo                | Valor                           |
| -------------------- | ------------------------------- |
| Host name/address    | `postgres`                      |
| Port                 | `5432`                          |
| Maintenance database | `postgres`                      |
| Username             | Usuário do Secret do PostgreSQL |
| Password             | Senha do Secret do PostgreSQL   |

Marcar **Save password?** e clicar em **Save**.

**Importante:** utilizar `postgres` como hostname, pois esse é o nome do Service Kubernetes. Como pgAdmin e PostgreSQL estão no mesmo namespace, a comunicação acontece pela rede interna do cluster.

---

## 6. 🔧 Comandos úteis

### Verificar os recursos

```powershell
kubectl get pods -n fcg-platform
kubectl get pvc -n fcg-platform
kubectl get svc -n fcg-platform
```

### Consultar logs do PostgreSQL

```powershell
kubectl logs deployment/postgres -n fcg-platform
```

### Consultar logs do pgAdmin

```powershell
kubectl logs deployment/pgadmin -n fcg-platform
```

### Reiniciar o pgAdmin

```powershell
kubectl rollout restart deployment/pgadmin -n fcg-platform
```

### Desligar o pgAdmin

Quando não estiver utilizando a interface, reduzir as réplicas para zero:

```powershell
kubectl scale deployment pgadmin `
  --replicas=0 `
  -n fcg-platform
```

Para iniciar novamente:

```powershell
kubectl scale deployment pgadmin `
  --replicas=1 `
  -n fcg-platform
```

Aguardar a inicialização antes de acessar novamente.

---

## 7. 💰 Cuidados com custos

- O pgAdmin consome CPU e memória do node enquanto estiver em execução.
- Reduzir as réplicas do pgAdmin para zero libera esses recursos, mas não desliga o node EC2.
- O PostgreSQL utiliza um volume EBS persistente, que pode gerar cobrança enquanto existir.
- O EKS e o node EC2 também podem gerar custos enquanto permanecerem provisionados.
- O acesso pelo `kubectl port-forward` não exige a criação de um Load Balancer.

**Atenção:** desligar o pgAdmin não encerra as cobranças do EKS, EC2 ou volume EBS.

Não exclua o PVC do PostgreSQL sem avaliar a necessidade de preservar os dados.

---

## 8. ✅ Checklist rápido

Para utilizar o ambiente novamente:

- [ ] Autenticar na AWS.
- [ ] Atualizar o kubeconfig.
- [ ] Verificar o node EKS.
- [ ] Subir o PostgreSQL, caso necessário.
- [ ] Subir o pgAdmin, caso esteja desligado.
- [ ] Executar o port-forward.
- [ ] Acessar `http://localhost:8080`.
- [ ] Conectar ao servidor `FCG PostgreSQL`.

**Resultado:** PostgreSQL e pgAdmin disponíveis no cluster EKS, com administração do banco pelo navegador e sem exposição pública do pgAdmin.
