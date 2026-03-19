--------------------------------------------------------------------------------
-- CreateOrder -----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new order
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pDebit - Debit amount
 * @param {uuid} pCredit - Credit amount
 * @param {numeric} pAmount - Amount
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @throws IncorrectClassType
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateOrder (
  pParent       uuid,
  pType         uuid,
  pDebit        uuid,
  pCredit       uuid,
  pAmount       numeric,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
DECLARE
  uOrder        uuid;
  uDocument     uuid;
  udCurrency    uuid;
  ucCurrency    uuid;

  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'order' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT currency INTO udCurrency FROM db.account WHERE id = pDebit;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('account', 'id', pDebit);
  END IF;

  SELECT currency INTO ucCurrency FROM db.account WHERE id = pCredit;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('account', 'id', pCredit);
  END IF;

  IF udCurrency <> ucCurrency THEN
    PERFORM InvalidOrderAccountCurrency();
  END IF;

  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.order (id, document, currency, debit, credit, amount, code)
  VALUES (uDocument, uDocument, udCurrency, pDebit, pCredit, pAmount, pCode)
  RETURNING id INTO uOrder;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uOrder, uMethod);

  RETURN uOrder;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditOrder -------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Edits an existing order
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pDebit - Debit amount
 * @param {uuid} pCredit - Credit amount
 * @param {numeric} pAmount - Amount
 * @param {text} pCode - Code
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {void}
 * @throws ObjectNotFound
 * @throws OrderCodeExists
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditOrder (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pDebit        uuid default null,
  pCredit       uuid default null,
  pAmount       numeric default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;
  udCurrency    uuid;
  ucCurrency    uuid;

  -- current
  cCode         text;
  cCurrency     uuid;
BEGIN
  SELECT code, currency INTO cCode, cCurrency FROM db.order WHERE id = pId;

  pCode := coalesce(pCode, cCode);

  IF pCode <> cCode THEN
    PERFORM FROM db.order WHERE code = pCode;
    IF FOUND THEN
      PERFORM OrderCodeExists(pCode);
    END IF;
  END IF;

  IF pDebit IS NOT NULL THEN
    SELECT currency INTO udCurrency FROM db.account WHERE id = pDebit;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('account', 'id', pDebit);
    END IF;
  END IF;

  IF pCredit IS NOT NULL THEN
    SELECT currency INTO ucCurrency FROM db.account WHERE id = pCredit;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('account', 'id', pCredit);
    END IF;
  END IF;

  IF coalesce(udCurrency, cCurrency) <> coalesce(ucCurrency, cCurrency) THEN
    PERFORM InvalidOrderAccountCurrency();
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.order
     SET debit = coalesce(pDebit, debit),
         credit = coalesce(pCredit, credit),
         amount = coalesce(pAmount, amount),
         code = coalesce(pCode, code)
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetOrder --------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the order by code
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetOrder (
  pCode     text
) RETURNS   uuid
AS $$
  SELECT id FROM db.order WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetOrderCode ----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the order code by identifier
 * @param {uuid} pOrder - Order
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetOrderCode (
  pOrder    uuid
) RETURNS   text
AS $$
  SELECT code FROM db.order WHERE id = pOrder;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetOrderAmount --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the order by code
 * @param {uuid} pOrder - Order
 * @return {numeric}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetOrderAmount (
  pOrder    uuid
) RETURNS   numeric
AS $$
  SELECT amount FROM db.order WHERE id = pOrder;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- InternalPayment -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief InternalPayment
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pDebit - Debit amount
 * @param {uuid} pCredit - Credit amount
 * @param {numeric} pAmount - Amount
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION InternalPayment (
  pParent       uuid,
  pDebit        uuid,
  pCredit       uuid,
  pAmount       numeric,
  pLabel        text DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateOrder(pParent, GetType('memo.order'), pDebit, pCredit, pAmount, null, pLabel, pDescription);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- TransactionPayment ----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief TransactionPayment
 * @param {uuid} pTransaction - Transaction
 * @param {uuid} pService - Service
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {numeric} pAmount - Amount
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION TransactionPayment (
  pTransaction  uuid,
  pService      uuid,
  pClient       uuid,
  pCurrency     uuid,
  pAmount       numeric,
  pLabel        text DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  uOrder        uuid;
  uDebit        uuid;
  uCredit       uuid;
BEGIN
  IF pAmount > 0 THEN
    uDebit := GetClientAccount(pClient, pCurrency, '200');

    IF uDebit IS NULL THEN
      RAISE EXCEPTION 'ERR-40000: The account for debiting funds for the "%" service was not found.', GetReferenceName(pService);
    END IF;

    uCredit := GetClientAccount(pClient, pCurrency, '000');

    IF uCredit IS NULL THEN
      RAISE EXCEPTION 'ERR-40000: The account for crediting funds for the "%" service was not found.', GetReferenceName(pService);
    END IF;

    uOrder := InternalPayment(pTransaction, uDebit, uCredit, pAmount, pLabel, pDescription);

    PERFORM DoDisable(uOrder);

    UPDATE db.transaction SET "order" = uOrder WHERE id = pTransaction;
  END IF;

  RETURN uOrder;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- ServicePayment --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief ServicePayment
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pClient - Client identifier
 * @param {uuid} pCurrency - Currency identifier
 * @param {numeric} pAmount - Amount
 * @param {text} pLabel - Label
 * @param {text} pDescription - Description
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION ServicePayment (
  pParent       uuid,
  pClient       uuid,
  pCurrency     uuid,
  pAmount       numeric,
  pLabel        text DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  uOrder        uuid;
  uDebit        uuid;
  uCredit       uuid;

  vCurrency     text;
BEGIN
  vCurrency := GetCurrencyCode(pCurrency);

  uDebit := GetClientAccount(pClient, pCurrency, '100');

  IF uDebit IS NULL THEN
    RAISE EXCEPTION 'ERR-40000: The account for debiting in the currency "%" was not found.', vCurrency;
  END IF;

  uCredit := GetClientAccount(pClient, pCurrency, '200');

  IF uCredit IS NULL THEN
    RAISE EXCEPTION 'ERR-40000: The account for crediting in the currency "%" was not found.', vCurrency;
  END IF;

  uOrder := InternalPayment(pParent, uDebit, uCredit, pAmount, pLabel, pDescription);

  PERFORM DoDisable(uOrder);

  RETURN uOrder;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
