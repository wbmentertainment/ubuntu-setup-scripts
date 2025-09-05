#!/bin/bash

cd /home/wbm/projects/media-editor

docker compose down

umount -a -t cifs -l || true

rm -rf /home/wbm/projects/media-editor/NAS
mkdir /home/wbm/projects/media-editor/NAS

mount -t cifs -o username=admin1,password=Came2020,rw //192.168.1.111/media-editor /home/wbm/projects/media-editor/NAS

chmod -R 777 /home/wbm/projects/media-editor/NAS

echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
docker compose up -d
docker image prune -f