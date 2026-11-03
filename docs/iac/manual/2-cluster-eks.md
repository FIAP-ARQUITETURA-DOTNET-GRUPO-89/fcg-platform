# ☁️ 2º passo: Criação do Cluster Amazon EKS

## 🎯 Objetivo

Documentar a criação do cluster Kubernetes do projeto **FIAP Cloud Games (FCG)** na AWS, priorizando baixo custo, simplicidade e controle dos recursos provisionados.

## 📋 Informações gerais

| Configuração         | Valor                           |
| -------------------- | ------------------------------- |
| Provedor             | AWS                             |
| Serviço              | Amazon EKS                      |
| Região               | `us-east-1` — Virgínia do Norte |
| Nome do cluster      | `fcg-platform`                  |
| Versão do Kubernetes | `1.37`                          |
| Modo de criação      | Personalizado                   |
| EKS Auto Mode        | Desabilitado                    |

## 1. ⚙️ Configurar o cluster

Definição das configurações básicas, versão do Kubernetes e perfil IAM utilizado pelo EKS.

| Configuração                        | Valor definido           | Justificativa                                                                                     |
| ----------------------------------- | ------------------------ | ------------------------------------------------------------------------------------------------- |
| Nome                                | `fcg-platform`           | Identifica o cluster principal da plataforma.                                                     |
| Kubernetes                          | `1.37`                   | Versão selecionada durante a criação.                                                             |
| Modo de configuração                | Personalizado            | Permite escolher manualmente a infraestrutura.                                                    |
| EKS Auto Mode                       | Desabilitado             | Evita habilitar gerenciamento automático sem necessidade.                                         |
| Role IAM                            | `AmazonEKSClusterPolicy` | Permite ao EKS gerenciar recursos do plano de controle.                                           |
| Acesso administrativo               | Habilitado               | Concede acesso administrativo inicial à identidade responsável pela criação.                      |
| Autenticação                        | EKS API e ConfigMap      | Permite gerenciar o acesso por esses mecanismos.                                                  |
| Escalabilidade do plano de controle | Padrão                   | Mantém a configuração padrão do serviço.                                                          |
| ARC Zonal Shift                     | Desabilitado             | Não habilita esse recurso adicional de resiliência zonal.                                         |
| Proteção contra exclusão            | Desabilitada             | Facilita a exclusão do cluster ao finalizar os testes.                                            |
| Tag                                 | `Project=Project`        | Identificação informada durante a criação. Recomenda-se corrigir para `Project=FCG`, se possível. |

**⚠️ Observações importantes:**

- A role IAM do cluster é diferente da identidade IAM utilizada por quem cria o cluster.
- A permissão `iam:PassRole` permite passar a role ao EKS, mas não substitui as permissões necessárias para criar o cluster.
- Confira a disponibilidade da versão do Kubernetes caso precise recriar o cluster futuramente.
- A proteção contra exclusão desabilitada facilita a limpeza da infraestrutura ao finalizar os testes.

## 2. 🌐 Especificar as redes

Definição da VPC, sub-redes e formas de acesso ao endpoint Kubernetes.

| Configuração        | Valor definido                            | Justificativa                                                                  |
| ------------------- | ----------------------------------------- | ------------------------------------------------------------------------------ |
| VPC                 | VPC padrão da conta                       | Reutiliza a rede existente, evitando criar outra VPC.                          |
| Sub-redes           | `us-east-1a`, `us-east-1b` e `us-east-1c` | Distribui os recursos entre zonas de disponibilidade.                          |
| Endereçamento       | IPv4                                      | Utiliza o padrão definido para o projeto.                                      |
| Endpoint Kubernetes | Público e privado                         | Permite acesso pelas redes pública e privada, conforme as regras configuradas. |
| IPs autorizados     | `0.0.0.0/0`                               | Permite acesso ao endpoint público a partir de qualquer origem IPv4.           |
| Saída de rede       | Gerenciada pela AWS                       | Mantém a opção padrão do assistente.                                           |

**🔒 Atenção à segurança**

A configuração `0.0.0.0/0` permite que o endpoint público seja acessado de qualquer endereço IPv4.

Isso **não elimina a necessidade de autenticação**, mas amplia a superfície de exposição.

Recomenda-se restringir o acesso ao IP público confiável de quem administra o cluster, sempre que possível.

O acesso privado continua dependendo da conectividade com a VPC.

💡 A reutilização da VPC padrão simplifica a configuração inicial, mas não significa que todos os recursos associados sejam gratuitos.

## 3. 📊 Configurar a observabilidade

Definição das informações do plano de controle enviadas aos serviços de monitoramento e logs da AWS.

| Configuração                          | Valor definido      | Justificativa                                                                    |
| ------------------------------------- | ------------------- | -------------------------------------------------------------------------------- |
| Monitoramento de rede dos contêineres | Desabilitado        | Evita habilitar monitoramento adicional sem necessidade inicial.                 |
| Logs do plano de controle             | Todos desabilitados | Reduz a geração e o armazenamento de logs potencialmente cobrados no CloudWatch. |

**💡 Observações:**

- Os logs podem ser habilitados posteriormente para diagnóstico e monitoramento.
- Desabilitar os logs do plano de controle não substitui a observabilidade das aplicações.
- Para a entrega acadêmica, podemos utilizar Prometheus e Grafana ou outros componentes compatíveis com o orçamento.

## 4. 🧩 Selecionar complementos (Add-ons)

Foram selecionados os componentes necessários para o funcionamento básico do cluster.

### Complementos padrão da AWS

| Complemento    | Seleção     | Finalidade                                                 |
| -------------- | ----------- | ---------------------------------------------------------- |
| CoreDNS        | Selecionado | Resolução DNS dos serviços e Pods do Kubernetes.           |
| kube-proxy     | Selecionado | Implementa regras de rede para comunicação entre serviços. |
| Amazon VPC CNI | Selecionado | Integra a rede dos Pods à VPC da AWS.                      |

### Complementos adicionais

Nenhum complemento adicional da comunidade foi selecionado.

**Justificativa:** manter apenas os componentes necessários reduz a complexidade inicial e evita habilitar serviços sem necessidade definida.

### Versões observadas durante a criação

| Complemento    | Versão                |
| -------------- | --------------------- |
| CoreDNS        | `v1.14.7-eksbuild.19` |
| kube-proxy     | `v1.37.0-eksbuild.29` |
| Amazon VPC CNI | `v1.22.4-eksbuild.8`  |

Essas versões representam o estado observado durante a criação e podem mudar em futuras atualizações.

## 5. 🔧 Configurar os complementos selecionados

Revisão das configurações específicas dos complementos.

| Configuração                     | Valor definido        |
| -------------------------------- | --------------------- |
| EKS Pod Identity para `aws-node` | Não configurado       |
| Configuração dos complementos    | Padrões do assistente |

**💡 Observações:**

- O Amazon VPC CNI é necessário para a configuração de rede dos Pods.
- Não configurar Pod Identity nessa etapa não significa que workloads futuros dispensarão permissões IAM.
- Componentes que precisarem acessar serviços AWS devem receber permissões seguindo o princípio do menor privilégio.

## 6. 🔍 Revisar e criar o cluster

Antes de confirmar a criação, revise as configurações:

### Checklist de validação

- [ ] Nome do cluster: `fcg-platform`.
- [ ] Região: `us-east-1`.
- [ ] Versão do Kubernetes conferida.
- [ ] EKS Auto Mode desabilitado.
- [ ] Role IAM selecionada corretamente.
- [ ] Acesso administrativo inicial configurado.
- [ ] VPC e sub-redes revisadas.
- [ ] Acesso público ao endpoint revisado.
- [ ] Logs do plano de controle desabilitados.
- [ ] Apenas os complementos necessários selecionados.
- [ ] Nenhum complemento adicional sem necessidade.
- [ ] Tags revisadas.
- [ ] Estimativa de custos avaliada.

Após confirmar, o EKS inicia o provisionamento do plano de controle.

<badge color="success">Status esperado: Active</badge>

⏳ A criação pode levar vários minutos. Não é necessário criar os nós de trabalho imediatamente após o cluster ficar ativo.

## 7. 💰 Controle de custos

A criação do EKS gera cobranças pelo plano de controle enquanto o cluster existir. Outros recursos também podem gerar custos adicionais.

### Recursos que devem ser monitorados

- Cluster EKS.
- Instâncias EC2 dos nós de trabalho.
- Volumes EBS.
- Load Balancers.
- Endereços IPv4 públicos.
- NAT Gateways, caso sejam criados.
- Logs armazenados no CloudWatch.

### 🧹 Procedimento de encerramento

Ao finalizar os testes:

1. Excluir os workloads e serviços que não serão mais utilizados.
2. Remover recursos de exposição externa, como Load Balancers.
3. Excluir os nós de trabalho ou seus grupos, caso existam.
4. Excluir o cluster EKS.
5. Verificar volumes EBS, endereços IP, NAT Gateways e outros recursos remanescentes.
6. Consultar o AWS Billing para acompanhar os custos registrados.

**⚠️ Atenção:** excluir o cluster não garante que todos os recursos criados separadamente sejam removidos automaticamente.

## 📚 Referências oficiais

- [Amazon EKS — Documentação](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [Amazon EKS — Criação de clusters](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)
- [Amazon EKS — Complementos](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)
- [AWS Billing — Gerenciamento de custos](https://docs.aws.amazon.com/cost-management/latest/userguide/what-is-costmanagement.html)

### ➡️ Próximo passo

Com o cluster EKS criado e ativo, prossiga para [3. Criação dos nós de trabalho (EC2)](./3-nos-ec2.md).
