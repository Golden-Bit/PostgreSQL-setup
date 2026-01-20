#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 backups/pg_YYYY-MM-DD_HHMMSS.sql.gz" >&2
  exit 1
fi

FILE="$1"
if [[ ! -f "$FILE" ]]; then
  echo "File not found: $FILE" >&2
  exit 1
fi

set -a
source .env
set +a

echo "WARNING: this will overwrite data in database '$POSTGRES_DB'."
read -r -p "Type 'RESTORE' to continue: " CONF
if [[ "$CONF" != "RESTORE" ]]; then
  echo "Aborted."
  exit 1
fi

echo "Restoring from $FILE ..."
# Drop and recreate DB for a clean restore (safe for single DB setups)
# If you need a different strategy, edit this script.
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" pg psql -U "$POSTGRES_USER" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${POSTGRES_DB}' AND pid <> pg_backend_pid();" >/dev/null

docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" pg psql -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS \"${POSTGRES_DB}\";" >/dev/null

docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" pg psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE \"${POSTGRES_DB}\" OWNER \"${POSTGRES_USER}\";" >/dev/null

zcat "$FILE" | docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" -i pg psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null

echo "Restore completed."
