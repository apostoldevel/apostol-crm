--------------------------------------------------------------------------------
-- pgTAP setup + test helpers for Project Example
-- Note: CREATE EXTENSION pgtap is done by run.sh as superuser before this file.
--------------------------------------------------------------------------------

SET search_path TO kernel, public;

--------------------------------------------------------------------------------
-- test_setup_session — Establish session context for tests.
-- Uses the 'admin' user which already exists in the database.
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test_setup_session()
RETURNS void
AS $$
DECLARE
  vSession text;
BEGIN
  vSession := GetSession(GetUser('admin'));

  IF vSession IS NULL THEN
    RAISE EXCEPTION 'test_setup_session: Failed to get session for admin';
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- test_create_client — Creates a test client with minimal required fields.
-- Returns the client UUID.
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test_create_client(
  pCode    text DEFAULT 'test_client_' || gen_random_uuid()::text,
  pName    text DEFAULT 'Test Client'
) RETURNS  uuid
AS $$
DECLARE
  uClient  uuid;
BEGIN
  uClient := CreateClient(
    null,                               -- pParent
    GetType('person.customer'),        -- pType (customer → EventCustomerCreate auto-creates accounts)
    current_company(),                  -- pCompany
    null_uuid(),                        -- pUserId (creates a new user)
    pCode,                              -- pCode
    pName                               -- pName
  );

  IF uClient IS NULL THEN
    RAISE EXCEPTION 'test_create_client: Failed to create client %', pCode;
  END IF;

  PERFORM DoEnable(uClient);

  RETURN uClient;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- test_create_account — Creates a test account for a client.
-- pAccountType: 'active.account' or 'passive.account'
-- Returns the account UUID.
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test_create_account(
  pClient       uuid,
  pAccountType  text DEFAULT 'active.account',
  pCategory     text DEFAULT 'customer.category',
  pCode         text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  uAccount      uuid;
  vCode         text;
BEGIN
  vCode := coalesce(pCode, 'test.' || SubStr(gen_random_uuid()::text, 1, 8));

  uAccount := CreateAccount(
    pClient,                            -- pParent
    GetType(pAccountType),              -- pType
    DefaultCurrency(),                  -- pCurrency
    pClient,                            -- pClient
    GetCategory(pCategory),             -- pCategory
    vCode,                              -- pCode
    vCode,                              -- pLabel
    'Test account'                      -- pDescription
  );

  IF uAccount IS NULL THEN
    RAISE EXCEPTION 'test_create_account: Failed to create account for client %', pClient;
  END IF;

  PERFORM DoEnable(uAccount);

  RETURN uAccount;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- test_create_product — Creates a test product.
-- Returns the product UUID.
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test_create_product(
  pCode    text DEFAULT 'test.product.' || gen_random_uuid()::text,
  pName    text DEFAULT 'Test Product'
) RETURNS  uuid
AS $$
DECLARE
  uProduct uuid;
BEGIN
  uProduct := CreateProduct(null, GetType('service.product'), pCode, pName, pLabel => pName, pDescription => 'Test product');
  PERFORM DoEnable(uProduct);
  RETURN uProduct;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- test_create_price — Creates a test price for a product.
-- Returns the price UUID.
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test_create_price(
  pProduct  uuid,
  pAmount   numeric DEFAULT 100.00,
  pMetadata jsonb DEFAULT null
) RETURNS   uuid
AS $$
DECLARE
  uPrice    uuid;
BEGIN
  uPrice := CreatePrice(
    null,                               -- pParent
    GetType('one_off.price'),           -- pType
    DefaultCurrency(),                  -- pCurrency
    pProduct,                           -- pProduct
    null,                               -- pCode
    pAmount,                            -- pAmount
    null,                               -- pPaymentLink
    pMetadata,                          -- pMetaData
    null,                               -- pLabel
    'Test price'                        -- pDescription
  );

  PERFORM DoEnable(uPrice);

  RETURN uPrice;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
