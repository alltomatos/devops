#!/usr/bin/env bash
# Estado atual do ecossistema: conta skills instaladas x pendentes.
set -u

DADOS="${ORION_DADOS_DIR:-/root/dados_vps}"
SKILLS="${ORION_SKILLS_DIR:-/root/setup-skills/skills}"

if [ ! -d "$SKILLS" ]; then
  echo "Servidor nao conectado"
  exit 0
fi

total=0; ok=0
for d in "$SKILLS"/*/; do
  name="$(basename "$d")"
  [ "$name" = "00-core" ] && continue
  total=$((total + 1))
  short="${name#app-}"; short="${short#infra-}"
  if [ -f "$DADOS/$name.md" ] || [ -f "$DADOS/$short.md" ]; then
    ok=$((ok + 1))
  fi
done
pend=$((total - ok))

echo "Instaladas : $ok"
echo "Pendentes  : $pend"
echo "Total      : $total"
