#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
set -a
source .env
set +a

mkdir -p backups
TS=$(date +%F_%H%M%S)
OUT="backups/pg_${TS}.sql.gz"

echo "Creating backup: $OUT"
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" pg pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip -9 > "$OUT"

echo "Backup written: $OUT"
