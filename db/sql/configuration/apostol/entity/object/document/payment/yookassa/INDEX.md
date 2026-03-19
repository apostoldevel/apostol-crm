# yookassa

> Payment sub-entity | Loaded by `payment/create.psql` line 23

YooKassa (formerly Yandex.Kassa) provider integration for payment processing. Implements the YooKassa Payments API v3: payment creation with receipts, capture, cancel, refund, and status polling. Handles card binding via `save_payment_method`, redirect-based confirmations, and idempotency keys. Complex callback handler processes all payment status transitions from YooKassa webhooks.

## Dependencies

- Parent: `payment` -- inherits `db.payment` table
- `card` -- card binding management
- `client` -- payer email/phone for receipts
- `invoice` -- invoice reference for payment types
- `price` -- price lookup for receipt line items
- Platform: `http` (outbound fetch), `registry` (API credentials, shop ID/key)

## Schemas Used

| Schema | Usage |
|--------|-------|
| `kernel` | Routines (API client functions) |
| `api` | Callback + HTTP response handlers |
| `rest` | Dispatcher `rest.yookassa()` |

## Functions

**kernel schema (8):**
- `YK_Error(pObject, pCode, pEvent, pText)` -- logs YooKassa error
- `YK_Fetch(pResource, pMethod, pCommand, pPayload, pData, pMessage)` -- HTTP client for YooKassa API with Basic auth, idempotency key, test mode detection
- `YK_CreateBindingPayment(pCard, pPAN, pExpiry, pHolderName, pCVC, pLabel)` -- creates validation payment with raw card data
- `YK_CreatePayment(pPayment, pReturnUrl, pCapture, pRefund, pMethod, pMetadata)` -- builds full payment payload with receipt, customer info, confirmation redirect
- `YK_Capture(pPayment)` -- captures authorized payment
- `YK_Cancel(pPayment)` -- cancels payment
- `YK_Refund(pPayment)` -- refunds payment
- `YK_Payment(pPayment)` -- polls payment status

**api schema (3):**
- `api.yookassa_callback(pPath, pPayload)` -- handles YooKassa webhooks: processes payment.succeeded, payment.canceled, payment.waiting_for_capture, refund.succeeded events with card binding, order creation, and state transitions
- `api.yookassa_done(pId, pResponse)` -- processes successful HTTP responses: extracts payment_id, confirmation URL, handles command routing (/payment/create, /payment/capture, /payment/cancel, /payment/refund)
- `api.yookassa_fail(pId, pError)` -- handles HTTP request failures, transitions to failed state

**Event functions (7):**
- `EventYooKassaCreate`, `EventYooKassaDelete`
- `EventYooKassaPay` -- processes successful payment: binds card, creates crediting order
- `EventYooKassaExpire`, `EventYooKassaConfirm`, `EventYooKassaRefund`
- `EventYooKassaCancel`, `EventYooKassaReject`

## REST Routes

Dispatcher: `rest.yookassa(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/yookassa/callback` | YooKassa webhook receiver |
| `/yookassa/type` | List YooKassa types |
| `/yookassa/method` | Get available methods |
| Dynamic routes | Payment code-based routing (e.g., `/yookassa/{code}`) |

## Workflow States / Methods / Transitions

**Types:** `reserve.yookassa`, `smart_payment.yookassa`, `payment.yookassa`, `validation.yookassa`

**States (13):**
- `created` (created) -- new payment
- `pending` (enabled) -- submitted, awaiting provider response
- `waiting_for_capture` (enabled) -- authorized, awaiting capture
- `confirming` (enabled) -- capture in progress
- `canceling` (enabled) -- cancellation in progress
- `refunding` (enabled) -- refund in progress
- `succeeded` (disabled) -- successfully completed
- `refunded` (disabled) -- fully refunded
- `partial_refunded` (disabled) -- partially refunded
- `canceled` (disabled) -- canceled
- `expired` (disabled) -- authorization expired
- `failed` (disabled) -- processing failed
- `deleted` (deleted) -- soft deleted

**Key transitions:**
- created -> pending (enable)
- pending -> waiting_for_capture (pay), succeeded (disable), canceled (cancel), expired (expire), failed (fail)
- waiting_for_capture -> confirming (confirm), canceling (cancel)
- confirming -> succeeded (disable), canceled (cancel)
- succeeded -> refunding (refund)
- refunding -> refunded (disable), partial_refunded (disable)

## Init / Seed Data

- `CreateClassYooKassa(pParent, pEntity)` -- registers child class under payment, 4 types, 13 states, events, transitions
- `AddYooKassaMethods(pClass)` -- defines complex state machine
- `AddYooKassaEvents(pClass)` -- wires 7 event handlers
- Creates `yookassa` agent
- Registers REST route: `yookassa`
- Seeds registry: `CONFIG\Service\YooKassa\API\URL`, `CONFIG\Service\YooKassa\Shop\Id`, `CONFIG\Service\YooKassa\Shop\Key`

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | (empty -- uses parent payment table) |
| `view.sql` | yes | yes | (empty -- uses parent payment views) |
| `exception.sql` | yes | yes | (empty) |
| `routine.sql` | yes | yes | 8 kernel functions (API client) |
| `api.sql` | yes | yes | 3 api callback/response functions |
| `rest.sql` | yes | yes | REST dispatcher (3+ routes) |
| `event.sql` | yes | yes | 7 event handler functions |
| `init.sql` | yes | no | Class/type registration, 13-state workflow, agent/route/registry setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
