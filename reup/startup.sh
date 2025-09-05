#!/bin/bash

cd /home/wbm/projects/media-reup

docker compose down

umount -a -t cifs -l || true
rm -rf NAS
mkdir -p NAS
mount -t cifs -o username=admin1,password=Came2020,vers=3.0,rw,iocharset=utf8,uid=1001,gid=1001,dir_mode=0777,file_mode=0777,noperm //192.168.1.111/media-reup NAS

echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
docker compose up -d
docker image prune -f