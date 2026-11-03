# 🚀 1º passo: Instalar as CLIs e autenticar na AWS

Neste passo, vamos instalar as ferramentas necessárias para interagir com a AWS e preparar o ambiente para trabalhar com o Amazon EKS.

## 1. AWS CLI

A AWS CLI permite gerenciar os serviços da AWS diretamente pelo terminal.

- 📚 **Documentação:** [Instalação da AWS CLI](https://docs.aws.amazon.com/pt_br/cli/latest/userguide/getting-started-install.html)
- 💻 **Instalação via PowerShell:**

```powershell
irm https://awscli.amazonaws.com/v2/install.ps1 | iex
```

**Validar a instalação:**

```powershell
aws --version
```

## 2. eksctl

O `eksctl` é uma ferramenta de linha de comando para criar, configurar e excluir clusters Amazon EKS.

- 📚 **Documentação:** [Instalação do eksctl](https://docs.aws.amazon.com/pt_br/eks/latest/eksctl/installation.html)
- 📥 **Download para Windows (AMD64/x86_64):** [Baixar eksctl](https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_windows_amd64.zip)

### Instalação no Windows

1. Baixe o arquivo ZIP da versão **AMD64/x86_64**, compatível com processadores Intel e AMD de 64 bits.
2. Crie a pasta `C:\EKSCTL`.
3. Extraia o conteúdo do ZIP para essa pasta.

O executável deverá ficar em:

```text
C:\EKSCTL\eksctl_Windows_amd64\eksctl.exe
```

4. Configure a variável de ambiente `Path`:
   - Pressione `Win + S` e pesquise por **Editar as variáveis de ambiente do sistema**.
   - Clique em **Variáveis de Ambiente**.
   - Em **Variáveis de usuário**, selecione `Path` e clique em **Editar**.
   - Clique em **Novo** e adicione:

```text
C:\EKSCTL\eksctl_Windows_amd64
```

5. Confirme as alterações e reabra o PowerShell.

**Validar a instalação:**

```powershell
eksctl version
```

Se o número da versão for exibido, a instalação foi concluída.

## 3. 🌎 Configurar a região padrão

Para o projeto, utilizaremos **US East (N. Virginia) — `us-east-1`**.

Configure a região:

```powershell
aws configure set region us-east-1
```

Confira a configuração:

```powershell
aws configure get region
```

Resultado esperado:

```text
us-east-1
```

⚠️ **Importante:** a região define onde os recursos serão consultados ou criados por padrão. Ela não altera a região dos recursos existentes nem impede que um comando utilize outra região explicitamente.

## 4. 🔐 Fazer login na AWS

Execute:

```powershell
aws login
```

A AWS CLI iniciará a autenticação pelo navegador.

1. Aguarde a abertura do navegador.
2. Se solicitado, entre na conta AWS desejada.
3. Autorize a solicitação de acesso.
4. Retorne ao PowerShell e aguarde a conclusão.

📚 [Documentação: Login na AWS CLI](https://docs.aws.amazon.com/pt_br/cli/latest/userguide/cli-configure-sign-in.html)

## 5. ✅ Validar a autenticação

Após o login, execute:

```powershell
aws sts get-caller-identity
```

O comando deverá retornar informações semelhantes a estas:

```json
{
  "UserId": "EXEMPLO",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/fcg-developer"
}
```

Os valores são apenas exemplos. Confira se o número da conta e a identidade correspondem à conta AWS utilizada no projeto.

## 6. 🔎 Confirmar conta e região antes de criar recursos

Antes de executar comandos de criação, alteração ou exclusão, confira:

```powershell
aws configure get region
aws sts get-caller-identity
```

Se necessário, configure novamente:

```powershell
aws configure set region us-east-1
```

## 7. 🚪 Encerrar a sessão

Ao finalizar os estudos, você pode encerrar a sessão de autenticação temporária:

```powershell
aws logout
```

Para trabalhar novamente, basta realizar um novo login:

```powershell
aws login
```

## 8. 🛡️ Cuidados de segurança e custos

- 🔒 Nunca compartilhe senhas, tokens ou credenciais AWS.
- 📁 Não armazene credenciais em arquivos do repositório Git.
- 👤 Utilize identidades com permissões limitadas ao necessário.
- 🌎 Confira a conta e a região antes de executar comandos.
- 💰 Avalie os custos antes de criar recursos.
- 🧹 Ao finalizar os estudos, exclua os recursos que não serão mais utilizados e verifique se não restaram recursos gerando cobranças.

### ➡️ Próximo passo

Com as CLIs instaladas e o acesso validado, prossiga para [2. Criação do cluster EKS](./2-cluster-eks.md).
