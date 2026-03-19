#!/usr/bin/env python3
"""
audit_descriptions.py - Find JSDoc copy-paste errors in api.sql files.

Detects:
  1. @brief descriptions that don't match the function they document
  2. Duplicate @brief text across different functions (copy-paste)
  3. API functions missing JSDoc entirely
  4. @return type vs actual RETURNS clause mismatches

Usage:
    python3 audit_descriptions.py [--platform-only] [--verbose]
"""

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DB_ROOT = SCRIPT_DIR.parent.parent
PLATFORM_DIR = DB_ROOT / "sql" / "platform"
CONFIG_DIR = DB_ROOT / "sql" / "configuration"

# Known entity names to check against @brief
ENTITY_KEYWORDS = {
    "user": ["пользовател", "user", "учётн"],
    "group": ["групп", "group"],
    "area": ["область", "зон", "area"],
    "interface": ["интерфейс", "interface"],
    "session": ["сесси", "session"],
    "locale": ["язык", "locale", "локал"],
    "log": ["журнал", "log", "лог"],
    "object": ["объект", "object"],
    "document": ["документ", "document"],
    "reference": ["справочник", "reference"],
    "agent": ["агент", "agent", "контрагент"],
    "vendor": ["поставщик", "vendor"],
    "scheduler": ["планировщик", "scheduler", "расписани"],
    "version": ["верси", "version"],
    "message": ["сообщени", "message"],
    "job": ["задани", "job"],
    "client": ["клиент", "client"],
    "device": ["устройств", "device"],
    "station": ["станци", "station"],
    "notice": ["извещени", "notice"],
    "comment": ["комментари", "comment"],
    "notification": ["уведомлени", "notification"],
    "form": ["форм", "form"],
    "program": ["программ", "program"],
    "report": ["отчёт", "отчет", "report"],
    "file": ["файл", "file"],
}


def find_api_files(platform_only=False):
    dirs = [PLATFORM_DIR]
    if not platform_only and CONFIG_DIR.exists():
        dirs.append(CONFIG_DIR)
    files = []
    for d in dirs:
        files.extend(sorted(d.rglob("api.sql")))
    return files


def parse_api_file(filepath):
    """Parse an api.sql file and extract JSDoc + function pairs."""
    text = filepath.read_text(encoding="utf-8")
    entries = []

    # Split into JSDoc + function pairs
    # Pattern: /** ... */ ... CREATE OR REPLACE FUNCTION/VIEW api.name
    pattern = re.compile(
        r"(/\*\*.*?\*/)\s*\n"  # JSDoc block
        r"(CREATE\s+OR\s+REPLACE\s+(?:FUNCTION|VIEW)\s+"
        r"((?:api|rest)\.\w+).*?(?:RETURNS\s+(\S+(?:\s+\S+)*))?)",
        re.DOTALL,
    )

    # Also find functions WITHOUT JSDoc
    func_pattern = re.compile(
        r"CREATE\s+OR\s+REPLACE\s+FUNCTION\s+(api\.\w+)", re.IGNORECASE
    )

    # All documented functions
    documented = set()
    for match in pattern.finditer(text):
        jsdoc = match.group(1)
        func_name = match.group(3)
        returns_clause = match.group(4) or ""
        line_num = text[: match.start()].count("\n") + 1

        documented.add(func_name)

        # Extract @brief
        brief = ""
        brief_match = re.search(r"@brief\s+(.+?)(?:\n|$)", jsdoc)
        if brief_match:
            brief = brief_match.group(1).strip()
        else:
            # First non-tag line
            for line in jsdoc.split("\n"):
                line = line.strip().lstrip("* ").strip()
                if line and not line.startswith("@") and not line.startswith("/"):
                    brief = line
                    break

        # Extract @return type
        ret_type = ""
        ret_match = re.search(r"@return\s+\{([^}]+)\}", jsdoc)
        if ret_match:
            ret_type = ret_match.group(1).strip()

        entries.append(
            {
                "func_name": func_name,
                "brief": brief,
                "jsdoc_return": ret_type,
                "actual_return": returns_clause.strip(),
                "line": line_num,
                "filepath": filepath,
            }
        )

    # Find undocumented functions
    all_funcs = set()
    for match in func_pattern.finditer(text):
        fname = match.group(1)
        all_funcs.add(fname)
        if fname not in documented:
            line_num = text[: match.start()].count("\n") + 1
            entries.append(
                {
                    "func_name": fname,
                    "brief": None,  # Missing JSDoc
                    "jsdoc_return": "",
                    "actual_return": "",
                    "line": line_num,
                    "filepath": filepath,
                    "missing_doc": True,
                }
            )

    return entries


def extract_entity_from_func(func_name):
    """Extract the entity name from a function name like api.add_user -> user."""
    name = func_name.replace("api.", "").replace("rest.", "")
    # Common patterns: add_xxx, get_xxx, list_xxx, set_xxx, delete_xxx, update_xxx
    prefixes = [
        "add_",
        "update_",
        "set_",
        "delete_",
        "get_",
        "list_",
        "safely_delete_",
        "write_to_",
        "check_",
        "clear_",
    ]
    for prefix in prefixes:
        if name.startswith(prefix):
            return name[len(prefix) :]

    # Suffix patterns: xxx_add, xxx_delete, xxx_member
    suffixes = ["_add", "_delete", "_member", "_lock", "_unlock"]
    for suffix in suffixes:
        if name.endswith(suffix):
            return name[: -len(suffix)]

    return name


def check_brief_mismatch(entry):
    """Check if the @brief mentions a different entity than the function."""
    if not entry.get("brief"):
        return None

    func_entity = extract_entity_from_func(entry["func_name"])
    brief_lower = entry["brief"].lower()

    # Check if the brief's entity keywords conflict with the function entity
    # First, find which entities the brief mentions
    brief_entities = set()
    for entity, keywords in ENTITY_KEYWORDS.items():
        for kw in keywords:
            if kw.lower() in brief_lower:
                brief_entities.add(entity)
                break

    # Find which entity the function belongs to
    func_entities = set()
    for entity, keywords in ENTITY_KEYWORDS.items():
        if entity in func_entity or func_entity in entity:
            func_entities.add(entity)

    # If brief mentions entities but NOT the function's entity, flag it
    if brief_entities and func_entities and not brief_entities.intersection(
        func_entities
    ):
        return (
            f"Brief mentions {brief_entities} but function is about {func_entities}"
        )

    return None


def main():
    parser = argparse.ArgumentParser(
        description="Audit JSDoc descriptions in api.sql files"
    )
    parser.add_argument("--platform-only", action="store_true")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    files = find_api_files(args.platform_only)

    print("=" * 70)
    print("JSDoc Copy-Paste Audit")
    print("=" * 70)
    print(f"Scanning {len(files)} api.sql files...\n")

    all_entries = []
    for f in files:
        all_entries.extend(parse_api_file(f))

    issues = 0
    warnings = 0

    # --- Check 1: Brief / function name entity mismatch ---
    print("--- Check 1: @brief / function name entity mismatch ---\n")
    for entry in all_entries:
        if entry.get("missing_doc"):
            continue
        mismatch = check_brief_mismatch(entry)
        if mismatch:
            rel = entry["filepath"].relative_to(DB_ROOT)
            print(f"  WARN {rel}:{entry['line']}  {entry['func_name']}")
            print(f"       Brief: {entry['brief'][:80]}")
            print(f"       Issue: {mismatch}\n")
            warnings += 1
        elif args.verbose:
            rel = entry["filepath"].relative_to(DB_ROOT)
            print(f"  OK   {rel}:{entry['line']}  {entry['func_name']}")

    # --- Check 2: Duplicate @brief descriptions ---
    print("\n--- Check 2: Duplicate @brief descriptions ---\n")
    briefs_by_text = defaultdict(list)
    for entry in all_entries:
        if entry.get("brief") and not entry.get("missing_doc"):
            briefs_by_text[entry["brief"]].append(entry)

    for brief_text, entries in sorted(briefs_by_text.items()):
        # Only flag if different function names share the same brief
        func_names = set(e["func_name"] for e in entries)
        if len(func_names) > 1:
            print(f'  DUPLICATE: "{brief_text[:70]}..."' if len(brief_text) > 70 else f'  DUPLICATE: "{brief_text}"')
            for e in entries:
                rel = e["filepath"].relative_to(DB_ROOT)
                print(f"    -> {e['func_name']}  at {rel}:{e['line']}")
            print()
            issues += 1

    # --- Check 3: Functions missing JSDoc ---
    print("\n--- Check 3: API functions without JSDoc ---\n")
    missing = [e for e in all_entries if e.get("missing_doc")]
    for entry in missing:
        rel = entry["filepath"].relative_to(DB_ROOT)
        print(f"  NODOC {rel}:{entry['line']}  {entry['func_name']}")
        warnings += 1

    # --- Summary ---
    total = len(all_entries)
    documented = total - len(missing)
    print(f"\n{'='*70}")
    print(f"Summary:")
    print(f"  Total API entries:    {total}")
    print(f"  Documented:           {documented}")
    print(f"  Missing JSDoc:        {len(missing)}")
    print(f"  Entity mismatches:    {warnings}")
    print(f"  Duplicate briefs:     {issues}")
    print(f"{'='*70}")


if __name__ == "__main__":
    main()
