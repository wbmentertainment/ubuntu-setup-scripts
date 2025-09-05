#!/bin/bash

cd /home/wbm/projects/media-nginx

docker compose down

umount -a -t cifs -l || true

rm -rf /home/wbm/projects/media-nginx/NAS
mkdir /home/wbm/projects/media-nginx/NAS

mount -t cifs -o username=admin1,password=Came2020,rw //192.168.1.111/media-nginx /home/wbm/projects/media-nginx/NAS

chmod -R 777 /home/wbm/projects/media-nginx/NAS

echo "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" | docker login ghcr.io -u dev-binhnx --password-stdin
docker compose up -d
docker image prune -f