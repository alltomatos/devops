### Auditoria Técnica (GAPs)

🚨 GAP: Infraestrutura inicial ineficiente e sujeita a poluição de arquivos de sistema (Zone.Identifier)
├── 📉 Impacto: Ambiente desorganizado, dificuldade de rastreabilidade (git), acúmulo de lixo de OS (Windows/WSL).
├── 💡 BOA PRÁTICA: Uso de `.gitignore` rigoroso e estrutura de projeto limpa (Clean Architecture).
├── 🗺️ PLANO AÇÃO: Limpar arquivos indesejados e implementar `.gitignore`.
├── 📋 TAREFAS:
│   ├── [ ] T1: Criar `.gitignore` para ignorar arquivos de sistema (*.Zone.Identifier) e diretórios temporários.
│   ├── [ ] T2: Remover arquivos `*.Zone.Identifier` do versionamento e do disco.
│   └── [ ] T3: Consolidar/revisar documentação de setup (Setup.md, SetupOrion.md) em um único `docs/setup.md`.
└── ⚠️ TIER RISCO: T1 (Fast Path/Automático)
