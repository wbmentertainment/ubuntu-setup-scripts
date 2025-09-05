#!/bin/bash

cd /home/wbm/projects/media-nginx

docker compose down

umount -l /home/wbm/projects/media-nginx/NAS 2>/dev/null || true

rm -rf /home/wbm/projects/media-nginx/NAS
mkdir /home/wbm/projects/media-nginx/NAS

mount -t cifs -o username=admin1,password=Came2020,vers=3.0,rw,dir_mode=0777,file_mode=0777 //192.168.1.111/media-nginx /home/wbm/projects/media-nginx/NAS


echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
docker compose up -d
docker image prune -f