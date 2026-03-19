#!/bin/bash
#
# migrate.sh — Automatic patch migration for db-platform projects.
#
# Scans platform and configuration patch directories, compares against
# db.patch_log table, and applies only unapplied patches in sorted order.
# After patches, runs platform/update.psql + configuration/update.psql.
#
# Multi-phase patches:
#   Patches containing \connect are split into phases at each \connect boundary.
#   Each phase is executed and checkpointed independently (name#0, name#1, ...),
#   so a crash mid-patch resumes from the last successful phase on re-run.
#
# Location: db/migrate.sh
# Usage:    cd db && ./migrate.sh [OPTIONS]
#
# Options:
#   --baseline       Mark all patches as applied without executing them
#   --dry-run        Show what would be applied, but do nothing
#   --no-update      Skip update.psql after patches (routines/views)
#   --force-update   Run update even if no patches were applied
#   --status         Show applied/pending patches and exit
#
# Environment:
#   PSQL_KERNEL     psql command for kernel user (default: psql -U kernel)
#

set -e

# ── Paths ─────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"   # .../db/
SQL_DIR="$SCRIPT_DIR/sql"                      # .../db/sql/
PHASE_DIR="$SQL_DIR/.migrate_phases"           # temp dir for split phases

# ── Connection ────────────────────────────────────────────────────────────────
# kernel is the database owner — all operations run as kernel by default.
# Override via PSQL_KERNEL env var (e.g., Docker sets -h/-p/-U flags).

PSQL_KERNEL="${PSQL_KERNEL:-psql -U kernel}"

psql_run() {
  $PSQL_KERNEL "$@"
}

# ── Parse arguments ───────────────────────────────────────────────────────────

BASELINE=false
DRY_RUN=false
NO_UPDATE=false
FORCE_UPDATE=false
STATUS_ONLY=false

for arg in "$@"; do
  case $arg in
    --baseline)      BASELINE=true ;;
    --dry-run)       DRY_RUN=true ;;
    --no-update)     NO_UPDATE=true ;;
    --force-update)  FORCE_UPDATE=true ;;
    --status)        STATUS_ONLY=true ;;
    --help|-h)
      sed -n '2,/^$/{ s/^# \?//; p }' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

# ── Determine dbname from sets.psql ──────────────────────────────────────────

DB_NAME=$(grep -oP '\\set dbname \K\w+' "$SQL_DIR/sets.psql" 2>/dev/null || true)

if [[ -z "$DB_NAME" ]]; then
  echo "ERROR: Cannot determine dbname from $SQL_DIR/sets.psql"
  exit 1
fi

# ── Ensure db.patch_log table exists ─────────────────────────────────────────

psql_run -d "$DB_NAME" -v ON_ERROR_STOP=1 -q <<'EOSQL'
CREATE TABLE IF NOT EXISTS db.patch_log (
  name        text PRIMARY KEY,
  applied_at  timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE db.patch_log IS 'Applied database patches (migration tracking).';
EOSQL

# ── Load applied patches into associative array ──────────────────────────────

declare -A APPLIED_MAP

while IFS= read -r line; do
  [[ -n "$line" ]] && APPLIED_MAP["$line"]=1
done < <(psql_run -d "$DB_NAME" -t -A -c "SELECT name FROM db.patch_log ORDER BY name")

is_applied() {
  [[ -v APPLIED_MAP["$1"] ]]
}

mark_applied() {
  psql_run -d "$DB_NAME" -v ON_ERROR_STOP=1 -q \
    -c "INSERT INTO db.patch_log (name) VALUES ('$1') ON CONFLICT DO NOTHING"
  APPLIED_MAP["$1"]=1
}

# ── Phase splitting ──────────────────────────────────────────────────────────
#
# Given a patch file, detect \connect lines. If none — single phase.
# If present — split into N+1 phases at each \connect boundary.
#
# Phase 0: everything before first \connect (runs as current user, typically kernel)
# Phase N: starts with \connect line (determines target user), includes all lines until next \connect
#
# Each phase is written to a temp .psql file with \\ir sets.psql prepended.
# The \connect line itself determines which psql command to use for that phase.

split_into_phases() {
  local patch_file="$1"   # absolute path to patch file
  local phase_prefix="$2" # prefix for temp files: .migrate_phases/<name>

  rm -rf "$PHASE_DIR"
  mkdir -p "$PHASE_DIR"

  local phase_num=0
  local current_file="$PHASE_DIR/${phase_prefix}_phase_${phase_num}.psql"
  local has_connect=false

  # Start phase 0 with sets.psql
  echo "\\ir $SQL_DIR/sets.psql" > "$current_file"

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Detect \connect lines
    if [[ "$line" =~ ^\\connect[[:space:]] ]]; then
      has_connect=true
      phase_num=$((phase_num + 1))
      current_file="$PHASE_DIR/${phase_prefix}_phase_${phase_num}.psql"
      # New phase starts with the \connect line itself + sets.psql reload
      echo "\\ir $SQL_DIR/sets.psql" > "$current_file"
      echo "$line" >> "$current_file"
    else
      echo "$line" >> "$current_file"
    fi
  done < "$patch_file"

  if $has_connect; then
    echo "$((phase_num + 1))"
  else
    echo "1"
  fi
}

# Determine psql command for a phase file based on \connect target.
# All phases run via PSQL_KERNEL (kernel is the DB owner).
# The \connect directive inside the patch switches the active user.
psql_for_phase() {
  echo "PSQL_KERNEL"
}

# ── Collect patches ──────────────────────────────────────────────────────────

PATCHES=()

# Platform patches: sql/platform/patch/v*/*.sql
for version_dir in $(find "$SQL_DIR/platform/patch" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort); do
  ver=$(basename "$version_dir")
  for f in $(find "$version_dir" -maxdepth 1 -name 'P*.sql' 2>/dev/null | sort); do
    name=$(basename "$f" .sql)
    PATCHES+=("0-$ver-$name|platform/$ver/$name|platform/patch/$ver/$name.sql")
  done
done

# Configuration patches: sql/configuration/*/patch/P*.{psql,sql}
for patch_dir in $(find "$SQL_DIR/configuration" -path '*/patch' -type d 2>/dev/null | sort); do
  cfg_name=$(basename "$(dirname "$patch_dir")")
  for f in $(find "$patch_dir" -maxdepth 1 \( -name 'P*.psql' -o -name 'P*.sql' \) 2>/dev/null | sort); do
    ext="${f##*.}"
    name=$(basename "$f" ".$ext")
    rel="${f#"$SQL_DIR/"}"
    PATCHES+=("1-$cfg_name-$name|config/$cfg_name/$name|$rel")
  done
done

# ── Status mode ──────────────────────────────────────────────────────────────

if $STATUS_ONLY; then
  echo
  echo "Database: $DB_NAME"
  echo "Applied patches: ${#APPLIED_MAP[@]}"
  echo
  pending=0
  for entry in "${PATCHES[@]}"; do
    IFS='|' read -r _ patch_name patch_rel <<< "$entry"
    if is_applied "$patch_name"; then
      echo "  [x] $patch_name"
    else
      echo "  [ ] $patch_name  ($patch_rel)"
      pending=$((pending + 1))
    fi
  done
  echo
  echo "Pending: $pending"
  exit 0
fi

# ── Apply patches ────────────────────────────────────────────────────────────

echo
echo "============================================"
echo " Patch migration — $DB_NAME"
echo " $(date -Iseconds)"
echo "============================================"
echo

TOTAL=${#PATCHES[@]}
APPLIED_COUNT=0
SKIPPED=0

for entry in "${PATCHES[@]}"; do
  IFS='|' read -r _ patch_name patch_rel <<< "$entry"

  if is_applied "$patch_name"; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if $DRY_RUN; then
    echo "  WOULD APPLY: $patch_name  ($patch_rel)"
    APPLIED_COUNT=$((APPLIED_COUNT + 1))
    continue
  fi

  if $BASELINE; then
    echo "  BASELINE: $patch_name"
    mark_applied "$patch_name"
    APPLIED_COUNT=$((APPLIED_COUNT + 1))
    continue
  fi

  echo "  APPLY: $patch_name ..."

  patch_file="$SQL_DIR/$patch_rel"

  # Check if patch has \connect lines
  if grep -q '^\\connect' "$patch_file"; then
    # ── Multi-phase execution with checkpoints ──
    phase_count=$(split_into_phases "$patch_file" "patch")

    echo "    (multi-phase: $phase_count phases)"

    for ((phase_idx=0; phase_idx<phase_count; phase_idx++)); do
      phase_name="${patch_name}#${phase_idx}"
      phase_file="$PHASE_DIR/patch_phase_${phase_idx}.psql"

      if is_applied "$phase_name"; then
        echo "    phase $phase_idx: skipped (already applied)"
        continue
      fi

      if [[ ! -s "$phase_file" ]] || [[ $(wc -l < "$phase_file") -le 1 ]]; then
        # Empty phase (only sets.psql line) — mark and skip
        mark_applied "$phase_name"
        echo "    phase $phase_idx: skipped (empty)"
        continue
      fi

      # Determine which psql command to use
      psql_var=$(psql_for_phase "$phase_file")
      psql_cmd="${!psql_var}"

      echo "    phase $phase_idx: applying (${psql_var})..."

      if $psql_cmd -d "$DB_NAME" -v ON_ERROR_STOP=1 -q -f "$phase_file" 2>&1; then
        mark_applied "$phase_name"
        echo "    phase $phase_idx: OK"
      else
        echo
        echo "  FAILED: $patch_name (phase $phase_idx)"
        echo "  Phases 0..$((phase_idx - 1)) committed and checkpointed."
        echo "  Fix the issue and re-run — completed phases will be skipped."
        rm -rf "$PHASE_DIR"
        exit 1
      fi
    done

    rm -rf "$PHASE_DIR"

  else
    # ── Single-phase execution ──
    local_wrapper="$SQL_DIR/.migrate_run.psql"
    cat > "$local_wrapper" <<WRAPPER
\\ir sets.psql
\\ir $patch_rel
WRAPPER

    if $PSQL_KERNEL -d "$DB_NAME" -v ON_ERROR_STOP=1 -q -f "$local_wrapper" 2>&1; then
      rm -f "$local_wrapper"
    else
      rm -f "$local_wrapper"
      echo
      echo "  FAILED: $patch_name"
      echo "  Migration stopped. Fix the issue and re-run."
      exit 1
    fi
  fi

  # Mark the whole patch as applied
  mark_applied "$patch_name"
  echo "  OK: $patch_name"
  APPLIED_COUNT=$((APPLIED_COUNT + 1))

done

echo
echo "  Total: $TOTAL  Applied: $APPLIED_COUNT  Skipped: $SKIPPED"

# ── Run update.psql (routines/views) ─────────────────────────────────────────

if ! $NO_UPDATE && ! $DRY_RUN && { [[ $APPLIED_COUNT -gt 0 ]] || $FORCE_UPDATE; }; then
  echo
  echo "--- Running update (routines/views) ---"

  update_wrapper="$SQL_DIR/.migrate_update.psql"
  cat > "$update_wrapper" <<WRAPPER
\\ir sets.psql
\\ir './platform/update.psql'
\\ir './configuration/update.psql'
WRAPPER

  $PSQL_KERNEL -d "$DB_NAME" -v ON_ERROR_STOP=1 -q -f "$update_wrapper" 2>&1
  rm -f "$update_wrapper"

  echo "  Update complete."
fi

echo
echo "============================================"
echo " Migration complete"
echo "============================================"
echo
