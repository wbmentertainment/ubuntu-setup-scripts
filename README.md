## Setup server:
```bash
git clone https://github.com/wbmentertainment/ubuntu-setup-scripts.git
cd /ubuntu-setup-scripts

chmod +x setup-server.sh
./setup-server.sh

chmod +x setup-system.sh
./setup-system.sh

chmod +x docker-clean.sh
./docker-clean.sh
```

Khôi phục (restore) khi cần
```bash
LATEST=$(ls -1t /home/wbm/projects/media-reup/backups/mongo-*.archive.gz | head -n1)
```
# hoặc backup trên NAS: /home/wbm/projects/media-reup/NAS/backup/...

```bash
echo "Restoring from $LATEST"
gunzip -c "$LATEST" | docker exec -i reup-db bash -lc "mongorestore --uri='${MONGO_URI}' --archive --drop"
```
