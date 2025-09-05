#!/usr/bin/env bash
set -euo pipefail

# ==== Config ====
OWNER="${SUDO_USER:-$USER}"
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
PROJECT_DIR="/home/${OWNER}/projects/media-editor"
SERVICE_FILE="/etc/systemd/system/media-editor.service"
SRC_DIR="${REPO_DIR}/editor"

# Image cần dùng (chỉnh theo docker-compose.yml của bạn)
DOCKER_IMAGE="ghcr.io/wbmentertainment/editor:latest"

# ==== Chuẩn bị thư mục ====
sudo mkdir -p "$PROJECT_DIR"
sudo chown -R "${OWNER}:${OWNER}" "$PROJECT_DIR"

cp -f "${SRC_DIR}/startup.sh"        "${PROJECT_DIR}/startup.sh"
cp -f "${SRC_DIR}/docker-compose.yml" "${PROJECT_DIR}/docker-compose.yml"

# Quyền thực thi cho startup.sh
sudo chown "${OWNER}:${OWNER}" "${PROJECT_DIR}/startup.sh" "${PROJECT_DIR}/docker-compose.yml"
sudo chmod +x "${PROJECT_DIR}/startup.sh"

# Kiểm tra & pull image nếu chưa có
if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
  echo "----> Docker image $DOCKER_IMAGE chưa có, tiến hành pull..."
  echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
  docker pull "$DOCKER_IMAGE"
else
  echo "ℹ️  Docker image $DOCKER_IMAGE đã tồn tại, bỏ qua pull."
fi

# ==== Tạo service ====
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Chạy media-editor khi khởi động
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
sudo systemctl enable --now media-editor.service
sudo systemctl status media-editor.service --no-pager