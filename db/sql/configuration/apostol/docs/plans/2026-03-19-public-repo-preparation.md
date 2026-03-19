# Public Repository Preparation — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prepare the `configuration/apostol/` database layer for public GitHub repository: English documentation, localized errors, and 6-locale workflow translations.

**Architecture:** Three sequential blocks — (1) Documentation Overhaul: JSDoc + COMMENT ON + inline cleanup for all 1032 functions and 366 table comments, (2) Exception Localization per `platform/docs/migration-1.2.0.md`: register project errors in error_catalog, replace Russian strings, (3) Workflow Localization per `platform/docs/migration-1.2.1.md`: English base language in all init.sql, 6-locale Edit*Text.

**Tech Stack:** PL/pgSQL, PostgreSQL COMMENT ON, JSDoc-style documentation blocks, db-platform error_catalog, Edit*Text localization infrastructure.

**Design doc:** `docs/plans/2026-03-19-public-repo-preparation-design.md` (approved in brainstorming session)

---

## Reference: Configuration Layer Metrics

| Metric | Count |
|--------|------:|
| Total SQL/PSQL files | 368 |
| Functions (CREATE OR REPLACE FUNCTION) | 1032 |
| COMMENT ON statements | 366 |
| JSDoc blocks (existing) | 216 |
| Russian inline comments | 25 |
| init.sql files | 37 |
| exception.sql files (with content) | 10 |
| exception.sql files (empty) | 7 |

## Reference: Loading Order (create.psql)

```
admin/       → entity/     → priority/  → api/
→ report/    → observer/   → confirmation/ → notice/
→ oauth2.sql → routine.sql → init.sql
```

## Reference: Entity List (30 entities)

**Documents (18):** account, card, client (+name/customer/employee), company, device (+station/caster), identity, invoice, job*, message*, order, payment (+cloudpayments/yookassa), price, product, subscription, tariff, task, transaction

**References (12):** address, calendar, category, country, currency, format, measure, model, property, region, service

---

# BLOCK 1: Documentation Overhaul

## Reference: JSDoc Template

```sql
/**
 * @brief <One sentence: what the function does as an action.>
 * @param {<type>} <pName> - <Purpose in business context>
 * @return {<type>} - <What is returned>
 * @throws <ExceptionName> - <When it fires>
 * @see <RelatedFunction>
 * @since 1.0.0
 */
```

## Reference: COMMENT ON Template

```sql
COMMENT ON TABLE db.<table> IS '<Role in the system, what it stores.>';
COMMENT ON COLUMN db.<table>.<col> IS '<Purpose and constraints.>';
```

## Reference: Inline Comment Policy

- **Remove** — comments restating the code
- **Translate** — comments explaining business logic
- **Keep Russian** — only inside string literals (business data)

---

### Task 1: admin/ — Platform Hook Overrides

**Files:**
- Modify: `admin/do.sql` (~150 lines, 9 functions)
- Modify: `admin/api.sql` (if exists)

**Step 1:** Read `admin/do.sql`. For each function (DoLogin, DoLogout, DoCreateArea, DoDeleteArea, etc.), add JSDoc block with `@brief`, `@param`, `@return`, `@throws`, `@since 1.0.0`.

**Step 2:** Translate any Russian inline comments to English. Remove obvious comments.

**Step 3:** Commit.

```bash
git add db/sql/configuration/apostol/admin/
git commit -m "docs(config/admin): add English JSDoc and clean up inline comments"
```

---

### Task 2: entity/object/ — Base Object Overrides

**Files:**
- Modify: `entity/object/event.sql` (base object event overrides)

**Step 1:** Read file. Add JSDoc for each event function override.

**Step 2:** Clean inline comments.

**Step 3:** Commit.

```bash
git add db/sql/configuration/apostol/entity/object/
git commit -m "docs(config/entity/object): add JSDoc for object event overrides"
```

---

### Task 3: Reference Entities — table.sql (COMMENT ON)

**Files (12 entities):**
- Modify: `entity/object/reference/address/table.sql` (if exists)
- Modify: `entity/object/reference/calendar/table.sql`
- Modify: `entity/object/reference/category/table.sql`
- Modify: `entity/object/reference/country/table.sql`
- Modify: `entity/object/reference/currency/table.sql`
- Modify: `entity/object/reference/measure/table.sql`
- Modify: `entity/object/reference/model/table.sql`
- Modify: `entity/object/reference/property/table.sql`
- Modify: `entity/object/reference/service/table.sql`

Note: not all references have table.sql (some use only platform tables). Only process files that exist.

**Step 1:** For each table.sql, read the file. Rewrite all COMMENT ON statements to meaningful English. Follow the pattern:
- Table: one sentence about its role
- Column: describe purpose, not data type

**Step 2:** Commit.

```bash
git add db/sql/configuration/apostol/entity/object/reference/
git commit -m "docs(config/reference): rewrite COMMENT ON to English for all reference tables"
```

---

### Task 4: Reference Entities — routine.sql, api.sql, rest.sql, event.sql, exception.sql

**Files:** All routine.sql, api.sql, rest.sql, event.sql, exception.sql under `entity/object/reference/*/`

For each reference entity (address, calendar, category, country, currency, format, measure, model, property, region, service):

**Step 1:** Read each .sql file in the entity directory. For every function, add JSDoc block.

**Step 2:** Translate Russian inline comments, remove obvious ones.

**Step 3:** Commit per entity group (split into 2-3 commits if needed for size).

```bash
git add db/sql/configuration/apostol/entity/object/reference/
git commit -m "docs(config/reference): add JSDoc for all reference entity functions"
```

---

### Task 5: Document Entities — table.sql (COMMENT ON)

**Files (18 entities):** All table.sql under `entity/object/document/*/`

Entities with table.sql: account (+balance), card, client (+name), company, device (+station/caster), identity, invoice, order, payment (+cloudpayments/yookassa), price, product, subscription, tariff, task, transaction

**Step 1:** For each table.sql, rewrite all COMMENT ON statements to meaningful English.

**Step 2:** Commit.

```bash
git add db/sql/configuration/apostol/entity/object/document/
git commit -m "docs(config/document): rewrite COMMENT ON to English for all document tables"
```

---

### Task 6: Document Entities — routine.sql, api.sql (large entities)

**Files:** routine.sql + api.sql for large entities: account, client, device, payment, order, transaction, subscription, invoice

These are the largest files. Process each entity's routine.sql and api.sql:

**Step 1:** Read each file. Add JSDoc for every function.

**Step 2:** Translate Russian inline comments.

**Step 3:** Commit per entity or per batch.

```bash
git add db/sql/configuration/apostol/entity/object/document/
git commit -m "docs(config/document): add JSDoc for large document entity functions (routine+api)"
```

---

### Task 7: Document Entities — rest.sql, event.sql, exception.sql, view.sql

**Files:** All rest.sql, event.sql, exception.sql, view.sql under `entity/object/document/*/`

**Step 1:** For each file, add JSDoc blocks where missing. Exception functions: document the error code, when it fires, and the message.

**Step 2:** Clean inline comments.

**Step 3:** Commit.

```bash
git add db/sql/configuration/apostol/entity/object/document/
git commit -m "docs(config/document): add JSDoc for rest, event, exception, view files"
```

---

### Task 8: Non-entity Modules — api/, confirmation/, notice/, observer/, priority/, report/

**Files:**
- `api/api.sql`, `api/event.sql`
- `confirmation/table.sql`, `confirmation/routine.sql`, `confirmation/api.sql`, `confirmation/rest.sql`, `confirmation/view.sql`
- `notice/view.sql`
- `observer/routine.sql`
- `priority/rest.sql`
- `report/import/api.sql`, `report/import/rest.sql`

**Step 1:** For confirmation/table.sql: rewrite COMMENT ON to English.

**Step 2:** For each function file: add JSDoc blocks.

**Step 3:** Clean inline comments.

**Step 4:** Commit.

```bash
git add db/sql/configuration/apostol/api/ db/sql/configuration/apostol/confirmation/ db/sql/configuration/apostol/notice/ db/sql/configuration/apostol/observer/ db/sql/configuration/apostol/priority/ db/sql/configuration/apostol/report/
git commit -m "docs(config): add JSDoc for api, confirmation, notice, observer, priority, report modules"
```

---

### Task 9: Top-level Files — routine.sql, oauth2.sql

**Files:**
- `routine.sql` (email text templates)
- `oauth2.sql` (OAuth2 setup)

**Step 1:** Add JSDoc blocks for all functions.

**Step 2:** Clean inline comments.

**Step 3:** Commit.

```bash
git add db/sql/configuration/apostol/routine.sql db/sql/configuration/apostol/oauth2.sql
git commit -m "docs(config): add JSDoc for routine.sql and oauth2.sql"
```

---

# BLOCK 2: Exception Localization

## Reference

Follow `platform/docs/migration-1.2.0.md` guide. Key steps:
1. Register project-specific exceptions via `RegisterError()`
2. Replace hardcoded Russian strings with English
3. Replace `ObjectNotFound('русский')` with English entity names
4. Translate `WriteToEventLog()` messages to English

---

### Task 10: Register Project-Specific Errors in error_catalog

**Files:**
- Create: `exception/init.sql` (project-specific error registrations)
- Create: `exception/create.psql` (include script)

**Step 1:** Create `exception/init.sql` with `RegisterError()` calls for all 30 project-specific exceptions found in the audit:

From exception.sql files (CreateExceptionResource pattern — 8 files, ~25 functions):
- account: AccountCodeExists, AccountNotFound, AccountNotAssociated, InsufficientFunds, IncorrectTurnover
- client: ClientCodeExists, AccountNotClient, EmailAddressNotSet, EmailAddressNotVerified, PhoneNumberNotSet, PhoneNumberNotVerified, InvalidClientId, IncorrectDateValue
- device: DeviceExists, DeviceNotAssociated
- identity: IdentityExists, IdentityNotFound, IdentityNotAssociated
- invoice: InvoiceCodeExists, InvalidInvoiceAmount, InvalidInvoiceBalance, UnsupportedInvoiceType
- order: OrderCodeExists, InvalidOrderAccountCurrency, IncorrectOrderAmount, TransferringInactiveAccount
- payment: PaymentCodeExists, IncorrectPaymentData
- transaction: TransactionCodeExists, TariffNotFound

Use error code range `ERR-400-200` through `ERR-400-249` for project-specific errors.

Register each in 6 locales (en, ru, de, fr, it, es):

```sql
SELECT RegisterError('ERR-400-200', 400, 'E', 'entity', 'en', 'Account "%s" already exists');
SELECT RegisterError('ERR-400-200', 400, 'E', 'entity', 'ru', 'Счёт "%s" уже существует');
SELECT RegisterError('ERR-400-200', 400, 'E', 'entity', 'de', 'Konto "%s" existiert bereits');
SELECT RegisterError('ERR-400-200', 400, 'E', 'entity', 'fr', 'Le compte "%s" existe déjà');
SELECT RegisterError('ERR-400-200', 400, 'E', 'entity', 'it', 'Il conto "%s" esiste già');
SELECT RegisterError('ERR-400-200', 400, 'E', 'entity', 'es', 'La cuenta "%s" ya existe');
```

**Step 2:** Wire `exception/create.psql` into `create.psql` (after entity module, before init.sql).

**Step 3:** Commit.

```bash
git add db/sql/configuration/apostol/exception/
git commit -m "feat(config/exception): register 30 project errors in error_catalog with 6 locales"
```

---

### Task 11: Migrate exception.sql Files to RegisterError

**Files:**
- Modify: All 10 exception.sql files with content
- Remove: `CreateExceptionResource()` calls from 8 files (replaced by Task 10)
- Rewrite: 2 files with direct RAISE EXCEPTION (card/exception.sql, company/exception.sql) to use `GetExceptionStr()` pattern

**Step 1:** For each of the 8 files using `CreateExceptionResource()`:
- Replace `CreateExceptionResource()` calls with `GetExceptionStr()` using new ERR-400-2xx codes
- Keep the exception function structure, just change the error string source

**Step 2:** For card/exception.sql and company/exception.sql:
- Replace direct `RAISE EXCEPTION 'ERR-40000: Russian text'` with proper `GetExceptionStr()` pattern

**Step 3:** Commit.

```bash
git add db/sql/configuration/apostol/entity/
git commit -m "fix(config/exception): migrate all exception.sql to error_catalog pattern"
```

---

### Task 12: Replace Hardcoded Russian Strings

**Files (19 instances of RAISE EXCEPTION with Russian text):**
- Modify: `admin/do.sql:114` — area deletion check
- Modify: `api/api.sql:66,72,78,82` — DoSignUp validation
- Modify: `entity/object/document/card/event.sql:111,122` — EventCardDisable checks
- Modify: `entity/object/document/device/event.sql:196` — EventDeviceDrop check
- Modify: `entity/object/document/payment/routine.sql:350,360,406,416` — account lookup errors

**Step 1:** For each instance, either:
- A) Register as new error in `exception/init.sql` and use `RAISE EXCEPTION '%', GetExceptionStr(400, 2xx);`
- B) Replace with English text directly if it's a simple validation (for non-user-facing errors)

**Step 2:** Commit.

```bash
git add db/sql/configuration/apostol/admin/ db/sql/configuration/apostol/api/ db/sql/configuration/apostol/entity/
git commit -m "fix(config/i18n): replace hardcoded Russian strings in RAISE EXCEPTION"
```

---

### Task 13: Replace ObjectNotFound() Russian Parameters

**Files (10 instances):**
- Modify: `entity/object/document/client/api.sql:255` — 'клиент' → 'client'
- Modify: `entity/object/document/task/api.sql:114` — 'задача' → 'task'
- Modify: `entity/object/reference/address/api.sql:113,304` — 'адрес' → 'address', 'объект' → 'object'
- Modify: `entity/object/reference/calendar/api.sql:165` — 'календарь' → 'calendar'
- Modify: `entity/object/reference/calendar/routine.sql:302` — 'календарь' → 'calendar'
- Modify: `entity/object/reference/category/api.sql:69` — 'категория' → 'category'
- Modify: `entity/object/reference/measure/api.sql:69` — 'мера' → 'measure'
- Modify: `entity/object/reference/model/api.sql:192` — 'модель' → 'model'
- Modify: `entity/object/reference/property/api.sql:69` — 'свойство' → 'property'

**Step 1:** Replace each Russian parameter with English equivalent.

**Step 2:** Commit.

```bash
git add db/sql/configuration/apostol/entity/
git commit -m "fix(config/i18n): replace Russian entity names in ObjectNotFound with English"
```

---

### Task 14: Translate WriteToEventLog() Messages

**Files:** All event.sql files across all 30 entities (~100+ instances)

**Step 1:** For each entity's event.sql, replace Russian event log messages with English:

Pattern:
| Russian | English |
|---------|---------|
| '{Сущность} создан(а).' | '{Entity} created.' |
| '{Сущность} открыт(а) на просмотр.' | '{Entity} opened.' |
| '{Сущность} изменён(а).' | '{Entity} modified.' |
| '{Сущность} сохранён(а).' | '{Entity} saved.' |
| '{Сущность} включен(а).' | '{Entity} enabled.' |
| '{Сущность} выключен(а).' | '{Entity} disabled.' |
| '{Сущность} будет удалён(а).' | '{Entity} will be deleted.' |
| '{Сущность} восстановлен(а).' | '{Entity} restored.' |
| '{Сущность} будет уничтожен(а).' | '{Entity} will be dropped.' |

Apply for all entities: Service, Region, Address, Model, Country, Category, Currency, Property, Format, Calendar, Measure, Account, Client, Card, Company, Device, Identity, Invoice, Order, Payment, Transaction, Task, Product, Price, Subscription, Tariff, etc.

**Step 2:** Commit.

```bash
git add db/sql/configuration/apostol/entity/
git commit -m "fix(config/i18n): translate all WriteToEventLog messages to English"
```

---

# BLOCK 3: Workflow Localization

## Reference

Follow `platform/docs/migration-1.2.1.md` guide. Key patterns:
- **Pattern A:** AddEntity → English base + 5 EditEntityText
- **Pattern B:** AddClass → English base + 5 EditClassText
- **Pattern C:** AddType → English base + 5 EditTypeText
- **Pattern D:** AddState → English base + 5 EditStateText
- **Pattern E:** AddMethod → English base + 5 EditMethodText (capture UUID)
- **Pattern F:** AddEvent → English label only
- **Pattern G:** AddDefaultMethods → swap parameter order (English first)

---

### Task 15: Reference Entities — init.sql Localization (12 entities)

**Files:**
- Modify: `entity/object/reference/address/init.sql`
- Modify: `entity/object/reference/calendar/init.sql`
- Modify: `entity/object/reference/category/init.sql`
- Modify: `entity/object/reference/country/init.sql`
- Modify: `entity/object/reference/currency/init.sql`
- Modify: `entity/object/reference/format/init.sql`
- Modify: `entity/object/reference/measure/init.sql`
- Modify: `entity/object/reference/model/init.sql`
- Modify: `entity/object/reference/property/init.sql`
- Modify: `entity/object/reference/region/init.sql`
- Modify: `entity/object/reference/service/init.sql`

**Step 1:** For each reference entity init.sql, apply Patterns A-G from migration-1.2.1.md:
1. `AddEntity('code', 'English')` + EditEntityText for ru/de/fr/it/es
2. `AddClass(..., 'English', ...)` + EditClassText for 5 locales
3. `AddType(..., 'English name', 'English desc')` + EditTypeText for 5 locales
4. `AddEvent(...)` labels → English
5. `AddDefaultMethods(uClass, ARRAY[en...], ARRAY[ru...])` — swap parameter order

Where entities currently have EditTypeText for English (format, region, service), restructure: make English the base, Russian moves to EditTypeText.

Where entities have no English translations (address, calendar, category, country, currency, measure, model, property), add all 5 EditText calls.

**Step 2:** Declare `uMethod uuid;` in DECLARE blocks where needed for EditMethodText.

**Step 3:** Commit.

```bash
git add db/sql/configuration/apostol/entity/object/reference/
git commit -m "feat(config/i18n): localize 12 reference entity init.sql to 6 languages"
```

---

### Task 16: Document Entities with Standard State Machines — init.sql (8 entities)

**Files (entities using AddDefaultMethods):**
- Modify: `entity/object/document/account/init.sql`
- Modify: `entity/object/document/card/init.sql`
- Modify: `entity/object/document/company/init.sql`
- Modify: `entity/object/document/price/init.sql`
- Modify: `entity/object/document/product/init.sql`
- Modify: `entity/object/document/tariff/init.sql`

**Step 1:** Apply Patterns A-G. These entities use AddDefaultMethods — swap parameter order.

For entities with existing EditTypeText (account, company, price, product): make English the base.
For entities without English (card, tariff): add all translations.

**Step 2:** Switch AddEvent labels to English.

**Step 3:** Commit.

```bash
git add db/sql/configuration/apostol/entity/object/document/
git commit -m "feat(config/i18n): localize 6 standard-state document entities to 6 languages"
```

---

### Task 17: Document Entities with Custom State Machines — init.sql (9 entities)

**Files (entities using AddState/SetState with custom methods):**
- Modify: `entity/object/document/client/init.sql` — custom states: created, enabled, disabled, deleted + submit/confirm/reconfirm
- Modify: `entity/object/document/device/init.sql` — custom states: created, available, unavailable, faulted, disabled, deleted
- Modify: `entity/object/document/identity/init.sql` — custom states with 'expired'
- Modify: `entity/object/document/invoice/init.sql` — custom states: in_progress, failed, closed
- Modify: `entity/object/document/order/init.sql` — SetState: processing, succeeded, refunded, canceled
- Modify: `entity/object/document/payment/init.sql` — SetState similar to order
- Modify: `entity/object/document/subscription/init.sql` — 7 custom states
- Modify: `entity/object/document/task/init.sql` — custom states: expired, planned, postponed
- Modify: `entity/object/document/transaction/init.sql` — SetState similar to order

**Step 1:** Apply Patterns A-F. For custom states (Pattern D):
- Switch AddState/SetState labels to English
- Add EditStateText for ru/de/fr/it/es

For custom methods (Pattern E):
- Change `PERFORM AddMethod(...)` to `uMethod := AddMethod(...)`
- Add EditMethodText for ru/de/fr/it/es
- Declare `uMethod uuid;` in DECLARE blocks

**Step 2:** Switch AddEvent labels to English.

**Step 3:** For entities already having EditStateText/EditMethodText (order, payment, subscription, transaction, device): restructure — English as base, Russian to EditStateText.

**Step 4:** Commit.

```bash
git add db/sql/configuration/apostol/entity/object/document/
git commit -m "feat(config/i18n): localize 9 custom-state document entities to 6 languages"
```

---

### Task 18: Payment Subclass init.sql + Main entity/init.sql

**Files:**
- Modify: `entity/object/document/payment/yookassa/init.sql` (if exists)
- Modify: `entity/object/document/payment/cloudpayments/init.sql` (if exists)
- Modify: `entity/init.sql` (InitConfigurationEntity)

**Step 1:** Apply localization patterns to payment subclass init.sql files.

**Step 2:** In `entity/init.sql`, translate any Russian inline comments.

**Step 3:** Commit.

```bash
git add db/sql/configuration/apostol/entity/
git commit -m "feat(config/i18n): localize payment subclasses and entity init"
```

---

### Task 19: Non-entity init.sql — confirmation, report, main init

**Files:**
- Modify: `confirmation/init.sql` — CreatePublisher with Russian text
- Modify: `report/init.sql` — CreateReportTree, CreateReportForm with Russian text
- Modify: `init.sql` — FillDataBase() with Russian text for products, services, etc.

**Step 1:** In `confirmation/init.sql`:
```sql
-- Before
SELECT CreatePublisher('confirmation', 'Подтверждение', 'Уведомления о наличии данных...');
-- After
SELECT CreatePublisher('confirmation', 'Confirmation', 'Notifications about data for 3-D Secure confirmation.');
```

**Step 2:** In `report/init.sql`: switch CreateReportTree and related calls to English base.

**Step 3:** In main `init.sql` / `FillDataBase()`: translate Russian string parameters to English where they are UI-facing labels (group names, category names, etc.). Keep Russian business data that is part of seed content (company names for Russian market).

**Step 4:** Commit.

```bash
git add db/sql/configuration/apostol/confirmation/ db/sql/configuration/apostol/report/ db/sql/configuration/apostol/init.sql
git commit -m "feat(config/i18n): localize confirmation, report, and main init to English base"
```

---

### Task 20: routine.sql — Email Templates

**Files:**
- Modify: `routine.sql` — email text templates (password recovery, registration)

**Step 1:** Review email templates. These contain user-facing Russian text for emails. Switch to English as default with locale-aware selection if the platform supports it. If not, keep Russian templates but add English versions.

**Step 2:** Commit.

```bash
git add db/sql/configuration/apostol/routine.sql
git commit -m "feat(config/i18n): add English email templates"
```

---

### Task 21: Update INDEX.md and Create Error Code Reference

**Files:**
- Modify: `INDEX.md` — update "Project Example" references to "Apostol CRM", mention localization
- Create: `docs/error-codes.md` — project-specific error code reference

**Step 1:** Update INDEX.md header from "Project Example" to proper project name. Add section about localization support.

**Step 2:** Create `docs/error-codes.md` with all project-specific error codes (ERR-400-200 through ERR-400-249), their functions, messages, and categories.

**Step 3:** Commit.

```bash
git add db/sql/configuration/apostol/INDEX.md db/sql/configuration/apostol/docs/
git commit -m "docs(config): update INDEX.md and add project error code reference"
```

---

## Summary

| Task | Block | Module | What | Complexity |
|-----:|-------|--------|------|-----------|
| 1 | Docs | admin/ | JSDoc for 9 hook functions | Small |
| 2 | Docs | entity/object/ | JSDoc for base event overrides | Small |
| 3 | Docs | reference/ | COMMENT ON for all reference tables | Medium |
| 4 | Docs | reference/ | JSDoc for all reference functions | Large |
| 5 | Docs | document/ | COMMENT ON for all document tables | Large |
| 6 | Docs | document/ | JSDoc for large entity functions | XL |
| 7 | Docs | document/ | JSDoc for rest, event, exception, view | Large |
| 8 | Docs | api/confirm/notice/etc | JSDoc for non-entity modules | Medium |
| 9 | Docs | routine/oauth2 | JSDoc for top-level files | Small |
| 10 | Errors | exception/ | Register 30 errors in error_catalog (6 locales) | Large |
| 11 | Errors | exception.sql files | Migrate to error_catalog pattern | Medium |
| 12 | Errors | admin/api/entity | Replace 19 hardcoded Russian RAISE | Medium |
| 13 | Errors | entity | Replace 10 ObjectNotFound Russian params | Small |
| 14 | Errors | entity | Translate 100+ WriteToEventLog messages | Large |
| 15 | i18n | reference/init.sql | Localize 12 reference entities | Large |
| 16 | i18n | document/init.sql | Localize 6 standard-state entities | Medium |
| 17 | i18n | document/init.sql | Localize 9 custom-state entities | XL |
| 18 | i18n | payment+entity | Payment subclasses + entity init | Small |
| 19 | i18n | confirm/report/init | Non-entity init localization | Medium |
| 20 | i18n | routine.sql | Email templates | Small |
| 21 | Docs | INDEX/docs | Update INDEX.md + error reference | Small |
| **Total** | | **30 entities + 8 modules** | **21 tasks** | |
