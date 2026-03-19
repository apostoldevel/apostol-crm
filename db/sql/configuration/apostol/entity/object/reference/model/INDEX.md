# model

> Configuration entity -- reference | Loaded by `reference/create.psql` line 11

Device model reference with vendor and category links, plus a model_property junction table for typed key-value properties.

## Dependencies

| Depends on | Depended by |
|------------|-------------|
| platform: reference, object, type, scope, state, user, aou; vendor (FK), category (FK), property (FK in model_property), measure (FK in model_property) | device/station (conceptual) |

## Schemas Used

| Schema | Usage |
|--------|-------|
| `db` | Tables, trigger function |
| `kernel` | Views, functions |
| `api` | API views, functions |
| `rest` | REST dispatcher |

## Tables -- 2

| Table | Description | Key Columns |
|-------|-------------|-------------|
| `db.model` | Model reference | `id`, `reference`, `vendor` uuid FK, `category` uuid FK |
| `db.model_property` | Model property junction | `model` uuid FK, `property` uuid FK, `measure` uuid FK, `value` variant, `format` text, `sequence` integer; PK (model, property) |

## Triggers -- 1

| Trigger | Table | Event | Purpose |
|---------|-------|-------|---------|
| `t_model_insert` | `db.model` | BEFORE INSERT | Auto-sets `id` from `reference` |

## Views

### kernel schema

| View | Source | Grants |
|------|--------|--------|
| `Model` | `db.model` + reference + vendor/category refs | administrator |
| `AccessModel` | `db.model` + `db.aou` + member_group | administrator |
| `ObjectModel` | `db.model` + full object/entity/class/type/state/user + vendor/category joins | administrator |
| `ModelProperty` | `db.model_property` + Model + Property + Measure (formatted value display) | administrator |
| `ModelPropertyJson` | `db.model_property` + Model + Property + Measure (JSON row output) | administrator |

### api schema

| View | Source | Purpose |
|------|--------|---------|
| `api.model` | `ObjectModel` | Public API view for models |
| `api.model_property` | `ModelPropertyJson` | Public API view for model properties |

## Functions (kernel schema) -- 9

| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateModel(pParent, pType, pVendor, pCategory, pCode, pName, pDescription)` | `uuid` | Creates a model |
| `EditModel(pId, pParent, pType, pVendor, pCategory, pCode, pName, pDescription)` | `void` | Edits a model |
| `GetModel(pCode text)` | `uuid` | Finds model by code |
| `GetModelVendor(pId)` | `uuid` | Returns vendor UUID |
| `GetModelCategory(pId)` | `uuid` | Returns category UUID |
| `SetModelProperty(pModel, pProperty, pMeasure, pValue, pFormat, pSequence)` | `void` | Upsert a model property |
| `DeleteModelProperty(pModel, pProperty)` | `boolean` | Deletes model property (or all if pProperty is null) |
| `GetModelPropertyJson(pModel)` | `json` | Returns model properties as JSON array |
| `GetModelPropertyJsonb(pObject)` | `jsonb` | Returns model properties as JSONB |

## Functions (api schema) -- 12

| Function | Returns | Purpose |
|----------|---------|---------|
| `api.add_model(pParent, pType, pVendor, pCategory, pCode, pName, pDescription)` | `uuid` | Add a model |
| `api.update_model(pId, ...)` | `void` | Update a model |
| `api.set_model(pId, ...)` | `SETOF api.model` | Upsert a model |
| `api.get_model(pId)` | `SETOF api.model` | Get model by ID |
| `api.list_model(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.model` | List models with filtering |
| `api.set_model_property_json(pModel, pProperties)` | `SETOF api.model_property` | Set model properties from JSON |
| `api.set_model_property_jsonb(pModel, pProperties)` | `SETOF api.model_property` | Set model properties from JSONB |
| `api.get_model_property_json(pModel)` | `json` | Get model properties as JSON |
| `api.get_model_property_jsonb(pModel)` | `jsonb` | Get model properties as JSONB |
| `api.set_model_property(pModel, pProperty, pMeasure, pTypeValue, pValue, pFormat, pSequence)` | `SETOF api.model_property` | Set a single model property |
| `api.get_model_property(pModel, pProperty)` | `SETOF api.model_property` | Get a specific model property |
| `api.delete_model_property(pModel, pProperty)` | `boolean` | Delete a model property |
| `api.clear_model_property(pModel)` | `boolean` | Delete all model properties |
| `api.list_model_property(pSearch, pFilter, pLimit, pOffSet, pOrderBy)` | `SETOF api.model_property` | List model properties with filtering |

## REST Routes -- 12

Dispatcher: `rest.model(pPath text, pPayload jsonb)`.

| Path | Purpose |
|------|---------|
| `/model/type` | List entity types |
| `/model/method` | Get available methods for a model |
| `/model/count` | Count models with optional filtering |
| `/model/set` | Create or update a model |
| `/model/get` | Get a model by ID |
| `/model/list` | List models with filtering/pagination |
| `/model/property` | Get or set model properties (JSON bulk) |
| `/model/property/set` | Set a single model property |
| `/model/property/get` | Get a specific model property |
| `/model/property/delete` | Delete a model property |
| `/model/property/clear` | Delete all properties for a model |
| `/model/property/count` | Count model properties |
| `/model/property/list` | List model properties with filtering |

## Workflow States / Methods / Transitions

Defined via `AddDefaultMethods` with labels: Created, Opened, Closed, Deleted, Open, Close, Delete.

Type registered: `device.model` -- "Device" (Device model).

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | `db.model` + `db.model_property` tables, indexes, insert trigger |
| `view.sql` | yes | yes | Model, AccessModel, ObjectModel, ModelProperty, ModelPropertyJson views |
| `routine.sql` | yes | yes | CreateModel, EditModel, GetModel*, SetModelProperty, DeleteModelProperty, GetModelProperty* |
| `api.sql` | yes | yes | api.model + api.model_property views + 14 functions |
| `rest.sql` | yes | yes | REST dispatcher with 12 routes (model + model/property/*) |
| `event.sql` | yes | yes | 9 event handler functions |
| `init.sql` | yes | no | Entity/class/type registration |
