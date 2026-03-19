--------------------------------------------------------------------------------
-- FUNCTION AccountCodeExists --------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('86615dbe-5cbc-45fc-bde8-b7afe8d5f236', 'ru', 'AccountCodeExists', 'Счёт "%s" уже существует');
SELECT CreateExceptionResource('86615dbe-5cbc-45fc-bde8-b7afe8d5f236', 'en', 'AccountCodeExists', 'Account "%s" already exists');

/**
 * @brief Raises exception: Account with the given code already exists
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION AccountCodeExists (
  pCode     text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('86615dbe-5cbc-45fc-bde8-b7afe8d5f236'), pCode);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION AccountNotFound ----------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('6750236e-5328-474d-968c-c0a15e40ffe4', 'ru', 'AccountNotFound', 'Счёт "%s" не найден');
SELECT CreateExceptionResource('6750236e-5328-474d-968c-c0a15e40ffe4', 'en', 'AccountNotFound', 'Account "%s" not found');

/**
 * @brief Raises exception: Account not found
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION AccountNotFound (
  pCode     text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('6750236e-5328-474d-968c-c0a15e40ffe4'), pCode);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION AccountNotAssociated -----------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('6750236e-5328-474d-968c-c0a15e40ffe4', 'ru', 'AccountNotAssociated', 'Счёт "%s" не связан с клиентом');
SELECT CreateExceptionResource('6750236e-5328-474d-968c-c0a15e40ffe4', 'en', 'AccountNotAssociated', 'Account "%s" not affiliated with the client');

/**
 * @brief Raises exception: Account is not associated with a client
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION AccountNotAssociated (
  pCode     text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('6750236e-5328-474d-968c-c0a15e40ffe4'), pCode);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION InsufficientFunds --------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('256bd60f-5bce-4f03-89af-bee4788e5212', 'ru', 'InsufficientFunds', 'Недостаточно средств на счете: %s. Баланс: %s. Сумма: %s');
SELECT CreateExceptionResource('256bd60f-5bce-4f03-89af-bee4788e5212', 'en', 'InsufficientFunds', 'Insufficient funds in the account: %s. Balance: %s. Amount: %s');

/**
 * @brief Raises exception: Insufficient funds in the account
 * @param {text} pCode - Code
 * @param {numeric} pBalance - Balance
 * @param {numeric} pAmount - Amount
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION InsufficientFunds (
  pCode     text,
  pBalance  numeric,
  pAmount   numeric
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('256bd60f-5bce-4f03-89af-bee4788e5212'), pCode, pBalance, pAmount);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION IncorrectTurnover --------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('5fd72453-fd4c-424d-802a-35872e426852', 'ru', 'IncorrectTurnover', 'Неправильный ввод суммы оборота по счету: %s');
SELECT CreateExceptionResource('5fd72453-fd4c-424d-802a-35872e426852', 'en', 'IncorrectTurnover', 'Incorrect entry of the account turnover amount: %s');

/**
 * @brief Raises exception: Incorrect turnover amount entry
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION IncorrectTurnover (
  pCode     text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('5fd72453-fd4c-424d-802a-35872e426852'), pCode);
END;
$$ LANGUAGE plpgsql;
