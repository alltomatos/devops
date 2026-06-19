#!/bin/bash
# skills/app-stirlingpdf/run.sh
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SKILL_DIR/../00-core/lib-persistence.sh"
amarelo="\e[33m"; verde="\e[32m"; reset="\e[0m"
STACK_NAME="stirlingpdf"; NOME_REDE_INTERNA="${NOME_REDE_INTERNA:-$(docker network ls --filter driver=overlay --format "{{.Name}}" | grep -vw ingress | head -n1)}"
echo -e "${amarelo}Instalando Stirling PDF...${reset}"
for vol in data config logs; do
    docker volume create stirlingpdf_${vol} > /dev/null 2>&1
done
# Imagem stirling-pdf e monolitica (UI+API em :8080); MODE=BACKEND/FRONTEND nao se aplica
# (rodava 2 JVMs completos e estourava o Metaspace). Servico unico com memoria adequada.
cat > stirlingpdf.yaml <<YAML
version: "3.7"
services:
  stirlingpdf:
    image: stirlingtools/stirling-pdf:latest
    volumes:
      - stirlingpdf_data:/usr/share/tessdata
      - stirlingpdf_config:/configs
      - stirlingpdf_logs:/logs
    networks:
      - $NOME_REDE_INTERNA
    environment:
      - SECURITY_ENABLELOGIN=true
      - DOCKER_ENABLE_SECURITY=false
      - DISABLE_ADDITIONAL_FEATURES=false
      - UI_APPNAME=$STIRLING_APP_NAME
      - UI_APPNAMENAVBAR=$STIRLING_APP_NAME
      - SYSTEM_DEFAULTLOCALE=pt_BR
      - SYSTEM_MAXFILESIZE=100
      - SYSTEM_GOOGLEVISIBILITY=false
      - METRICS_ENABLED=true
      - LANGS=en_GB,en_US,pt_BR,es_ES,fr_FR,de_DE,it_IT,zh_CN,ja_JP
      - PUID=1000
      - PGID=1000
    deploy:
      labels:
        - traefik.enable=true
        - traefik.http.routers.stirlingpdf.rule=Host(\`$DOMAIN_STIRLINGPDF\`)
        - traefik.http.routers.stirlingpdf.entrypoints=websecure
        - traefik.http.routers.stirlingpdf.tls.certresolver=letsencryptresolver
        - traefik.http.services.stirlingpdf.loadbalancer.server.port=8080
      resources:
        limits:
          cpus: "2"
          memory: 2560M

volumes:
  stirlingpdf_data:
    external: true
  stirlingpdf_config:
    external: true
  stirlingpdf_logs:
    external: true
networks:
  $NOME_REDE_INTERNA:
    external: true
YAML
deploy_via_portainer "$STACK_NAME" "stirlingpdf.yaml"
[ $? -eq 0 ] && echo -e "${verde}OK${reset}" && save_data "app-stirlingpdf" "[ STIRLINGPDF ]

Dominio: https://$DOMAIN_STIRLINGPDF

Host: stirlingpdf

Port: 8080

Rede: $NOME_REDE_INTERNA"
rm -f stirlingpdf.yaml; exit 0