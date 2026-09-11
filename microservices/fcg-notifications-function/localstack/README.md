# Rodando a FcgNotifications.Function no LocalStack

**Importante primeiro:** o LocalStack não simula o gatilho automático do Amazon MQ (RabbitMQ) —
esse recurso [não é implementado](https://github.com/localstack/localstack/issues/9645) (só têm
ActiveMQ, não RabbitMQ). Então aqui a gente só consegue: (1) subir a função Lambda de verdade
dentro do LocalStack, e (2) invocá-la manualmente passando o mesmo formato de evento que o
Amazon MQ mandaria. Isso prova que o pacote de deploy e o handler funcionam, mas não testa o
"fila publicou → lambda disparou sozinha" - pra isso só na AWS de verdade (ver `../terraform/`).

## Pré-requisitos

1. Docker Desktop rodando.
2. Conta gratuita no LocalStack (obrigatória desde 2026, mesmo pro tier "Hobby"):
   crie em [app.localstack.cloud](https://app.localstack.cloud), depois pegue seu token em
   **perfil → Auth Tokens**.
3. `pip install awscli-local` (instala o comando `awslocal`, um atalho pro `aws` CLI já
   apontado pro LocalStack).
4. `dotnet tool install -g Amazon.Lambda.Tools` (se ainda não tiver).
5. `dotnet tool install -g dotnet-ef` (se ainda não tiver, pra rodar as migrations).

## 1. Configurar o token e subir LocalStack + Postgres

```powershell
cd localstack
Copy-Item .env.example .env
notepad .env   # cole o LOCALSTACK_AUTH_TOKEN
docker compose up -d
```

Aguarde uns segundos e confirme que subiu:

```powershell
docker compose ps
```

## 2. Aplicar as migrations no Postgres

O Postgres do compose fica exposto em `localhost:5432` pra você rodar isso direto da sua máquina:

```powershell
cd ..\src\FcgNotifications.Infrastructure
dotnet ef database update
cd ..\..\localstack
```

Se der erro de conexão, confirme que o `docker compose ps` mostra o `postgres` como `healthy`/`running`.

## 3. Empacotar a function

```powershell
cd ..\src\FcgNotifications.Function
dotnet lambda package -c Release -o ..\..\localstack\build\function.zip
cd ..\..\localstack
```

## 4. Deploy no LocalStack

```powershell
awslocal lambda create-function `
  --function-name fcg-notifications-function `
  --runtime dotnet10 `
  --zip-file fileb://build/function.zip `
  --handler "FcgNotifications.Function::FcgNotifications.Function.Function::FunctionHandler" `
  --role arn:aws:iam::000000000000:role/lambda-role `
  --timeout 30 `
  --memory-size 512 `
  --environment file://env.json
```

O `env.json` já está configurado com `ConnectionStrings__Default` apontando pro Postgres
usando o nome do serviço (`postgres`) - isso funciona porque a Lambda que o LocalStack sobe
entra na mesma rede Docker (`LAMBDA_DOCKER_NETWORK` no `docker-compose.yml`).

A role `arn:aws:iam::000000000000:role/lambda-role` é fake - o LocalStack não valida IAM de
verdade, só precisa de um ARN com o formato certo.

Espere ficar ativa:

```powershell
awslocal lambda wait function-active-v2 --function-name fcg-notifications-function
```

## 5. Invocar manualmente

```powershell
$env:AWS_CLI_BINARY_FORMAT = "raw-in-base64-out"

awslocal lambda invoke `
  --function-name fcg-notifications-function `
  --payload file://events/user-created-event.json `
  response.json

Get-Content response.json
```

O evento em `events/user-created-event.json` já vem pronto: é um `UserCreatedEvent` (usuário
"Maria Teste") codificado em base64 dentro do formato `RabbitMQEvent` que a Amazon MQ entregaria
de verdade pro handler. Pra testar `PaymentProcessed`, preencha o campo `data` de
`events/payment-processed-event.json` com o base64 do seu `PaymentProcessedEvent` - confira o
enum `PaymentStatus` (em `FgcGames.EventContracts.Enums`, via "Go to Definition" no Visual
Studio) pra saber o valor numérico certo do campo `Status`.

Pra gerar o base64 de um payload novo, no PowerShell:

```powershell
$json = '{"UserId":"...","Name":"...","Email":"..."}'
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
```

## 6. Conferir os logs e o resultado

```powershell
awslocal logs tail /aws/lambda/fcg-notifications-function --since 10m
```

E confira no Postgres (`localhost:5432`, banco `fcgnotifications-db`) se apareceu a linha nova
nas tabelas `Users`/`Notifications`.

## Derrubar tudo

```powershell
docker compose down -v
```
