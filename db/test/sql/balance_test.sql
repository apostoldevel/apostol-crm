--------------------------------------------------------------------------------
-- Project Example — Balance Tests (pgTAP)
--
-- Tests for: CheckBalance, UpdateBalance, ChangeBalance, GetBalance
-- Source: entity/object/document/account/balance/routine.sql
--------------------------------------------------------------------------------

SET search_path TO kernel, public;

BEGIN;

SELECT plan(12);

-- Setup: create a dedicated test client and accounts for this test file
SELECT test_setup_session();

DO $$
DECLARE
  uClient   uuid;
  uActive   uuid;
  uPassive  uuid;
  nBalance  numeric;
BEGIN
  uClient := test_create_client('bal_test_client', 'Balance Test Client');
  uActive := test_create_account(uClient, 'active.account', 'customer.category', 'bal.active.001');
  uPassive := test_create_account(uClient, 'passive.account', 'customer.category', 'bal.passive.001');

  -- Store for use in tests
  PERFORM set_config('test.client', uClient::text, true);
  PERFORM set_config('test.active_account', uActive::text, true);
  PERFORM set_config('test.passive_account', uPassive::text, true);
END;
$$;

--------------------------------------------------------------------------------
-- Test 1: Initial balance is zero (or null → coalesced to 0)
--------------------------------------------------------------------------------
SELECT is(
  coalesce(GetBalance(current_setting('test.active_account')::uuid), 0),
  0::numeric,
  'Active account: initial balance is 0'
);

--------------------------------------------------------------------------------
-- Test 2: Active account — credit (negative amount) succeeds
-- Active account stores debits as negative, credits as negative too.
-- In active accounts: balance goes negative (debit side).
-- UpdateBalance with negative pAmount = debit on active account.
--------------------------------------------------------------------------------
SELECT is(
  UpdateBalance(current_setting('test.active_account')::uuid, -100.00),
  -100.00::numeric,
  'Active account: debit of -100 returns balance -100'
);

--------------------------------------------------------------------------------
-- Test 3: Active account — balance is persisted correctly
--------------------------------------------------------------------------------
SELECT is(
  GetBalance(current_setting('test.active_account')::uuid),
  -100.00::numeric,
  'Active account: GetBalance returns -100 after debit'
);

--------------------------------------------------------------------------------
-- Test 4: Active account — second debit accumulates
--------------------------------------------------------------------------------
SELECT is(
  UpdateBalance(current_setting('test.active_account')::uuid, -50.00),
  -150.00::numeric,
  'Active account: second debit of -50 returns balance -150'
);

--------------------------------------------------------------------------------
-- Test 5: Active account — invalid debit (positive amount) raises exception.
-- For active accounts: balance + amount must be <= 0.
-- Current balance is -150, adding +200 = +50 > 0 → InsufficientFunds.
--------------------------------------------------------------------------------
SELECT throws_ok(
  format('SELECT UpdateBalance(%L::uuid, 200.00)', current_setting('test.active_account')),
  'P0001'
);

--------------------------------------------------------------------------------
-- Test 6: Active account — credit that stays within bounds succeeds.
-- Current balance is -150, adding +100 = -50 <= 0 → OK.
--------------------------------------------------------------------------------
SELECT is(
  UpdateBalance(current_setting('test.active_account')::uuid, 100.00),
  -50.00::numeric,
  'Active account: credit of +100 returns balance -50'
);

--------------------------------------------------------------------------------
-- Test 7: Passive account — initial balance is zero
--------------------------------------------------------------------------------
SELECT is(
  coalesce(GetBalance(current_setting('test.passive_account')::uuid), 0),
  0::numeric,
  'Passive account: initial balance is 0'
);

--------------------------------------------------------------------------------
-- Test 8: Passive account — credit (positive amount) succeeds
--------------------------------------------------------------------------------
SELECT is(
  UpdateBalance(current_setting('test.passive_account')::uuid, 100.00),
  100.00::numeric,
  'Passive account: credit of +100 returns balance 100'
);

--------------------------------------------------------------------------------
-- Test 9: Passive account — invalid debit (negative exceeding balance) raises exception.
-- Current balance is 100, adding -200 = -100 < 0 → InsufficientFunds.
--------------------------------------------------------------------------------
SELECT throws_ok(
  format('SELECT UpdateBalance(%L::uuid, -200.00)', current_setting('test.passive_account')),
  'P0001'
);

--------------------------------------------------------------------------------
-- Test 10: Passive account — valid debit within balance succeeds.
-- Current balance is 100, adding -50 = 50 >= 0 → OK.
--------------------------------------------------------------------------------
SELECT is(
  UpdateBalance(current_setting('test.passive_account')::uuid, -50.00),
  50.00::numeric,
  'Passive account: debit of -50 returns balance 50'
);

--------------------------------------------------------------------------------
-- Test 11: Turnover records are created for debit operations
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT count(*) > 0 FROM db.turnover
    WHERE account = current_setting('test.active_account')::uuid
      AND debit < 0),
  'Active account: turnover records exist with debit entries'
);

--------------------------------------------------------------------------------
-- Test 12: Turnover records are created for credit operations
--------------------------------------------------------------------------------
SELECT ok(
  (SELECT count(*) > 0 FROM db.turnover
    WHERE account = current_setting('test.passive_account')::uuid
      AND credit > 0),
  'Passive account: turnover records exist with credit entries'
);

SELECT * FROM finish();

ROLLBACK;
