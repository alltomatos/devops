# Skill: app-evoai

Instalação da EvoAI (Plataforma de Agentes e Automação Orion) em cluster Docker Swarm.

## Estrutura

- **Frontend**: Interface visual para gestão de agentes.
- **API**: Backend de processamento.
- **Redis Dedicado**: Instância de cache exclusiva para a EvoAI.
- **Postgres**: Utiliza a instância global `infra-postgres`.

## Inputs

- Domínios para API e Frontend.
- Credenciais de administrador.
- Configurações de SMTP para notificações e recuperação de senha.
