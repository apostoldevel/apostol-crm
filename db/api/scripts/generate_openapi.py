#!/usr/bin/env python3
"""
generate_openapi.py - Generate a complete OpenAPI 3.0 spec from SQL source files.

Reads rest.sql WHEN clauses and api.sql JSDoc to produce a comprehensive
api.yaml, preserving hand-crafted entries from the existing spec.

Usage:
    python3 generate_openapi.py [--platform-only] [--output FILE]
"""

import argparse
import re
import sys
from collections import OrderedDict, defaultdict
from pathlib import Path

# Use the extract module
SCRIPT_DIR = Path(__file__).resolve().parent
DB_ROOT = SCRIPT_DIR.parent.parent  # db/
sys.path.insert(0, str(SCRIPT_DIR))
from extract_openapi import (
    find_rest_files,
    find_api_files,
    extract_routes_from_rest,
    extract_functions_from_api,
)

EXISTING_SPEC = DB_ROOT / "api" / "base-api.yaml"


# ---------------------------------------------------------------------------
# Tag classification
# ---------------------------------------------------------------------------

# Routes whose standard CRUD (type, method, count, set, get, list)
# is already covered by /{document}/* or /{reference}/* parameterized paths.
DOCUMENT_ENTITIES = [
    "account", "card", "client", "company", "customer",
    "device", "employee", "identity", "invoice", "job", "message",
    "order", "payment", "price", "product",
    "report_ready", "subscription", "tariff", "task",
    "transaction",
]
REFERENCE_ENTITIES = [
    "address", "agent", "calendar", "category", "country", "currency",
    "form", "format", "measure", "model", "program",
    "property", "reference", "region", "report", "report_form",
    "report_routine", "report_tree", "scheduler", "service", "vendor",
    "version",
]
STANDARD_CRUD_SUFFIXES = {"type", "method", "count", "set", "get", "list"}

TAG_DESCRIPTIONS = OrderedDict([
    ("Connection", "Server connectivity test."),
    ("Security", "Authentication and authorization."),
    ("Sign", "Sign up, sign in, sign out."),
    ("User", "User management and profiles."),
    ("Current", "Current session parameters."),
    ("Session", "Session management."),
    ("Locale", "Language and locale selection."),
    ("Workflow", "Entity, class, state, action, method, transition, event management."),
    ("Object", "Generic object CRUD, groups, links, files, data, addresses, geolocation."),
    ("Document", "Parameterized document endpoints (type, method, count, set, get, list)."),
    ("Reference", "Parameterized reference endpoints (type, method, count, set, get, list)."),
    ("Admin", "Administrative operations: users, groups, areas, interfaces, sessions, logs."),
    ("Log", "Event logging."),
    ("Registry", "Hierarchical key-value configuration store."),
    ("Resource", "Multilingual resource tree."),
    ("File", "File management and object file attachments."),
    ("KLADR", "Russian address classifier (KLADR)."),
    ("Notice", "System notices and user alerts."),
    ("Comment", "Hierarchical object comments."),
    ("Notification", "Real-time push notifications (FCM)."),
    ("Verification", "Email and phone verification codes."),
    ("Observer", "Publisher/subscriber event system."),
    ("Replication", "Data replication between instances."),
    ("Report", "Report trees, forms, routines, and ready reports."),
    ("Search", "Global search."),
    ("Account", "Account-specific endpoints."),
    ("Card", "Payment card binding."),
    ("Client", "Client-specific endpoints."),
    ("Address", "Address-specific endpoints (tree, string)."),
    ("Calendar", "Calendar and date management."),
    ("Device", "Device management."),
    ("Message", "Message inbox and outbox."),
    ("Model", "Model properties and data."),
    ("Tariff", "Tariff options and features."),
    ("Payment", "Payment processing (CloudPayments, YooKassa)."),
    ("Member", "User group/area/interface membership."),
])


def classify_route(path):
    """Return (tag, is_standard_crud) for a route path."""
    parts = path.strip("/").split("/")
    if not parts:
        return "Common", False

    first = parts[0]
    last = parts[-1] if len(parts) > 1 else ""

    # Explicit classification by first segment
    tag_map = {
        "ping": "Connection",
        "time": "Connection",
        "authenticate": "Security",
        "authorize": "Security",
        "su": "Security",
        "search": "Search",
        "whoami": "User",
        "run": "Common",
        "sign": "Sign",
        "user": "User",
        "current": "Current",
        "session": "Session",
        "locale": "Locale",
        "entity": "Workflow",
        "type": "Workflow",
        "class": "Workflow",
        "priority": "Workflow",
        "state": "Workflow",
        "action": "Workflow",
        "method": "Workflow",
        "member": "Member",
        "admin": "Admin",
        "event": "Log",
        "object": "Object",
        "registry": "Registry",
        "resource": "Resource",
        "file": "File",
        "kladr": "KLADR",
        "notice": "Notice",
        "comment": "Comment",
        "notification": "Notification",
        "verification": "Verification",
        "observer": "Observer",
        "replication": "Replication",
        "report": "Report",
        "report_form": "Report",
        "report_ready": "Report",
        "report_routine": "Report",
        "report_tree": "Report",
        "cloudpayments": "Payment",
        "yookassa": "Payment",
    }

    # Check entity-specific non-standard routes
    entity_tag_map = {
        "account": "Account",
        "card": "Card",
        "client": "Client",
        "address": "Address",
        "calendar": "Calendar",
        "device": "Device",
        "message": "Message",
        "model": "Model",
        "tariff": "Tariff",
    }

    # Is this a standard CRUD route for a document/reference entity?
    is_std = False
    if first in DOCUMENT_ENTITIES or first in REFERENCE_ENTITIES:
        if len(parts) == 2 and last in STANDARD_CRUD_SUFFIXES:
            is_std = True
            if first in DOCUMENT_ENTITIES:
                return "Document", True
            else:
                return "Reference", True

        # Non-standard route for an entity
        if first in entity_tag_map:
            return entity_tag_map[first], False
        # Fallback: use the entity name capitalized
        return first.replace("_", " ").title(), False

    if first in tag_map:
        return tag_map[first], False

    return first.replace("_", " ").title(), False


def make_operation_id(path):
    """Generate a camelCase operationId from path."""
    parts = path.strip("/").split("/")
    if not parts:
        return "root"
    # camelCase: first word lowercase, rest capitalized
    words = []
    for p in parts:
        p = p.replace("_", " ").replace("-", " ")
        for w in p.split():
            words.append(w)
    if not words:
        return "root"
    result = words[0].lower()
    for w in words[1:]:
        result += w.capitalize()
    return result


def translate_comment(comment):
    """Translate common Russian REST comments to English."""
    translations = {
        "Группы пользователя": "User groups.",
        "Зоны пользователя": "User areas.",
        "Интерфейсы пользователя": "User interfaces.",
        "Пользователи группы": "Group members (users).",
        "Добавляет пользователя в группу": "Add user to group.",
        "Удаляет пользователя из группу": "Remove user from group.",
        "Удаляет зону": "Delete area.",
        "Удаляет интерфейс": "Delete interface.",
        "Участники интерфейса": "Interface members.",
        "Добавляет пользователя или группу в зону": "Add user or group to area.",
        "Удаляет пользователя или группу из зоны": "Remove user or group from area.",
        "Добавляет пользователя или группу к интерфейсу": "Add user or group to interface.",
        "Удаляет пользователя или группу из интерфейса": "Remove user or group from interface.",
        "Участники (пользователи) группы": "Group members (users).",
        "Группы участника (пользователя)": "Member groups.",
        "Добавляет пользователя в группу": "Add user to group.",
        "Удаляет группу для пользователя": "Remove group from user.",
        "Зоны участника (пользователя или группы)": "Member areas.",
        "Добавляет пользователя или группу в зону": "Add user or group to area.",
        "Удаляет зону для пользователя или группы": "Remove area from user or group.",
        "Интерфейсы участника (пользователя или группы)": "Member interfaces.",
        "Добавляет пользователя или группу к интерфейсу": "Add user or group to interface.",
        "Удаляет интерфейс для пользователя или группы": "Remove interface from user or group.",
    }
    return translations.get(comment.strip(), comment)


def infer_summary(path, comment=""):
    """Generate a human-readable summary for a route."""
    if comment:
        # Translate Russian if needed
        translated = translate_comment(comment)
        if translated != comment:
            return translated
        # Check if it's Russian (contains Cyrillic)
        if any("\u0400" <= c <= "\u04ff" for c in comment):
            # Fallback: don't use untranslated Russian
            pass
        else:
            return comment

    parts = path.strip("/").split("/")
    last = parts[-1] if parts else ""

    # Path-specific overrides for special cases
    path_overrides = {
        "/admin/area/delete/safely": "Safely delete area.",
        "/admin/area/clear": "Clear all area data.",
        "/session/set/locale": "Set session locale.",
        "/session/set/area": "Set session area.",
        "/session/set/interface": "Set session interface.",
        "/session/set/operdate": "Set session operation date.",
        "/user/registration/code": "Send registration verification code.",
        "/user/registration/check": "Check registration verification code.",
        "/user/password/recovery": "Initiate password recovery.",
        "/user/password/reset": "Reset user password.",
        "/user/security/answer": "Submit security answer.",
        "/verification/email/code": "Send email verification code.",
        "/verification/phone/code": "Send phone verification code.",
        "/verification/email/check": "Check email verification code.",
        "/verification/phone/check": "Check phone verification code.",
        "/action/execute": "Execute workflow action.",
        "/method/run": "Run workflow method by ID.",
        "/method/execute": "Execute workflow method.",
        "/method/get": "Get workflow methods for an object.",
        "/object/access": "Get object access permissions.",
        "/object/access/set": "Set object access permissions.",
        "/object/access/decode": "Decode object access bitmask.",
        "/object/force/delete": "Force delete object (bypass workflow).",
        "/model/property/set": "Set model property.",
        "/model/property/get": "Get model property.",
        "/model/property/delete": "Delete model property.",
        "/model/data/set": "Set model data.",
        "/model/data/get": "Get model data.",
        "/model/data/list": "List model data.",
        "/model/data/delete": "Delete model data.",
        "/yookassa/callback": "YooKassa payment callback.",
    }
    if path in path_overrides:
        return path_overrides[path]

    op_map = {
        "count": "Count",
        "get": "Get",
        "set": "Create or update",
        "list": "List",
        "delete": "Delete",
        "add": "Add",
        "type": "Get available types for",
        "method": "Get available methods for",
        "clear": "Clear all",
        "build": "Build",
        "fill": "Fill",
        "send": "Send",
        "execute": "Execute",
        "run": "Run",
        "decode": "Decode access mask for",
        "string": "Get string representation of",
        "history": "Get history of",
        "bind": "Bind",
        "unbind": "Unbind",
        "close": "Close",
        "balance": "Get balance of",
        "callback": "Payment callback for",
        "init": "Initialize",
        "mail": "Send email via",
        "sms": "Send SMS via",
        "push": "Send push notification via",
        "check": "Check",
        "reset": "Reset",
        "recovery": "Password recovery for",
        "answer": "Security answer for",
        "safely": "Safely delete",
        "profile": "Get profile of",
        "lock": "Lock",
        "unlock": "Unlock",
        "data": "Get data of",
        "role": "Get role for",
        "all": "Get all",
    }

    # Build a human-readable entity name from path
    def entity_name(parts_slice):
        """Convert path parts to a human-readable entity name."""
        return " ".join(
            p.replace("_", " ") for p in parts_slice
        ).strip()

    if last in op_map:
        prefix = op_map[last]
        # For single-word actions, compose with entity context
        if len(parts) == 1:
            return f"{prefix}."
        elif len(parts) == 2:
            ename = entity_name(parts[:1])
            return f"{prefix} {ename}."
        else:
            # /admin/user/set → "Create or update admin user."
            ename = entity_name(parts[:-1])
            return f"{prefix} {ename}."

    # No known operation suffix - describe the endpoint
    if len(parts) == 1:
        ename = entity_name(parts)
        return f"{ename.title()} endpoint."
    else:
        ename = entity_name(parts)
        return f"{ename.title()} endpoint."


def infer_http_method(path):
    """Infer HTTP method from path pattern."""
    parts = path.strip("/").split("/")
    first = parts[0] if parts else ""
    # GET for current/* and simple info endpoints
    if first == "current":
        return "get"
    if path in ("/ping", "/time"):
        return "get"
    return "post"


def build_request_body(keys, path):
    """Build requestBody YAML lines for a route based on its keys."""
    if not keys:
        return []

    lines = []
    lines.append("      requestBody:")
    lines.append("        content:")
    lines.append("          application/json:")
    lines.append("            schema:")

    # Check if it's a standard list/count pattern
    list_keys = {"search", "filter", "orderby", "reclimit", "recoffset", "fields"}
    if list_keys.issubset(set(keys)):
        lines.append("              $ref: '#/components/schemas/list'")
        return lines

    count_keys = {"search", "filter", "orderby", "reclimit", "recoffset"}
    if count_keys == set(keys):
        lines.append("              $ref: '#/components/schemas/list'")
        return lines

    # Get with id + fields
    if set(keys) == {"id", "fields"}:
        lines.append("              $ref: '#/components/schemas/get_json'")
        return lines
    if set(keys) == {"id"}:
        lines.append("              $ref: '#/components/schemas/get_form'")
        return lines

    # Build inline schema
    lines.append("              type: object")
    lines.append("              properties:")
    for key in sorted(keys):
        if key in ("id", "parent", "member", "area", "interface", "groupid",
                    "object", "owner", "calendar", "userid"):
            lines.append(f"                {key}:")
            lines.append("                  type: string")
            lines.append("                  format: uuid")
        elif key in ("reclimit", "recoffset", "code", "level"):
            lines.append(f"                {key}:")
            lines.append("                  type: integer")
        elif key in ("compact", "short", "flag"):
            lines.append(f"                {key}:")
            lines.append("                  type: boolean")
        elif key in ("search", "filter", "orderby", "fields", "params",
                      "iptable", "name"):
            lines.append(f"                {key}:")
            lines.append("                  type: object")
        else:
            lines.append(f"                {key}:")
            lines.append("                  type: string")
    return lines


def build_responses(path, tag):
    """Build standard response block."""
    parts = path.strip("/").split("/")
    last = parts[-1] if parts else ""

    lines = []
    lines.append("      responses:")

    # Determine 200 response
    if last == "count":
        lines.append("        '200':")
        lines.append("          $ref: '#/components/responses/Count'")
    elif last == "get":
        if tag == "Reference" or tag in (
            "Address", "Calendar", "Model", "Agent", "Form", "Program",
            "Scheduler", "Vendor", "Version", "Category", "Country",
            "Currency", "Format", "Measure", "Navigation", "Property",
            "Region", "Service",
        ):
            lines.append("        '200':")
            lines.append("          $ref: '#/components/responses/GetReference'")
        elif tag == "Object":
            lines.append("        '200':")
            lines.append("          $ref: '#/components/responses/GetObject'")
        else:
            lines.append("        '200':")
            lines.append("          $ref: '#/components/responses/GetDocument'")
    elif last == "list":
        if tag == "Reference" or tag in (
            "Address", "Calendar", "Model", "Agent", "Form", "Program",
            "Scheduler", "Vendor", "Version", "Category", "Country",
            "Currency", "Format", "Measure", "Navigation", "Property",
            "Region", "Service",
        ):
            lines.append("        '200':")
            lines.append("          $ref: '#/components/responses/ListReference'")
        elif tag == "Object":
            lines.append("        '200':")
            lines.append("          $ref: '#/components/responses/ListObject'")
        else:
            lines.append("        '200':")
            lines.append("          $ref: '#/components/responses/ListDocument'")
    elif last == "set":
        lines.append("        '200':")
        lines.append("          $ref: '#/components/responses/GetDocument'")
    else:
        lines.append("        '200':")
        lines.append("          description: Success.")

    lines.append("        '400':")
    lines.append("          $ref: '#/components/responses/BadRequest'")
    lines.append("        '401':")
    lines.append("          $ref: '#/components/responses/Unauthorized'")
    lines.append("        '403':")
    lines.append("          $ref: '#/components/responses/Unauthorized'")
    lines.append("        '404':")
    lines.append("          $ref: '#/components/responses/NotFound'")
    lines.append("        '5XX':")
    lines.append("          $ref: '#/components/responses/InternalError'")
    return lines


# ---------------------------------------------------------------------------
# Parse existing api.yaml to extract hand-crafted paths and components
# ---------------------------------------------------------------------------

def parse_existing_spec():
    """Read existing api.yaml and extract hand-crafted path keys."""
    if not EXISTING_SPEC.exists():
        return set(), ""

    text = EXISTING_SPEC.read_text(encoding="utf-8")

    # Find the paths section to know which paths are already hand-crafted
    existing_paths = set()
    for m in re.finditer(r"^  (/[^\s:]+):\s*$", text, re.MULTILINE):
        existing_paths.add(m.group(1))

    # Extract the components section (everything from "components:" onwards)
    comp_match = re.search(r"^components:.*", text, re.MULTILINE | re.DOTALL)
    components_text = comp_match.group(0) if comp_match else ""

    # Also extract security section
    sec_match = re.search(r"^security:.*", text, re.MULTILINE | re.DOTALL)
    # Security is before components or after
    security_text = ""
    if sec_match:
        # Security comes after components in the file
        security_text = sec_match.group(0).split("\n")
        # Take only up to the next top-level key
        sec_lines = []
        for i, line in enumerate(security_text):
            if i > 0 and line and not line.startswith(" ") and not line.startswith("-"):
                break
            sec_lines.append(line)
        security_text = "\n".join(sec_lines)

    return existing_paths, components_text


def read_existing_path_block(path):
    """Read the full YAML block for a hand-crafted path from existing spec."""
    if not EXISTING_SPEC.exists():
        return None

    text = EXISTING_SPEC.read_text(encoding="utf-8")
    # Escape special regex chars in path
    escaped = re.escape(path)
    # Find path block: starts with "  /path:" and ends before next "  /path:" or "components:"
    pattern = rf"^(  {escaped}:\n(?:    .*\n|      .*\n|        .*\n|          .*\n|            .*\n|              .*\n|                .*\n| *\n)*)"
    m = re.search(pattern, text, re.MULTILINE)
    if m:
        return m.group(1).rstrip("\n")
    return None


# ---------------------------------------------------------------------------
# Main generation
# ---------------------------------------------------------------------------

def generate_spec(platform_only=False):
    """Generate the complete OpenAPI 3.0 spec."""

    # Extract all routes
    rest_files = find_rest_files(platform_only)
    all_routes = []
    for f in rest_files:
        all_routes.extend(extract_routes_from_rest(f))

    # Extract API functions for better summaries
    api_files = find_api_files(platform_only)
    all_functions = []
    for f in api_files:
        all_functions.extend(extract_functions_from_api(f))

    # Build function lookup by approximate route matching
    func_by_name = {}
    for fn in all_functions:
        func_by_name[fn["name"]] = fn

    # Parse existing spec
    existing_paths, components_text = parse_existing_spec()

    # Classify routes
    route_by_path = {}
    for r in all_routes:
        path = r["path"]
        tag, is_std = classify_route(path)
        r["tag"] = tag
        r["is_standard_crud"] = is_std
        route_by_path[path] = r

    # Collect all used tags
    used_tags = set()
    for r in all_routes:
        if not r["is_standard_crud"]:
            used_tags.add(r["tag"])
    # Always include Document and Reference for parameterized paths
    used_tags.add("Document")
    used_tags.add("Reference")

    # Build output
    lines = []

    # Header
    lines.append("openapi: 3.0.0")
    lines.append("info:")
    lines.append("  description: |")
    lines.append("    Apostol CRM API.")
    lines.append("")
    lines.append("    This specification covers all platform and configuration REST endpoints.")
    lines.append("    For detailed documentation, see the [Wiki](https://github.com/apostoldevel/db-platform/wiki).")
    lines.append('  version: "2.0.0"')
    lines.append("  title: Apostol CRM API")
    lines.append("  contact:")
    lines.append("    email: apostoldevel@gmail.com")
    lines.append("  license:")
    lines.append("    name: MIT License")
    lines.append("    url: https://github.com/apostoldevel/apostol/blob/master/LICENSE")
    lines.append("externalDocs:")
    lines.append("  description: Wiki")
    lines.append("  url: https://github.com/apostoldevel/db-platform/wiki")
    lines.append("servers:")
    lines.append("  - url: '{protocol}://api.example.com/api/v1'")
    lines.append("    description: Apostol CRM")
    lines.append("    variables:")
    lines.append("      protocol:")
    lines.append("        enum:")
    lines.append("          - http")
    lines.append("          - https")
    lines.append("        default: https")
    lines.append("  - url: 'http://localhost:{port}/api/v1'")
    lines.append("    description: Local host")
    lines.append("    variables:")
    lines.append("      port:")
    lines.append("        enum:")
    lines.append("          - '8080'")
    lines.append("          - '4977'")
    lines.append("          - '3000'")
    lines.append("        default: '8080'")

    # Tags (ordered)
    lines.append("tags:")
    for tag_name, tag_desc in TAG_DESCRIPTIONS.items():
        if tag_name in used_tags:
            lines.append(f"  - name: {yaml_escape(tag_name)}")
            lines.append(f"    description: {yaml_escape(tag_desc)}")

    # Paths
    lines.append("paths:")

    # 1. Hand-crafted paths from existing spec (preserved as-is)
    # Only include in full mode, not platform-only
    hand_crafted_paths = set()
    if not platform_only and EXISTING_SPEC.exists():
        text = EXISTING_SPEC.read_text(encoding="utf-8")
        # Extract everything between "paths:" and "components:"
        paths_match = re.search(
            r"^paths:\n(.*?)^components:",
            text,
            re.MULTILINE | re.DOTALL,
        )
        if paths_match:
            paths_block = paths_match.group(1)
            # Find all path keys
            for pm in re.finditer(r"^  (/[^\s:]+):", paths_block, re.MULTILINE):
                hand_crafted_paths.add(pm.group(1))

            # Include the entire hand-crafted paths block
            lines.append(paths_block.rstrip())

    # 2. Auto-generated paths for routes NOT already in hand-crafted spec
    # In full mode: skip standard CRUD routes (covered by parameterized paths)
    # In platform-only mode: include everything (no parameterized paths)
    new_routes = []
    for r in sorted(all_routes, key=lambda x: x["path"]):
        path = r["path"]
        if path in hand_crafted_paths:
            continue
        if not platform_only and r["is_standard_crud"]:
            continue
        new_routes.append(r)

    if new_routes:
        lines.append("")
        lines.append("  # ─── Auto-generated paths ────────────────────────────────────────")
        lines.append("")

    for r in new_routes:
        path = r["path"]
        tag = r["tag"]
        http_method = infer_http_method(path)
        summary = infer_summary(path, r.get("comment", ""))
        op_id = make_operation_id(path)

        lines.append(f"  {path}:")
        lines.append(f"    {http_method}:")
        lines.append(f"      tags:")
        lines.append(f"        - {tag}")
        lines.append(f"      summary: {yaml_escape(summary)}")
        lines.append(f"      operationId: {op_id}")

        # Parameters for non-POST methods
        if http_method == "get":
            lines.append("      parameters:")
            lines.append("        - $ref: '#/components/parameters/resultObject'")
            lines.append("        - $ref: '#/components/parameters/resultFormat'")

        # Request body for POST methods
        if http_method == "post":
            body_lines = build_request_body(r["keys"], path)
            if body_lines:
                lines.extend(body_lines)

        # Responses
        resp_lines = build_responses(path, tag)
        lines.extend(resp_lines)

    # Components - use from existing spec with updated enums
    lines.append("")
    if components_text:
        # Remove the trailing security section if it's embedded
        comp_lines = components_text.split("\n")
        clean_comp = []
        for cl in comp_lines:
            if cl.startswith("security:"):
                break
            clean_comp.append(cl)
        comp_text = "\n".join(clean_comp).rstrip()

        # Update {document} parameter enum
        doc_enum = ", ".join(sorted(DOCUMENT_ENTITIES))
        comp_text = re.sub(
            r"(name: document\n.*?enum: \[)[^\]]+(\])",
            rf"\g<1>{doc_enum}\2",
            comp_text,
            flags=re.DOTALL,
        )

        # Update {reference} parameter enum
        ref_enum = ", ".join(sorted(REFERENCE_ENTITIES))
        comp_text = re.sub(
            r"(name: reference\n.*?enum: \[)[^\]]+(\])",
            rf"\g<1>{ref_enum}\2",
            comp_text,
            flags=re.DOTALL,
        )

        lines.append(comp_text)
    else:
        lines.append("components: {}")

    # Security
    lines.append("security:")
    lines.append("  - oauth2:")
    lines.append("      - apostol")

    return "\n".join(lines) + "\n", len(hand_crafted_paths), len(new_routes)


def yaml_escape(s):
    """Escape a string for YAML if needed."""
    if not s:
        return '""'
    # If contains special chars, quote it
    needs_quote = False
    if any(c in s for c in "{}[]|>&*!%#`@"):
        needs_quote = True
    # Colon followed by space is a YAML mapping indicator
    if ": " in s or s.endswith(":"):
        needs_quote = True
    if s.startswith(("'", '"', "-", "?", " ", ",")):
        needs_quote = True
    if needs_quote:
        s = s.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{s}"'
    return s


def main():
    parser = argparse.ArgumentParser(
        description="Generate complete OpenAPI spec from SQL sources"
    )
    parser.add_argument(
        "--platform-only",
        action="store_true",
        help="Only include platform routes",
    )
    parser.add_argument(
        "--output", "-o", type=str, default=None,
        help="Output file (default: stdout)",
    )
    args = parser.parse_args()

    spec, n_existing, n_new = generate_spec(args.platform_only)

    if args.output:
        Path(args.output).write_text(spec, encoding="utf-8")
        print(f"Written to {args.output}", file=sys.stderr)
    else:
        print(spec)

    total = n_existing + n_new
    print(f"\nOpenAPI spec generated:", file=sys.stderr)
    print(f"  {n_existing} hand-crafted paths (preserved)", file=sys.stderr)
    print(f"  {n_new} auto-generated paths", file=sys.stderr)
    print(f"  {total} total paths", file=sys.stderr)


if __name__ == "__main__":
    main()
