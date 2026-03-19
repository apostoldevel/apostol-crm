#!/usr/bin/env python3
"""
extract_openapi.py - Extract REST routes and API function signatures from SQL files.

Parses rest.sql WHEN clauses and api.sql function signatures to generate
OpenAPI 3.0 path stubs. Output is YAML suitable for merging into api.yaml.

Usage:
    python3 extract_openapi.py [--platform-only] [--output FILE]

    --platform-only   Only scan sql/platform/ (skip sql/configuration/)
    --output FILE     Write YAML to FILE (default: stdout)
    --summary         Print route summary table instead of YAML
"""

import argparse
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

# Resolve project root (db/ directory)
SCRIPT_DIR = Path(__file__).resolve().parent
DB_ROOT = SCRIPT_DIR.parent.parent  # db/
PLATFORM_DIR = DB_ROOT / "sql" / "platform"
CONFIG_DIR = DB_ROOT / "sql" / "configuration"


def find_rest_files(platform_only=False):
    """Find all rest.sql files in platform and optionally configuration."""
    dirs = [PLATFORM_DIR]
    if not platform_only and CONFIG_DIR.exists():
        dirs.append(CONFIG_DIR)

    rest_files = []
    for d in dirs:
        for f in sorted(d.rglob("rest.sql")):
            rest_files.append(f)
    return rest_files


def find_api_files(platform_only=False):
    """Find all api.sql files in platform and optionally configuration."""
    dirs = [PLATFORM_DIR]
    if not platform_only and CONFIG_DIR.exists():
        dirs.append(CONFIG_DIR)

    api_files = []
    for d in dirs:
        for f in sorted(d.rglob("api.sql")):
            api_files.append(f)
    return api_files


def extract_routes_from_rest(filepath):
    """Extract WHEN '/path' clauses from a rest.sql file.

    Returns list of dicts: {path, keys, source_file, line_number, dispatcher}
    """
    routes = []
    text = filepath.read_text(encoding="utf-8")

    # Find the dispatcher function name: rest.xxx(...)
    dispatcher_match = re.search(
        r"CREATE\s+OR\s+REPLACE\s+FUNCTION\s+(rest\.\w+)", text, re.IGNORECASE
    )
    dispatcher = dispatcher_match.group(1) if dispatcher_match else "unknown"

    # Find all WHEN '/path' THEN blocks
    # Pattern: WHEN '/some/path' THEN  (with optional comment after --)
    for match in re.finditer(
        r"WHEN\s+'(/[^']+)'\s+THEN\s*(?:--\s*(.+?))?$", text, re.MULTILINE
    ):
        path = match.group(1)
        comment = (match.group(2) or "").strip()
        line_num = text[: match.start()].count("\n") + 1

        # Try to find arKeys for this route by looking at the block after WHEN
        block_start = match.end()
        # Find next WHEN or END CASE or ELSE
        next_when = re.search(
            r"\n\s*(?:WHEN\s+'|ELSE\b|END\s+CASE)", text[block_start:]
        )
        block_end = block_start + next_when.start() if next_when else len(text)
        block = text[block_start:block_end]

        # Extract arKeys from ARRAY['key1', 'key2'] patterns
        keys = set()
        for arr_match in re.finditer(r"ARRAY\[([^\]]+)\]", block):
            arr_content = arr_match.group(1)
            for key in re.findall(r"'([^']+)'", arr_content):
                keys.add(key)

        # Also check GetRoutines('func_name', 'api', ...) for dynamic keys
        dynamic_keys = []
        for gr_match in re.finditer(r"GetRoutines\('(\w+)',\s*'(\w+)'", block):
            dynamic_keys.append(f"api.{gr_match.group(1)} params")

        routes.append(
            {
                "path": path,
                "comment": comment,
                "keys": sorted(keys),
                "dynamic_keys": dynamic_keys,
                "source_file": str(filepath.relative_to(DB_ROOT)),
                "line_number": line_num,
                "dispatcher": dispatcher,
            }
        )

    return routes


def extract_functions_from_api(filepath):
    """Extract function signatures and JSDoc from api.sql files.

    Returns list of dicts: {name, params, returns, brief, source_file, line}
    """
    functions = []
    text = filepath.read_text(encoding="utf-8")

    # Match JSDoc + CREATE FUNCTION blocks
    # Pattern: optional JSDoc comment block followed by CREATE OR REPLACE FUNCTION
    pattern = re.compile(
        r"(?:/\*\*\s*\n(.*?)\*/\s*\n)?"  # Optional JSDoc
        r"CREATE\s+OR\s+REPLACE\s+(?:FUNCTION|VIEW)\s+"
        r"((?:api|rest)\.\w+)",
        re.DOTALL | re.IGNORECASE,
    )

    for match in pattern.finditer(text):
        jsdoc = match.group(1) or ""
        func_name = match.group(2)
        line_num = text[: match.start()].count("\n") + 1

        # Parse JSDoc @brief
        brief = ""
        brief_match = re.search(r"@brief\s+(.+?)(?:\n|$)", jsdoc)
        if brief_match:
            brief = brief_match.group(1).strip()
        elif jsdoc.strip():
            # First non-empty, non-tag line as description
            for line in jsdoc.split("\n"):
                line = line.strip().lstrip("* ").strip()
                if line and not line.startswith("@"):
                    brief = line
                    break

        # Parse @param entries
        params = []
        for p_match in re.finditer(
            r"@param\s+\{(\w+)\}\s+(\w+)\s*-?\s*(.*?)(?:\n|$)", jsdoc
        ):
            params.append(
                {
                    "type": p_match.group(1),
                    "name": p_match.group(2),
                    "description": p_match.group(3).strip(),
                }
            )

        # Parse @return
        returns = ""
        ret_match = re.search(r"@return\s+\{([^}]+)\}\s*-?\s*(.*?)(?:\n|$)", jsdoc)
        if ret_match:
            returns = ret_match.group(1).strip()

        # Extract actual SQL parameter list
        func_start = match.end()
        paren_match = re.search(r"\((.*?)\)\s*RETURNS", text[func_start:], re.DOTALL)
        sql_params = []
        if paren_match:
            param_block = paren_match.group(1)
            for pline in param_block.split("\n"):
                pline = pline.strip().rstrip(",")
                if pline and not pline.startswith("--"):
                    # Match: pName type DEFAULT value  or  OUT name type
                    pm = re.match(
                        r"(?:OUT\s+)?(\w+)\s+(\w[\w\s\[\]]*?)(?:\s+DEFAULT\s+.*)?$",
                        pline,
                        re.IGNORECASE,
                    )
                    if pm:
                        sql_params.append(
                            {"name": pm.group(1), "type": pm.group(2).strip()}
                        )

        functions.append(
            {
                "name": func_name,
                "brief": brief,
                "params": params,
                "sql_params": sql_params,
                "returns": returns,
                "source_file": str(filepath.relative_to(DB_ROOT)),
                "line_number": line_num,
            }
        )

    return functions


def infer_tag(path):
    """Infer OpenAPI tag from route path."""
    parts = path.strip("/").split("/")
    if not parts:
        return "Common"
    first = parts[0]
    tag_map = {
        "admin": "Admin",
        "sign": "Sign",
        "user": "User",
        "current": "Current",
        "event": "Log",
        "object": "Object",
        "document": "Document",
        "reference": "Reference",
        "session": "Session",
        "locale": "Locale",
        "notice": "Notice",
        "comment": "Comment",
        "notification": "Notification",
        "verification": "Verification",
        "observer": "Observer",
        "report": "Report",
        "registry": "Registry",
        "resource": "Resource",
        "kladr": "KLADR",
        "file": "File",
        "replication": "Replication",
        "daemon": "Daemon",
    }
    return tag_map.get(first, first.capitalize())


def infer_operation(path):
    """Infer operation type from path suffix."""
    parts = path.strip("/").split("/")
    last = parts[-1] if parts else ""
    op_map = {
        "count": "Count records",
        "get": "Get record",
        "set": "Create or update",
        "list": "List records",
        "delete": "Delete record",
        "add": "Add item",
        "type": "Get types",
        "method": "Get methods",
    }
    return op_map.get(last, f"Endpoint: {path}")


def routes_to_openapi_yaml(routes):
    """Generate OpenAPI paths YAML from extracted routes."""
    lines = ["# Auto-generated OpenAPI paths from rest.sql files", "paths:"]

    for route in sorted(routes, key=lambda r: r["path"]):
        path = route["path"]
        tag = infer_tag(path)
        summary = route["comment"] if route["comment"] else infer_operation(path)

        lines.append(f"  {path}:")
        lines.append("    post:")
        lines.append(f"      tags:")
        lines.append(f"        - {tag}")
        lines.append(f"      summary: \"{summary}\"")
        lines.append(
            f"      # Source: {route['source_file']}:{route['line_number']}"
        )
        lines.append(f"      # Dispatcher: {route['dispatcher']}")

        # Request body with known keys
        if route["keys"] or route["dynamic_keys"]:
            lines.append("      requestBody:")
            lines.append("        content:")
            lines.append("          application/json:")
            lines.append("            schema:")
            lines.append("              type: object")
            lines.append("              properties:")
            for key in route["keys"]:
                pg_type = "string"
                if key in ("id", "parent", "member", "area", "interface", "groupid"):
                    pg_type = "string"
                    lines.append(f"                {key}:")
                    lines.append(f"                  type: {pg_type}")
                    lines.append("                  format: uuid")
                elif key in ("reclimit", "recoffset", "code"):
                    lines.append(f"                {key}:")
                    lines.append("                  type: integer")
                elif key in ("search", "filter", "orderby", "fields"):
                    lines.append(f"                {key}:")
                    lines.append("                  type: object")
                else:
                    lines.append(f"                {key}:")
                    lines.append(f"                  type: {pg_type}")
            for dk in route["dynamic_keys"]:
                lines.append(f"              # Dynamic keys from: {dk}")

        lines.append("      responses:")
        lines.append("        '200':")
        lines.append("          description: Success.")
        lines.append("        '400':")
        lines.append("          $ref: '#/components/responses/BadRequest'")
        lines.append("        '401':")
        lines.append("          $ref: '#/components/responses/Unauthorized'")
        lines.append("        '5XX':")
        lines.append("          $ref: '#/components/responses/InternalError'")

    return "\n".join(lines) + "\n"


def print_summary(routes, functions):
    """Print a summary table of routes and functions."""
    print(f"\n{'='*80}")
    print(f"REST ROUTE SUMMARY")
    print(f"{'='*80}")

    # Group by dispatcher
    by_dispatcher = defaultdict(list)
    for r in routes:
        by_dispatcher[r["dispatcher"]].append(r)

    for dispatcher in sorted(by_dispatcher):
        rs = by_dispatcher[dispatcher]
        print(f"\n--- {dispatcher} ({len(rs)} routes) ---")
        for r in rs:
            keys_str = ", ".join(r["keys"][:5])
            if len(r["keys"]) > 5:
                keys_str += f" (+{len(r['keys'])-5})"
            comment = f"  -- {r['comment']}" if r["comment"] else ""
            print(f"  {r['path']:<45} [{keys_str}]{comment}")

    print(f"\n{'='*80}")
    print(f"TOTAL: {len(routes)} routes from {len(by_dispatcher)} dispatchers")
    print(f"{'='*80}")

    # API functions summary
    print(f"\n{'='*80}")
    print(f"API FUNCTION SUMMARY")
    print(f"{'='*80}")

    by_file = defaultdict(list)
    for f in functions:
        by_file[f["source_file"]].append(f)

    total_funcs = 0
    total_views = 0
    for source in sorted(by_file):
        funcs = by_file[source]
        print(f"\n--- {source} ({len(funcs)} entries) ---")
        for f in funcs:
            brief_short = f["brief"][:60] + "..." if len(f["brief"]) > 60 else f["brief"]
            print(f"  {f['name']:<45} {brief_short}")
            if "view" in f["name"].lower() or "VIEW" in f.get("returns", ""):
                total_views += 1
            else:
                total_funcs += 1

    print(f"\n{'='*80}")
    print(f"TOTAL: {len(functions)} API entries from {len(by_file)} files")
    print(f"{'='*80}")


def main():
    parser = argparse.ArgumentParser(
        description="Extract OpenAPI paths from platform SQL files"
    )
    parser.add_argument(
        "--platform-only",
        action="store_true",
        help="Only scan sql/platform/ (skip configuration)",
    )
    parser.add_argument(
        "--output", "-o", type=str, default=None, help="Output file (default: stdout)"
    )
    parser.add_argument(
        "--summary", action="store_true", help="Print summary table instead of YAML"
    )
    args = parser.parse_args()

    # Extract routes
    rest_files = find_rest_files(args.platform_only)
    all_routes = []
    for f in rest_files:
        all_routes.extend(extract_routes_from_rest(f))

    # Extract functions
    api_files = find_api_files(args.platform_only)
    all_functions = []
    for f in api_files:
        all_functions.extend(extract_functions_from_api(f))

    if args.summary:
        print_summary(all_routes, all_functions)
        print(f"\nScanned {len(rest_files)} rest.sql files, {len(api_files)} api.sql files")
        return

    # Generate YAML
    yaml_output = routes_to_openapi_yaml(all_routes)

    if args.output:
        Path(args.output).write_text(yaml_output, encoding="utf-8")
        print(
            f"Written {len(all_routes)} routes to {args.output}", file=sys.stderr
        )
    else:
        print(yaml_output)

    # Stats to stderr
    print(f"\nExtracted:", file=sys.stderr)
    print(f"  {len(all_routes)} REST routes from {len(rest_files)} rest.sql files", file=sys.stderr)
    print(f"  {len(all_functions)} API functions from {len(api_files)} api.sql files", file=sys.stderr)


if __name__ == "__main__":
    main()
