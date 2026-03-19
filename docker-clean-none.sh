#!/usr/bin/env bash
set -euo pipefail

echo "Dangling images (<none>):"
docker images -f "dangling=true"

echo
read -r -p "Удалить ВСЕ эти образы? (y/N): " ans
if [[ "${ans}" != "y" && "${ans}" != "Y" ]]; then
  echo "Отмена."
  exit 0
fi

# Удаляем все dangling-образы
docker rmi $(docker images -q -f "dangling=true") 2>/dev/null || true

echo "Готово. Остаток dangling images:"
docker images -f "dangling=true"
