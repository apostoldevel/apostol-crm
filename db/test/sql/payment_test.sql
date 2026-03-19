--------------------------------------------------------------------------------
-- Project Example — Payment Tests (pgTAP)
--
-- Tests for: CreatePayment, payment state transitions
-- Source: entity/object/document/payment/routine.sql
--
-- Note: YK_CreatePayment calls YK_Fetch (external HTTP to YooKassa API),
-- so we test CreatePayment directly and verify state machine transitions.
-- YooKassa integration is tested via the NTRIP emulator + live API.
--------------------------------------------------------------------------------

SET search_path TO kernel, public;

BEGIN;

SELECT plan(8);

SELECT test_setup_session();

--------------------------------------------------------------------------------
-- Setup: create client, invoice, payment
--------------------------------------------------------------------------------
DO $$
DECLARE
  uClient     uuid;
  uDevice     uuid;
  uProduct    uuid;
  uTariff     uuid;
  uService    uuid;
  uCurrency   uuid;
  uInvoice    uuid;
  uPayment    uuid;
BEGIN
  uClient := test_create_client('pay_client', 'Payment Test Client');
  uCurrency := DefaultCurrency();
  uService := GetService('time.service');
  uProduct := GetProduct('default.product');

  -- Create device
  uDevice := CreateDevice(
    null, GetType('base.station'), GetModel('unknown.model'), uClient,
    'pay_test_device', null, null, null, null, null, null, null,
    'Payment Test Station', 'Test device for payment tests'
  );
  -- Note: EventDeviceCreate auto-calls DoEnable (created → unavailable)

  -- Create invoice directly (not via BuildInvoice, since we need a known invoice)
  uInvoice := CreateInvoice(
    uDevice,                                -- pParent
    GetType('payment.invoice'),             -- pType
    uCurrency,                              -- pCurrency
    uClient,                                -- pClient
    uDevice,                                -- pDevice
    null,                                   -- pCode (auto-generated)
    100.00,                                 -- pAmount
    null,                                   -- pPDF
    'Test invoice',                         -- pLabel
    'Invoice for payment tests'             -- pDescription
  );
  PERFORM DoEnable(uInvoice);

  -- Create a payment linked to the invoice
  uPayment := CreatePayment(
    uInvoice,                               -- pParent
    GetType('card.payment'),               -- pType
    uClient,                                -- pClient
    uCurrency,                              -- pCurrency
    100.00,                                 -- pAmount
    'Test payment',                         -- pDescription
    null,                                   -- pCard
    uInvoice                                -- pInvoice
  );

  PERFORM set_config('test.client', uClient::text, true);
  PERFORM set_config('test.device', uDevice::text, true);
  PERFORM set_config('test.invoice', uInvoice::text, true);
  PERFORM set_config('test.payment', uPayment::text, true);
END;
$$;

--------------------------------------------------------------------------------
-- Test 1: Payment was created successfully
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT count(*) = 1 FROM db.payment WHERE id = current_setting('test.payment')::uuid),
  'Payment record exists in db.payment'
);

--------------------------------------------------------------------------------
-- Test 2: Payment amount matches
--------------------------------------------------------------------------------
SELECT is(
  (SELECT amount FROM db.payment WHERE id = current_setting('test.payment')::uuid),
  100.00::numeric,
  'Payment amount = 100.00'
);

--------------------------------------------------------------------------------
-- Test 3: Payment is linked to correct client
--------------------------------------------------------------------------------
SELECT is(
  (SELECT client FROM db.payment WHERE id = current_setting('test.payment')::uuid),
  current_setting('test.client')::uuid,
  'Payment is linked to the correct client'
);

--------------------------------------------------------------------------------
-- Test 4: Payment is linked to correct invoice
--------------------------------------------------------------------------------
SELECT is(
  (SELECT invoice FROM db.payment WHERE id = current_setting('test.payment')::uuid),
  current_setting('test.invoice')::uuid,
  'Payment is linked to the correct invoice'
);

--------------------------------------------------------------------------------
-- Test 5: Payment initial state is "created"
-- state_type for "created" = 00000000-0000-4000-b001-000000000001
--------------------------------------------------------------------------------
SELECT is(
  (SELECT o.state_type FROM db.object o WHERE o.id = current_setting('test.payment')::uuid),
  '00000000-0000-4000-b001-000000000001'::uuid,
  'Payment initial state is created'
);

--------------------------------------------------------------------------------
-- Test 6: Payment can be enabled (DoEnable)
--------------------------------------------------------------------------------
SELECT lives_ok(
  format('SELECT DoEnable(%L::uuid)', current_setting('test.payment')),
  'DoEnable succeeds on payment'
);

--------------------------------------------------------------------------------
-- Test 7: After enable, state is "enabled"
-- state_type for "enabled" = 00000000-0000-4000-b001-000000000002
--------------------------------------------------------------------------------
SELECT is(
  (SELECT o.state_type FROM db.object o WHERE o.id = current_setting('test.payment')::uuid),
  '00000000-0000-4000-b001-000000000002'::uuid,
  'Payment state is enabled after DoEnable'
);

--------------------------------------------------------------------------------
-- Test 8: Payment can be disabled (DoDisable)
--------------------------------------------------------------------------------
SELECT lives_ok(
  format('SELECT DoDisable(%L::uuid)', current_setting('test.payment')),
  'DoDisable succeeds on payment'
);

SELECT * FROM finish();

ROLLBACK;
