#!/usr/bin/env bash
# Catalogo de deploy do ecossistema Setup Orion.
# Renderiza o menu categorizado com status de instalacao (✅/⬜).
# Invocado pela skill /devops. Paths sobreescreviveis via ORION_SKILLS_DIR / ORION_DADOS_DIR.
set -u

DADOS_DIR="${ORION_DADOS_DIR:-/root/dados_vps}"

is_installed() {
  local name="$1" short
  [ -d "$DADOS_DIR" ] || return 1
  short="${name#app-}"; short="${short#infra-}"
  # Padrão Setup Orion: /root/dados_vps/dados_<servico> (sem extensão)
  [ -f "$DADOS_DIR/dados_$short" ] || [ -f "$DADOS_DIR/dados_$name" ]
}

icon() { if is_installed "$1"; then printf '✅'; else printf '⬜'; fi; }

row() { # num|name|label|deps
  local num="$1" name="$2" label="$3" deps="$4" dep_str=""
  [ -n "$deps" ] && dep_str="  ← $deps"
  printf '  [%3s] %s %-40s%s\n' "$num" "$(icon "$name")" "$label" "$dep_str"
}

hr() { printf '+-'; printf -- '-%.0s' $(seq 75); printf -- '-+\n'; }

section() { # titulo  rec...
  local title="$1"; shift
  hr; printf '|  %s\n' "$title"; hr
  local rec num name label deps
  for rec in "$@"; do
    IFS='|' read -r num name label deps <<< "$rec"
    row "$num" "$name" "$label" "$deps"
  done
  printf '\n'
}

BASE=(
  " 0|infra-bootstrap|Bootstrap do Servidor|"
  " 1|app-traefik|Traefik + SSL + Portainer|bootstrap"
)
DATA=(
  " 2|infra-postgres|PostgreSQL 14|"
  " 3|infra-pgvector|PostgreSQL + pgvector (AI/RAG)|postgres"
  " 4|infra-redis|Redis 7 (cache / pub-sub)|"
  " 5|infra-mysql|MySQL 8.0|"
  " 6|infra-mongodb|MongoDB 6.0|"
  " 7|infra-rabbitmq|RabbitMQ + Management UI|"
  " 8|infra-kafka|Apache Kafka (KRaft)|"
  " 9|infra-clickhouse|ClickHouse (analytics OLAP)|"
  "10|infra-qdrant|Qdrant (vector search)|"
)
AI=(
  "11|app-ollama|Ollama (modelos locais LLM)|"
  "12|app-openwebui|Open WebUI (frontend Ollama)|ollama"
  "13|app-flowise|Flowise (orquestrador LLM)|postgres"
  "14|app-langflow|Langflow (builder visual LLM)|"
  "15|app-langfuse|Langfuse (observabilidade LLM)|postgres"
  "16|app-dify|Dify (plataforma LLM + RAG)|postgres, redis"
  "17|app-anythingllm|AnythingLLM (RAG privado)|"
  "18|app-firecrawl|Firecrawl (web scraping LLM)|redis"
  "19|app-zep|Zep (memória long-term agentes)|pgvector"
  "20|app-evoai|EvoAI (plataforma de agentes)|postgres"
  "21|app-omnitools|OmniTools (hub ferramentas AI)|"
)
WA=(
  "22|app-evolution|Evolution API (WhatsApp)|"
  "23|app-unoapi|UnoAPI (gateway Baileys)|minio, rabbitmq"
  "24|app-quepasa|QuePasa (gateway WhatsApp)|postgres"
  "25|app-wuzapi|WuzAPI (gateway leve)|postgres"
  "26|app-wppconnect|WPPConnect (gateway robusto)|"
  "27|app-transcrevezap|TranscreveZap (transcrição)|"
)
CRM=(
  "28|app-chatwoot|Chatwoot (omnichannel)|pgvector"
  "29|app-woofed|WoofedCRM (CRM WhatsApp)|pgvector, redis"
  "30|app-krayincrm|Krayin CRM|"
  "31|app-twentycrm|Twenty CRM|"
  "32|app-evocrm|EvoCRM (CRM + AI)|pgvector"
  "33|app-mautic|Mautic (automação marketing)|postgres"
)
CMS=(
  "34|app-strapi|Strapi (headless CMS)|postgres"
  "35|app-directus|Directus (headless CMS + BaaS)|postgres, redis, minio"
  "36|app-nocobase|NocoBase (no-code BaaS)|postgres"
  "37|app-nocodb|NocoDB (Airtable open-source)|postgres"
  "38|app-baserow|Baserow (no-code DB)|postgres"
  "39|app-tooljet|ToolJet (low-code internal tools)|postgres"
  "40|app-lowcoder|Lowcoder (low-code apps)|postgres"
  "41|app-appsmith|Appsmith (low-code internal tools)|postgres"
)
COLLAB=(
  "42|app-nextcloud|Nextcloud (armazenamento)|"
  "43|app-outline|Outline (wiki/knowledge base)|"
  "44|app-mattermost|Mattermost (chat team)|"
  "45|app-docmost|Docmost (docs colaborativo)|"
  "46|app-wiki|Wiki.js (wiki moderna)|"
  "47|app-affine|AFFiNE (Notion open-source)|"
  "48|app-jitsi|Jitsi Meet (videoconferência)|"
  "49|app-hoppscotch|Hoppscotch (API client)|"
  "50|app-excalidraw|Excalidraw (diagramas collab)|"
)
DOCS=(
  "51|app-documenso|Documenso (assinatura digital)|"
  "52|app-docuseal|DocuSeal (assinatura digital)|"
  "53|app-stirlingpdf|Stirling PDF (manipulação PDF)|"
  "54|app-gotenberg|Gotenberg (API PDF)|"
  "55|app-opensign|OpenSign (assinatura digital)|"
)
SEC=(
  "56|app-vaultwarden|Vaultwarden (cofre senhas)|"
  "57|app-keycloak|Keycloak (SSO/IAM)|"
  "58|app-authentik|Authentik (SSO/IAM)|"
  "59|app-passbolt|Passbolt (cofre senhas team)|"
)
MON=(
  "60|app-uptimekuma|Uptime Kuma (monitoramento)|"
  "61|app-monitor|Stack Prometheus + Grafana|"
  "62|app-checkmate|Checkmate (monitoramento)|"
  "63|app-netbox|NetBox (inventário rede)|"
)
MISC=(
  "64|app-metabase|Metabase (BI dashboards)|postgres"
  "65|app-wordpress|WordPress (CMS/blog)|"
  "66|app-calcom|Cal.com (agendamento)|postgres"
  "67|app-odoo|Odoo (ERP completo)|postgres"
  "68|app-frappe|Frappe/ERPNext (ERP)|postgres"
  "69|app-glpi|GLPI (helpdesk/ITSM)|postgres"
  "70|app-openproject|OpenProject (gestão projetos)|postgres"
  "71|app-planka|Planka (kanban Trello-like)|postgres"
  "72|app-supabase|Supabase (BaaS + auth + storage)|"
  "73|app-code-server|Code Server (VSCode no browser)|"
  "74|app-rustdesk|RustDesk (remote desktop)|"
  "75|app-azuracast|AzuraCast (rádio web)|"
  "76|app-ntfy|ntfy (notificações push)|"
  "77|app-formbricks|Formbricks (surveys)|postgres"
  "78|app-activepieces|Activepieces (automação)|"
  "79|app-botpress|Botpress (chatbot platform)|"
)

printf '\n'
section "E1-E4  BASE / INFRAESTRUTURA"      "${BASE[@]}"
section "E5     DADOS / BANCO / FILAS"       "${DATA[@]}"
section "E6     AI / LLM / ORQUESTRAÇÃO"     "${AI[@]}"
section "E7     WHATSAPP / MENSAGERIA"       "${WA[@]}"
section "E8     CRM / ATENDIMENTO"           "${CRM[@]}"
section "E9     LOW-CODE / CMS"              "${CMS[@]}"
section "E10    PRODUTIVIDADE / COLABORAÇÃO" "${COLLAB[@]}"
section "E11    DOCS / PDF / ASSINATURA"     "${DOCS[@]}"
section "E12    SEGURANÇA / AUTENTICAÇÃO"    "${SEC[@]}"
section "E13    MONITORAMENTO"               "${MON[@]}"
section "E14-E22 UTILITÁRIOS / DIVERSOS"     "${MISC[@]}"

printf '  ✅ = já instalado   ⬜ = disponível para instalar\n\n'
printf '  Digite o número, nome da skill ou categoria para instalar.\n'
printf '  Ex: "36"  ou  "nocobase"  ou  "instalar calcom"\n'
printf '  Para auditoria do servidor (Segurança/Performance): "/devops audit"\n'
printf '  Para diagnóstico de stack: "/diagnose-stack <nome>"\n'
printf '  Para status do ecossistema: "/status-ecossistema"\n'
printf '  Para auditar conformance das skills: "/audit-skills"\n'
