#!/usr/bin/env bash
set -euo pipefail

# ==== Config ====
OWNER="${SUDO_USER:-$USER}"
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
PROJECT_DIR="/home/${OWNER}/projects/media-auth"
SERVICE_FILE="/etc/systemd/system/media-auth.service"
BK_SERVICE_FILE="/etc/systemd/system/media-auth-backup.service"
TIMER_SERVICE_FILE="/etc/systemd/system/media-auth-backup.timer"
SRC_DIR="${REPO_DIR}/auth"

# Image cần dùng (chỉnh theo docker-compose.yml của bạn)
DOCKER_IMAGE="ghcr.io/wbmentertainment/auth:latest"

# ==== Chuẩn bị thư mục ====
sudo mkdir -p "$PROJECT_DIR"
sudo chown -R "${OWNER}:${OWNER}" "$PROJECT_DIR"

cp -f "${SRC_DIR}/backup-mongo.sh"        "${PROJECT_DIR}/backup-mongo.sh"
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
Description=Chạy media-auth khi khởi động
After=network-online.target docker.service
Wants=network-online.target docker.service

[Service]
Type=oneshot
User=${OWNER}
PermissionsStartOnly=true
ExecStartPre=-/usr/bin/umount -l ${PROJECT_DIR}/NAS
ExecStartPre=/usr/bin/mkdir -p ${PROJECT_DIR}/NAS
ExecStartPre=/usr/bin/mount -t cifs -o username=admin1,password=Came2020,vers=3.0,rw,dir_mode=0777,file_mode=0777 //192.168.1.111/media-auth ${PROJECT_DIR}/NAS
ExecStart=/bin/bash ${PROJECT_DIR}/startup.sh
StandardOutput=append:/var/log/media-auth.log
StandardError=append:/var/log/media-auth.log
RemainAfterExit=true
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WorkingDirectory=${PROJECT_DIR}

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 "$SERVICE_FILE"

# ==== Nạp & chạy service ====
sudo systemctl daemon-reload
sudo systemctl enable --now media-auth.service || true
sudo systemctl restart media-auth.service || true
sudo systemctl status media-auth.service --no-pager || true

# ==== Tạo Backup service ====
sudo tee "$BK_SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Backup Mongo (auth) to NAS
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
User=wbm
WorkingDirectory=/home/wbm/projects/media-auth
ExecStart=/bin/bash /home/wbm/projects/media-auth/backup-mongo.sh
EOF

sudo chmod 644 "$BK_SERVICE_FILE"

# ==== Nạp Backup service ====
sudo systemctl daemon-reload

# ==== Tạo Timer service ====
sudo tee "$TIMER_SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Run Backup Mongo (auth) daily at 02:00

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
Unit=media-auth-backup.service

[Install]
WantedBy=timers.target
EOF

sudo chmod 644 "$TIMER_SERVICE_FILE"

# ==== Nạp & chạy Timer service ====
sudo systemctl daemon-reload
sudo systemctl enable --now media-auth-backup.timer || true
systemctl list-timers | grep media-auth-backup || true