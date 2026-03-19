# entity/object/document

> Configuration — document entity hierarchy

Eighteen document entities (plus 9 sub-entities) implementing the core business logic: clients, companies, devices (stations/casters), payments, subscriptions, billing, and NTRIP-related operations.

## Loading Order (document/create.psql)

```
document/
  event.sql                ← Shared EventDocumentCreate override
  company/create.psql      ← Hierarchical company management
  client/create.psql       ← Core client entity
  │  ├── name/             ← Locale-aware temporal names
  │  ├── customer/         ← Customer sub-class (auto-creates accounts)
  │  └── employee/         ← Employee sub-class
  card/create.psql         ← Payment/identification cards
  account/create.psql      ← Financial accounts
  │  └── balance/          ← Temporal balance tracking
  device/create.psql       ← IoT/GNSS devices
  │  ├── station/          ← GNSS base stations
  │  └── caster/           ← NTRIP casters
  identity/create.psql     ← Identity documents (passport, INN, etc.)
  invoice/create.psql      ← Invoice management with auto-payment
  job/create.psql          ← Thin: periodic job event overrides
  message/create.psql      ← Thin: email/SMS/push delivery overrides
  order/create.psql        ← Financial orders (debit/credit)
  payment/create.psql      ← Payment processing hub
  │  ├── cloudpayments/    ← CloudPayments gateway
  │  └── yookassa/         ← YooKassa gateway
  product/create.psql      ← Product catalog
  price/create.psql        ← Price management
  subscription/create.psql ← Time/volume-based subscriptions
  tariff/create.psql       ← Tariff plans (bundle subscriptions)
  task/create.psql         ← Background tasks
  transaction/create.psql  ← Financial transactions
```

## Entity Index

| Entity | Tables | Sub-entities | Key Feature |
|--------|--------|-------------|-------------|
| [account](account/INDEX.md) | 1 | [balance](account/balance/INDEX.md) | Currency-based financial accounts |
| [card](card/INDEX.md) | 2 | — | RFID/credit/plastic card binding |
| [client](client/INDEX.md) | 1 | [name](client/name/INDEX.md), [customer](client/customer/INDEX.md), [employee](client/employee/INDEX.md) | Core client with confirm/reconfirm workflow |
| [company](company/INDEX.md) | 1 | — | Hierarchical company structure |
| [device](device/INDEX.md) | 4 | [station](device/station/INDEX.md), [caster](device/caster/INDEX.md) | GNSS devices with heartbeat/availability |
| [identity](identity/INDEX.md) | 1 | — | 10 identity document types |
| [invoice](invoice/INDEX.md) | 1 | — | Auto-payment with card cycling |
| [job](job/INDEX.md) | — | — | Thin: periodic job rescheduling |
| [message](message/INDEX.md) | — | — | Thin: email/SMS/push/FCM delivery |
| [order](order/INDEX.md) | 1 | — | Debit/credit with balance operations |
| [payment](payment/INDEX.md) | 1 | [cloudpayments](payment/cloudpayments/INDEX.md), [yookassa](payment/yookassa/INDEX.md) | Payment processing with reservations |
| [price](price/INDEX.md) | 1 | — | One-off/recurring price definitions |
| [product](product/INDEX.md) | 1 | — | Product catalog with cascade enable |
| [subscription](subscription/INDEX.md) | 1 | — | Time/volume-based subscriptions |
| [tariff](tariff/INDEX.md) | 1 | — | Tariff plans bundling subscriptions |
| [task](task/INDEX.md) | 1 | — | Background task execution |
| [transaction](transaction/INDEX.md) | 1 | — | Financial transaction records |

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `event.sql` | yes | yes | Shared EventDocumentCreate override |
| `*/create.psql` | yes | — | 18 entity sub-modules |
| `create.psql` | — | — | Loads event.sql + 18 entities |
| `update.psql` | — | — | Loads event.sql + 18 entity updates |
