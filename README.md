[![ru](https://img.shields.io/badge/lang-ru-green.svg)](README.ru-RU.md)

# Apostol CRM

**Apostol CRM**[^crm] is a production-ready backend template that gives you **[418 REST API endpoints](www/docs/api.yaml)**, **[OAuth 2.0 authentication](https://github.com/apostoldevel/module-AuthServer#readme)**, a **[workflow engine](https://github.com/apostoldevel/db-platform/wiki/04-Workflow)**, **[WebSocket pub/sub](https://github.com/apostoldevel/module-WebSocketAPI#readme)**, **[background processing](https://github.com/apostoldevel/process-MessageServer#readme)**, and **[file storage](https://github.com/apostoldevel/module-FileServer#readme)** — all in a single binary with a PostgreSQL database.

Built on two open-source frameworks:

| Framework | Role | What it provides |
|-----------|------|------------------|
| [**A-POST-OL**](https://github.com/apostoldevel/libapostol) | C++20 server | HTTP/WebSocket server, async PostgreSQL, single `epoll` event loop — **507K RPS** |
| [**db-platform**](https://github.com/apostoldevel/db-platform) | PostgreSQL layer | 26 PL/pgSQL modules, 100+ tables, 800+ functions — REST API, auth, workflow, entities |

No PHP. No Python. No Node.js. HTTP requests flow directly from C++ to PostgreSQL — zero intermediate layers, sub-millisecond latency.

> **This is a template.** Fork it, add your entities, customize workflows — and you have a production backend. Everything below is included out of the box.

## What You Get

| Category | Details |
|----------|---------|
| **Authentication** | OAuth 2.0 (6 grant types), JWT (HS/RS/ES/PS), cookie-based sessions, RBAC |
| **REST API** | 418 endpoints with [OpenAPI 3.0](www/docs/api.yaml) spec and [Swagger UI](https://swagger.io/tools/swagger-ui/) |
| **Entities** | 30 business entities — clients, invoices, payments, subscriptions, devices, and more |
| **Workflow** | State machine for every entity: `created → enabled ↔ disabled → deleted` with custom transitions |
| **Real-time** | WebSocket with JSON-RPC and pub/sub ([observer pattern](https://github.com/apostoldevel/db-platform/wiki/65-Observer-PubSub)) |
| **Background** | Email/SMS/push dispatch, cron scheduler, report generation — as separate OS processes |
| **File storage** | Virtual filesystem with UNIX permissions and S3 bucket support |
| **Access control** | Three-layer permission system: [ACU](https://github.com/apostoldevel/db-platform/wiki/64-Access-Control) (class), AOU (object), AMU (method) |
| **Localization** | Error messages and workflow states in 6 languages (EN, RU, DE, FR, IT, ES) |
| **Performance** | [507K RPS](https://github.com/apostoldevel/apostol/blob/master/doc/BENCHMARK.md) on `/ping` (90% of Nginx), 112K RPS with PostgreSQL round-trip |

## How It Works

**Apostol CRM** combines two frameworks into a single backend:

```
                        ┌─────────────────────────────────────────────────┐
 HTTP/WebSocket    ──>  │  C++ Server (libapostol)                        │
   request              │                                                 │
                        │  Master process                                 │
                        │  ├── Workers (N)     ← AppServer, AuthServer,   │
                        │  │                     FileServer, WebSocketAPI,│
                        │  │                     PGHTTP, WebServer        │
                        │  ├── Helper (1)      ← PGFetch, PGFile          │
                        │  └── Processes       ← MessageServer,           │
                        │                        TaskScheduler,           │
                        │                        ReportServer             │
                        └────────────┬────────────────────────────────────┘
                                     │ libpq async
                        ┌────────────▼────────────────────────────────────┐
                        │  PostgreSQL (db-platform)                       │
                        │                                                 │
                        │  rest.* ─> api.* ─> kernel.* ─> db.*            │
                        │  (dispatch)  (CRUD)   (logic)    (tables)       │
                        │                                                 │
                        │  26 platform modules + 30 project entities      │
                        └─────────────────────────────────────────────────┘
```

**C++ layer** handles HTTP parsing, TLS, connection pooling, WebSocket, JWT verification, and async I/O. **Database layer** handles business logic, REST routing, access control, workflow transitions, and data storage. They communicate through `libpq` — one event loop, no threads.

## Quick Start

### Docker (recommended)

```bash
git clone --recurse-submodules https://github.com/apostoldevel/apostol-crm.git
cd apostol-crm/backend
./docker-build.sh
./docker-up.sh
```

Five services start: **PostgreSQL 18** · **PgBouncer** · **Nginx** · **PgWeb** · **Backend**

| URL | What |
|-----|------|
| [localhost:8080](http://localhost:8080) | Frontend |
| [localhost:8080/docs](http://localhost:8080/docs) | Swagger UI (418 endpoints) |
| [localhost:8081](http://localhost:8081) | PgWeb — database admin |

Default credentials: **admin** / **admin**

```bash
./docker-down.sh           # stop all services
./docker-new-database.sh   # recreate PostgreSQL volume (destructive)
```

### Build from Source

**Prerequisites:** Linux, GCC 12+, CMake 3.25+, PostgreSQL 12+, OpenSSL, libcurl, zlib

```bash
# Install dependencies (Debian/Ubuntu)
sudo apt-get install build-essential libssl-dev libcurl4-openssl-dev \
    libpq-dev zlib1g-dev make cmake gcc g++

# Build
git clone --recurse-submodules https://github.com/apostoldevel/apostol-crm.git
cd apostol-crm/backend
./configure
cmake --build cmake-build-release --parallel $(nproc)
sudo cmake --install cmake-build-release
```

**Database setup:**

```bash
# 1. Configure passwords
echo '*:*:*:kernel:kernel' >> ~/.pgpass
echo '*:*:*:admin:admin'   >> ~/.pgpass
echo '*:*:*:daemon:daemon' >> ~/.pgpass
chmod 600 ~/.pgpass

# 2. Set search_path in postgresql.conf, then restart PostgreSQL
#    search_path = '"$user", kernel, public'

# 3. Initialize
cd db/
./runme.sh --init
```

**Run:**

```bash
sudo service apostol-crm start
curl http://localhost:4977/api/v1/ping   # {"ok": true}
```

### Development mode

```bash
./configure --debug
cmake --build cmake-build-debug --parallel $(nproc)
mkdir -p logs
./cmake-build-debug/apostol-crm -p . -c conf/default.json
```

## Modules & Processes

Every module is a separate [GitHub repository](https://github.com/apostoldevel), cloned by `./configure`:

### Workers — handle HTTP/WebSocket requests

| Module | Description | Docs |
|--------|-------------|------|
| [AppServer](https://github.com/apostoldevel/module-AppServer) | Auth-aware REST API → PostgreSQL dispatch | [README](https://github.com/apostoldevel/module-AppServer#readme) |
| [AuthServer](https://github.com/apostoldevel/module-AuthServer) | OAuth 2.0 (6 grant types), JWT, cookie auth, PKCE | [README](https://github.com/apostoldevel/module-AuthServer#readme) |
| [WebSocketAPI](https://github.com/apostoldevel/module-WebSocketAPI) | JSON-RPC + pub/sub over WebSocket | [README](https://github.com/apostoldevel/module-WebSocketAPI#readme) |
| [FileServer](https://github.com/apostoldevel/module-FileServer) | File serving from `db.file` with JWT authentication | [README](https://github.com/apostoldevel/module-FileServer#readme) |
| [PGHTTP](https://github.com/apostoldevel/module-PGHTTP) | HTTP → PL/pgSQL function dispatch | [README](https://github.com/apostoldevel/module-PGHTTP#readme) |
| [WebServer](https://github.com/apostoldevel/module-WebServer) | Static files, SPA support, Swagger UI | [README](https://github.com/apostoldevel/module-WebServer#readme) |

### Helpers — background modules in helper process

| Module | Description |
|--------|-------------|
| [PGFetch](https://github.com/apostoldevel/module-PGFetch) | LISTEN/NOTIFY → outbound HTTP requests |
| [PGFile](https://github.com/apostoldevel/module-PGFile) | LISTEN/NOTIFY → file sync (PostgreSQL ↔ filesystem) |

### Processes — independent background daemons

| Process | Description |
|---------|-------------|
| [MessageServer](https://github.com/apostoldevel/process-MessageServer) | Email/SMS/push dispatch via SMTP, FCM, HTTP API |
| [TaskScheduler](https://github.com/apostoldevel/process-TaskScheduler) | Cron-like job execution from `db.job` queue |
| [ReportServer](https://github.com/apostoldevel/process-ReportServer) | LISTEN-driven report generation |

Need fewer modules? Disable any in `conf/default.json`. Need more? Add [Replication](https://github.com/apostoldevel/process-Replication) or [StreamServer](https://github.com/apostoldevel/process-StreamServer).

## Entity System

The template includes **30 business entities** with full CRUD, REST endpoints, workflow states, and event handlers:

### References (catalogs)

`address` · `calendar` · `category` · `country` · `currency` · `format` · `measure` · `model` · `property` · `region` · `service`

### Documents (business records)

| Entity | Sub-entities | Purpose |
|--------|-------------|---------|
| `account` | `balance` | Financial accounts with temporal balance tracking |
| `card` | | Payment/identification cards |
| `client` | `name`, `customer`, `employee` | Core client entity with sub-classes |
| `company` | | Companies (hierarchical) |
| `device` | `station`, `caster` | IoT/GNSS devices |
| `identity` | | Identity documents (10 types) |
| `invoice` | | Invoices with auto-payment |
| `job` | | Scheduled tasks |
| `message` | | Email/SMS/push delivery |
| `order` | | Financial orders (debit/credit) |
| `payment` | `cloudpayments`, `yookassa` | Payment processing (two gateways) |
| `price` | | Price definitions |
| `product` | | Product catalog |
| `subscription` | | Time/volume-based subscriptions |
| `tariff` | | Tariff plans |
| `task` | | Background task execution |
| `transaction` | | Financial transaction records |

Each entity follows a [standard file convention](https://github.com/apostoldevel/db-platform/wiki/71-Creating-Entity):

```
entity/object/document/myentity/
├── table.sql       # CREATE TABLE, indexes, triggers
├── view.sql        # Kernel views (CREATE OR REPLACE)
├── routine.sql     # Create*/Edit*/Get*/Delete* functions
├── api.sql         # API schema views + CRUD wrappers
├── rest.sql        # REST dispatcher
├── event.sql       # Event handlers
├── init.sql        # Workflow: states, methods, transitions
├── create.psql     # Master create script
└── update.psql     # Master update script (excludes table.sql + init.sql)
```

## Extending the Template

### Add a new entity

1. Create a directory under `db/sql/configuration/apostol/entity/object/document/` or `.../reference/`
2. Follow the [entity file convention](https://github.com/apostoldevel/db-platform/wiki/71-Creating-Entity) — 8 SQL files per entity
3. Wire into `create.psql` / `update.psql`
4. Run `./runme.sh --install` (first time) or `--patch` (table changes)

Detailed guides: [Creating a Document](https://github.com/apostoldevel/db-platform/wiki/72-Creating-Document) · [Creating a Reference](https://github.com/apostoldevel/db-platform/wiki/73-Creating-Reference)

### Add a module or process

1. Clone from [apostoldevel](https://github.com/apostoldevel) into `src/modules/Workers/` or `src/processes/`
2. Register in `Workers.hpp` / `Processes.hpp`
3. Enable in `conf/default.json`
4. Rebuild

Guide: [Creating Modules](https://github.com/apostoldevel/libapostol/wiki/Creating-Modules) · [Creating Processes](https://github.com/apostoldevel/libapostol/wiki/Creating-Processes)

### Customize workflows

Every entity has a state machine defined in `init.sql`. Add custom states, methods, and transitions:

```sql
PERFORM AddState(uClass, rec_type, 'approved',  'Approved');
PERFORM AddMethod(uClass, uParent, 'Approve',   'Approve document');
PERFORM AddTransition(uState_Enabled, 'approve', uState_Approved);
```

Guide: [Workflow Customization](https://github.com/apostoldevel/db-platform/wiki/74-Workflow-Customization)

## Project Structure

```
backend/
├── src/
│   ├── app/main.cpp               # Entry point (ApostolCRMApp)
│   ├── lib/libapostol/            # C++20 framework (git submodule)
│   ├── modules/
│   │   ├── Workers/               # 6 HTTP handler modules
│   │   └── Helpers/               # 2 background helpers
│   └── processes/                 # 3 background processes
├── db/sql/
│   ├── platform/                  # db-platform (26 modules) — DO NOT EDIT
│   └── configuration/apostol/     # Project entities (30) — EDIT HERE
├── conf/
│   ├── default.json               # Server config (modules, postgres, server)
│   └── oauth2/                    # OAuth2 provider configs
├── www/docs/                      # Swagger UI + api.yaml (418 endpoints)
├── docker-compose.yml             # 5-service Docker stack
├── Dockerfile                     # Multi-stage C++20 build
└── configure                      # Downloads modules from GitHub
```

`libapostol` is a [git submodule](https://github.com/apostoldevel/libapostol). All modules, processes, and `db/sql/platform/` are separate repositories cloned by `./configure`.

## Database

| Command | Effect |
|---------|--------|
| `./runme.sh --update` | **Safe:** update routines and views only |
| `./runme.sh --patch` | Update tables + routines + views |
| `./runme.sh --install` | **Destructive:** drop/recreate DB with seed data |
| `./runme.sh --init` | **Destructive:** first-time setup (create users + install) |

All run from `db/` directory.

## Configuration

| File | Purpose |
|------|---------|
| `conf/default.json` | Main config — modules, server, PostgreSQL connections |
| `conf/oauth2/default.json` | OAuth2 clients (web, service, android, ios) |
| `conf/oauth2/google.json` | Google OAuth2 provider |
| `.env` | Docker environment (ports, DB credentials, secrets) |
| `db/sql/sets.psql` | Database name (`apostol`), encoding, search_path |
| `db/sql/.env.psql` | DB passwords, project settings, OAuth2 secrets |

## Process Signals

| Signal | Action |
|--------|--------|
| TERM, INT | Fast shutdown |
| QUIT | Graceful shutdown |
| HUP | Reload config, restart workers |
| WINCH | Graceful worker shutdown |

PID file: `/run/apostol-crm.pid`

## Ecosystem

Production projects built on the same frameworks:

| Project | Industry | Description                                                                             | Version |
|---------|----------|-----------------------------------------------------------------------------------------|:-------:|
| [**ChargeMeCar**](https://chargemecar.com/) | EV Charging | Charging Station Management System with OCPP 1.5/1.6/2.0.1 and OCPI                     | v2 |
| [**Apostol ARB**](https://arb.apostol-crm.com/) | FinTech | SaaS arbitrage aggregator for crypto futures (Binance, Bybit, OKX, MEXC, Bitget)        | v2 |
| [**PlugMe**](https://plugme.ru) | EV Charging | OCPP Central System — hundreds of stations, thousands of EV owners, payment integration | v1 |
| [**Ship Safety ERP**](https://ship-safety.ru) | Maritime | Automated ERP for maritime safety (SOLAS, ISM code compliance)                          | v1 |
| [**CopyFrog**](https://copyfrog.ai) | AI | AI-powered platform for images, ad copy, and marketing content                          | v1 |
| [**Talking to AI**](https://t.me/TalkingToAIBot) | AI | Telegram chatbot for AI conversations                                                   | v1 |
| [**DEBT-Master**](https://debt-master.ru) | Finance | Utility debt collection and management                                                  | v1 |
| [**Campus CORS**](https://cors.campusagro.com/) | Geodesy | GNSS correction data system with NTRIP Caster                                           | v1 |

## Documentation

| Resource | Description |
|----------|-------------|
| [libapostol Wiki](https://github.com/apostoldevel/libapostol/wiki) | C++20 framework — architecture, modules, processes, API reference |
| [db-platform Wiki](https://github.com/apostoldevel/db-platform/wiki) | PostgreSQL framework — 52 pages: API, entities, workflow, access control |
| [Getting Started](https://github.com/apostoldevel/libapostol/wiki/Getting-Started) | From empty project to full-stack backend |
| [OpenAPI Spec](www/docs/api.yaml) | 418 REST endpoints |
| `db/INDEX.md` | Database layer overview |
| `db/CLAUDE.md` | Database commands and conventions |

## License

[MIT](LICENSE)

---

[^crm]: **Apostol CRM** — a template project built on the [A-POST-OL](https://github.com/apostoldevel/libapostol) (C++20) and [PostgreSQL Framework for Backend Development](https://github.com/apostoldevel/db-platform) frameworks.
