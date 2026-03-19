[![ru](https://img.shields.io/badge/lang-ru-green.svg)](README.ru-RU.md)

# Apostol CRM

**Apostol CRM**[^crm] is a full-stack backend template for building business applications on Linux. It combines a C++ HTTP/WebSocket server with a PostgreSQL database layer that handles REST API, authentication, workflow engine, and business logic — all in PL/pgSQL.

## Architecture

```
HTTP/WebSocket request
  -> Apostol Worker (C++, single epoll event loop)
  -> libpq async query
  -> rest.* dispatcher (PL/pgSQL)
  -> api.* CRUD functions
  -> kernel.* business logic
  -> db.* tables
```

The project has two layers:

- **Platform** — reusable C++ modules and a [PostgreSQL framework](https://github.com/apostoldevel/db-platform) (25 PL/pgSQL modules, 100+ tables, 800+ functions): OAuth2, workflow engine, entity system, file storage, pub/sub, reports.
- **Configuration** — project-specific business logic (30 entities, REST endpoints, event handlers) written in PL/pgSQL.

## Features

- OAuth 2.0 with 6 grant types, JWT, cookie-based auth
- REST API with OpenAPI 3.0 / Swagger UI (418 endpoints)
- Workflow engine (state machine per entity)
- Real-time updates via WebSocket (JSON-RPC + pub/sub)
- Background processes: email/SMS/push dispatch, cron-like scheduler, report generation
- File storage with S3 support
- Role-based access control (ACU/AOU/AMU)
- Localized error messages (EN, RU, DE, FR, IT, ES)
- Docker Compose deployment (PostgreSQL, PgBouncer, Nginx, Swagger UI)

## Quick Start

### Prerequisites

- Linux (Debian/Ubuntu)
- GCC 7+ with C++14 support
- CMake 3.13+
- PostgreSQL 12+ with `libpq-dev` and `postgresql-server-dev-all`
- OpenSSL, libcurl

```bash
sudo apt-get install build-essential libssl-dev libcurl4-openssl-dev make cmake gcc g++
```

### Build from Source

```bash
git clone https://github.com/apostoldevel/apostol-crm.git
cd apostol-crm/backend
./configure
cd cmake-build-release
make
sudo make install
```

### Database Setup

1. Configure PostgreSQL passwords in `~/.pgpass`:
   ```
   *:*:*:kernel:kernel
   *:*:*:admin:admin
   *:*:*:daemon:daemon
   ```

2. Set `search_path` in `postgresql.conf`:
   ```
   search_path = '"$user", kernel, public'
   ```

3. Initialize the database:
   ```bash
   cd db/
   ./runme.sh --init
   ```

### Run

```bash
sudo service apostol-crm start
sudo service apostol-crm status
```

The API is available at [http://localhost:4977/api/v1/ping](http://localhost:4977/api/v1/ping).

Swagger UI: [http://localhost:4977/docs/](http://localhost:4977/docs/)

## Docker

```bash
./docker-build.sh        # build images
./docker-up.sh           # start all services
./docker-down.sh         # stop all services
./docker-new-database.sh # recreate PostgreSQL volume (destructive)
```

Services: PostgreSQL 18, PgBouncer, Nginx, PgWeb (admin), Backend.

Backend: port 8080. PgWeb: port 8081.

## Project Structure

```
backend/
├── src/
│   ├── app/crm.cpp            # Application entry point
│   ├── lib/delphi/            # libdelphi C++ framework (cloned by ./configure)
│   ├── core/                  # apostol-core (cloned)
│   ├── common/                # BackEnd, FetchCommon, FileCommon (cloned)
│   ├── modules/
│   │   ├── Workers/           # HTTP request handlers (cloned)
│   │   │   ├── AppServer/     # Auth-aware REST -> PG dispatch
│   │   │   ├── AuthServer/    # OAuth2 + JWT
│   │   │   ├── FileServer/    # File serving
│   │   │   ├── WebServer/     # Static files + Swagger UI
│   │   │   └── WebSocketAPI/  # JSON-RPC + pub/sub
│   │   └── Helpers/           # Background helpers (cloned)
│   │       ├── PGFetch/       # LISTEN -> outbound HTTP
│   │       └── PGFile/        # LISTEN -> file sync
│   └── processes/             # Background processes (cloned)
│       ├── MessageServer/     # SMTP/FCM/API dispatch
│       ├── TaskScheduler/     # Cron-like jobs
│       └── ReportServer/      # Report generation
├── db/
│   └── sql/
│       ├── platform/          # db-platform framework (cloned)
│       └── configuration/
│           └── apostol/       # Business logic (30 entities)
├── conf/                      # Server configuration (INI)
├── www/docs/                  # Swagger UI + OpenAPI spec
├── .docker/                   # Docker build files
├── docker-compose.yml
├── Dockerfile
└── configure                  # Downloads all dependencies from GitHub
```

All modules and processes under `src/` are separate repositories cloned by `./configure`. The `db/sql/platform/` directory is also cloned from [db-platform](https://github.com/apostoldevel/db-platform).

## Database Commands

All run from `db/` directory:

```bash
./runme.sh --update    # Safe: updates routines and views only
./runme.sh --patch     # Updates tables + routines + views
./runme.sh --install   # DESTRUCTIVE: drop/recreate DB with seed data
./runme.sh --init      # DESTRUCTIVE: first-time setup (creates users + install)
```

## Configuration

| File | Purpose |
|------|---------|
| `conf/default.conf` | Main server config (modules, processes, PostgreSQL) |
| `conf/oauth2/default.json` | OAuth2 client definitions |
| `.env` | Docker environment (ports, DB credentials) |
| `db/sql/sets.psql` | Database name, encoding, search_path |
| `db/sql/.env.psql` | DB passwords, project settings, OAuth2 secrets |

## Process Management

Signals:

| Signal | Action |
|--------|--------|
| TERM, INT | Fast shutdown |
| QUIT | Graceful shutdown |
| HUP | Reload config, restart workers |
| WINCH | Graceful worker shutdown |

PID file: `/run/apostol-crm.pid`

## Documentation

- [db-platform Wiki](https://github.com/apostoldevel/db-platform/wiki) — API guide (52 pages)
- [OpenAPI Spec](www/docs/api.yaml) — 418 REST endpoints
- `db/INDEX.md` — database layer overview
- `db/CLAUDE.md` — database commands and conventions

## License

[MIT](LICENSE)

---

[^crm]: **Apostol CRM** — a template project built on the [A-POST-OL](https://github.com/apostoldevel/libapostol) (C++20) and [PostgreSQL Framework for Backend Development](https://github.com/apostoldevel/db-platform) frameworks.
