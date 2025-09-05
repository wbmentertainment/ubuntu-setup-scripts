#!/usr/bin/env bash
set -euo pipefail

# === Config ===
GITHUB_USER="wbmentertainment"
REPO="ubuntu-setup-scripts"
BRANCH="main"
BASE_URL="https://cdn.jsdelivr.net/gh/${GITHUB_USER}/${REPO}@${BRANCH}"
OWNER="${SUDO_USER:-$USER}"
BASE_DIR="/home/${OWNER}/projects"

MODULES=(auth editor reup nginx)

# === Helpers ===
fetch_and_run() {
  local name="$1"
  local dir="${BASE_DIR}/media-${name}"
  local file="${dir}/setup-${name}.sh"
  local url="${BASE_URL}/setup-${name}.sh"

  echo "----> Preparing dir ${dir}"
  sudo mkdir -p "$dir"
  sudo chown -R wbm:wbm "$dir"

  echo "----> Downloading ${name}: ${url} -> ${file}"
  curl -fsSL "$url" -o "$file"

  echo "----> Executing ${file}"
  chmod +x "$file"
  sudo bash "$file"
}

ensure_docker_network() {
  local net="$1"
  if ! command -v docker >/dev/null 2>&1; then
    echo "⚠️ Docker chưa cài, bỏ qua tạo network '${net}'."
    return 0
  fi
  if ! docker network ls --format '{{.Name}}' | grep -qw "$net"; then
    echo "----> Creating docker network: ${net}"
    sudo docker network create "$net"
  else
    echo "ℹ️ Docker network '${net}' đã tồn tại."
  fi
}

# === Main ===
echo "===> Đảm bảo docker network nginx-net tồn tại"
ensure_docker_network "nginx-net"

echo "===> Running setup for modules: ${MODULES[*]}"
for m in "${MODULES[@]}"; do
  fetch_and_run "$m"
done

echo "✅ All modules completed."