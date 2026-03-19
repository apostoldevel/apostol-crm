#!/usr/bin/env bash
set -euo pipefail

echo
read -r -p "Recreate the database? (y/N): " ans
if [[ "${ans}" != "y" && "${ans}" != "Y" ]]; then
  echo "Cancel."
  exit 0
fi

./docker-down.sh

if docker volume inspect apostol-crm_postgresql >/dev/null 2>&1; then
  docker volume rm apostol-crm_postgresql
fi

docker compose up -d --force-recreate postgres
docker compose logs -fn 500
