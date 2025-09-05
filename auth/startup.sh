#!/bin/bash

cd /home/wbm/projects/media-auth

docker compose down
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
docker compose up -d
docker image prune -f