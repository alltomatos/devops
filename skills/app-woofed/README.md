# Skill: app-woofed

Instalação do WoofedCRM (Sistema de CRM otimizado para integração com WhatsApp e Evolution API) em cluster Docker Swarm.

## Estrutura

- **Web**: Interface principal Ruby on Rails.
- **Sidekiq**: Processamento de filas em background.
- **Banco de Dados**: Utiliza `infra-pgvector`.
- **Cache/Filas**: Utiliza `infra-redis`.

## Inputs

- `DOMAIN_WOOFED`: Domínio para acesso.
- `MOTOR_USER` / `MOTOR_PASS`: Credenciais para o motor de processamento.

## Observações

- A skill executa automaticamente as migrações do banco de dados (`rails db:prepare`).
- É altamente recomendado ter a `app-evolution` instalada para integração completa de mensagens.
