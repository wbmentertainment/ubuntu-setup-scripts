# /home/wbm/projects/media-auth/backup-mongo.sh
#!/usr/bin/env bash
set -euo pipefail

# === config ===
DATE="$(date +%F-%H%M%S)"
LOCAL_BK_DIR="/home/wbm/projects/media-auth/backups"
NAS_BK_DIR="/home/wbm/projects/media-auth/NAS/database"  # thư mục NAS đã mount
CONTAINER="zodi-auth-db"         # primary container
RETENTION_DAYS=3                 # số ngày giữ bản local
MONGO_URI="mongodb://root:dGcnRzGcNc8RXx6u@zodi-auth-db:27017/zodi-auth?replicaSet=replicaset&authSource=admin&retryWrites=true&w=majority&enableUtf8Validation=false"  # đổi pass nếu khác

# === prepare ===
mkdir -p "$LOCAL_BK_DIR"
mkdir -p "$NAS_BK_DIR" || true    # NAS có thể là automount, thư mục sẽ xuất hiện khi truy cập

ARCHIVE_FILE="${LOCAL_BK_DIR}/mongo-${DATE}.archive.gz"

# === dump (dùng mongodump trong container) ===
echo "==> Dumping MongoDB to ${ARCHIVE_FILE}"
docker exec "${CONTAINER}" bash -lc \
  "mongodump --uri='${MONGO_URI}' --archive | gzip -c" > "${ARCHIVE_FILE}"

# === sync to NAS ===
echo "==> Sync to NAS: ${NAS_BK_DIR}"
rsync -a --partial --inplace "${ARCHIVE_FILE}" "${NAS_BK_DIR}/"

# === prune local old backups ===
echo "==> Prune local backups > ${RETENTION_DAYS} days"
find "${LOCAL_BK_DIR}" -type f -name 'mongo-*.archive.gz' -mtime +${RETENTION_DAYS} -delete

echo "✅ Done: ${ARCHIVE_FILE}"
