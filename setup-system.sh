#!/usr/bin/env bash
set -euo pipefail

# === Config ===
OWNER="${SUDO_USER:-$USER}"
BASE_DIR="/home/${OWNER}/projects"
MODULES=(auth editor reup nginx)

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Helpers ===
ensure_docker_network() {
  local net="$1"
  if ! command -v docker >/dev/null 2>&1; then
    echo "⚠️  Docker chưa cài, bỏ qua tạo network '${net}'."
    return 0
  fi
  if ! docker network ls --format '{{.Name}}' | grep -qw "$net"; then
    echo "----> Creating docker network: ${net}"
    sudo docker network create "$net"
  else
    echo "ℹ️  Docker network '${net}' đã tồn tại."
  fi
}

run_module() {
  local name="$1"
  local src="${REPO_DIR}/setup-${name}.sh"
  local dir="${BASE_DIR}/media-${name}"
  local dst="${dir}/setup-${name}.sh"

  echo "----> Chuẩn bị module: $name"
  sudo mkdir -p "$dir"
  sudo chown -R "${OWNER}:${OWNER}" "$dir"

  if [[ ! -f "$src" ]]; then
    echo "❌ Không tìm thấy $src trong repo"
    exit 1
  fi

  cp "$src" "$dst"
  chmod +x "$dst"

  echo "----> Chạy $dst"
  sudo bash "$dst"
}

# === Main ===
echo "===> Bước 1: Đảm bảo Docker network"
ensure_docker_network "nginx-net"

echo "===> Bước 2: Setup modules: ${MODULES[*]}"
for m in "${MODULES[@]}"; do
  run_module "$m"
done

echo "✅ Tất cả modules đã hoàn thành."