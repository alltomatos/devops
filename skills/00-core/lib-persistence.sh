#!/bin/bash
# =============================================================================
# skills/00-core/lib-persistence.sh
# Biblioteca de persistência centralizada do ecossistema Orion
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
# Catálogo de Instalações Orion

> Gerado automaticamente pelas skills do ecossistema Orion.

## Serviços Instalados

MD
    fi

    # Adiciona entrada somente se ainda não existir
    local entry="- [$service]($service.md)"
    if ! grep -qF "$entry" "$index"; then
        echo "$entry" >> "$index"
    fi
}

# -----------------------------------------------------------------------------
# Lista todos os serviços registrados
# Uso: list_services
# -----------------------------------------------------------------------------
list_services() {
    local index="$DATA_DIR/index.md"
    if [ -f "$index" ]; then
        grep "^- \[" "$index" | sed 's/- \[//;s/\].*//'
    else
        echo "[lib-persistence] Nenhum serviço registrado ainda."
    fi
}
