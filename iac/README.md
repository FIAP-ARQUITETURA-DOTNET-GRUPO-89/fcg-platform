# Infraestrutura como código

Esta pasta reúne o código Terraform da infraestrutura da FCG. Os procedimentos
manuais para executar a infraestrutura na AWS ficam em
[`docs/iac/manual`](../docs/iac/manual).

## Execução manual na AWS

Siga os documentos na ordem numérica:

1. [Instalar as CLIs e autenticar na AWS](../docs/iac/manual/1-aws-cli-e-eksctl.md)
2. [Criar o cluster Amazon EKS](../docs/iac/manual/2-cluster-eks.md)
3. [Criar o grupo de nós EC2](../docs/iac/manual/3-nos-ec2.md)
4. [Subir o PostgreSQL](../docs/iac/manual/4-postgres.md)
5. [Subir o PostgreSQL e o pgAdmin](../docs/iac/manual/5-pg-admin.md)
6. [Subir o RabbitMQ](../docs/iac/manual/6-rabbit.md)

Os documentos foram numerados para representar a sequência de execução manual.
O acesso à AWS e a instalação das ferramentas ficam consolidados no primeiro
passo.

## Terraform

- [Guia de execução com Terraform](../docs/iac/terraform/README.md)
- [Configuração AWS](./terraform/aws)

Antes de executar o Terraform, valide a conta e a região AWS usando o primeiro
guia da seção manual.
