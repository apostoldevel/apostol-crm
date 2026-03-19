#!/usr/bin/env bash
set -euo pipefail

#------------------------------------------------------------------------------
# Project Example — SQL Test Runner (Docker)
#
# Usage:
#   ./db/test/run.sh                              # Run all tests
#   ./db/test/run.sh db/test/sql/balance_test.sql  # Run one file
#   ./db/test/run.sh --keep                        # Keep container after run
#   ./db/test/run.sh --local                       # Run on host (requires sudo)
#------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_DB="example"
TEST_DB="${EXAMPLE_TEST_DB:-example_test}"
DB_USER="kernel"
DB_HOST="${PGHOST:-localhost}"
DB_PORT="${PGPORT:-5432}"

IMAGE_NAME="example-pgtap"
CONTAINER_NAME="example-test-$$"

KEEP=false
LOCAL_MODE=false
TEST_FILES=()

for arg in "$@"; do
  case "$arg" in
    --keep)  KEEP=true ;;
    --local) LOCAL_MODE=true ;;
    *)       TEST_FILES+=("$arg") ;;
  esac
done

# If no specific files, run all test files
if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
  while IFS= read -r -d '' f; do
    TEST_FILES+=("$f")
  done < <(find "$SCRIPT_DIR/sql" -name '*_test.sql' -print0 | sort -z)
fi

if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
  echo "No test files found."
  exit 1
fi

#==============================================================================
# LOCAL MODE — run directly on host PostgreSQL (requires sudo for DB ops)
#==============================================================================
run_local() {
  echo "==> [local] Creating test database '$TEST_DB' from template '$SOURCE_DB'..."

  sudo -u postgres psql -d template1 -q -c "
    SELECT pg_terminate_backend(pid)
      FROM pg_stat_activity
     WHERE datname = '$TEST_DB' AND pid <> pg_backend_pid();
  " 2>/dev/null || true
  sudo -u postgres psql -d template1 -q -c "DROP DATABASE IF EXISTS $TEST_DB;" 2>/dev/null || true
  sudo -u postgres psql -d template1 -q -c "CREATE DATABASE $TEST_DB TEMPLATE $SOURCE_DB;"

  echo "==> [local] Installing pgTAP extension..."
  sudo -u postgres psql -d "$TEST_DB" -q -c "CREATE EXTENSION IF NOT EXISTS pgtap;"

  echo "==> [local] Installing test helpers..."
  psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$TEST_DB" -q -f "$SCRIPT_DIR/setup.sql"

  echo "==> [local] Loading fixtures..."
  psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$TEST_DB" -q -f "$SCRIPT_DIR/fixtures.sql"

  echo "==> [local] Running ${#TEST_FILES[@]} test file(s)..."
  echo ""

  local EXIT_CODE=0
  if command -v pg_prove &>/dev/null; then
    pg_prove -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$TEST_DB" --verbose "${TEST_FILES[@]}" || EXIT_CODE=$?
  else
    for tf in "${TEST_FILES[@]}"; do
      echo "--- $tf ---"
      psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$TEST_DB" -f "$tf" || EXIT_CODE=$?
      echo ""
    done
  fi

  if [[ "$KEEP" = false ]]; then
    echo ""
    echo "==> [local] Dropping test database '$TEST_DB'..."
    sudo -u postgres psql -d template1 -q -c "
      SELECT pg_terminate_backend(pid)
        FROM pg_stat_activity
       WHERE datname = '$TEST_DB' AND pid <> pg_backend_pid();
    " 2>/dev/null || true
    sudo -u postgres psql -d template1 -q -c "DROP DATABASE IF EXISTS $TEST_DB;"
  else
    echo ""
    echo "==> [local] Test database '$TEST_DB' preserved (--keep)."
  fi

  return $EXIT_CODE
}

#==============================================================================
# DOCKER MODE — temporary container (default)
#==============================================================================
run_docker() {
  local PG_SUPER="postgres"
  local PG_USER="kernel"
  # Use same DB name as source so current_database() matches audience records
  TEST_DB="$SOURCE_DB"

  # Build test image if needed
  echo "==> Building test image '$IMAGE_NAME'..."
  docker build -q -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR" > /dev/null

  # Dump host database (no owner/acl — everything runs as postgres in container)
  echo "==> Dumping host database '$SOURCE_DB'..."
  DUMP_DIR=$(mktemp -d /tmp/example_test_XXXXXX)
  trap "rm -rf $DUMP_DIR" EXIT

  pg_dump -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$SOURCE_DB" \
    --no-owner --no-acl > "$DUMP_DIR/dump.sql"

  # Start container
  echo "==> Starting test container '$CONTAINER_NAME'..."
  docker run -d --name "$CONTAINER_NAME" \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_HOST_AUTH_METHOD=trust \
    "$IMAGE_NAME" > /dev/null

  # Wait for postgres to be ready
  echo -n "==> Waiting for PostgreSQL... "
  for i in $(seq 1 30); do
    if docker exec "$CONTAINER_NAME" pg_isready -U "$PG_SUPER" -q 2>/dev/null; then
      echo "ready."
      break
    fi
    if [[ $i -eq 30 ]]; then
      echo "timeout!"
      docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1
      exit 1
    fi
    sleep 1
  done

  # Create application roles
  echo "==> Creating database roles..."
  docker exec "$CONTAINER_NAME" psql -U "$PG_SUPER" -q -c "
    CREATE ROLE kernel WITH LOGIN SUPERUSER PASSWORD 'kernel';
    CREATE ROLE admin WITH LOGIN PASSWORD 'admin';
    CREATE ROLE daemon WITH LOGIN PASSWORD 'daemon';
    CREATE ROLE apibot WITH LOGIN PASSWORD 'apibot';
    CREATE ROLE ntrip WITH LOGIN PASSWORD 'ntrip';
  "

  # Create database and restore dump (as superuser, dump has no owner/acl)
  echo "==> Restoring database into '$TEST_DB'..."
  docker exec "$CONTAINER_NAME" psql -U "$PG_SUPER" -q \
    -c "CREATE DATABASE $TEST_DB OWNER $PG_USER;"
  docker exec "$CONTAINER_NAME" psql -U "$PG_SUPER" -d "$TEST_DB" -q \
    -c "ALTER DATABASE $TEST_DB SET search_path TO \"\\\$user\", kernel, public;"

  docker cp "$DUMP_DIR/dump.sql" "$CONTAINER_NAME:/tmp/dump.sql"
  docker exec "$CONTAINER_NAME" psql -U "$PG_SUPER" -d "$TEST_DB" -q -o /dev/null -f /tmp/dump.sql

  # Install pgTAP (requires superuser) + test helpers + fixtures (as kernel)
  echo "==> Installing pgTAP and test helpers..."
  docker exec "$CONTAINER_NAME" psql -U "$PG_SUPER" -d "$TEST_DB" -q \
    -c "CREATE EXTENSION IF NOT EXISTS pgtap;"

  docker cp "$SCRIPT_DIR/setup.sql" "$CONTAINER_NAME:/tmp/setup.sql"
  docker exec "$CONTAINER_NAME" psql -U "$PG_USER" -d "$TEST_DB" -q -f /tmp/setup.sql

  docker cp "$SCRIPT_DIR/fixtures.sql" "$CONTAINER_NAME:/tmp/fixtures.sql"
  docker exec "$CONTAINER_NAME" psql -U "$PG_USER" -d "$TEST_DB" -q -f /tmp/fixtures.sql

  # Copy test files and run
  echo "==> Running ${#TEST_FILES[@]} test file(s)..."
  echo ""

  docker exec "$CONTAINER_NAME" mkdir -p /tmp/tests
  for tf in "${TEST_FILES[@]}"; do
    docker cp "$tf" "$CONTAINER_NAME:/tmp/tests/$(basename "$tf")"
  done

  local EXIT_CODE=0

  # Prefer pg_prove if available in container
  if docker exec "$CONTAINER_NAME" which pg_prove &>/dev/null; then
    local PG_PROVE_FILES=()
    for tf in "${TEST_FILES[@]}"; do
      PG_PROVE_FILES+=("/tmp/tests/$(basename "$tf")")
    done
    docker exec "$CONTAINER_NAME" \
      pg_prove -U "$PG_USER" -d "$TEST_DB" --verbose "${PG_PROVE_FILES[@]}" || EXIT_CODE=$?
  else
    for tf in "${TEST_FILES[@]}"; do
      echo "--- $(basename "$tf") ---"
      docker exec "$CONTAINER_NAME" \
        psql -U "$PG_USER" -d "$TEST_DB" -f "/tmp/tests/$(basename "$tf")" || EXIT_CODE=$?
      echo ""
    done
  fi

  # Cleanup
  if [[ "$KEEP" = false ]]; then
    echo ""
    echo "==> Removing test container..."
    docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1
  else
    echo ""
    echo "==> Container '$CONTAINER_NAME' preserved (--keep). Connect with:"
    echo "    docker exec -it $CONTAINER_NAME psql -U $PG_USER -d $TEST_DB"
  fi

  return $EXIT_CODE
}

#==============================================================================
# Main
#==============================================================================
EXIT_CODE=0

if [[ "$LOCAL_MODE" = true ]]; then
  run_local || EXIT_CODE=$?
else
  run_docker || EXIT_CODE=$?
fi

echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
  echo "All tests passed."
else
  echo "Some tests FAILED (exit code: $EXIT_CODE)."
fi

exit $EXIT_CODE
