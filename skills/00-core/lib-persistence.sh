#!/bin/bash
# =============================================================================
# skills/00-core/lib-persistence.sh
# Biblioteca de persistência centralizada do ecossistema Setup Orion
#
# Padrão:
#   - Todo dado persistido em /root/dados_vps/*.md
#   - index.md mantém catálogo de todas as instalações
#   - Escrita atômica via arquivo temporário (evita corrupção)
# =============================================================================

DATA_DIR="/root/dados_vps"

# Garante que o diretório de dados existe
_ensure_data_dir() {
    mkdir -p "$DATA_DIR"
}

# -----------------------------------------------------------------------------
# Salva dados de uma skill em arquivo .md
# Uso: save_data "nome-serviço" "conteúdo markdown completo"
# -----------------------------------------------------------------------------
save_data() {
    local service="$1"
    local content="$2"
    local target="$DATA_DIR/$service.md"
    local tmp
    tmp=$(mktemp)

    _ensure_data_dir

    # Escrita atômica: escreve no temp e move (evita corrupção em falhas)
    echo "$content" > "$tmp" && mv "$tmp" "$target"

    # Atualiza o índice central
    _update_index "$service"
}

# -----------------------------------------------------------------------------
# Lê dados de uma skill persistida
# Uso: read_data "nome-serviço"
# -----------------------------------------------------------------------------
read_data() {
    local service="$1"
    local target="$DATA_DIR/$service.md"

    if [ -f "$target" ]; then
        cat "$target"
    else
        echo "[lib-persistence] Nenhum dado encontrado para: $service"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Verifica se um serviço já foi instalado/registrado
# Uso: service_exists "nome-serviço" → retorna 0 (sim) ou 1 (não)
# -----------------------------------------------------------------------------
service_exists() {
    [ -f "$DATA_DIR/$1.md" ]
}

# -----------------------------------------------------------------------------
# Atualiza o índice central de instalações
# Mantém entradas únicas e ordenadas
# -----------------------------------------------------------------------------
_update_index() {
    local service="$1"
    local index="$DATA_DIR/index.md"

    _ensure_data_dir

    # Cria o cabeçalho se o índice não existe ainda
    if [ ! -f "$index" ]; then
        cat > "$index" <<MD
# Catálogo de Instalações Setup Orion

> Gerado automaticamente pelas skills do ecossistema Setup Orion.

## Serviços Instalados

MD
    fi

    # Adiciona entrada somente se ainda não existir
    local entry="- [$service]($service.md)"
    if ! grep -qF -- "$entry" "$index"; then
        echo "$entry" >> "$index"
    fi
}

# -----------------------------------------------------------------------------
# Resolve as credenciais do Portainer (env tem prioridade; senão o arquivo de auth)
# Popula as globais: _PORT_URL _PORT_USER _PORT_PASS _PORT_TOKEN
# -----------------------------------------------------------------------------
_portainer_load_auth() {
    local auth_file="$DATA_DIR/portainer_auth"
    _PORT_URL="${PORTAINER_URL:-}"
    _PORT_USER="${PORTAINER_USER:-}"
    _PORT_PASS="${PORTAINER_PASS:-}"
    _PORT_TOKEN="${PORTAINER_TOKEN:-}"

    if [ -f "$auth_file" ]; then
        [ -z "$_PORT_URL" ]   && _PORT_URL=$(grep -E '^PORTAINER_URL='   "$auth_file" | cut -d= -f2- | tr -d '\r')
        [ -z "$_PORT_USER" ]  && _PORT_USER=$(grep -E '^PORTAINER_USER='  "$auth_file" | cut -d= -f2- | tr -d '\r')
        [ -z "$_PORT_PASS" ]  && _PORT_PASS=$(grep -E '^PORTAINER_PASS='  "$auth_file" | cut -d= -f2- | tr -d '\r')
        [ -z "$_PORT_TOKEN" ] && _PORT_TOKEN=$(grep -E '^PORTAINER_TOKEN=' "$auth_file" | cut -d= -f2- | tr -d '\r')
    fi
    # Fallback de URL a partir do portainer.md (campo "URL de Acesso")
    if [ -z "$_PORT_URL" ] && [ -f "$DATA_DIR/portainer.md" ]; then
        _PORT_URL=$(grep -oP '(?<=URL de Acesso\*\*: ).*' "$DATA_DIR/portainer.md" | tr -d '\r ')
    fi
    _PORT_URL="${_PORT_URL#https://}"; _PORT_URL="${_PORT_URL#http://}"; _PORT_URL="${_PORT_URL%/}"
}

# -----------------------------------------------------------------------------
# Persiste as credenciais do Portainer (chmod 600). Segredos ficam neste arquivo
# operacional fora do contexto Markdown (necessário p/ deploys via API).
# Uso: portainer_save_auth <url> <user> <pass> [token]
# -----------------------------------------------------------------------------
portainer_save_auth() {
    _ensure_data_dir
    local auth_file="$DATA_DIR/portainer_auth"
    ( umask 077; cat > "$auth_file" <<EOF
PORTAINER_URL=${1#https://}
PORTAINER_USER=$2
PORTAINER_PASS=$3
PORTAINER_TOKEN=${4:-}
EOF
    )
    chmod 600 "$auth_file"
}

# -----------------------------------------------------------------------------
# Inicializa o admin do Portainer via API (modo Total Control) e persiste auth.
# Só funciona na primeira vez (enquanto não existe admin). Idempotente: se o
# admin já existe, apenas valida que a senha informada autentica.
# Uso: portainer_init_admin <url> <user> <pass>
# -----------------------------------------------------------------------------
portainer_init_admin() {
    local url="${1#https://}"; url="${url%/}"
    local user="$2" pass="$3"
    local base="https://$url"

    # Aguarda a API responder
    local i
    for i in $(seq 1 30); do
        curl -k -s -o /dev/null "$base/api/status" && break
        sleep 2
    done

    local check
    check=$(curl -k -s -o /dev/null -w "%{http_code}" "$base/api/users/admin/check")
    if [ "$check" = "404" ]; then
        # Nenhum admin ainda -> cria
        local code
        code=$(curl -k -s -o /dev/null -w "%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$(jq -nc --arg u "$user" --arg p "$pass" '{Username:$u,Password:$p}')" \
            "$base/api/users/admin/init")
        if [ "$code" -ge 200 ] && [ "$code" -lt 300 ]; then
            portainer_save_auth "$url" "$user" "$pass"
            echo "[portainer] Admin '$user' criado via API e credenciais persistidas."
            return 0
        fi
        echo "[portainer] ERRO: falha ao criar admin (HTTP $code)." >&2
        return 1
    fi

    # Admin já existe -> valida senha e persiste
    local jwt
    jwt=$(curl -k -s -X POST -H "Content-Type: application/json" \
          -d "$(jq -nc --arg u "$user" --arg p "$pass" '{username:$u,password:$p}')" \
          "$base/api/auth" | jq -r '.jwt // empty')
    if [ -n "$jwt" ]; then
        portainer_save_auth "$url" "$user" "$pass"
        echo "[portainer] Admin já existia; credenciais validadas e persistidas."
        return 0
    fi
    echo "[portainer] AVISO: admin já existe mas a senha informada não autentica." >&2
    return 1
}

# -----------------------------------------------------------------------------
# Faz o deploy de uma stack através da API do Portainer (modo Total Control).
# As stacks ficam totalmente gerenciáveis pela UI do Portainer (NÃO usa
# `docker stack deploy`, que criaria stacks "limited/external").
# Idempotente: cria se nova, atualiza (redeploy) se já existir.
# Uso: deploy_via_portainer "nome_da_stack" "/caminho/para/arquivo.yaml"
# Auth: env PORTAINER_TOKEN ou PORTAINER_USER/PORTAINER_PASS, ou /root/dados_vps/portainer_auth
# Retorna 0 em sucesso; !=0 em falha (SEM fallback para docker stack deploy).
# -----------------------------------------------------------------------------
deploy_via_portainer() {
    local stack_name="$1"
    local compose_file="$2"

    if [ ! -f "$compose_file" ]; then
        echo "[portainer] ERRO: arquivo compose não encontrado: $compose_file" >&2
        return 1
    fi

    local _PORT_URL _PORT_USER _PORT_PASS _PORT_TOKEN
    _portainer_load_auth
    if [ -z "$_PORT_URL" ]; then
        echo "[portainer] ERRO: URL do Portainer não encontrada (defina PORTAINER_URL ou ~/dados_vps/portainer_auth)." >&2
        return 1
    fi

    local base="https://$_PORT_URL"
    local -a auth_hdr
    if [ -n "$_PORT_TOKEN" ]; then
        auth_hdr=(-H "X-API-Key: $_PORT_TOKEN")
    elif [ -n "$_PORT_USER" ] && [ -n "$_PORT_PASS" ]; then
        local jwt
        jwt=$(curl -k -s -X POST -H "Content-Type: application/json" \
              -d "$(jq -nc --arg u "$_PORT_USER" --arg p "$_PORT_PASS" '{username:$u,password:$p}')" \
              "$base/api/auth" | jq -r '.jwt // empty')
        if [ -z "$jwt" ]; then
            echo "[portainer] ERRO: autenticação falhou (verifique PORTAINER_USER/PASS)." >&2
            return 1
        fi
        auth_hdr=(-H "Authorization: Bearer $jwt")
    else
        echo "[portainer] ERRO: sem credenciais (PORTAINER_TOKEN ou PORTAINER_USER/PASS)." >&2
        return 1
    fi

    # Endpoint local (prefere Name=="primary", senão o primeiro) e SwarmID
    local endpoint_id swarm_id
    endpoint_id=$(curl -k -s "${auth_hdr[@]}" "$base/api/endpoints" \
                  | jq -r 'map(select(.Name=="primary"))[0].Id // .[0].Id // empty')
    if [ -z "$endpoint_id" ]; then
        echo "[portainer] ERRO: nenhum endpoint Docker encontrado." >&2
        return 1
    fi
    swarm_id=$(curl -k -s "${auth_hdr[@]}" "$base/api/endpoints/$endpoint_id/docker/swarm" | jq -r '.ID // empty')
    if [ -z "$swarm_id" ]; then
        echo "[portainer] ERRO: SwarmID não encontrado (endpoint $endpoint_id)." >&2
        return 1
    fi

    local content_json
    content_json=$(jq -Rs . < "$compose_file")

    # Stack já existe? -> update; senão -> create
    local existing_id
    existing_id=$(curl -k -s "${auth_hdr[@]}" "$base/api/stacks" \
                  | jq -r --arg n "$stack_name" 'map(select(.Name==$n))[0].Id // empty')

    local resp_file http_code body
    resp_file=$(mktemp)
    if [ -n "$existing_id" ]; then
        body=$(jq -nc --argjson c "$content_json" '{StackFileContent:$c, Env:[], Prune:true}')
        http_code=$(curl -k -s -o "$resp_file" -w "%{http_code}" -X PUT \
            "${auth_hdr[@]}" -H "Content-Type: application/json" \
            -d "$body" "$base/api/stacks/$existing_id?endpointId=$endpoint_id")
    else
        body=$(jq -nc --arg n "$stack_name" --arg s "$swarm_id" --argjson c "$content_json" \
               '{Name:$n, SwarmID:$s, StackFileContent:$c, Env:[]}')
        http_code=$(curl -k -s -o "$resp_file" -w "%{http_code}" -X POST \
            "${auth_hdr[@]}" -H "Content-Type: application/json" \
            -d "$body" "$base/api/stacks/create/swarm/string?endpointId=$endpoint_id")
    fi

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        rm -f "$resp_file"
        echo "[portainer] Stack '$stack_name' deployada via API (HTTP $http_code, $([ -n "$existing_id" ] && echo update || echo create))."
        return 0
    fi
    echo "[portainer] ERRO: deploy via API de '$stack_name' falhou (HTTP $http_code):" >&2
    cat "$resp_file" >&2 2>/dev/null; echo >&2
    rm -f "$resp_file"
    return 1
}
list_services() {
    local index="$DATA_DIR/index.md"
    if [ -f "$index" ]; then
        grep "^- \[" "$index" | sed 's/- \[//;s/\].*//'
    else
        echo "[lib-persistence] Nenhum serviço registrado ainda."
    fi
}
