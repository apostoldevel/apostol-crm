# address

> Configuration entity -- reference | Loaded by `reference/create.psql` line 5

Object address reference with KLADR integration, country FK, and full address fields. Supports linking addresses to other objects via object_link with temporal validity.

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: reference, object, type, scope, state, user, aou, object_link, kladr (address_tree, GetAddressTreeString); country (FK) | client, company, station (conceptual address assignment via object_link) |

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Tables, trigger function |
| `kernel` | Views, functions |
| `api` | API views, functions |
| `rest` | REST dispatcher |

## Tables -- 1

| Table | Description | Key Columns |
|-------|-------------|-------------|
| `db.address` | Object address | `id`, `reference`, `country` uuid FK, `kladr` text, `index` text, `region` text, `district` text, `city` text, `settlement` text, `street` text, `house` text, `building` text, `structure` text, `apartment` text, `sortnum` integer |

## Indexes -- 6

| Index on |
|----------|
| `reference` |
| `country` |
| `kladr` |
| `index` |
| `city` |
| `street` |

## Triggers -- 1

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `t_address_insert` | `db.address` | BEFORE INSERT | Auto-sets `id` from `reference` |

## Views

### kernel schema

| View | Source | Grants |
|------|--------|--------|
| `Address` | `db.address` + reference + type + scope | administrator |
| `AccessAddress` | `db.address` + `db.aou` + member_group | administrator |
| `ObjectAddress` | `db.address` + full object/entity/class/type/state/user joins | administrator |
| `ObjectAddresses` | `db.object_link` + `db.address` (linked addresses with temporal validity) | administrator |

### api schema

| View | Source | Purpose |
|------|--------|---------|
| `api.address` | `ObjectAddress` | Public API view for addresses |
| `api.object_address` | `ObjectAddresses` | Public API view for object-address links |

## Functions (kernel schema) -- 8

| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateAddress(pParent, pType, pCountry, pCode, pKladr, pIndex, pRegion, pDistrict, pCity, pSettlement, pStreet, pHouse, pBuilding, pStructure, pApartment, pAddressText)` | `uuid` | Creates an address (auto-builds display string from fields or KLADR) |
| `EditAddress(pId, ...)` | `void` | Edits an address |
| `GetAddress(pCode)` | `uuid` | Finds address by code |
| `GetAddressString(pId)` | `text` | Builds full address string from fields or KLADR |
| `GetObjectAddress(pObject, pKey, pDate)` | `text` | Returns address string for an object by key and date |
| `GetObjectAddresses(pObject, pDate)` | `text[]` | Returns all addresses for an object as text array |
| `GetObjectAddressesJson(pObject, pDate)` | `json` | Returns all addresses for an object as JSON |
| `GetObjectAddressesJsonb(pObject, pDate)` | `jsonb` | Returns all addresses for an object as JSONB |

## Functions (kernel schema, parsing) -- 1

| Function | Returns | Purpose |
|----------|---------|---------|
| `AddressStringToJsonb(pString, pAddress)` | `jsonb` | Parses free-text address string into structured JSONB with KLADR lookup (~25 street type synonyms recognized) |

## Functions (api schema) -- 16

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.add_address(pParent, pType, pCountry, pCode, pKladr, pIndex, pRegion, pDistrict, pCity, pSettlement, pStreet, pHouse, pBuilding, pStructure, pApartment, pAddressText)` | `uuid` | Add an address |
| `api.update_address(pId, ...)` | `void` | Update an address |
| `api.set_address(pId, ...)` | `SETOF api.address` | Upsert an address |
| `api.get_address(pId)` | `SETOF api.address` | Get address by ID |
| `api.count_address(pSearch, pFilter)` | `SETOF bigint` | Count addresses with filtering |
| `api.list_address(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.address` | List addresses with filtering |
| `api.get_address_string(pId)` | `text` | Get address as formatted string |
| `api.set_object_addresses(pObject, pAddress, pParent, pType, pCountry, pCode, ...)` | `SETOF api.object_address` | Upsert address and link to object |
| `api.set_object_addresses_json(pObject, pAddresses)` | `SETOF api.object_address` | Set object addresses from JSON array |
| `api.set_object_addresses_jsonb(pObject, pAddresses)` | `SETOF api.object_address` | Set object addresses from JSONB |
| `api.get_object_addresses_json(pObject)` | `json` | Get object addresses as JSON |
| `api.get_object_addresses_jsonb(pObject)` | `jsonb` | Get object addresses as JSONB |
| `api.set_object_address(pObject, pAddress, pDateFrom)` | `SETOF api.object_address` | Link address to object with date |
| `api.delete_object_address(pObject, pAddress)` | `void` | Unlink address from object |
| `api.get_object_address(pObject, pAddress)` | `SETOF api.object_address` | Get specific object-address link |
| `api.list_object_address(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.object_address` | List object-address links with filtering |

## REST Routes -- 11

Dispatcher: `rest.address(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/address/tree/get` | Get address tree entry by ID |
| `/address/tree/count` | Count address tree entries |
| `/address/tree/list` | List address tree entries |
| `/address/tree/history` | Get address tree change history |
| `/address/tree/string` | Get formatted address string from KLADR code |
| `/address/type` | List entity types |
| `/address/method` | Get available methods for an address |
| `/address/set` | Create or update an address |
| `/address/get` | Get an address by ID |
| `/address/get/string` | Get address as formatted string |
| `/address/count` | Count addresses with optional filtering |
| `/address/list` | List addresses with filtering/pagination |

## Workflow States / Methods / Transitions

Defined via `AddDefaultMethods` (default labels).

Types registered: `post.address` -- "Postal" (Postal address), `actual.address` -- "Actual" (Actual address), `legal.address` -- "Legal" (Legal address).

## Notable Event Behavior

On `enable` and `disable`, the address entity cascades the state change to all children via `ExecuteMethodForAllChild()`.

On `drop`, `EventAddressDrop` also deletes all `object_link` records referencing the address.

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | `db.address` table, 6 indexes, insert trigger |
| `exception.sql` | yes | yes | Reserved (empty) |
| `view.sql` | yes | yes | Address, AccessAddress, ObjectAddress, ObjectAddresses views |
| `routine.sql` | yes | yes | CreateAddress, EditAddress, GetAddress, GetAddressString, GetObject* helpers, AddressStringToJsonb |
| `api.sql` | yes | yes | api.address + api.object_address views + 16 functions |
| `rest.sql` | yes | yes | REST dispatcher with 12 routes (address/* + address/tree/*) |
| `event.sql` | yes | yes | 9 event handlers (enable/disable cascade to children) |
| `init.sql` | yes | no | Entity/class/type registration (3 address types) |
