--------------------------------------------------------------------------------
-- Project Example — Invoice Tests (pgTAP)
--
-- Tests for: BuildInvoice, CreateInvoice
-- Source: entity/object/document/invoice/routine.sql
--
-- Real flow: NTRIP emulator → station_transaction → CreateTransactions() →
--            transaction (enabled) → BuildInvoice() → invoice → payment
-- These tests create transactions directly to unit-test BuildInvoice.
--------------------------------------------------------------------------------

SET search_path TO kernel, public;

BEGIN;

SELECT plan(7);

SELECT test_setup_session();

--------------------------------------------------------------------------------
-- Setup: create clients, device, tariff, transactions
--------------------------------------------------------------------------------
DO $$
DECLARE
  uClient1    uuid;
  uClient2    uuid;
  uDevice     uuid;
  uProduct    uuid;
  uTariff     uuid;
  uService    uuid;
  uCurrency   uuid;
  uTx         uuid;
BEGIN
  uClient1 := test_create_client('inv_client_1', 'Invoice Client 1');
  uClient2 := test_create_client('inv_client_2', 'Invoice Client 2');

  uCurrency := DefaultCurrency();
  uService := GetService('time.service');
  uProduct := GetProduct('default.product');

  -- Create a test device (station)
  -- CreateDevice(pParent, pType, pModel, pClient, pIdentifier, ...)
  uDevice := CreateDevice(
    null,                                   -- pParent
    GetType('base.station'),                -- pType
    GetModel('unknown.model'),              -- pModel
    uClient1,                               -- pClient
    'inv_test_device',                      -- pIdentifier
    null,                                   -- pPassword
    null,                                   -- pVersion
    null,                                   -- pSerial
    null,                                   -- pHost
    null,                                   -- pIp
    null,                                   -- piccid
    null,                                   -- pimsi
    'Invoice Test Station',                 -- pLabel
    'Test device for invoice tests'         -- pDescription
  );
  -- Note: EventDeviceCreate auto-calls DoEnable (created → unavailable)

  -- Create a tariff for the device
  -- CreateTariff(pParent, pType, pProduct, pService, pCurrency, pCode, pTag, pPrice, pCommission, pTax, pLabel, pDescription)
  uTariff := CreateTariff(
    uDevice,                                -- pParent
    GetType('system.tariff'),                 -- pType
    uProduct,                               -- pProduct
    uService,                               -- pService
    uCurrency,                              -- pCurrency
    'inv_test_tariff',                      -- pCode
    'inv_test',                             -- pTag
    10.00,                                  -- pPrice
    0,                                      -- pCommission
    0,                                      -- pTax
    'Invoice test tariff',                  -- pLabel
    'Tariff for invoice tests'              -- pDescription
  );
  -- Note: EventTariffCreate auto-enables

  -- Create 5 transactions for client1 (total = 50.00)
  -- CreateTransaction(pParent, pType, pClient, pService, pCurrency, pOrder, pDevice, pTariff, pSubscription, pInvoice, pTransactionId, pPrice, pVolume, pAmount, ...)
  FOR i IN 1..5 LOOP
    uTx := CreateTransaction(
      uDevice,                              -- pParent
      GetType('service.transaction'),       -- pType
      uClient1,                             -- pClient
      uService,                             -- pService
      uCurrency,                            -- pCurrency
      null,                                 -- pOrder
      uDevice,                              -- pDevice
      uTariff,                              -- pTariff
      null,                                 -- pSubscription
      null,                                 -- pInvoice
      null,                                 -- pTransactionId
      10.00,                                -- pPrice
      1,                                    -- pVolume
      10.00                                 -- pAmount
    );
    -- Auto-enabled by EventTransactionCreate (processing state)
    -- DoDisable moves to "succeeded" state (state_type=disabled) — required for BuildInvoice
    PERFORM DoDisable(uTx);
  END LOOP;

  -- Create 3 transactions for client2 (total = 30.00)
  FOR i IN 1..3 LOOP
    uTx := CreateTransaction(
      uDevice,
      GetType('service.transaction'),
      uClient2,
      uService,
      uCurrency,
      null, uDevice, uTariff, null, null, null,
      10.00, 1, 10.00
    );
    PERFORM DoDisable(uTx);
  END LOOP;

  -- Create a small transaction for client1 (0.50)
  -- Combined with the 50.00 above → total 50.50 >= 1 threshold
  uTx := CreateTransaction(
    uDevice,
    GetType('service.transaction'),
    uClient1,
    uService,
    uCurrency,
    null, uDevice, uTariff, null, null, null,
    0.50, 1, 0.50
  );
  PERFORM DoDisable(uTx);

  PERFORM set_config('test.device', uDevice::text, true);
  PERFORM set_config('test.client1', uClient1::text, true);
  PERFORM set_config('test.client2', uClient2::text, true);
END;
$$;

--------------------------------------------------------------------------------
-- Test 1: BuildInvoice executes without error
--------------------------------------------------------------------------------
SELECT lives_ok(
  format('SELECT BuildInvoice(%L::uuid)', current_setting('test.device')),
  'BuildInvoice executes without error'
);

--------------------------------------------------------------------------------
-- Test 2: At least one invoice was created
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT count(*) > 0 FROM db.invoice WHERE device = current_setting('test.device')::uuid),
  'BuildInvoice created at least one invoice'
);

--------------------------------------------------------------------------------
-- Test 3: Client1 has an invoice (total 50.50 >= threshold 1)
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT count(*) > 0 FROM db.invoice
    WHERE device = current_setting('test.device')::uuid
      AND client = current_setting('test.client1')::uuid),
  'Client1 has an invoice'
);

--------------------------------------------------------------------------------
-- Test 4: Client2 has an invoice (total 30.00 >= threshold 1)
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT count(*) > 0 FROM db.invoice
    WHERE device = current_setting('test.device')::uuid
      AND client = current_setting('test.client2')::uuid),
  'Client2 has an invoice'
);

--------------------------------------------------------------------------------
-- Test 5: Client1 invoice amount = 50.50 (5x10 + 0.50)
--------------------------------------------------------------------------------
SELECT is(
  (SELECT amount FROM db.invoice
    WHERE device = current_setting('test.device')::uuid
      AND client = current_setting('test.client1')::uuid
    ORDER BY amount DESC LIMIT 1),
  50.50::numeric,
  'Client1 invoice amount = 50.50'
);

--------------------------------------------------------------------------------
-- Test 6: All client1 enabled transactions linked to invoice after BuildInvoice
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT count(*) = 0 FROM db.transaction t
    INNER JOIN db.object o ON o.id = t.document
      AND o.state_type = '00000000-0000-4000-b001-000000000003'::uuid
    WHERE t.device = current_setting('test.device')::uuid
      AND t.invoice IS NULL
      AND t.client = current_setting('test.client1')::uuid),
  'All enabled transactions for client1 are linked to an invoice'
);

--------------------------------------------------------------------------------
-- Test 7: Client2 invoice amount = 30.00 (3x10)
--------------------------------------------------------------------------------
SELECT is(
  (SELECT amount FROM db.invoice
    WHERE device = current_setting('test.device')::uuid
      AND client = current_setting('test.client2')::uuid
    LIMIT 1),
  30.00::numeric,
  'Client2 invoice amount = 30.00'
);

SELECT * FROM finish();

ROLLBACK;
