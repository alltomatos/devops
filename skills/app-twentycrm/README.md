# Skill: app-twentycrm

Instalação do Twenty CRM (CRM open-source moderno e focado em experiência do usuário) em cluster Docker Swarm.

## Estrutura

- **Server**: Core da aplicação rodando em Node.js.
- **Worker**: Processamento de tarefas assíncronas.
- **Banco de Dados**: Spilo (PostgreSQL altamente disponível).
- **Redis**: Instância dedicada para cache e mensageria.

## Inputs

- `DOMAIN_TWENTY`: Domínio de acesso.

## Observações

- A skill gera automaticamente segredos para o banco de dados e para a aplicação.
- Utiliza volumes externos para persistência.
- Configuração de memória otimizada para o Swarm.
