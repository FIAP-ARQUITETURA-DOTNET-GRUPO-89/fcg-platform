# 🔐 Kubernetes Secrets

Este documento explica como os Secrets são utilizados na plataforma FCG.

Os Secrets armazenam informações sensíveis utilizadas pelos componentes da aplicação, como credenciais de banco de dados, usuários, senhas e chaves de acesso.

## 📑 Sumário

- [O que é um Secret?](#o-que-é-um-secret)
- [Base64](#base64)
- [Gerando valores Base64](#gerando-valores-base64)
- [Decodificando valores Base64](#decodificando-valores-base64)
- [Boas práticas](#boas-práticas)

# O que é um Secret?

Os Secrets do Kubernetes são utilizados para armazenar informações sensíveis.

Exemplos:

- Usuários
- Senhas
- Tokens
- Chaves de API
- Connection Strings

Na plataforma FCG, os Secrets são utilizados por:

- PostgreSQL
- RabbitMQ
- Microsserviços

# Base64

Os valores armazenados em um Secret devem estar codificados em Base64.

> ⚠️ Base64 **não é criptografia**. É apenas uma codificação.

Exemplo:

```yaml
data:
  POSTGRES_USER: ZmNnX3VzZXI=
  POSTGRES_PASSWORD: Y2hhbmdlbWU=
```

Corresponde a:

```text
POSTGRES_USER=fcg_user
POSTGRES_PASSWORD=changeme
```

# Gerando valores Base64

## Linux / WSL / Git Bash

```bash
echo -n "fcg_user" | base64
```

```bash
echo -n "changeme" | base64
```

## PowerShell

```powershell
[Convert]::ToBase64String(
    [Text.Encoding]::UTF8.GetBytes("fcg_user")
)
```

```powershell
[Convert]::ToBase64String(
    [Text.Encoding]::UTF8.GetBytes("changeme")
)
```

# Decodificando valores Base64

## Linux

```bash
echo "ZmNnX3VzZXI=" | base64 -d
```

## PowerShell

```powershell
[Text.Encoding]::UTF8.GetString(
    [Convert]::FromBase64String("ZmNnX3VzZXI=")
)
```

Resultado:

```text
fcg_user
```

# Boas práticas

- Utilize valores específicos para cada ambiente (Development, Homologação e Produção).
- Utilize Secrets apenas para informações sensíveis.
- Armazene configurações não sensíveis em ConfigMaps.
