# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Apostol CRM backend — a C++14 server application built on the [Apostol](https://github.com/apostoldevel/apostol) framework (v1, libdelphi) with a PostgreSQL database layer powered by [db-platform](https://github.com/apostoldevel/db-platform). The C++ side is an HTTP/WebSocket server with direct async PostgreSQL access via a single epoll event loop. The database side (PL/pgSQL) contains the business logic, REST API dispatch, workflow engine, and entity system.

## Build Commands

```bash
# Configure (downloads all dependencies from GitHub)
./configure                    # release build → cmake-build-release/
./configure --debug            # debug build → cmake-build-debug/
./configure --not-pull-github  # skip GitHub downloads (use existing deps)

# Compile
cd cmake-build-release && make

# Install (as root — binary to /usr/sbin/apostol-crm, config to /etc/apostol-crm/)
sudo make install

# Deploy (compile + stop service + copy binary + restart)
sudo ./deploy
sudo ./deploy --update         # skip recompile, just redeploy binary
```

## Database Commands

All run from `db/` directory:

```bash
./runme.sh --update    # SAFE: updates routines and views only
./runme.sh --patch     # updates tables + routines + views
./runme.sh --install   # DESTRUCTIVE: drop/recreate DB with seed data
./runme.sh --init      # DESTRUCTIVE: first-time setup (creates users + install)
./runme.sh --create    # DESTRUCTIVE: drop/recreate DB without data
./runme.sh --api       # drop and recreate only the api schema
```

Under the hood: `runme.sh` calls `install.sh --<option>` which runs `sudo -u postgres -H psql -d template1 -f sql/<option>.psql`. Logs in `db/log/`.

Day-to-day: use `--update` after changing routines/views/api/rest SQL files. Use `--patch` when table DDL changes.

Database name: `apostol` (set in `db/sql/sets.psql`).

## Running Tests

SQL tests use pgTAP. Prerequisite: `sudo apt-get install postgresql-18-pgtap libtap-parser-sourcehandler-pgtap-perl`

```bash
cd db/
./test/run.sh                              # all tests (Docker mode, default)
./test/run.sh db/test/sql/balance_test.sql # single test file
./test/run.sh --local                      # run on host PostgreSQL (requires sudo)
./test/run.sh --keep                       # keep test DB/container after run
./runme.sh --test                          # via dashboard menu
```

Docker mode: builds a temporary container, dumps host DB, restores into container, runs tests, destroys container.

## Docker

```bash
./docker-build.sh       # build images
./docker-up.sh          # start all services (nginx, postgres, pgbouncer, pgweb, backend)
./docker-down.sh        # stop all services
./docker-new-database.sh # recreate PostgreSQL volume (destructive)
```

Backend listens on port 4977 inside container, mapped to 8080 on host.

## Architecture

### Process Model

```
Master process
├── Worker processes (N, auto = CPU count)
│   Modules: AppServer, AuthServer, FileServer, WebServer, PGHTTP, ConfirmEmail, WebSocketAPI
├── Helper process (1)
│   Modules: PGFetch, PGFile
└── Background processes
    MessageServer, TaskScheduler, ReportServer, Replication
```

Workers connect to PostgreSQL as `daemon`. Helpers/processes connect as `apibot`.

### Request Flow

```
HTTP request → Apostol Worker (C++) → BackEnd.cpp → libpq async query
→ rest.* dispatcher (PL/pgSQL) → api.* CRUD → kernel.* logic → db.* tables
```

### Source Layout

- `src/app/crm.cpp` — entry point, `CApostolCRM` application class
- `src/core/` — apostol-core (git submodule: apostoldevel/apostol-core)
- `src/common/` — BackEnd, FetchCommon, FileCommon (git submodule: apostoldevel/apostol-common)
- `src/lib/delphi/` — libdelphi C++ framework (git submodule: ufocomp/libdelphi)
- `src/modules/Workers/` — HTTP request handler modules (each is a git submodule)
- `src/modules/Helpers/` — background helper modules (PGFetch, PGFile)
- `src/processes/` — independent background processes (each is a git submodule)

All modules and processes under `src/` are separate git repos cloned by `./configure`.

### Database Two-Layer Architecture

```
db/sql/
  platform/               ← db-platform framework (DO NOT EDIT, separate git repo)
  configuration/apostol/  ← project-specific business logic (EDIT HERE)
```

The `\set dbname apostol` in `db/sql/sets.psql` determines the active configuration directory.

Execution order: platform first, then configuration. `install.psql` → `platform/create.psql` → `configuration/create.psql`.

### Database Schemas

| Schema | Purpose |
|--------|---------|
| `db` | All tables (always use `db.` prefix) |
| `kernel` | Core business logic (in search_path, no prefix needed) |
| `api` | API-facing views and CRUD functions |
| `rest` | REST endpoint dispatchers |
| `oauth2` | OAuth2 infrastructure |
| `daemon` | C++ ↔ PL/pgSQL interface |

### Configuration Entity Structure

Each entity in `db/sql/configuration/apostol/entity/object/{document,reference}/<name>/` follows:

| File | Purpose |
|------|---------|
| `table.sql` | DDL (CREATE TABLE, indexes, triggers) — create only |
| `view.sql` | CREATE OR REPLACE VIEW — create + update |
| `routine.sql` | Create*/Edit*/Get*/Delete* functions — create + update |
| `api.sql` | `api` schema views + CRUD wrappers — create + update |
| `rest.sql` | REST dispatcher in `rest` schema — create + update |
| `event.sql` | Event handlers (Event*Create, Event*Edit) — create + update |
| `init.sql` | Workflow states, methods, transitions — create only |

### Workflow Engine

Every entity has a state machine registered in its `init.sql` via `AddState`/`AddMethod`/`AddTransition`. State transitions are driven by `api.execute_object_action(id, 'action')`. State changes emit `NOTIFY` picked up by background processes.

## Configuration

- `conf/default.conf` — main INI config (modules, processes, server, postgres connections)
- `conf/oauth2/default.json` — OAuth2 client definitions
- `db/sql/sets.psql` — database name (`apostol`), encoding, search_path
- `db/sql/.env.psql` — passwords, project settings, OAuth2 secrets
- `.env` — Docker environment (ports, DB credentials, OAuth2 secrets)

Module/process enable/disable is in `conf/default.conf` sections like `[module/AppServer]` and `[process/MessageServer]`.

## SQL Coding Conventions

- **Function naming:** `Create*`/`Edit*`/`Get*`/`Delete*` (CRUD), `Do*` (state transitions), `Event*` (handlers), `ft_*` (trigger functions)
- **Parameter prefixes:** `p` (params), `u` (UUIDs), `v` (text), `n` (numeric), `r`/`rec_` (records)
- **Tables:** all in `db` schema, UUID PKs via `gen_kernel_uuid()`, comments in Russian
- **Views:** PascalCase in `kernel` schema; lowercase in `api` schema
- **REST:** `rest.entity_name(pPath text, pPayload jsonb)` with CASE-based path routing
- **Functions:** `SECURITY DEFINER` with `SET search_path = kernel, pg_temp`

## Service Management

```bash
sudo service apostol-crm start
sudo service apostol-crm status
```

Signals: TERM/INT (fast stop), QUIT (graceful stop), HUP (reload config + restart workers), WINCH (graceful worker shutdown). PID file: `/run/example.pid`.

## Code Style

Enforced by `.clang-format` (LLVM-based, 120 col, 4-space indent) and `.clang-tidy` (bugprone-*, modernize-*, performance-*, readability-* checks enabled at compile time).

## Key Documentation

- `db/CLAUDE.md` — database layer guidance (commands, conventions, testing)
- `db/INDEX.md` — top-level database overview
- `db/sql/configuration/apostol/INDEX.md` — configuration entity tree
- Platform wiki (52 pages): https://github.com/apostoldevel/db-platform/wiki
