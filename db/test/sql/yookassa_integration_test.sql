--------------------------------------------------------------------------------
-- Project Example — YooKassa Integration Test (pgTAP)
--
-- Tests the full payment flow through YooKassa (test mode):
--   GetSession → bind_card → create invoice → create payment → verify queue
--
-- REQUIREMENTS:
--   - YooKassa test credentials configured in registry (shop id / key)
--   - Test card number: 2202474301322987
--   - This test queues real HTTP requests to YooKassa API;
--     without the C++ PGFetch process running, requests stay in http.request
--     with state=0 (queued). The test verifies the SQL layer is correct.
--
-- RUN:  ./db/test/run.sh db/test/sql/yookassa_integration_test.sql
--------------------------------------------------------------------------------

SET search_path TO kernel, public;

BEGIN;

SELECT plan(13);

--------------------------------------------------------------------------------
-- Step 1: Establish session as 'demo' user
--------------------------------------------------------------------------------
DO $$
DECLARE
  vSession text;
BEGIN
  vSession := GetSession(GetUser('demo'));

  IF vSession IS NULL THEN
    RAISE EXCEPTION 'Failed to get session for demo user';
  END IF;

  PERFORM set_config('test.session', vSession, true);
END;
$$;

SELECT ok(
  current_setting('test.session') IS NOT NULL,
  'Session established for demo user'
);

--------------------------------------------------------------------------------
-- Step 2: Get demo client id
--------------------------------------------------------------------------------
DO $$
DECLARE
  uClient uuid;
BEGIN
  uClient := current_client();

  IF uClient IS NULL THEN
    RAISE EXCEPTION 'Demo user has no associated client';
  END IF;

  PERFORM set_config('test.client', uClient::text, true);
END;
$$;

SELECT ok(
  current_setting('test.client')::uuid IS NOT NULL,
  'Demo client found'
);

--------------------------------------------------------------------------------
-- Step 3: Count HTTP requests before bind_card (to isolate our test)
--------------------------------------------------------------------------------
DO $$
DECLARE
  nBefore bigint;
BEGIN
  SELECT count(*) INTO nBefore FROM http.request WHERE agent = 'yookassa';
  PERFORM set_config('test.http_before', nBefore::text, true);
END;
$$;

--------------------------------------------------------------------------------
-- Step 4: Bind test card via api.bind_card
-- Test card: 2202474301322987, expiry: 2027-12, CVC: 111
--------------------------------------------------------------------------------
SELECT lives_ok(
  $$SELECT api.bind_card('2202474301322987', 'Card holder', '2027-12-01'::date, '111')$$,
  'api.bind_card executes without error'
);

--------------------------------------------------------------------------------
-- Step 5: Card record was created
--------------------------------------------------------------------------------
DO $$
DECLARE
  uCard     uuid;
  vMasked   text;
BEGIN
  -- api.bind_card masks the card: first 6 + XXXXXX + last 4
  vMasked := '220247XXXXXX2987';

  SELECT id INTO uCard FROM db.card
   WHERE client = current_setting('test.client')::uuid
     AND code = vMasked;

  IF uCard IS NULL THEN
    RAISE EXCEPTION 'Card not found with masked PAN %', vMasked;
  END IF;

  PERFORM set_config('test.card', uCard::text, true);
END;
$$;

SELECT ok(
  current_setting('test.card')::uuid IS NOT NULL,
  'Card record created with masked PAN'
);

--------------------------------------------------------------------------------
-- Step 6: A validation payment was created for the card
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT count(*) > 0 FROM db.payment
    WHERE card = current_setting('test.card')::uuid),
  'Validation payment created for card binding'
);

--------------------------------------------------------------------------------
-- Step 7: HTTP request to YooKassa was queued
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT count(*) > current_setting('test.http_before')::bigint
     FROM http.request
    WHERE agent = 'yookassa'
      AND command = '/payment/create'),
  'HTTP request queued to YooKassa /payment/create'
);

--------------------------------------------------------------------------------
-- Step 8: The queued request targets the correct API endpoint
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT resource LIKE '%/v3/payments'
     FROM http.request
    WHERE agent = 'yookassa'
      AND command = '/payment/create'
    ORDER BY datetime DESC LIMIT 1),
  'Request targets YooKassa /v3/payments endpoint'
);

--------------------------------------------------------------------------------
-- Step 9: Request contains test flag (test shop key starts with "test")
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT convert_from(content, 'utf8')::jsonb ? 'test'
     FROM http.request
    WHERE agent = 'yookassa'
      AND command = '/payment/create'
    ORDER BY datetime DESC LIMIT 1),
  'Request payload contains test flag'
);

--------------------------------------------------------------------------------
-- Step 10: Create a top-up invoice for the demo client
--------------------------------------------------------------------------------
DO $$
DECLARE
  uClient   uuid;
  uInvoice  uuid;
  uPrice    uuid;
BEGIN
  uClient := current_setting('test.client')::uuid;

  -- Use an existing enabled price (100 RUB from FillDataBase)
  SELECT p.id INTO uPrice
    FROM db.price p
    INNER JOIN db.object o ON o.id = p.id
      AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
   WHERE p.amount = 100
   LIMIT 1;

  IF uPrice IS NULL THEN
    RAISE EXCEPTION 'No enabled 100 RUB price found';
  END IF;

  uInvoice := CreateInvoice(
    uPrice,                                 -- pParent (price as parent)
    GetType('top-up.invoice'),              -- pType
    DefaultCurrency(),                      -- pCurrency
    uClient,                                -- pClient
    null,                                   -- pDevice
    null,                                   -- pCode
    100.00,                                 -- pAmount
    null,                                   -- pPDF
    'Test top-up',                          -- pLabel
    'Integration test top-up invoice'       -- pDescription
  );

  PERFORM set_config('test.invoice', uInvoice::text, true);
  PERFORM set_config('test.price', uPrice::text, true);
END;
$$;

SELECT ok(
  current_setting('test.invoice')::uuid IS NOT NULL,
  'Top-up invoice created'
);

--------------------------------------------------------------------------------
-- Test 11: Invoice is enabled (top-up.invoice auto-enables on create)
--------------------------------------------------------------------------------
SELECT is(
  (SELECT o.state_type FROM db.object o WHERE o.id = current_setting('test.invoice')::uuid),
  '00000000-0000-4000-b001-000000000002'::uuid,
  'Top-up invoice is in enabled state'
);

--------------------------------------------------------------------------------
-- Step 12: Create a payment for the invoice
--------------------------------------------------------------------------------
DO $$
DECLARE
  uPayment  uuid;
  nBefore   bigint;
BEGIN
  SELECT count(*) INTO nBefore FROM http.request WHERE agent = 'yookassa';
  PERFORM set_config('test.http_before_payment', nBefore::text, true);

  uPayment := CreatePayment(
    current_setting('test.invoice')::uuid,  -- pParent
    GetType('payment.yookassa'),               -- pType
    current_setting('test.client')::uuid,   -- pClient
    DefaultCurrency(),                      -- pCurrency
    100.00,                                 -- pAmount
    'Integration test payment',             -- pDescription
    current_setting('test.card')::uuid,     -- pCard
    current_setting('test.invoice')::uuid   -- pInvoice
  );

  PERFORM set_config('test.payment', uPayment::text, true);
END;
$$;

SELECT ok(
  current_setting('test.payment')::uuid IS NOT NULL,
  'Payment created for top-up invoice'
);

--------------------------------------------------------------------------------
-- Test 13: Payment is linked to correct invoice and card
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT invoice = current_setting('test.invoice')::uuid
      AND card = current_setting('test.card')::uuid
     FROM db.payment
    WHERE id = current_setting('test.payment')::uuid),
  'Payment linked to correct invoice and card'
);

--------------------------------------------------------------------------------
-- Test 14: Payment amount matches invoice amount
--------------------------------------------------------------------------------
SELECT is(
  (SELECT amount FROM db.payment WHERE id = current_setting('test.payment')::uuid),
  100.00::numeric,
  'Payment amount = 100.00'
);

SELECT * FROM finish();

ROLLBACK;
