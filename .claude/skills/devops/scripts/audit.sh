#!/usr/bin/env bash
# Auditoria de Seguranca e Performance do servidor (Linux/VPS).
set -u

na() { local v; v="$("$@" 2>/dev/null)"; [ -n "$v" ] && printf '%s' "$v" || printf 'N/A'; }

# 1. Sistema e Hardware
os_ver="$(lsb_release -ds 2>/dev/null || echo N/A)"
kernel="$(uname -r 2>/dev/null || echo N/A)"
cpu="$(nproc 2>/dev/null || echo N/A)"
mem="$(free -h 2>/dev/null | awk '/^Mem:/{print $2}')"; mem="${mem:-N/A}"
mem_avail="$(free -h 2>/dev/null | awk '/^Mem:/{print $7}')"; mem_avail="${mem_avail:-N/A}"
disk="$(df -h / 2>/dev/null | awk 'NR==2{print $4}')"; disk="${disk:-N/A}"

# 2. Seguranca SSH
root_login="N/A"; pass_auth="N/A"; ssh_port="22"
if [ -f /etc/ssh/sshd_config ]; then
  while read -r key val _; do
    case "$key" in
      PermitRootLogin)        root_login="$val" ;;
      PasswordAuthentication) pass_auth="$val" ;;
      Port)                   ssh_port="$val" ;;
    esac
  done < /etc/ssh/sshd_config
fi

# 3. Firewall e Atualizacoes
ufw_status="$(ufw status 2>/dev/null | head -n 1)"; ufw_status="${ufw_status:-N/A}"
updates="$(apt list --upgradable 2>/dev/null | wc -l)"; updates="${updates:-0}"

# 4. Docker Swarm
swarm="$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)"; swarm="${swarm:-N/A}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              RELATÓRIO DE AUDITORIA DEVOPS                   ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf '  SISTEMA:  %s (%s)\n' "$os_ver" "$kernel"
printf '  RECURSOS: %s vCPUs | %s RAM (%s livre) | %s Disco Disp.\n' "$cpu" "$mem" "$mem_avail" "$disk"
printf '  DOCKER:   Swarm %s\n' "$swarm"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "  SEGURANÇA SSH:"
printf '    - Porta: %s\n' "$ssh_port"
printf '    - Login Root: %s\n' "$root_login"
printf '    - Senha Ativa: %s\n' "$pass_auth"
printf '  FIREWALL: %s\n' "$ufw_status"
printf '  UPDATES:  %s pacotes pendentes\n' "$updates"
echo "╚══════════════════════════════════════════════════════════════╝"

echo ""
echo "📝 RECOMENDAÇÕES DEVOPS:"
[ "$root_login" = "yes" ] && echo "  [!] PERIGO: Login root permitido. Use chaves SSH e mude para 'prohibit-password'."
[ "$pass_auth" = "yes" ] && echo "  [!] RISCO: Autenticação por senha ativa. Desabilite em favor de chaves SSH."
[ "$ssh_port" = "22" ]   && echo "  [i] DICA: Considere mudar a porta SSH de 22 para uma porta alta (ex: 2222)."
case "$ufw_status" in *inactive*) echo "  [!] ALERTA: Firewall (UFW) está inativo." ;; esac
if [ "$updates" -gt 50 ] 2>/dev/null; then
  echo "  [i] INFO: Há $updates atualizações. Execute 'apt update && apt upgrade'."
fi
