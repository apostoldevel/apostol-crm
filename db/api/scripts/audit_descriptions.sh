#!/usr/bin/env bash
#
# audit_descriptions.sh - Find JSDoc copy-paste errors in api.sql files.
#
# Detects cases where a JSDoc @brief description doesn't match the function
# it documents (common when functions are copy-pasted and the doc is not updated).
#
# Usage:
#   ./audit_descriptions.sh [--platform-only] [--verbose]
#
# Delegates to audit_descriptions.py for the actual analysis.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/audit_descriptions.py" "$@"
