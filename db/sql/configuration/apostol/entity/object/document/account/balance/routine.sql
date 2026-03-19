--------------------------------------------------------------------------------
-- CheckBalance ----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Validates account balance against the given amount
 * @param {uuid} pAccount - Account identifier
 * @param {numeric} pAmount - Amount
 * @param {int} pType - Type identifier
 * @return {void}
 * @throws InsufficientFunds
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CheckBalance (
  pAccount  uuid,
  pAmount   numeric,
  pType     int DEFAULT 1
) RETURNS   void
AS $$
DECLARE
  uType     uuid;

  nBalance  numeric;
BEGIN
  uType := GetObjectType(pAccount);
  nBalance := coalesce(GetBalance(pAccount, pType), 0);

  IF uType = GetType('active.account') THEN
    IF nBalance + coalesce(pAmount, 0) > 0 THEN
      PERFORM InsufficientFunds(GetAccountCode(pAccount), nBalance, pAmount);
    END IF;
  END IF;

  IF uType = GetType('passive.account') THEN
    IF nBalance + coalesce(pAmount, 0) < 0 THEN
      PERFORM InsufficientFunds(GetAccountCode(pAccount), nBalance, pAmount);
    END IF;
  END IF;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- NewBalance ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Inserts a new balance record for the account
 * @param {uuid} pAccount - Account identifier
 * @param {numeric} pAmount - Amount
 * @param {integer} pType - Type identifier
 * @param {timestamptz} pDateFrom - Date from
 * @param {timestamptz} pDateTo - Date to
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION NewBalance (
  pAccount      uuid,
  pAmount       numeric,
  pType         integer DEFAULT null,
  pDateFrom     timestamptz DEFAULT null,
  pDateTo       timestamptz DEFAULT null
) RETURNS       void
AS $$
BEGIN
  INSERT INTO db.balance (type, account, amount, validfromdate, validToDate)
  VALUES (coalesce(pType, 1), pAccount, pAmount, coalesce(pDateFrom, Now()), coalesce(pDateTo, MAXDATE()));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- ChangeBalance ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Changes the account balance
 * @param {uuid} pAccount - Account identifier
 * @param {numeric} pAmount - Amount
 * @param {numeric} pBalance - Balance
 * @param {integer} pType - Type identifier
 * @param {timestamptz} pDateFrom - Date
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION ChangeBalance (
  pAccount      uuid,
  pAmount       numeric,
  pBalance      numeric,
  pType         integer DEFAULT 1,
  pDateFrom     timestamptz DEFAULT oper_date()
) RETURNS       void
AS $$
DECLARE
  dtDateFrom    timestamptz;
  dtDateTo      timestamptz;
BEGIN
  -- get the value date within the current date range
  SELECT min(validFromDate), max(validToDate) INTO dtDateFrom, dtDateTo
    FROM db.balance
   WHERE type = pType
     AND account = pAccount
     AND validFromDate <= pDateFrom
     AND validToDate > pDateFrom;

  IF FOUND AND pDateFrom = dtDateFrom THEN
    -- update the value within the current date range
    UPDATE db.balance SET amount = pBalance
     WHERE type = pType
       AND account = pAccount
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;

    -- update the difference in values above
    UPDATE db.balance SET amount = amount + pAmount
     WHERE type = pType
       AND account = pAccount
       AND validFromDate >= dtDateTo;
  ELSE
    -- update the value date within the current date range
    UPDATE db.balance SET validToDate = pDateFrom
     WHERE type = pType
       AND account = pAccount
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;

    IF dtDateTo IS NULL THEN
      -- ensure there is no gap in the date range
      SELECT min(validFromDate) INTO dtDateTo
        FROM db.balance
       WHERE type = pType
         AND account = pAccount
         AND validToDate > pDateFrom;
    END IF;

    -- update the values above
    UPDATE db.balance SET amount = amount + pAmount
     WHERE type = pType
       AND account = pAccount
       AND validFromDate >= dtDateTo;

    PERFORM NewBalance( pAccount, pBalance, pType, pDateFrom, dtDateTo);
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- NewTurnOver -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new turnover record for the account
 * @param {uuid} pAccount - Account identifier
 * @param {numeric} pDebit - Debit turnover amount
 * @param {numeric} pCredit - Credit turnover amount
 * @param {integer} pType - Type identifier
 * @param {timestamptz} pTimestamp - Date
 * @return {numeric}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION NewTurnOver (
  pAccount      uuid,
  pDebit        numeric,
  pCredit       numeric,
  pType         integer DEFAULT 1,
  pTimestamp    timestamptz DEFAULT oper_date()
) RETURNS       uuid
AS $$
DECLARE
  uId           uuid;
BEGIN
  INSERT INTO db.turnover (type, account, debit, credit, timestamp)
  VALUES (pType, pAccount, pDebit, pCredit, pTimestamp)
  RETURNING id INTO uId;

  RETURN uId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- UpdateBalance ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates the account balance
 * @param {uuid} pAccount - Account identifier
 * @param {numeric} pAmount - Balance change amount. Positive credits the account, negative debits it.
 * @param {integer} pType - Type identifier
 * @param {timestamptz} pDateFrom - Date
 * @return {numeric} - Balance (account remainder)
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION UpdateBalance (
  pAccount      uuid,
  pAmount       numeric,
  pType         integer DEFAULT 1,
  pDateFrom     timestamptz DEFAULT oper_date()
) RETURNS       numeric
AS $$
DECLARE
  nBalance      numeric;
BEGIN
  PERFORM CheckBalance(pAccount, pAmount, pType);

  IF pAmount > 0 THEN
    PERFORM NewTurnOver(pAccount, 0, pAmount, pType, pDateFrom);
  END IF;

  IF pAmount < 0 THEN
    PERFORM NewTurnOver(pAccount, pAmount, 0, pType, pDateFrom);
  END IF;

  SELECT Sum(debit) + Sum(credit) INTO nBalance
    FROM db.turnover
   WHERE type = pType
     AND account = pAccount
     AND timestamp <= pDateFrom;

  IF FOUND THEN
    PERFORM ChangeBalance(pAccount, pAmount, nBalance, pType, pDateFrom);
  END IF;

  RETURN coalesce(nBalance, 0);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetBalance ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the account balance
 * @param {numeric} pAccount - Account identifier
 * @param {integer} pType - Type identifier
 * @param {timestamptz} pDateFrom - Date
 * @return {numeric} - Balance (account remainder)
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetBalance (
  pAccount      uuid,
  pType         integer DEFAULT 1,
  pDateFrom     timestamptz DEFAULT oper_date()
) RETURNS       numeric
AS $$
  SELECT amount
    FROM db.balance
   WHERE type = pType
     AND account = pAccount
     AND validFromDate <= pDateFrom
     AND validToDate > pDateFrom;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
