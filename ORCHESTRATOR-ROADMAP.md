# ORCHESTRATOR-ROADMAP

Este documento mapeia o progresso do projeto `setup-skills` sob governança do orquestrador.

## Epics

- [x] **E1: Bootstrap do Ecossistema** (Configuração, docs, governança)
- [ ] **E2: Estrutura de Skills & Persistência** (Decomposição, bibliotecas, padrão MD)
- [ ] **E3: Implementação de Skills Base** (Infra: Bootstrap, Docker, Traefik)
- [ ] **E4: Implementação de Skills de Aplicação** (Chatwoot, Evolution, N8n, etc)
- [ ] **E5: Auditoria, Testes e Qualidade** (Segurança e Validação)

## Status

- **Fase Atual**: 2 (Estrutura de Skills & Persistência)
- **Estado**: Em andamento

## Tarefas (DAG)

- [x] T1: Criar .gitignore | depends_on: []
- [x] T2: Remover lixo de sistema | depends_on: []
- [x] T3: Organizar docs/ | depends_on: []
- [ ] T4: Criar ADR-001 (Padrão Persistência em Markdown) | depends_on: []
- [ ] T5: Criar ADR-002 (Segurança de Segredos e Contexto) | depends_on: []
- [ ] T6: Estruturar diretório base de skills | depends_on: [T4, T5]
