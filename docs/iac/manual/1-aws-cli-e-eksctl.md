# 1º passo: Instalar as CLIs e autenticar na AWS

## 1. Instalar AWS CLI

A AWS CLI permite interagir com os serviços da AWS pelo terminal.

- **Documentação oficial:** [Instalação da AWS CLI](https://docs.aws.amazon.com/pt_br/cli/latest/userguide/getting-started-install.html)
- **Instalação via PowerShell:** abra o PowerShell e execute:

```powershell
irm https://awscli.amazonaws.com/v2/install.ps1 | iex
```

- **Validar a instalação:**

```powershell
aws --version
```

## 2. Instalar eksctl

O `eksctl` é uma ferramenta de linha de comando utilizada para criar, configurar e excluir clusters Amazon EKS.

- **Documentação oficial:** [Instalação do eksctl](https://docs.aws.amazon.com/pt_br/eks/latest/eksctl/installation.html)
- **Download para Windows (AMD64/x86_64):** [Baixar eksctl](https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_windows_amd64.zip)

### Passo a passo da instalação

1. Baixe o arquivo ZIP da versão **AMD64/x86_64**, compatível com computadores Windows que utilizam processadores Intel ou AMD de 64 bits.
2. Crie a pasta `C:\EKSCTL`.
3. Extraia o conteúdo do arquivo ZIP para essa pasta.

   O executável deverá ficar neste caminho:

   ```text
   C:\EKSCTL\eksctl_Windows_amd64\eksctl.exe
   ```

4. Configure a variável de ambiente `Path` do Windows:
   - Pressione `Win + S` e pesquise por **Editar as variáveis de ambiente do sistema**.
   - Clique em **Variáveis de Ambiente**.
   - Na seção **Variáveis de usuário**, selecione `Path` e clique em **Editar**.
   - Clique em **Novo** e adicione:

     ```text
     C:\EKSCTL\eksctl_Windows_amd64
     ```

   - Confirme as alterações clicando em **OK** em todas as janelas.

5. Feche e abra novamente o PowerShell para atualizar as variáveis de ambiente.

### Validar a instalação

Execute o comando:

```powershell
eksctl version
```

Se aparecer o número da versão, a instalação foi concluída com sucesso.

## 3. Configurar a região padrão

Para o projeto, utilizaremos a região de São Paulo (`sa-east-1`).

```powershell
aws configure set region sa-east-1
```

Para conferir a região configurada:

```powershell
aws configure get region
```

O resultado esperado é:

```text
sa-east-1
```

**Importante:** a região define onde os recursos da AWS serão consultados ou criados por padrão. Ela não altera a região de recursos existentes nem impede que um comando utilize outra região explicitamente.

## 4. Fazer login na AWS

Execute:

```powershell
aws login
```

A AWS CLI iniciará o processo de autenticação pelo navegador.

1. Aguarde a abertura do navegador.
2. Se solicitado, entre na conta AWS desejada.
3. Autorize a solicitação de acesso.
4. Retorne ao PowerShell e aguarde a conclusão do processo.

Se o navegador não abrir automaticamente, siga a URL exibida no terminal. O comando utiliza credenciais temporárias, evitando a necessidade de configurar manualmente chaves de acesso permanentes para esse fluxo.

**Importante:** utilize a identidade IAM apropriada para o projeto, com as permissões mínimas necessárias. Evite usar a conta root nas atividades diárias.

Se houver erro de autenticação ou permissão, verifique a versão da AWS CLI, a identidade utilizada e as permissões necessárias. Para usuários IAM, a política gerenciada `SignInLocalDevelopmentAccess` pode ser necessária.

Documentação oficial: [Login na AWS CLI](https://docs.aws.amazon.com/pt_br/cli/latest/userguide/cli-configure-sign-in.html).

## 5. Validar a autenticação

Depois de concluir o login, execute:

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

Os valores acima são apenas exemplos. Confira se o número da conta e a identidade correspondem à conta AWS utilizada no projeto.

## 6. Confirmar a região antes de criar recursos

Antes de executar comandos de criação, alteração ou exclusão de recursos, confira a conta e a região de destino:

```powershell
aws configure get region
aws sts get-caller-identity
```

Se necessário, configure novamente:

```powershell
aws configure set region sa-east-1
```

## 7. Encerrar a sessão

Quando terminar de trabalhar, você pode encerrar a sessão de autenticação executando:

```powershell
aws logout
```

Esse comando encerra o fluxo de autenticação temporária correspondente. Se necessário, faça login novamente com `aws login`.

## 8. Cuidados de segurança e custos

- Nunca compartilhe senhas, tokens ou credenciais AWS.
- Não armazene credenciais em arquivos do repositório Git.
- Utilize uma identidade com permissões limitadas ao necessário.
- Antes de criar recursos, confira as permissões, a região e os custos estimados.
- Ao finalizar os estudos, exclua os recursos que não serão mais utilizados e confira se não restaram recursos cobrados.

**Próximo passo:** com as CLIs instaladas e o acesso validado, prossiga para [criação do cluster EKS](./2-cluster-eks.md).
