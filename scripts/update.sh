#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "Pulling images..."
docker compose pull

echo "Restarting..."
docker compose up -d

docker compose ps
