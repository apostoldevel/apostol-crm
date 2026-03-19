--------------------------------------------------------------------------------
-- FUNCTION DeviceExists -------------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('a930c839-050f-450c-80e7-0b6d0c9341e9', 'ru', 'DeviceExists', 'Устройство с идентификатором "%s" уже существует');
SELECT CreateExceptionResource('a930c839-050f-450c-80e7-0b6d0c9341e9', 'en', 'DeviceExists', 'The device with the identifier "%s" already exists');

/**
 * @brief DeviceExists
 * @param {text} pIdentifier - Identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DeviceExists (
  pIdentifier   text
) RETURNS       void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('a930c839-050f-450c-80e7-0b6d0c9341e9'), pIdentifier);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION DeviceNotAssociated ------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('eaac5e16-664d-4bc0-b57d-4fc3b67b175d', 'ru', 'DeviceNotAssociated', 'Устройство с идентификатором "%s" не связано с клиентом');
SELECT CreateExceptionResource('eaac5e16-664d-4bc0-b57d-4fc3b67b175d', 'en', 'DeviceNotAssociated', 'The device with the identifier "%s" is not associated with the client');

/**
 * @brief Raises exception: Device is not associated with a client
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DeviceNotAssociated (
  pCode     text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('eaac5e16-664d-4bc0-b57d-4fc3b67b175d'), pCode);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
