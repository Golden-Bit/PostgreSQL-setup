#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
docker compose pull
docker compose up -d
docker compose ps
