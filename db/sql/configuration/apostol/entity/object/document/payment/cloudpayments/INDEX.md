# cloudpayments

> Payment sub-entity | Loaded by `payment/create.psql` line 22

CloudPayments provider integration for payment processing. Implements the full CloudPayments API: card binding, charges, confirmations, cancellations, refunds, and receipt generation (KKT). Handles HTTP callbacks for payment status updates and manages a complex multi-state workflow (14 states) for payment lifecycle tracking.

## Dependencies

- Parent: `payment` -- inherits `db.payment` table
- `card` -- card binding management
- `client` -- payer identification
- Platform: `http` (outbound fetch), `registry` (API credentials), `agent`

## Schemas Used

| Schema | Usage |
|--------|-------|
| `kernel` | Routines (API client functions) |
| `api` | Callback handlers |
| `rest` | Dispatcher `rest.cloudpayments()` |

## Functions

**kernel schema (12):**
- `CreateCloudPaymentContent(pReceipt)` -- builds receipt JSON for CloudPayments
- `SendCloudPayment(pPayment, pPAN, pExpiry, pCVC, pHolderName, pAmount)` -- sends card payment request
- `SendCloudPaymentTest(pPayment)` -- sends test payment
- `CP_Error(pObject, pCode, pEvent, pText)` -- logs CloudPayments error
- `CP_Fetch(pResource, pMethod, pCommand, pPayload, pData, pMessage)` -- HTTP client for CloudPayments API with auth
- `CP_BindCard(pCard, pPAN, pExpiry, pHolderName, pCVC, pLabel)` -- creates validation payment + sends to CloudPayments
- `CP_Payment(pPayment, pPAN, pExpiry, pCVC, pHolderName, pCapture, pReturnUrl, pMetadata)` -- sends payment with receipt
- `CP_Charge(pPayment, pCard, pAmount, pReturnUrl, pMetadata)` -- charges saved card by token
- `CP_Confirm(pPayment)` -- confirms two-stage payment
- `CP_Cancel(pPayment)` -- cancels/voids payment
- `CP_Refund(pPayment)` -- refunds completed payment
- `CP_Get(pPayment)` -- retrieves payment status
- `CP_Kkt(pPayment, pType)` -- generates fiscal receipt

**api schema (3):**
- `api.cloudpayments_callback(pPath, pPayload)` -- handles CloudPayments webhooks (check/pay/confirm/cancel/fail/refund)
- `api.cloudpayments_done(pId, pResponse)` -- processes successful HTTP responses
- `api.cloudpayments_fail(pId, pError)` -- handles HTTP request failures

**Event functions (7):**
- `EventCloudPaymentsCreate`, `EventCloudPaymentsDelete`
- `EventCloudPaymentsPay` -- processes successful payment: binds card, creates order, credits payment
- `EventCloudPaymentsExpire`, `EventCloudPaymentsConfirm`, `EventCloudPaymentsRefund`
- `EventCloudPaymentsCancel`, `EventCloudPaymentsReject`

## REST Routes

Dispatcher: `rest.cloudpayments(pPath, pPayload)`

| Route | Description |
|-------|-------------|
| `/cloudpayments/type` | List CloudPayments types |
| `/cloudpayments/method` | Get available methods |
| Dynamic routes | Callback handling via `api.cloudpayments_callback` |

## Workflow States / Methods / Transitions

**Types:** `reserve.cloudpayments`, `payment.cloudpayments`, `validation.cloudpayments`

**States (14):**
- `created` (created) -- new payment
- `waiting` (enabled) -- awaiting 3DS/redirect
- `authorized` (enabled) -- authorized, awaiting capture
- `confirming` (enabled) -- capture in progress
- `canceling` (enabled) -- cancellation in progress
- `refunding` (enabled) -- refund in progress
- `completed` (disabled) -- successfully completed
- `refunded` (disabled) -- fully refunded
- `partial_refunded` (disabled) -- partially refunded
- `canceled` (disabled) -- canceled
- `declined` (disabled) -- declined by provider
- `expired` (disabled) -- authorization expired
- `failed` (disabled) -- processing failed
- `deleted` (deleted) -- soft deleted

**Key transitions:**
- created -> waiting (enable), authorized (pay)
- waiting -> authorized (pay), declined (reject), expired (expire)
- authorized -> completed (disable), confirming (confirm), canceling (cancel)
- confirming -> completed (disable), canceled (cancel)
- completed -> refunding (refund)
- refunding -> refunded (disable), partial_refunded (disable)

## Init / Seed Data

- `CreateClassCloudPayments(pParent, pEntity)` -- registers child class under payment, 3 types, 14 states, events, transitions
- `AddCloudPaymentsMethods(pClass)` -- defines complex state machine
- `AddCloudPaymentsEvents(pClass)` -- wires 7 event handlers
- Creates `cloudpayments` agent and user
- Registers REST route: `cloudpayments`
- Seeds registry: `CONFIG\Service\CloudPayments\API\URL`, shop credentials

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `table.sql` | yes | no | (empty -- uses parent payment table) |
| `view.sql` | yes | yes | (empty -- uses parent payment views) |
| `exception.sql` | yes | yes | (empty) |
| `routine.sql` | yes | yes | 12 kernel functions (API client) |
| `api.sql` | yes | yes | 3 api callback functions |
| `rest.sql` | yes | yes | REST dispatcher (2+ routes) |
| `event.sql` | yes | yes | 7 event handler functions |
| `init.sql` | yes | no | Class/type registration, 14-state workflow, agent/route/registry setup |
| `create.psql` | -- | -- | Loads all files |
| `update.psql` | -- | -- | Loads all except table.sql and init.sql |
