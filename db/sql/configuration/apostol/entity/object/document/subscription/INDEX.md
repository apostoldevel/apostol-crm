# subscription

> Configuration entity -- document | Loaded by `document/create.psql` line 18

Client subscription management with Stripe-like billing semantics. Tracks subscription periods, pricing plans, and payment collection methods. Supports trial periods, automatic charging, and plan switching with balance replenishment per product tier (Basic/Standard/Pro).

## Dependencies

- `price` -- each subscription references a price record
- `client` -- optional client association with ACL propagation
- `product` -- resolved through price for tier-based replenishment
- `category` -- chat/text/media categories for balance allocation
- Platform: `document`, `object`, `aou` (access control)

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Table `subscription`, triggers |
| `kernel` | Views `Subscription`, `AccessSubscription`, `ObjectSubscription`; routines |
| `api` | View `api.subscription`; CRUD + list/count functions |
| `rest` | Dispatcher `rest.subscription()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.subscription` | id, document, price, client, code, customer, period_start, period_end, metadata, current | Subscription record with billing period and Stripe customer reference |

**Indexes:** document, price, client, customer, UNIQUE(code)

**Triggers (3):**
- `t_subscription_insert` -- BEFORE INSERT: sets id, generates code (`sub_*`), grants client read/write ACL
- `t_subscription_after_update` -- AFTER UPDATE (client change): migrates ACL from old to new client
- `t_subscription_price_update` -- AFTER UPDATE (price change): calls `SubscriptionSwitch` to rebalance

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Subscription` | kernel | Joins subscription with type, state, client, price, product, currency |
| `AccessSubscription` | kernel | ACL-filtered subscription access |
| `ObjectSubscription` | kernel | Full object view with entity, class, owner, area, scope metadata |
| `api.subscription` | api | Exposes `ObjectSubscription` |

## Functions

**kernel schema (9):**
- `CreateSubscription(pParent, pType, pPrice, pClient, pCustomer, pCode, pPeriodStart, pPeriodEnd, pMetaData, pLabel, pDescription)` -- creates subscription document
- `EditSubscription(pId, ...)` -- updates subscription fields
- `GetSubscription(pCode)` -- lookup by code
- `GetSubscriptionProductName(pSubscription)` -- resolves product name through price
- `Replenishment(pParent, pCategory, pClient, pAmount)` -- allocates balance to client accounts (stub)
- `SubscriptionPaid(pId)` -- applies tier-based balance (Basic/Standard/Pro quotas), marks current
- `SubscriptionCanceled(pId)` -- cancels active transactions, zeroes balances, clears current flag
- `SubscriptionSwitch(pOld, pNew)` -- cancel old + pay new
- `GetCurrentSubscription(pClient)` -- returns active current subscription for client
- `GetSubscriptionJson(pClient)` -- returns all enabled subscriptions as JSON array

**api schema (6):**
- `api.add_subscription` -- defaults to type `charge_automatically.subscription`
- `api.update_subscription` -- lookup by id or code
- `api.set_subscription` -- upsert
- `api.get_subscription` -- with access check
- `api.count_subscription` -- non-admin scoped to current client
- `api.list_subscription` -- non-admin scoped to current client

**Event functions (13):**
- `EventSubscriptionCreate`, `EventSubscriptionOpen`, `EventSubscriptionEdit`, `EventSubscriptionSave`
- `EventSubscriptionEnable` -- trial activation
- `EventSubscriptionPay` -- calls `SubscriptionPaid()`
- `EventSubscriptionExpire`, `EventSubscriptionCancel` -- cancel triggers fallback to next subscription
- `EventSubscriptionStop`, `EventSubscriptionFail`
- `EventSubscriptionDisable`, `EventSubscriptionDelete`, `EventSubscriptionRestore`, `EventSubscriptionDrop`

## REST Routes

Dispatcher: `rest.subscription(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/subscription/type` | List subscription types |
| `/subscription/method` | Get available methods for subscription instance |
| `/subscription/count` | Count with search/filter |
| `/subscription/set` | Upsert subscription |
| `/subscription/get` | Get by id with field selection |
| `/subscription/list` | List with search/filter/pagination |

## Workflow States / Methods / Transitions

**Types:** `charge_automatically.subscription`, `send_invoice.subscription`

**States (7):**
- `incomplete` (created) -- initial state after creation
- `trialing` (enabled) -- trial period
- `active` (enabled) -- paid and active
- `past_due` (disabled) -- payment overdue
- `unpaid` (disabled) -- payment failed
- `incomplete_expired` (deleted) -- expired before completion
- `canceled` (deleted) -- explicitly canceled

**Key transitions:**
- incomplete -> active (pay), trialing (enable), incomplete_expired (expire)
- trialing -> active (pay), canceled (cancel), past_due (stop), unpaid (fail)
- active -> canceled (cancel), past_due (stop), unpaid (fail)
- past_due/unpaid -> active (pay), canceled (cancel)
- incomplete_expired/canceled -> incomplete (restore)

## Init / Seed Data

- `CreateEntitySubscription(pParent)` -- registers entity, class, types, events, methods, transitions
- `AddSubscriptionMethods(pClass)` -- defines state machine
- `AddSubscriptionEvents(pClass)` -- wires 14 event handlers
- Registers REST route: `subscription`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | Table DDL, indexes, 3 triggers |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | (empty) |
| `routine.sql` | yes | yes | 10 kernel + 6 api functions |
| `api.sql` | yes | yes | 1 api view, 6 api functions |
| `rest.sql` | yes | yes | REST dispatcher (6 routes) |
| `event.sql` | yes | yes | 13 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
