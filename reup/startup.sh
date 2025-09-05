#!/bin/bash

cd /home/wbm/projects/media-reup

docker compose down

umount -a -t cifs -l || true

rm -rf /home/wbm/projects/media-reup/NAS
mkdir /home/wbm/projects/media-reup/NAS

mount -t cifs -o username=admin1,password=Came2020,rw //192.168.1.111/media-reup /home/wbm/projects/media-reup/NAS

chmod -R 777 /home/wbm/projects/media-reup/NAS

echo "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" | docker login ghcr.io -u dev-binhnx --password-stdin
docker compose up -d
docker image prune -f