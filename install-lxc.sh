#!/usr/bin/env bash
# Ejecutar como root DENTRO de un contenedor LXC Debian 12/13, NUNCA en Proxmox host.
set -euo pipefail
APP="musicos"
TARGET="/opt/so2/$APP"
SERVICE="so2-$APP.service"
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if (( EUID != 0 )); then echo "Error: ejecutar como root dentro del CT LXC (sudo ./install-lxc.sh)" >&2; exit 1; fi
if [ ! -d /run/systemd/system ] || ! command -v systemctl >/dev/null; then
  echo 'El contenedor debe iniciar con systemd.' >&2
  exit 1
fi
# Evitar cambios accidentales en la VM Debian o en el host Proxmox.
if [ "$(systemd-detect-virt --container 2>/dev/null || true)" != "lxc" ]; then
  echo 'Por seguridad, ejecutar SOLO dentro de un contenedor LXC de Proxmox.' >&2
  exit 1
fi
if [ ! -f "$SOURCE/.env" ]; then echo "Falta $SOURCE/.env; copiar .env.example y definir DB_HOST." >&2; exit 1; fi
if grep -q '^DB_HOST=REEMPLAZAR_POR_IP_VM' "$SOURCE/.env"; then echo 'Editar DB_HOST en .env.' >&2; exit 1; fi
. /etc/os-release
if [ "${ID:-}" != "debian" ]; then echo 'Este instalador fue preparado para Debian en LXC.' >&2; exit 1; fi
apt-get update
apt-get install -y python3 python3-venv ca-certificates
if ! id so2app >/dev/null 2>&1; then useradd --system --user-group --home-dir /nonexistent --shell /usr/sbin/nologin so2app; fi
install -d -m 0755 -o root -g root "$TARGET"
cp "$SOURCE/app.py" "$SOURCE/requirements.txt" "$TARGET/"
rm -rf "$TARGET/templates" "$TARGET/static"
cp -R "$SOURCE/templates" "$SOURCE/static" "$TARGET/"
install -m 0640 -o root -g so2app "$SOURCE/.env" "$TARGET/.env"
python3 -m venv "$TARGET/.venv"
"$TARGET/.venv/bin/python" -m pip install --no-cache-dir -r "$TARGET/requirements.txt"
cat > "/etc/systemd/system/$SERVICE" <<UNIT
[Unit]
Description=SO2 TPN4 - Backstage Flask
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=so2app
Group=so2app
WorkingDirectory=$TARGET
EnvironmentFile=$TARGET/.env
Environment=PYTHONDONTWRITEBYTECODE=1
Environment=PYTHONUNBUFFERED=1
ExecStart=$TARGET/.venv/bin/gunicorn --workers 1 --threads 2 --bind 0.0.0.0:8000 --access-logfile - --error-logfile - app:app
Restart=on-failure
RestartSec=2
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=full

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now "$SERVICE"
systemctl restart "$SERVICE"
echo "OK: $SERVICE instalado. Probar curl http://127.0.0.1:8000/health"
