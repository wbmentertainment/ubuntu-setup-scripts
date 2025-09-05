#!/bin/bash
# Script setup systemd service media-auth

PROJECT_DIR="/home/wbm/projects/media-auth"
SERVICE_FILE="/etc/systemd/system/media-auth.service"
STARTUP_SCRIPT="$PROJECT_DIR/startup.sh"

# Tạo thư mục project nếu chưa có
sudo mkdir -p "$PROJECT_DIR"
sudo chown -R wbm:wbm "$PROJECT_DIR"

# Tải file startup.sh (bạn thay link tải vào nếu cần)
# Ví dụ giả định: https://example.com/startup.sh
# sudo curl -o "$STARTUP_SCRIPT" https://example.com/startup.sh

# Nếu đã có sẵn startup.sh thì chỉ cần chmod
sudo chmod +x "$STARTUP_SCRIPT"

# Tạo systemd service file
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Media Auth Service
After=network.target

[Service]
Type=simple
User=wbm
ExecStart=/bin/bash $STARTUP_SCRIPT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Set quyền service file
sudo chmod 644 "$SERVICE_FILE"

# Thêm rule vào sudoers (chỉ cho phép chạy startup.sh không cần mật khẩu)
if ! sudo grep -q "$STARTUP_SCRIPT" /etc/sudoers; then
  echo "wbm ALL=(ALL) NOPASSWD: /bin/bash $STARTUP_SCRIPT" | sudo EDITOR='tee -a' visudo >/dev/null
fi

# Reload systemd và bật service
sudo systemctl daemon-reload
sudo systemctl enable media-auth.service
sudo systemctl start media-auth.service

# Hiển thị trạng thái
sudo systemctl status media-auth.service --no-pager