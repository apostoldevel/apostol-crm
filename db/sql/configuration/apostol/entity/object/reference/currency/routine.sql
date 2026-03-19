--------------------------------------------------------------------------------
-- CreateCurrency --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new currency.
 * @return {uuid} - New currency identifier
 * @throws IncorrectClassType - If type does not belong to 'currency' class
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateCurrency (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription  text default null,
  pDigital      integer default null,
  pDecimal      integer default null
) RETURNS       uuid
AS $$
DECLARE
  uReference    uuid;
  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetClassCode(uClass) <> 'currency' THEN
    PERFORM IncorrectClassType();
  END IF;

  uReference := CreateReference(pParent, pType, pCode, pName, pDescription);

  INSERT INTO db.currency (id, reference, digital, decimal)
  VALUES (uReference, uReference, pDigital, pDecimal);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uReference, uMethod);

  RETURN uReference;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditCurrency ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing currency.
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditCurrency (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null,
  pDigital      integer default null,
  pDecimal      integer default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;
BEGIN
  PERFORM EditReference(pId, pParent, pType, pCode, pName, pDescription, current_locale());

  UPDATE db.currency
     SET digital = CheckNull(coalesce(pDigital, digital, 0)),
         decimal = coalesce(pDecimal, decimal)
   WHERE id = pId;

  SELECT class INTO uClass FROM db.object WHERE id = pId;

  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetCurrency --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a currency identifier by code.
 * @param {text} pCode - Currency code
 * @return {uuid} - Currency identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCurrency (
  pCode         text
) RETURNS       uuid
AS $$
BEGIN
  RETURN GetReference(pCode, 'currency');
END;
$$ LANGUAGE plpgsql STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetCurrencyCode ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a currency code by identifier.
 * @param {uuid} pId - Currency identifier
 * @return {text} - Currency code (e.g. 'RUB', 'USD')
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCurrencyCode (
  pId           uuid
) RETURNS       text
AS $$
BEGIN
  RETURN GetReferenceCode(pId);
END;
$$ LANGUAGE plpgsql STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetCurrencyDigital -------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the numeric code of a currency.
 * @param {uuid} pId - Currency identifier
 * @return {integer} - ISO 4217 numeric code
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCurrencyDigital (
  pId           uuid
) RETURNS       integer
AS $$
  SELECT digital FROM db.currency WHERE id = pId
$$ LANGUAGE sql STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DefaultCurrencyCode ------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the default currency code from registry or fallback.
 * @param {text} pDefault - Fallback currency code (defaults to 'RUB')
 * @return {text} - Default currency code
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DefaultCurrencyCode (
  pDefault      text DEFAULT null
) RETURNS       text
AS $$
BEGIN
  RETURN coalesce(RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Currency'), coalesce(pDefault, 'RUB'));
END;
$$ LANGUAGE plpgsql STABLE
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION DefaultCurrency ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the default currency identifier.
 * @return {uuid} - Default currency identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION DefaultCurrency (
) RETURNS       uuid
AS $$
BEGIN
  RETURN GetCurrency(DefaultCurrencyCode());
END;
$$ LANGUAGE plpgsql STABLE
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
