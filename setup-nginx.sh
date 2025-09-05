#!/usr/bin/env bash
set -euo pipefail

# ==== Config ====
OWNER="${SUDO_USER:-$USER}"
PROJECT_DIR="/home/${OWNER}/projects/media-nginx"
SERVICE_FILE="/etc/systemd/system/media-nginx.service"

# Link RAW đến repo (đặt đúng username/repo/branch)
BASE_RAW="https://raw.githubusercontent.com/wbmentertainment/ubuntu-setup-scripts/main/nginx"
URL_STARTUP="${BASE_RAW}/startup.sh"
URL_COMPOSE="${BASE_RAW}/docker-compose.yml"

# ==== Chuẩn bị thư mục ====
sudo mkdir -p "$PROJECT_DIR"
sudo chown -R "${OWNER}:${OWNER}" "$PROJECT_DIR"

# ==== Tải file cần thiết ====
echo "-> Download startup.sh: ${URL_STARTUP}"
curl -fsSL "${URL_STARTUP}" -o "${PROJECT_DIR}/startup.sh"

echo "-> Download docker-compose.yml: ${URL_COMPOSE}"
curl -fsSL "${URL_COMPOSE}" -o "${PROJECT_DIR}/docker-compose.yml"

# Quyền thực thi cho startup.sh
sudo chown "${OWNER}:${OWNER}" "${PROJECT_DIR}/startup.sh" "${PROJECT_DIR}/docker-compose.yml"
sudo chmod +x "${PROJECT_DIR}/startup.sh"

# ==== Tạo service ====
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Chạy media-nginx khi khởi động
After=network-online.target docker.service
Wants=network-online.target docker.service

[Service]
Type=oneshot
User=${OWNER}
ExecStart=/bin/bash ${PROJECT_DIR}/startup.sh
RemainAfterExit=true
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WorkingDirectory=${PROJECT_DIR}

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 "$SERVICE_FILE"

# ==== Nạp & chạy service ====
sudo systemctl daemon-reload
sudo systemctl enable --now media-nginx.service
sudo systemctl status media-nginx.service --no-pager