#!/bin/bash
# Script auto cấu hình IP tĩnh và SSH cho Ubuntu 24.04.2 LTS

### Phần 1: Cấu hình Netplan ###
# Lấy tên card mạng (bỏ lo, docker, veth)
IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E 'enp|ens|eth' | head -n1)

# Lấy MAC của card
MAC=$(cat /sys/class/net/$IFACE/address)

# Đặt IP tĩnh (có thể sửa lại cho phù hợp mạng bạn)
IPADDR="192.168.1.6/24"
GATEWAY="192.168.1.1"
DNS1="8.8.8.8"
DNS2="1.1.1.1"

# Backup file cloud-init nếu có
if [ -f /etc/netplan/50-cloud-init.yaml ]; then
  sudo mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
fi

# Sinh file netplan
sudo tee /etc/netplan/01-$IFACE.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFACE:
      match:
        macaddress: $MAC
      set-name: $IFACE
      dhcp4: no
      dhcp6: no
      accept-ra: no
      addresses:
        - $IPADDR
      nameservers:
        addresses: [$DNS1, $DNS2]
      routes:
        - to: default
          via: $GATEWAY
          metric: 100
EOF

# Quyền file netplan
sudo chown root:root /etc/netplan/01-$IFACE.yaml
sudo chmod 600 /etc/netplan/01-$IFACE.yaml

# Áp dụng Netplan
sudo netplan generate
sudo netplan apply

echo "✅ Netplan: đã cấu hình $IFACE ($IPADDR) với MAC $MAC"

### Phần 2: Cấu hình SSH ###
# Cài đặt OpenSSH Server nếu chưa có
sudo apt update -y
sudo apt install -y openssh-server

# Bật SSH khi khởi động
sudo systemctl enable --now ssh

# Backup sshd_config
if [ -f /etc/ssh/sshd_config ]; then
  sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
fi

# Ghi cấu hình SSH cơ bản
sudo tee /etc/ssh/sshd_config > /dev/null <<'EOF'
Port 22
PermitRootLogin no

#Authhentication:
PasswordAuthentication yes
AllowUsers '"$USER"'
EOF

# Restart SSH
sudo systemctl restart ssh

# Mở firewall cho SSH (nếu dùng ufw)
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow 22/tcp
  sudo ufw --force enable
fi

echo "✅ SSH: đã cài đặt và cấu hình xong (Port 22, root login disabled, user $USER)"

### Phần 3: Tạo SSH Key ###
SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/id_rsa"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ ! -f "$KEY_FILE" ]; then
  ssh-keygen -t rsa -b 4096 -C "github devops" -f "$KEY_FILE" -N ""
  echo "✅ SSH key đã được tạo: $KEY_FILE"
else
  echo "⚠️ Key $KEY_FILE đã tồn tại, bỏ qua bước tạo."
fi

cat "$KEY_FILE.pub" >> "$SSH_DIR/authorized_keys"
sort -u "$SSH_DIR/authorized_keys" -o "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/authorized_keys"
chmod 700 "$SSH_DIR"

echo "✅ SSH key đã được cấu hình cho user $USER"

### Phần 4: Cài đặt Docker CE ###
echo "🔄 Đang cài đặt Docker CE..."

# Gỡ Docker Snap nếu có
sudo snap remove docker 2>/dev/null || true

# Chuẩn bị môi trường
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Thêm GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Thêm repo Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Cài Docker CE + plugin
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Thêm user hiện tại vào nhóm docker
sudo usermod -aG docker $USER

echo "✅ Docker đã cài đặt thành công!"
docker --version
echo "ℹ️ Bạn cần logout/login hoặc chạy 'newgrp docker' để dùng docker không cần sudo."

echo "📌 SSH public key của bạn:"
cat "$KEY_FILE.pub"