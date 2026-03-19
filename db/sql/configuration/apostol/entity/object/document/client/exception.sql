--------------------------------------------------------------------------------
-- FUNCTION ClientCodeExists  --------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('d4c75fff-8c6a-4c0f-b848-a83dd8e5ad2c', 'ru', 'ClientCodeExists', 'Клиент с кодом "%s" уже существует');
SELECT CreateExceptionResource('d4c75fff-8c6a-4c0f-b848-a83dd8e5ad2c', 'en', 'ClientCodeExists', 'A client with the code "%s" already exists');

/**
 * @brief Raises exception: Client with the given code already exists
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION ClientCodeExists (
  pCode     text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('d4c75fff-8c6a-4c0f-b848-a83dd8e5ad2c'), pCode);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION AccountNotClient  --------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('d9a4bc45-82df-4bf4-b3f9-692ac25ad8aa', 'ru', 'AccountNotClient', 'Учётная запись не принадлежит клиенту');
SELECT CreateExceptionResource('d9a4bc45-82df-4bf4-b3f9-692ac25ad8aa', 'en', 'AccountNotClient', 'The account does not belong to the client');

/**
 * @brief AccountNotClient
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION AccountNotClient (
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', GetResource('d9a4bc45-82df-4bf4-b3f9-692ac25ad8aa');
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION EmailAddressNotSet  ------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('39785dda-3fea-488d-a385-a046dbe80a5f', 'ru', 'EmailAddressNotSet', 'Не задан адрес электронной почты');
SELECT CreateExceptionResource('39785dda-3fea-488d-a385-a046dbe80a5f', 'en', 'EmailAddressNotSet', 'No e-mail address set');

/**
 * @brief EmailAddressNotSet
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EmailAddressNotSet (
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', GetResource('39785dda-3fea-488d-a385-a046dbe80a5f');
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION EmailAddressNotVerified  -------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('db73305a-e372-428c-9f2b-a5e782cd347c', 'ru', 'EmailAddressNotVerified', 'Адрес электронной почты "%s" не подтверждён');
SELECT CreateExceptionResource('db73305a-e372-428c-9f2b-a5e782cd347c', 'en', 'EmailAddressNotVerified', 'Email address "%s" is not verified');

/**
 * @brief EmailAddressNotVerified
 * @param {text} pEmail - Email address
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EmailAddressNotVerified (
  pEmail    text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('db73305a-e372-428c-9f2b-a5e782cd347c'), pEmail);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION PhoneNumberNotSet  -------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('cef9712e-9224-495f-8f1c-38b1aafbb210', 'ru', 'PhoneNumberNotSet', 'Не задан номер телефона');
SELECT CreateExceptionResource('cef9712e-9224-495f-8f1c-38b1aafbb210', 'en', 'PhoneNumberNotSet', 'No phone number set');

/**
 * @brief PhoneNumberNotSet
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION PhoneNumberNotSet (
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', GetResource('cef9712e-9224-495f-8f1c-38b1aafbb210');
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION PhoneNumberNotVerified  --------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('14491806-fe10-4d22-8c22-8c47b57255ab', 'ru', 'PhoneNumberNotVerified', 'Телефон "%s" не подтверждён');
SELECT CreateExceptionResource('14491806-fe10-4d22-8c22-8c47b57255ab', 'en', 'PhoneNumberNotVerified', 'Phone "%s" is not verified');

/**
 * @brief PhoneNumberNotVerified
 * @param {text} pPhone - Phone number
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION PhoneNumberNotVerified (
  pPhone    text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('14491806-fe10-4d22-8c22-8c47b57255ab'), pPhone);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION InvalidClientId ----------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('dfb0a241-4134-49f2-a211-f41f9ddcef91', 'ru', 'InvalidClientId', 'Неверно указан идентификатор клиента, ожидается: %s');
SELECT CreateExceptionResource('dfb0a241-4134-49f2-a211-f41f9ddcef91', 'en', 'InvalidClientId', 'Incorrect client ID, pending: %s');

/**
 * @brief InvalidClientId
 * @param {uuid} pObject - Object identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION InvalidClientId (
  pObject   uuid
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('dfb0a241-4134-49f2-a211-f41f9ddcef91'), pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION IncorrectDateValue -------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('e78f7d8b-08fd-44f1-8bfb-9feacfa3e5df', 'ru', 'IncorrectDateValue', 'Неверное значение даты: %s');
SELECT CreateExceptionResource('e78f7d8b-08fd-44f1-8bfb-9feacfa3e5df', 'en', 'IncorrectDateValue', 'Incorrect date value: %s');

/**
 * @brief IncorrectDateValue
 * @param {date} pValue - Value
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION IncorrectDateValue (
  pValue    date
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('e78f7d8b-08fd-44f1-8bfb-9feacfa3e5df'), pValue);
END;
$$ LANGUAGE plpgsql;
