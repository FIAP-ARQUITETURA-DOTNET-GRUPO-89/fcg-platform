# ☁️ Criação do Cluster Amazon EKS

## Objetivo

Documentar as configurações utilizadas na criação do cluster Kubernetes do projeto **FIAP Cloud Games (FCG)** na AWS, priorizando baixo custo, simplicidade e controle dos recursos provisionados.

## Informações gerais

| Configuração         | Valor                                    |
| -------------------- | ---------------------------------------- |
| Provedor             | AWS                                      |
| Serviço              | Amazon EKS                               |
| Região               | `sa-east-1` — América do Sul (São Paulo) |
| Nome do cluster      | `fcg-platform`                           |
| Versão do Kubernetes | `1.37`                                   |
| Modo de criação      | Configuração personalizada               |
| EKS Auto Mode        | Desabilitado                             |

---

## Etapa 1 — Configurar cluster

Nesta etapa, definimos as configurações básicas do cluster, a versão do Kubernetes e o perfil IAM utilizado pelo EKS.

| Campo                               | Valor definido           | Justificativa                                                                                                                                    |
| ----------------------------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Nome do cluster                     | `fcg-platform`           | Identifica o cluster principal da plataforma FCG.                                                                                                |
| Versão do Kubernetes                | `1.37`                   | Versão selecionada durante a criação.                                                                                                            |
| Modo de configuração                | Personalizada            | Permite escolher manualmente as opções de infraestrutura.                                                                                        |
| EKS Auto Mode                       | Desabilitado             | Evita habilitar recursos de gerenciamento automático sem necessidade.                                                                            |
| Perfil IAM do cluster               | `AmazonEKSClusterPolicy` | Role criada para permitir que o serviço EKS gerencie os recursos necessários ao plano de controle.                                               |
| Acesso de administrador do cluster  | Habilitado               | Permite que a identidade responsável pela criação tenha acesso administrativo inicial ao Kubernetes.                                             |
| Modo de autenticação                | EKS API e ConfigMap      | Permite gerenciar o acesso ao cluster por esses mecanismos.                                                                                      |
| Escalabilidade do plano de controle | Padrão                   | Mantém a configuração padrão do serviço.                                                                                                         |
| ARC Zonal Shift                     | Desabilitado             | Não habilita esse recurso adicional de resiliência zonal.                                                                                        |
| Proteção contra exclusão            | Desabilitada             | Permite excluir o cluster ao terminar os testes, sem precisar alterar essa configuração antes.                                                   |
| Tags                                | `Project=Project`        | Tag informada durante a criação. Recomenda-se corrigir para `Project=FCG` se ainda for possível, para identificar melhor os recursos do projeto. |

**Observações importantes:**

- A role IAM do cluster é diferente da identidade IAM utilizada pela pessoa que cria o cluster.
- A permissão `iam:PassRole` permite passar a role selecionada ao serviço EKS, mas não substitui as permissões necessárias para criar o cluster.
- A versão do Kubernetes deve ser conferida novamente caso o cluster precise ser recriado futuramente, pois as versões disponíveis mudam.
- Desabilitar a proteção contra exclusão facilita a limpeza dos recursos ao final dos testes.

---

## Etapa 2 — Especificar redes

Nesta etapa, definimos a VPC, as sub-redes e as formas de acesso ao endpoint do Kubernetes.

| Campo                                        | Valor definido                                                       | Justificativa                                                                                   |
| -------------------------------------------- | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| VPC                                          | VPC padrão da conta                                                  | Reutiliza a rede existente, evitando criar uma VPC adicional neste primeiro momento.            |
| Sub-redes                                    | Sub-redes padrão nas zonas `sa-east-1a`, `sa-east-1b` e `sa-east-1c` | Distribui os recursos de rede entre zonas de disponibilidade.                                   |
| Família de endereços IP                      | IPv4                                                                 | Utiliza o padrão de endereçamento definido para o projeto.                                      |
| Acesso ao endpoint                           | Público e privado                                                    | Permite acesso ao endpoint pela rede pública e pela rede privada, conforme as regras de acesso. |
| Lista de IPs autorizados no endpoint público | `0.0.0.0/0`                                                          | Configuração utilizada durante a criação para permitir acesso de qualquer origem IPv4.          |
| Gerenciamento de saída de rede               | Gerenciado pela AWS                                                  | Mantém a opção padrão selecionada no assistente.                                                |

**Atenção à segurança:**

A configuração `0.0.0.0/0` permite que o endpoint público seja acessado a partir de qualquer endereço IPv4. Isso **não elimina a necessidade de autenticação**, mas amplia a superfície de exposição.

Recomenda-se substituir esse valor pelo IP público confiável de quem administra o cluster, quando possível. O acesso privado continua dependendo da conectividade com a VPC.

A utilização da VPC padrão simplifica a configuração inicial, mas não significa que todos os recursos associados serão gratuitos.

---

## Etapa 3 — Configurar a observabilidade

Nesta etapa, escolhemos quais informações do plano de controle serão enviadas para os serviços de monitoramento e logs da AWS.

| Campo                                 | Valor definido      | Justificativa                                                                    |
| ------------------------------------- | ------------------- | -------------------------------------------------------------------------------- |
| Monitoramento de rede dos contêineres | Desabilitado        | Evita habilitar monitoramento adicional sem necessidade inicial.                 |
| Logs do plano de controle             | Todos desabilitados | Reduz a geração e a retenção de logs potencialmente cobrados no CloudWatch Logs. |

**Observações:**

- Os logs do plano de controle podem ser habilitados posteriormente, conforme a necessidade de diagnóstico e os requisitos do projeto.
- Desabilitar esses logs não substitui a implementação de observabilidade da aplicação.
- Para a entrega acadêmica, podemos avaliar posteriormente o uso de Prometheus e Grafana ou outros componentes compatíveis com o orçamento.

---

## Etapa 4 — Selecionar complementos

Nesta etapa, selecionamos os componentes necessários para o funcionamento básico do cluster.

### Complementos padrão da AWS

| Complemento    | Seleção     | Finalidade                                                               |
| -------------- | ----------- | ------------------------------------------------------------------------ |
| CoreDNS        | Selecionado | Fornece resolução de nomes DNS para os serviços e pods do Kubernetes.    |
| kube-proxy     | Selecionado | Implementa regras de rede necessárias para a comunicação entre serviços. |
| Amazon VPC CNI | Selecionado | Integra a rede dos pods à rede da VPC da AWS.                            |

### Complementos adicionais

Nenhum complemento adicional da comunidade foi selecionado durante a criação inicial.

**Justificativa:** manter apenas os componentes necessários reduz a complexidade inicial e evita habilitar serviços sem uma necessidade definida.

As versões exibidas no assistente durante a configuração foram:

- CoreDNS: `v1.14.7-eksbuild.19`
- kube-proxy: `v1.37.0-eksbuild.29`
- Amazon VPC CNI: `v1.22.4-eksbuild.8`

Essas versões registram o estado observado durante a criação e podem mudar com futuras atualizações.

---

## Etapa 5 — Definir configurações de complementos selecionados

Nesta etapa, revisamos as configurações específicas dos complementos selecionados.

| Configuração                                          | Valor definido                           | Justificativa                                   |
| ----------------------------------------------------- | ---------------------------------------- | ----------------------------------------------- |
| Perfil de identidade EKS Pod Identity para `aws-node` | Não configurado                          | Não foi criado um perfil adicional nessa etapa. |
| Configuração dos complementos                         | Padrões disponibilizados pelo assistente | Mantém a configuração inicial simples.          |

**Observações:**

- O Amazon VPC CNI é necessário para a configuração de rede dos pods.
- A ausência de um perfil adicional de Pod Identity nessa etapa não significa que todos os complementos ou workloads futuros dispensarão permissões IAM.
- Se algum componente precisar acessar serviços AWS, suas permissões devem ser definidas de acordo com o princípio do menor privilégio.

---

## Etapa 6 — Analisar e criar

Antes de confirmar a criação, revisar os itens abaixo.

### Checklist de revisão

- [ ] Nome do cluster: `fcg-platform`.
- [ ] Região: `sa-east-1`.
- [ ] Versão do Kubernetes conferida.
- [ ] EKS Auto Mode desabilitado.
- [ ] Role IAM do cluster selecionada corretamente.
- [ ] Acesso administrativo inicial configurado.
- [ ] VPC e sub-redes revisadas.
- [ ] Acesso público ao endpoint revisado.
- [ ] Logs do plano de controle desabilitados.
- [ ] Apenas os complementos necessários selecionados.
- [ ] Nenhum complemento adicional selecionado sem necessidade.
- [ ] Tags revisadas.
- [ ] Estimativa de custos avaliada antes de confirmar.

Após a confirmação, o EKS inicia o provisionamento do plano de controle. O status esperado ao final é `Active`.

A criação pode levar vários minutos. Não é necessário criar os nós de trabalho imediatamente após o cluster ficar ativo.

### Próximas etapas

Depois que o cluster estiver `Active`:

1. Confirmar o estado do cluster no console da AWS.
2. Verificar o acesso administrativo ao Kubernetes.
3. Planejar a criação dos nós de trabalho antes de provisionar workloads.
4. Configurar o ECR e o pipeline de CI/CD conforme a arquitetura do projeto.
5. Validar como os serviços serão expostos externamente antes de criar um Load Balancer.
6. Documentar o procedimento de exclusão e conferir os recursos remanescentes após os testes.

---

## 💰 Controle de custos

A criação do cluster EKS gera custos pelo plano de controle enquanto ele existir. Os demais recursos podem gerar cobranças adicionais, dependendo do que for provisionado.

Entre os recursos que devem ser monitorados estão:

- Cluster EKS.
- Instâncias EC2 dos nós de trabalho.
- Volumes EBS.
- Load Balancers.
- Endereços IPv4 públicos.
- NAT Gateways, caso sejam criados.
- Logs armazenados no CloudWatch.

**Importante:** configurar um AWS Budget ajuda a monitorar os gastos, mas não bloqueia automaticamente a criação de recursos nem garante que cobranças serão interrompidas ao atingir o limite.

### Procedimento de encerramento

Ao terminar os testes:

1. Excluir os workloads e os serviços que não serão mais utilizados.
2. Remover os recursos de exposição externa, como Load Balancers criados para o projeto.
3. Excluir os nós de trabalho ou seus grupos, se existirem.
4. Excluir o cluster EKS.
5. Conferir volumes, endereços IP, NAT Gateways e outros recursos remanescentes.
6. Consultar o AWS Billing para acompanhar os custos registrados.

A exclusão do cluster não garante que todos os recursos criados separadamente sejam removidos automaticamente.

---

## Referências oficiais

- [Amazon EKS — Documentação](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [Amazon EKS — Criação de clusters](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)
- [Amazon EKS — Complementos](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)
- [AWS Billing — Gerenciamento de custos](https://docs.aws.amazon.com/cost-management/latest/userguide/what-is-costmanagement.html)
