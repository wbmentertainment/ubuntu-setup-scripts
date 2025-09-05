# /home/wbm/projects/media-reup/backup-mongo.sh
#!/usr/bin/env bash
set -euo pipefail

# ==== CONFIG ====
MONGO_CONTAINER="${MONGO_CONTAINER:-reup-db}"   # tên container primary
MONGO_URI="${MONGO_URI:-mongodb://root:dGcnRzGcNc8RXx6u@reup-db:27017/reup?replicaSet=replicaset&authSource=admin&retryWrites=true&w=majority}"
NAS_DIR="${NAS_DIR:-/home/wbm/projects/media-auth/NAS/database}"  # thư mục NAS đã mount sẵn
RETENTION_DAYS="${RETENTION_DAYS:-3}"  # số ngày giữ bản backup
# ==== END CONFIG ====

DATE="$(date +%F-%H%M%S)"
FINAL="${NAS_DIR}/mongo-${DATE}.archive.gz"
PART="${FINAL}.part"

echo "==> Backup to NAS: ${FINAL}"

# 1) Đảm bảo NAS ghi được
mkdir -p "${NAS_DIR}"
touch "${NAS_DIR}/.write_test" 2>/dev/null || {
  echo "❌ NAS_DIR không ghi được: ${NAS_DIR}"; exit 1;
}
rm -f "${NAS_DIR}/.write_test"

# 2) Tạo file tạm (.part) rồi move sang tên cuối khi hoàn tất
#    Ưu tiên dùng mongodump trong container; nếu không có thì dùng image mongo:7 để dump
if docker exec "${MONGO_CONTAINER}" bash -lc 'command -v mongodump >/dev/null'; then
  echo "==> Using mongodump inside ${MONGO_CONTAINER}"
  docker exec "${MONGO_CONTAINER}" bash -lc \
    "mongodump --uri='${MONGO_URI}' --archive | gzip -c" > "${PART}"
else
  echo "==> mongodump not found in container; using helper image mongo:7"
  docker run --rm --network "container:${MONGO_CONTAINER}" mongo:7 \
    bash -lc "mongodump --uri='${MONGO_URI}' --archive | gzip -c" > "${PART}"
fi

# 3) Đổi tên atomically
mv -f "${PART}" "${FINAL}"
echo "✅ Wrote ${FINAL}"

# 4) Dọn bản cũ trên NAS
find "${NAS_DIR}" -type f -name 'mongo-*.archive.gz' -mtime +"${RETENTION_DAYS}" -delete || true