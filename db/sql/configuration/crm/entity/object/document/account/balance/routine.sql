--------------------------------------------------------------------------------
-- CheckBalance ----------------------------------------------------------------
--------------------------------------------------------------------------------

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
      PERFORM InsufficientFunds(GetAccountCode(pAccount));
	END IF;
  END IF;

  IF uType = GetType('passive.account') THEN
    IF nBalance + coalesce(pAmount, 0) < 0 THEN
      PERFORM InsufficientFunds(GetAccountCode(pAccount));
	END IF;
  END IF;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- ChangeBalance ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Меняет баланс счёта.
 * @param {uuid} pAccount - Счёт
 * @param {numeric} pAmount - Сумма
 * @param {integer} pType - Тип
 * @param {timestamptz} pDateFrom - Дата
 * @return {void}
 */
CREATE OR REPLACE FUNCTION ChangeBalance (
  pAccount      uuid,
  pAmount       numeric,
  pType         integer DEFAULT 1,
  pDateFrom     timestamptz DEFAULT Now()
) RETURNS       void
AS $$
DECLARE
  dtDateFrom    timestamptz;
  dtDateTo      timestamptz;
BEGIN
  -- получим дату значения в текущем диапозоне дат
  SELECT validFromDate, validToDate INTO dtDateFrom, dtDateTo
    FROM db.balance
   WHERE type = pType
     AND account = pAccount
     AND validFromDate <= pDateFrom
     AND validToDate > pDateFrom;

  IF coalesce(dtDateFrom, MINDATE()) = pDateFrom THEN
    -- обновим значение в текущем диапозоне дат
    UPDATE db.balance SET amount = pAmount
     WHERE type = pType
       AND account = pAccount
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;
  ELSE
    -- обновим дату значения в текущем диапозоне дат
    UPDATE db.balance SET validToDate = pDateFrom
     WHERE type = pType
       AND account = pAccount
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;

    INSERT INTO db.balance (type, account, amount, validfromdate, validToDate)
    VALUES (pType, pAccount, pAmount, pDateFrom, coalesce(dtDateTo, MAXDATE()));
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- NewTurnOver -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Новое движение по счёту.
 * @param {uuid} pAccount - Счёт
 * @param {numeric} pDebit - Сумма обота по дебету
 * @param {numeric} pCredit - Сумма обота по кредиту
 * @param {integer} pType - Тип
 * @param {timestamptz} pTimestamp - Дата
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION NewTurnOver (
  pAccount      uuid,
  pDebit        numeric,
  pCredit       numeric,
  pType         integer DEFAULT 1,
  pTimestamp    timestamptz DEFAULT Now()
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
 * Обновляет баланс счёта.
 * @param {uuid} pAccount - Счёт
 * @param {numeric} pAmount - Сумма изменения остатка. Если сумма положительная, то счёт кредитуется, если сумма отрицательная - счёт дебетуется.
 * @param {integer} pType - Тип
 * @param {timestamptz} pDateFrom - Дата
 * @return {numeric} - Баланс (остаток на счёте)
 */
CREATE OR REPLACE FUNCTION UpdateBalance (
  pAccount      uuid,
  pAmount       numeric,
  pType         integer DEFAULT 1,
  pDateFrom     timestamptz DEFAULT Now()
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

  IF nBalance IS NOT NULL THEN
    PERFORM ChangeBalance(pAccount, nBalance, pType, pDateFrom);
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
 * Возвращает баланс счёта.
 * @param {numeric} pAccount - Счёт
 * @param {integer} pType - Тип
 * @param {timestamptz} pDateFrom - Дата
 * @return {numeric} - Баланс (остаток на счёте)
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
