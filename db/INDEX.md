# Project Example — Database Layer

> Top-level overview for AI agents and developers

PostgreSQL database layer for the Project Example data platform. Two-layer architecture: a reusable **platform** framework and an application-specific **configuration**.

## Quick Start

```bash
./runme.sh --update    # Safe: updates routines and views only
./runme.sh --patch     # Updates tables + routines + views
./runme.sh --install   # DESTRUCTIVE: drops/recreates DB
```

## Architecture

```
sql/
  platform/              ← db-platform framework (DO NOT EDIT)
  │  25 modules, ~28 tables, ~500+ functions
  │  See: sql/platform/README.md + individual INDEX.md files
  │
  configuration/         ← Project Example application (EDIT HERE)
     apostol/         ← Active configuration
        30 entities, ~50 tables, ~400+ functions
        See: sql/configuration/apostol/INDEX.md
```

## Execution Order

| Script | Platform | Configuration |
|--------|----------|---------------|
| `install.psql` | `platform/create.psql` | `configuration/create.psql` |
| `update.psql` | `platform/update.psql` | `configuration/update.psql` |
| `patch.psql` | `platform/patch.psql` → `platform/update.psql` | `configuration/patch.psql` → `configuration/update.psql` |

## Platform Modules (25)

Core: kernel, oauth2, locale, admin, exception
Infrastructure: http, resource, registry, log, api, replication, daemon
Session: session, current
Business: workflow, entity, file, kladr
Communication: notice, comment, notification, verification, observer
Reporting: report, reports

Each module has its own `INDEX.md` in `sql/platform/<module>/INDEX.md`.

## Configuration Modules

| Module | Description |
|--------|-------------|
| [admin](sql/configuration/apostol/admin/INDEX.md) | Platform hook overrides (login/logout/area) |
| [entity](sql/configuration/apostol/entity/INDEX.md) | 30 business entities (class tree) |
| [ntrip](sql/configuration/apostol/ntrip/INDEX.md) | NTRIP protocol (own schema/user/tables) |
| [api](sql/configuration/apostol/api/INDEX.md) | API extensions (signup, whoami) |
| [report](sql/configuration/apostol/report/INDEX.md) | 3 reports (users, sessions, import) |
| [confirmation](sql/configuration/apostol/confirmation/INDEX.md) | Payment confirmation with pg_notify |
| [observer](sql/configuration/apostol/observer/INDEX.md) | Observer subscription hooks |
| [notice](sql/configuration/apostol/notice/INDEX.md) | Station notification visibility |
| [priority](sql/configuration/apostol/priority/INDEX.md) | Priority REST endpoint |

Master overview: [sql/configuration/apostol/INDEX.md](sql/configuration/apostol/INDEX.md)

## Database Schemas

| Schema | Purpose |
|--------|---------|
| `db` | All tables (always use `db.` prefix) |
| `kernel` | Core business logic (in search_path) |
| `api` | API-facing views and CRUD wrappers |
| `rest` | REST endpoint dispatchers |
| `oauth2` | OAuth2 authentication |
| `daemon` | Daemon-specific functions |
| `ntrip` | NTRIP-specific tables and functions |
| `report` | Report form and generator functions |

## Database Users

| User | Role |
|------|------|
| `kernel` | Schema owner, DDL operations |
| `admin` | Application admin |
| `daemon` | Background processes |
| `apibot` | API service account |
| `ntrip` | NTRIP service |

## Key Files

| File | Purpose |
|------|---------|
| `sql/sets.psql` | Database name, encoding, search_path |
| `sql/.env.psql` | Passwords, project settings, OAuth2 secrets |
| `runme.sh` | CLI wrapper for install/update/patch |
| `install.sh` | Low-level psql runner |
