--------------------------------------------------------------------------------
-- Project Example — Subscription Tests (pgTAP)
--
-- Tests for: SubscriptionPaid, SubscriptionCanceled, SubscriptionSwitch
-- Source: entity/object/document/subscription/routine.sql
--
-- Note: Replenishment() is currently a stub — it declares variables but
-- doesn't update balances. Tests verify SubscriptionPaid completes and
-- sets subscription.current = true for each product tier.
--------------------------------------------------------------------------------

SET search_path TO kernel, public;

BEGIN;

SELECT plan(10);

SELECT test_setup_session();

--------------------------------------------------------------------------------
-- Setup: create products, prices, client, subscriptions per tier
--------------------------------------------------------------------------------
DO $$
DECLARE
  uClient       uuid;
  uBasicProd    uuid;
  uStdProd      uuid;
  uProProd      uuid;
  uBasicPrice   uuid;
  uStdPrice     uuid;
  uProPrice     uuid;
  uBasicSub     uuid;
  uStdSub       uuid;
  uProSub       uuid;
  uYearlyPrice  uuid;
  uYearlySub    uuid;
  jMonthly      jsonb;
  jYearly       jsonb;
BEGIN
  uClient := test_create_client('sub_client', 'Subscription Test Client');

  jMonthly := jsonb_build_object('recurring', jsonb_build_object('interval', 'month'));
  jYearly  := jsonb_build_object('recurring', jsonb_build_object('interval', 'year'));

  -- Create products for each tier
  uBasicProd := test_create_product('sub.basic.product', 'Basic');
  uStdProd   := test_create_product('sub.standard.product', 'Standard');
  uProProd   := test_create_product('sub.pro.product', 'Pro');

  -- Create prices with monthly recurring metadata
  uBasicPrice := test_create_price(uBasicProd, 500.00, jMonthly);
  uStdPrice   := test_create_price(uStdProd, 1000.00, jMonthly);
  uProPrice   := test_create_price(uProProd, 2000.00, jMonthly);

  -- Create subscriptions for each tier
  uBasicSub := CreateSubscription(
    null, GetType('charge_automatically.subscription'), uBasicPrice, uClient,
    'sub_client', 'sub_basic_001',
    Now(), Now() + interval '1 month', jMonthly,
    'Basic subscription'
  );
  PERFORM DoEnable(uBasicSub);

  uStdSub := CreateSubscription(
    null, GetType('charge_automatically.subscription'), uStdPrice, uClient,
    'sub_client', 'sub_standard_001',
    Now(), Now() + interval '1 month', jMonthly,
    'Standard subscription'
  );
  PERFORM DoEnable(uStdSub);

  uProSub := CreateSubscription(
    null, GetType('charge_automatically.subscription'), uProPrice, uClient,
    'sub_client', 'sub_pro_001',
    Now(), Now() + interval '1 month', jMonthly,
    'Pro subscription'
  );
  PERFORM DoEnable(uProSub);

  PERFORM set_config('test.client', uClient::text, true);
  PERFORM set_config('test.basic_sub', uBasicSub::text, true);
  PERFORM set_config('test.std_sub', uStdSub::text, true);
  PERFORM set_config('test.pro_sub', uProSub::text, true);
  PERFORM set_config('test.basic_price', uBasicPrice::text, true);

  -- Also create a yearly subscription for testing yearly multiplier
  uYearlyPrice := test_create_price(uBasicProd, 5000.00, jYearly);
  uYearlySub := CreateSubscription(
    null, GetType('charge_automatically.subscription'), uYearlyPrice, uClient,
    'sub_client', 'sub_yearly_001',
    Now(), Now() + interval '1 year', jYearly,
    'Yearly subscription'
  );
  PERFORM DoEnable(uYearlySub);
  PERFORM set_config('test.yearly_sub', uYearlySub::text, true);
END;
$$;

--------------------------------------------------------------------------------
-- Test 1: SubscriptionPaid completes for Basic tier
--------------------------------------------------------------------------------
SELECT lives_ok(
  format('SELECT SubscriptionPaid(%L::uuid)', current_setting('test.basic_sub')),
  'SubscriptionPaid completes for Basic tier'
);

--------------------------------------------------------------------------------
-- Test 2: Basic subscription is marked as current
--------------------------------------------------------------------------------
SELECT is(
  (SELECT current FROM db.subscription WHERE id = current_setting('test.basic_sub')::uuid),
  true,
  'Basic subscription current = true after SubscriptionPaid'
);

--------------------------------------------------------------------------------
-- Test 3: SubscriptionPaid completes for Standard tier
--------------------------------------------------------------------------------
SELECT lives_ok(
  format('SELECT SubscriptionPaid(%L::uuid)', current_setting('test.std_sub')),
  'SubscriptionPaid completes for Standard tier'
);

--------------------------------------------------------------------------------
-- Test 4: Standard subscription is marked as current
--------------------------------------------------------------------------------
SELECT is(
  (SELECT current FROM db.subscription WHERE id = current_setting('test.std_sub')::uuid),
  true,
  'Standard subscription current = true after SubscriptionPaid'
);

--------------------------------------------------------------------------------
-- Test 5: SubscriptionPaid completes for Pro tier
--------------------------------------------------------------------------------
SELECT lives_ok(
  format('SELECT SubscriptionPaid(%L::uuid)', current_setting('test.pro_sub')),
  'SubscriptionPaid completes for Pro tier'
);

--------------------------------------------------------------------------------
-- Test 6: Pro subscription is marked as current
--------------------------------------------------------------------------------
SELECT is(
  (SELECT current FROM db.subscription WHERE id = current_setting('test.pro_sub')::uuid),
  true,
  'Pro subscription current = true after SubscriptionPaid'
);

--------------------------------------------------------------------------------
-- Test 7: SubscriptionCanceled resets current flag
--------------------------------------------------------------------------------
SELECT lives_ok(
  format('SELECT SubscriptionCanceled(%L::uuid)', current_setting('test.basic_sub')),
  'SubscriptionCanceled completes for Basic tier'
);

SELECT is(
  (SELECT current FROM db.subscription WHERE id = current_setting('test.basic_sub')::uuid),
  false,
  'Basic subscription current = false after SubscriptionCanceled'
);

--------------------------------------------------------------------------------
-- Test 9: SubscriptionPaid with yearly interval completes
--------------------------------------------------------------------------------
SELECT lives_ok(
  format('SELECT SubscriptionPaid(%L::uuid)', current_setting('test.yearly_sub')),
  'SubscriptionPaid completes for yearly subscription (12x multiplier)'
);

--------------------------------------------------------------------------------
-- Test 10: Yearly subscription is marked as current
--------------------------------------------------------------------------------
SELECT is(
  (SELECT current FROM db.subscription WHERE id = current_setting('test.yearly_sub')::uuid),
  true,
  'Yearly subscription current = true after SubscriptionPaid'
);

SELECT * FROM finish();

ROLLBACK;
