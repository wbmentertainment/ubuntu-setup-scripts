#!/bin/bash

cd /home/wbm/projects/media-auth

docker compose down

umount -a -t cifs -l || true

rm -rf /home/wbm/projects/media-auth/NAS
mkdir /home/wbm/projects/media-auth/NAS

mount -t cifs -o username=admin1,password=Came2020,rw //192.168.1.111/media-auth /home/wbm/projects/media-auth/NAS

chmod -R 777 /home/wbm/projects/media-auth/NAS

echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
docker compose up -d
docker image prune -f