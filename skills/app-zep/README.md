# Skill: app-zep

Instalação do Zep (Memória de longo prazo para agentes AI) em cluster Docker Swarm.

## Funcionalidades

- Armazenamento de chats com pesquisa vetorial (via `pgvector`).
- Sumarização automática de diálogos.
- Integração nativa com LangChain e outros frameworks de agentes.

## Inputs

- `DOMAIN_ZEP`: Domínio para acesso.
- `ZEP_USER` / `ZEP_PASS`: Credenciais para o painel administrativo (`/admin`).
- `OPENAI_API_KEY`: Chave necessária para processamento de embeddings e NLP.

## Detalhes de Implementação

- Utiliza `pgvector` para persistência de vetores.
- Autenticação via Traefik Basic Auth para a interface administrativa.
- API Key do Zep é gerada automaticamente durante a instalação.
