#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
# Load env
set -a
source .env
set +a

echo "Checking postgres container status..."
docker inspect -f '{{.State.Status}}' pg

echo "Running pg_isready..."
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" pg pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"

echo "Running SQL smoke test..."
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" -i pg psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "select now();" >/dev/null

echo "OK"
