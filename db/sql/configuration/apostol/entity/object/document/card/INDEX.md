# card

> Configuration entity -- document | Loaded by `document/create.psql` line 6

Payment and identification card management. Supports RFID, credit, and plastic card types. Tracks card data bindings with external payment agents, card sequencing/sorting, and encrypted card data storage.

## Dependencies

- `client` -- each card is linked to a client
- Platform: `document`, `object`, `aou` (access control)

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Tables `card`, `card_data`, triggers |
| `kernel` | Views `Card`, `AccessCard`, `ObjectCard`; routines |
| `api` | View `api.card`; CRUD + bind/unbind functions |
| `rest` | Dispatcher `rest.card()` |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.card` | id, document, client, code, name, expiry, binding, sequence | Card record with expiry date, binding flag, and display order |
| `db.card_data` | card, agent, card_id, binding, encrypted, data, created, updated | External payment agent card data storage |

**Indexes (card):** client, UNIQUE(code)
**Indexes (card_data):** PRIMARY KEY(card, agent)

**Triggers (4):**
- `t_card_before_insert` -- BEFORE INSERT: sets id, generates code, grants client read/write ACL
- `t_card_after_insert` -- AFTER INSERT: sets object owner to client's userId
- `t_card_before_update` -- BEFORE UPDATE: checks write access
- `t_card_after_update_client` -- AFTER UPDATE (client change): migrates AOUs from old to new client

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Card` | kernel | Joins card with type, state, client |
| `AccessCard` | kernel | ACL-filtered card access |
| `ObjectCard` | kernel | Full object view with entity, class, owner, area, scope metadata |
| `api.card` | api | Exposes `ObjectCard` |

## Functions

**kernel schema (11):**
- `CreateCard(pParent, pType, pClient, pCode, pName, pExpiry, pLabel, pDescription)` -- creates card document
- `EditCard(pId, ...)` -- updates card fields
- `GetCard(pCode)` -- lookup by code
- `GetCardCode(pCard)` -- returns code
- `GetCardClient(pCard)` -- returns client uuid
- `GetClientCardsJson(pClient)` -- returns client's cards as JSON
- `SetCardSequence(pCard, pSequence, pDate)` -- sets display order
- `SortCard()` -- reorders all cards for current client
- `GetCardBindingsJson(pClient)` -- returns card bindings with agent data as JSON
- `SetCardData(pCard, pAgent, pCardId, pBinding, pEncrypted, pData)` -- upserts external card data
- `ClearCardData(pCard, pAgent)` -- removes external card data

**api schema (10):**
- `api.card(uuid)` -- lookup by id
- `api.card(text)` -- lookup by code
- `api.add_card` -- create card
- `api.update_card` -- update card
- `api.set_card` -- upsert
- `api.get_card` -- with access check
- `api.count_card` -- non-admin scoped to current client
- `api.list_card` -- non-admin scoped to current client
- `api.bind_card(pCard, pAgent, pData)` -- bind card to payment agent
- `api.unbind_card(pCard, pAgent)` -- unbind card from payment agent

**Event functions (9):**
- `EventCardCreate` -- auto-enables card
- `EventCardOpen`, `EventCardEdit`, `EventCardSave`
- `EventCardEnable`, `EventCardDisable`
- `EventCardDelete`, `EventCardRestore`, `EventCardDrop`

## REST Routes

Dispatcher: `rest.card(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/card/type` | List card types |
| `/card/method` | Get available methods for card instance |
| `/card/count` | Count with search/filter |
| `/card/set` | Upsert card |
| `/card/get` | Get by id with field selection |
| `/card/list` | List with search/filter/pagination |
| `/card/bind` | Bind card to payment agent |
| `/card/unbind` | Unbind card from payment agent |

## Workflow States / Methods / Transitions

**Types:** `rfid.card`, `credit.card`, `plastic.card`

**States (4):**
- `created` (created) -- initial state
- `enabled` (enabled) -- active card
- `disabled` (disabled) -- suspended
- `deleted` (deleted) -- soft-deleted

**Key transitions:**
- created -> enabled (enable), deleted (delete)
- enabled -> disabled (disable)
- disabled -> enabled (enable), deleted (delete)
- deleted -> created (restore)

## Init / Seed Data

- `CreateEntityCard(pParent)` -- registers entity, class, types, events, methods, transitions
- `CreateClassCard(pParent, pEntity)` -- creates class with 3 types
- `AddCardEvents(pClass)` -- wires 9 event handlers
- Registers REST route: `card`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | 2 tables DDL, indexes, 4 triggers |
| `view.sql` | yes | yes | 3 kernel views |
| `exception.sql` | yes | yes | 2 exception functions |
| `routine.sql` | yes | yes | 11 kernel functions |
| `api.sql` | yes | yes | 1 api view, 10 api functions |
| `rest.sql` | yes | yes | REST dispatcher (8 routes) |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, workflow setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
