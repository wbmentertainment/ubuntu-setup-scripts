#!/usr/bin/env bash
set -euo pipefail

echo "⚠️ CẢNH BÁO: Script này sẽ xóa TOÀN BỘ container, image, volume, network trong Docker."

read -rp "Bạn có chắc chắn muốn tiếp tục? (yes/no) [yes]: " confirm
confirm=${confirm:-yes}   # nếu để trống thì mặc định = yes

if [[ "$confirm" != "yes" ]]; then
  echo "❌ Huỷ thao tác."
  exit 1
fi

echo "----> Dừng tất cả container"
docker stop $(docker ps -aq) 2>/dev/null || true

echo "----> Xóa tất cả container"
docker rm -f $(docker ps -aq) 2>/dev/null || true

echo "----> Xóa tất cả image"
docker rmi -f $(docker images -q) 2>/dev/null || true

echo "----> Xóa tất cả volume"
docker volume rm -f $(docker volume ls -q) 2>/dev/null || true

echo "----> Xóa tất cả network (trừ mặc định: bridge, host, none)"
docker network rm $(docker network ls --format '{{.Name}}' | grep -vE 'bridge|host|none') 2>/dev/null || true

echo "✅ Docker đã được dọn sạch hoàn toàn."