# Skill: app-wuzapi

Instalação do Wuzapi (Gateway WhatsApp focado em simplicidade) em cluster Docker Swarm.

## Funcionalidades

- API baseada em JSON para interação com WhatsApp.
- Persistência de sessões em arquivos e banco de dados.
- Leve e eficiente.

## Inputs

- `DOMAIN_WUZAPI`: Domínio de acesso.

## Observações

- **Banco de Dados**: Utiliza a instância global `infra-postgres`.
- **Token de Acesso**: O `WUZAPI_ADMIN_TOKEN` é gerado automaticamente e salvo nos metadados.
