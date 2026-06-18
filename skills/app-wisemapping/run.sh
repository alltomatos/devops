#!/bin/bash
# =============================================================================
# skills/app-wisemapping/run.sh
# Skill: Instalação do WiseMapping via Docker Swarm
# =============================================================================

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SKILL_DIR/../00-core/lib-persistence.sh"

amarelo="\e[33m"
verde="\e[32m"
reset="\e[0m"

STACK_NAME="wisemapping"
NOME_REDE_INTERNA="${NOME_REDE_INTERNA:-$(docker network ls --filter driver=overlay --format "{{.Name}}" | grep -vw ingress | head -n1)}"

if ! docker service ls --format "{{.Name}}" | grep -qE "(^|_)postgres"; then
    echo -e "${amarelo}Erro: infra-postgres nao instalado.${reset}"
    exit 1
fi

# Recuperar ou gerar JWT Secret (idempotência)
JWT_SECRET=$(read_data "app-wisemapping" | grep -oP '(?<=JWT Secret: ).*' || openssl rand -hex 32)

echo -e "${amarelo}Instalando WiseMapping no domínio $DOMAIN_WISEMAPPING...${reset}"

docker volume create wisemapping_data > /dev/null 2>&1

POSTGRES_PASSWORD=$(grep "Senha:" /root/dados_vps/dados_postgres | awk -F"Senha:" '{print $2}' | xargs)

cat > wisemapping.yaml <<EOL
version: "3.7"
services:
  wisemapping:
    image: wisemapping/wisemapping:latest
    volumes:
      - wisemapping_data:/usr/local/tomcat/webapps/wisemapping/WEB-INF/data
    networks:
      - $NOME_REDE_INTERNA
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/wisemapping?stringtype=unspecified&sslmode=disable
      - SPRING_DATASOURCE_USERNAME=postgres
      - SPRING_DATASOURCE_PASSWORD=$POSTGRES_PASSWORD
      - APP_SITE_UI_BASE_URL=https://$DOMAIN_WISEMAPPING
      - APP_SITE_API_BASE_URL=https://$DOMAIN_WISEMAPPING
      - APP_JWT_SECRET=$JWT_SECRET
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.wisemapping.rule=Host(\`$DOMAIN_WISEMAPPING\`)"
        - "traefik.http.routers.wisemapping.entrypoints=websecure"
        - "traefik.http.routers.wisemapping.tls.certresolver=letsencryptresolver"
        - "traefik.http.services.wisemapping.loadbalancer.server.port=8080"
      resources:
        limits:
          cpus: "1"
          memory: 1024M

volumes:
  wisemapping_data:
    external: true

networks:
  $NOME_REDE_INTERNA:
    external: true
EOL

ensure_db "postgres" "wisemapping" || { echo "Erro ao preparar o banco"; exit 1; }
deploy_via_portainer "$STACK_NAME" "wisemapping.yaml"

if [ $? -eq 0 ]; then
    echo -e "${verde}Stack $STACK_NAME enviada com sucesso!${reset}"
    save_data "app-wisemapping" "[ WISEMAPPING ]

Dominio: https://$DOMAIN_WISEMAPPING

Host: wisemapping

Port: 8080

Usuario: postgres

JWT Secret: $JWT_SECRET

Rede: $NOME_REDE_INTERNA"
else
    exit 1
fi

rm -f wisemapping.yaml
exit 0
