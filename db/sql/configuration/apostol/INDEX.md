# example

> Configuration — Project Example application

Application-specific database configuration for the Project Example GNSS correction data platform. Built on top of the [db-platform](https://github.com/apostoldevel/db-platform) framework, this layer adds 30 business entities, NTRIP protocol support, payment integrations, and reporting.

## Loading Order (example/create.psql)

```
apostol/
  admin/create.psql        ← Platform hook overrides (DoLogin, DoLogout, DoCreateArea, etc.)
  entity/create.psql       ← 30 business entities (12 reference + 18 document + 9 sub-entities)
  priority/create.psql     ← REST endpoint for platform priority entity
  api/create.psql          ← API extensions (signup, whoami, garbage_collector)
  report/create.psql       ← 3 reports (user list, session list, file import)
  observer/create.psql     ← Observer subscriptions (confirmation, urgent)
  confirmation/create.psql ← Payment confirmation flow with pg_notify
  notice/create.psql       ← Notice view override for station notifications
  oauth2.sql               ← OAuth2 providers, applications, audiences
  routine.sql              ← Email/password recovery text templates
  init.sql                 ← InitConfiguration() + FillDataBase()
```

## Module Index

| Module | Type | Description |
|--------|------|-------------|
| [admin/](admin/INDEX.md) | Override | 9 platform hook functions (login/logout/area/role management) |
| [entity/](entity/INDEX.md) | Hierarchy | 30 entities — full class tree |
| [priority/](priority/INDEX.md) | REST-only | 3 routes for platform priority entity |
| [api/](api/INDEX.md) | Extension | signup, whoami, garbage_collector, email confirmation |
| [report/](report/INDEX.md) | Reports | User list, session list, file import |
| [observer/](observer/INDEX.md) | Hooks | Confirmation + urgent publisher subscriptions |
| [confirmation/](confirmation/INDEX.md) | Full module | Payment confirmation table with pg_notify triggers |
| [notice/](notice/INDEX.md) | Override | Station notification visibility in Notice view |

## Entity Class Tree

```
object (platform)
├── reference (12 entities)
│     ├── address, calendar, category, country, currency, format
│     ├── measure, model, property, region, service
└── document (18 entities + 9 sub-entities)
      ├── account (+balance), card, client (+name/customer/employee)
      ├── company, device (+station/caster), identity, invoice
      ├── job*, message*, order, payment (+cloudpayments/yookassa)
      ├── price, product, subscription, tariff, task, transaction
```
\* Thin overrides only (no tables)

## Key Schemas

| Schema | Owned by | Purpose |
|--------|----------|---------|
| `db` | kernel | All configuration tables |
| `kernel` | kernel | Business logic functions, views |
| `api` | kernel | API-facing views and functions |
| `rest` | kernel | REST endpoint dispatchers |

## InitConfiguration() Flow

1. Registry settings (project name, host, domain, currency, payment system)
2. `InitConfigurationEntity()` — registers 30 entity classes
3. `InitConfigurationReport()` — registers 3 reports
4. `InitMeasure()` — seeds ~50 measurement units
5. `InitCountry()` — seeds ~240 countries
6. `InitCurrency()` — seeds RUB, USD, EUR
7. `InitRegion()` — seeds ~70 RF regions
8. `FillDataBase()` — creates scope aliases, groups/interfaces (employee/customer/accountant), default company, accounts, identities, calendar, scheduled jobs, vendors/models, data formats, services, product, prices, ACL permissions, demo user
9. `InitTariffScheme()` — sets up default tariff structure

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `admin/create.psql` | yes | — | Platform hook overrides |
| `entity/create.psql` | yes | — | All 30 entities |
| `priority/create.psql` | yes | — | Priority REST endpoint |
| `api/create.psql` | yes | — | API extensions |
| `report/create.psql` | yes | — | Report definitions |
| `observer/create.psql` | yes | — | Observer subscriptions |
| `confirmation/create.psql` | yes | — | Confirmation table + triggers |
| `notice/create.psql` | yes | — | Notice view override |
| `oauth2.sql` | yes | no | OAuth2 setup (algorithms, providers, applications, audiences) |
| `routine.sql` | yes | yes | Email text templates (recovery, registration) |
| `init.sql` | yes | no | `InitConfiguration()` + `FillDataBase()` |
| `create.psql` | — | — | Master create script |
| `update.psql` | — | — | Master update script |
