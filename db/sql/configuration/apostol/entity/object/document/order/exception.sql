--------------------------------------------------------------------------------
-- FUNCTION AccountCodeExists --------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('056f7462-17fd-442d-bbee-3d289f610d88', 'ru', 'OrderCodeExists', 'Заказ с кодом "%s" уже существует');
SELECT CreateExceptionResource('056f7462-17fd-442d-bbee-3d289f610d88', 'en', 'OrderCodeExists', 'Order "%s" already exists');

/**
 * @brief Raises exception: Order with the given code already exists
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION OrderCodeExists (
  pCode     text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('056f7462-17fd-442d-bbee-3d289f610d88'), pCode);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

--------------------------------------------------------------------------------

SELECT CreateExceptionResource('17fd11f8-dffd-42c0-a8b0-0a9d46e7a94a', 'ru', 'InvalidOrderAccountCurrency', 'Неверная валюта счета заказа');
SELECT CreateExceptionResource('17fd11f8-dffd-42c0-a8b0-0a9d46e7a94a', 'en', 'InvalidOrderAccountCurrency', 'Invalid currency of the order account');

/**
 * @brief InvalidOrderAccountCurrency
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION InvalidOrderAccountCurrency()
RETURNS     void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', GetResource('056f7462-17fd-442d-bbee-3d289f610d88');
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

--------------------------------------------------------------------------------
-- FUNCTION IncorrectOrderAmount -----------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('e3e04260-17a7-4571-9840-927b9e1400e8', 'ru', 'IncorrectOrderAmount', 'Недопустимая сумма %s в заказе: "%s"');
SELECT CreateExceptionResource('e3e04260-17a7-4571-9840-927b9e1400e8', 'en', 'IncorrectOrderAmount', 'Invalid amount %s in the order: "%s"');

/**
 * @brief IncorrectOrderAmount
 * @param {text} pCode - Code
 * @param {numeric} pAmount - Amount
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION IncorrectOrderAmount (
  pCode     text,
  pAmount   numeric
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('e3e04260-17a7-4571-9840-927b9e1400e8'), pAmount, pCode);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

--------------------------------------------------------------------------------
-- FUNCTION IncorrectOrderAmount -----------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('681fd4bc-1dd4-45a2-94d1-5a2261597ad0', 'ru', 'TransferringInactiveAccount', 'Перевод средств на неактивный счет "%s" неприемлем.');
SELECT CreateExceptionResource('681fd4bc-1dd4-45a2-94d1-5a2261597ad0', 'en', 'TransferringInactiveAccount', 'Transferring funds to an inactive account "%s" is unacceptable.');

/**
 * @brief TransferringInactiveAccount
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION TransferringInactiveAccount (
  pCode     text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('681fd4bc-1dd4-45a2-94d1-5a2261597ad0'), pCode);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
