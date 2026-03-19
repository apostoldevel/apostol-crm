# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

PostgreSQL database layer for **Project Example**. Built on the **apostoldevel/db-platform** framework -- a reusable PL/pgSQL application server framework providing auth, sessions, workflow engine, entity system, notifications, and more.

## Quick Navigation

For structured overviews of every module, table, function, and REST route:

- **[INDEX.md](INDEX.md)** -- Top-level overview (platform + configuration)
- **[sql/configuration/apostol/INDEX.md](sql/configuration/apostol/INDEX.md)** -- Master configuration overview (loading order, class tree, module index)
- **[sql/configuration/apostol/entity/INDEX.md](sql/configuration/apostol/entity/INDEX.md)** -- Entity class tree with links to all 30 entities
- Each module directory has its own `INDEX.md` with tables, functions, REST routes, and file manifests

## Platform Documentation

- **Wiki** (52 pages): https://github.com/apostoldevel/db-platform/wiki
- **Platform README** with module list: `sql/platform/README.md`

## Database Commands

All commands run from this `db/` directory:

```bash
./runme.sh --update    # Safe: updates routines and views only (no data loss)
./runme.sh --patch     # Updates tables + routines + views (runs patch scripts first)
./runme.sh --install   # DESTRUCTIVE: drops/recreates DB with data
./runme.sh --init      # DESTRUCTIVE: creates users + full install (first-time only)
./runme.sh --create    # DESTRUCTIVE: drops/recreates DB without data
./runme.sh --api       # Drops and recreates only the api schema
```

Under the hood, `runme.sh` calls `install.sh --<option>`, which runs:
```bash
sudo -u postgres -H psql -d template1 -f sql/<option>.psql
```

Logs go to `log/<option>.log`.

**Day-to-day development**: use `--update` after changing routines/views/api/rest files. Use `--patch` when table DDL changes are needed.

## Testing

SQL tests use **pgTAP** framework. Tests run against a temporary `example_test` database created from a template of the dev database.

### Prerequisites

```bash
sudo apt-get install postgresql-18-pgtap libtap-parser-sourcehandler-pgtap-perl
```

### Running Tests

```bash
./test/run.sh                              # Run all tests
./test/run.sh test/sql/balance_test.sql    # Run one file
./test/run.sh --keep                       # Keep test DB after run (for debugging)
./runme.sh --test                          # Via dashboard
```

### Test Structure

```
test/
├── run.sh                     # Test runner (creates/destroys test DB)
├── setup.sql                  # pgTAP extension + test helper functions
├── fixtures.sql               # Shared test data (test client, accounts)
└── sql/
    ├── balance_test.sql       # Balance temporal logic (CheckBalance, UpdateBalance, ChangeBalance)
    ├── invoice_test.sql       # Invoice aggregation (BuildInvoice)
    ├── payment_test.sql       # Payment creation and state transitions
    └── subscription_test.sql  # Subscription tiers and SubscriptionPaid
```

### Writing Tests

Each test file follows this pattern:
1. `BEGIN;` — wrap in transaction
2. `SELECT plan(N);` — declare expected test count
3. `SELECT test_setup_session();` — establish admin session
4. `DO $$ ... $$;` — setup block with `set_config()` to store test IDs
5. `SELECT is(...)`, `SELECT ok(...)`, `SELECT throws_ok(...)` etc.
6. `SELECT * FROM finish();`
7. `ROLLBACK;` — clean up (no side effects on test DB)

Helper functions in `setup.sql`: `test_setup_session()`, `test_create_client()`, `test_create_account()`, `test_create_product()`, `test_create_price()`.

### Integration Tests

`yookassa_integration_test.sql` tests the full payment flow: session → bind card → create invoice → create payment. Requires YooKassa test credentials configured in registry. Test card: `2202474301322987`, expiry: `2027-12`, CVC: `111`. Run separately:

```bash
./test/run.sh test/sql/yookassa_integration_test.sql
```

## Two-Layer Architecture

```
sql/
  platform/        ← Framework (separate git repo: apostoldevel/db-platform). DO NOT edit here.
  configuration/   ← Application-specific code (apostol/). Edit here.
```

The `\set dbname apostol` in `sets.psql` determines which configuration directory is used. Execution order is always platform first, then configuration:

```
install.psql  →  platform/create.psql  →  configuration/create.psql
update.psql   →  platform/update.psql  →  configuration/update.psql
patch.psql    →  platform/patch.psql   →  platform/update.psql  →  configuration/patch.psql  →  configuration/update.psql
```

## Platform Modules

25 modules in `sql/platform/`, loaded in dependency order by `create.psql`. Grouped by function:

- **Core:** kernel (types, JWT), oauth2 (clients, audiences), locale (i18n), admin (users, auth, sessions, ACL), exception (~84 error functions)
- **Infrastructure:** http (outbound request queue), resource (locale-aware content), registry (key-value config), log (structured events), api (REST routing, request log), replication (multi-instance sync), daemon (C++ interface)
- **Session:** session (context setters), current (context getters)
- **Business logic:** workflow (state machine: 23 tables), entity (object hierarchy: 27 tables), file (virtual FS + S3), kladr (Russian address classifier)
- **Communication:** notice (user alerts), comment (threaded comments), notification (event audit trail), verification (email/phone codes), observer (pub/sub events)
- **Reporting:** report (definition + generation framework), reports (built-in report routines)

## Database Schemas

| Schema | Purpose |
|--------|---------|
| `db` | All tables live here (always use `db.` prefix) |
| `kernel` | Core business logic functions (in search_path, no prefix needed) |
| `api` | API-facing views and CRUD functions |
| `rest` | REST endpoint dispatcher functions |
| `oauth2` | OAuth2 authentication |
| `daemon` | Daemon-specific functions |
| `ntrip` | NTRIP-specific tables and functions |

Users: `kernel` (schema owner/DDL), `admin` (app admin), `daemon` (background), `apibot` (API), `ntrip` (NTRIP service).

## Entity File Convention

Each entity (e.g., `entity/object/document/device/station/`) follows this structure:

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | DDL: CREATE TABLE, indexes, triggers |
| `view.sql` | yes | yes | CREATE OR REPLACE VIEW |
| `exception.sql` | yes | yes | Exception/error functions |
| `routine.sql` | yes | yes | Core logic: Create*, Edit*, Get*, Delete* |
| `api.sql` | yes | yes | API schema views + CRUD wrappers |
| `rest.sql` | yes | yes | REST dispatcher in `rest` schema |
| `event.sql` | yes | yes | Event handlers: Event*Create, Event*Edit |
| `init.sql` | yes | no | Workflow states, methods, transitions, entity registration |

Each entity also has `create.psql` (includes all files) and `update.psql` (excludes table.sql and init.sql).

## Workflow Concepts

The platform's workflow engine is a state machine that drives every entity's lifecycle:

- **Class hierarchy:** Entity → Class → Type (e.g., `object` → `document` → `client`)
- **State machine:** each entity type defines States, Methods, and Transitions
- **Flow:** Action (e.g., `DoEnable`) → Method executes → Event fires (`EventClientEnable`) → State transitions
- **Registration:** each entity's `init.sql` calls `AddState`, `AddMethod`, `AddTransition` to wire up the state machine

See wiki: [Workflow](https://github.com/apostoldevel/db-platform/wiki/04-Workflow), [Workflow Customization](https://github.com/apostoldevel/db-platform/wiki/74-Workflow-Customization).

## SQL Coding Conventions

**Function naming:**
- `Create*` / `Edit*` / `Get*` / `Delete*` -- CRUD
- `Do*` -- state transition actions (DoEnable, DoDisable)
- `Event*` -- event handlers
- `Init*` / `Fill*` -- initialization/seeding
- `ft_*` -- trigger functions; `t_*` -- trigger names

**Parameter/variable prefixes:**
- Parameters: `p` prefix (`pParent`, `pType`, `pIdentifier`)
- UUIDs: `u` prefix; text: `v` prefix; numeric: `n` prefix; records: `r` or `rec_` prefix

**Function signature pattern:**
```sql
CREATE OR REPLACE FUNCTION FunctionName (...)
RETURNS ...
AS $$
...
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
```

**Tables:** all in `db` schema, UUID primary keys via `gen_kernel_uuid()`, comments in Russian.
**Views:** PascalCase in `kernel` schema (`Station`, `AccessStation`); lowercase in `api` schema (`api.station`).
**REST:** `rest.entity_name(pPath text, pPayload jsonb)` with CASE-based path routing.

## Configuration

- `sql/sets.psql` -- database name, encoding, search_path, KLADR paths
- `sql/.env.psql` -- passwords, project settings (`set_config()`), OAuth2 secrets, payment keys, company data
- Runtime config uses a registry pattern: `RegSetValueString('CONFIG\Path', 'key', 'value')` in init.sql

## Key Directories Under `configuration/apostol/`

- `admin/` -- DoLogin, DoLogout, DoCreateArea overrides
- `entity/object/document/` -- 18 document entities: account, card, client, company, device (with station/ and caster/ sub-entities), identity, invoice, job, message, network, order, payment, price, product, subscription, tariff, task, transaction
- `entity/object/reference/` -- 12 reference entities: address, calendar, category, country, currency, format, measure, model, navigation, property, region, service
- `ntrip/` -- separate `ntrip` schema with its own user, tables, views, routines, api, and rest files
- `api/` -- API event callbacks
- `observer/` -- observer pattern configuration
- `init.sql` -- `InitConfiguration()` chains to entity registration, reference data, `FillDataBase()`
