# device

> Configuration entity -- document | Loaded by `document/create.psql` line 9

IoT device management with GNSS-specific extensions. Tracks devices with model, client ownership, connection state, and temporal notification/value/data storage. Registers custom actions (heartbeat, available, unavailable, faulted) for device lifecycle beyond standard CRUD. Parent entity for `station/` and `caster/` sub-classes.

## Dependencies

- `client` -- optional device owner
- `model` -- device hardware model (reference entity)
- Platform: `document`, `object`, `aou` (access control)

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Tables `device`, `device_notification`, `device_value`, `device_data`, sequences, triggers |
| `kernel` | Views `Device`, `AccessDevice`, `ObjectDevice`, `DeviceNotification`, `DeviceValue`, `DeviceData`; routines |
| `api` | Views `api.device`, `api.device_notification`, `api.device_value`, `api.device_data`; CRUD + init/switch functions |
| `rest` | Dispatcher `rest.device()` |

## Sequences

| Sequence | Description |
|----------|-------------|
| `db.sequence_status` | Status sequence counter |
| `db.sequence_transaction` | Transaction sequence counter |

## Tables

| Table | Columns | Description |
|-------|---------|-------------|
| `db.device` | id, document, model, client, identifier, pswhash, version, serial, host, ip, iccid, imsi, connected, connect_updated, metadata |
| `db.device_notification` | id, device, interfaceId, status, errorCode, info, vendorErrorCode, validFromDate, validToDate | Temporal device status notifications |
| `db.device_value` | id, device, type, value, validFromDate, validToDate | Temporal device JSON values |
| `db.device_data` | id, device, agent, data, validFromDate, validToDate | Temporal device binary data |

**Indexes (device):** model, client, UNIQUE(identifier)
**Indexes (device_notification):** device, UNIQUE(device, interfaceId, validFromDate, validToDate)
**Indexes (device_value):** device, UNIQUE(device, type, validFromDate, validToDate)
**Indexes (device_data):** device, UNIQUE(device, agent, validFromDate, validToDate)

**Triggers (2):**
- `t_device_before_insert` -- BEFORE INSERT: sets id from document
- `t_device_before_update` -- BEFORE UPDATE: checks write access

## Sub-entities

| Directory | Description |
|-----------|-------------|
| `station/` | Base station sub-class with NTRIP mount points and transactions |
| `caster/` | NTRIP Caster sub-class for relaying GNSS correction data |

## Views

| View | Schema | Description |
|------|--------|-------------|
| `Device` | kernel | Joins device with type, model, vendor, client |
| `AccessDevice` | kernel | ACL-filtered device access |
| `ObjectDevice` | kernel | Full object view with mountpoint from station_transaction |
| `DeviceNotification` | kernel | Wrapper over `db.device_notification` |
| `DeviceValue` | kernel | Wrapper over `db.device_value` |
| `DeviceData` | kernel | Wrapper over `db.device_data` |
| `api.device` | api | Exposes `ObjectDevice` |
| `api.device_notification` | api | Exposes `DeviceNotification` |
| `api.device_value` | api | Exposes `DeviceValue` |
| `api.device_data` | api | Exposes `DeviceData` |

## Functions

**kernel schema (10):**
- `CreateDevice(pParent, pType, pModel, pClient, pIdentifier, pPassword, ...)` -- creates device with password hash
- `EditDevice(pId, ...)` -- updates device; password change requires administrator role
- `GetDevice(pIdentifier)` -- lookup by identifier
- `GetDeviceIdentifier(pDevice)` -- returns identifier
- `SwitchDevice(pDevice, pClient)` -- transfers device ownership to another client
- `AddDeviceNotification(pDevice, pInterfaceId, pStatus, ...)` -- temporal status notification
- `GetJsonDeviceNotification(pDevice, pInterfaceId, pDate)` -- returns notifications as JSON
- `AddDeviceValue(pDevice, pType, pValue, pTimeStamp)` -- temporal JSON value storage
- `AddDeviceData(pDevice, pAgent, pData, pTimeStamp)` -- temporal binary data storage
- `SetDeviceConnected(pId, pConnected, pHost, pIP, pPort, pMetadata)` -- updates connection state with logging

**api schema (18):**
- `api.add_device` -- defaults to type `mobile.device` and model `unknown.model`
- `api.update_device` -- update device
- `api.set_device` -- upsert
- `api.switch_device(pDevice, pClient)` -- transfer ownership
- `api.init_device(...)` -- idempotent: creates or updates+re-enables device by identifier
- `api.get_device(uuid)` -- by id with access check
- `api.get_device(text)` -- by identifier with access check
- `api.count_device` -- non-admin scoped to current client
- `api.list_device` -- non-admin scoped to current client
- `api.device_notification(pDevice, pInterfaceId, pDate)` -- query notifications
- `api.get_device_notification`, `api.count_device_notification`, `api.list_device_notification`
- `api.get_device_value`, `api.count_device_value`, `api.list_device_value`
- `api.get_device_data`, `api.count_device_data`, `api.list_device_data`

**Event functions (12):**
- `EventDeviceCreate` -- auto-assigns client, auto-enables device
- `EventDeviceOpen`, `EventDeviceEdit`, `EventDeviceSave`
- `EventDeviceEnable`, `EventDeviceHeartbeat`
- `EventDeviceAvailable`
- `EventDeviceUnavailable` -- closes transactions, builds invoice
- `EventDeviceFaulted` -- closes transactions, builds invoice
- `EventDeviceDisable`, `EventDeviceDelete`, `EventDeviceRestore`, `EventDeviceDrop`

## REST Routes

Dispatcher: `rest.device(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/device/type` | List device types |
| `/device/method` | Get available methods for device instance |
| `/device/count` | Count with search/filter |
| `/device/set` | Upsert device |
| `/device/init` | Idempotent device initialization |
| `/device/get` | Get by id with field selection |
| `/device/list` | List with search/filter/pagination |
| `/device/notification/get` | Get notification by id |
| `/device/notification/count` | Count notifications |
| `/device/notification/list` | List notifications |
| `/device/value/get` | Get device value by id |
| `/device/value/count` | Count device values |
| `/device/value/list` | List device values |
| `/device/data/get` | Get device data by id |
| `/device/data/count` | Count device data |
| `/device/data/list` | List device data |

## Workflow States / Methods / Transitions

**Types:** `auto.device`, `tractor.device`, `mobile.device`, `iot.device`, `unknown.device`

**Custom actions registered:** heartbeat, available, preparing, finishing, reserved, unavailable, faulted

**States (6):**
- `created` (created) -- initial state
- `available` (enabled) -- device online and operational
- `unavailable` (enabled) -- device offline or unreachable
- `faulted` (enabled) -- device in error state
- `disabled` (disabled) -- administratively disabled
- `deleted` (deleted) -- soft-deleted

**Key transitions:**
- created -> unavailable (enable), deleted (delete)
- available -> unavailable (unavailable), faulted (faulted), disabled (disable)
- unavailable -> available (available), faulted (faulted), disabled (disable)
- faulted -> available (available), unavailable (unavailable), disabled (disable)
- disabled -> unavailable (enable), deleted (delete)
- deleted -> created (restore)

## Init / Seed Data

- `CreateEntityDevice(pParent)` -- registers entity with custom actions, class, types, events, methods, transitions
- `CreateClassDevice(pParent, pEntity)` -- creates class with 5 types
- `AddDeviceMethods(pClass)` -- defines extended state machine with heartbeat/available/unavailable/faulted
- `AddDeviceEvents(pClass)` -- wires 12 event handlers including custom actions
- Registers REST route: `device`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `sequence.sql` | yes | no | 2 sequences |
| `table.sql` | yes | no | 4 tables DDL, indexes, 2 triggers |
| `caster/` | yes | yes | Sub-entity: NTRIP Caster |
| `station/` | yes | yes | Sub-entity: base station |
| `view.sql` | yes | yes | 6 kernel views |
| `exception.sql` | yes | yes | 2 exception functions |
| `routine.sql` | yes | yes | 10 kernel functions |
| `api.sql` | yes | yes | 4 api views, 18 api functions |
| `rest.sql` | yes | yes | REST dispatcher (16 routes) |
| `event.sql` | yes | yes | 12 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration, custom actions, workflow setup |
| `create.psql` | -- | -- | Loads all files (caster+station before views) |
| `update.psql` | -- | -- | Loads all except sequence.sql, table.sql, init.sql (caster+station after event.sql) |
