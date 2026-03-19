--------------------------------------------------------------------------------
-- CreateCountry ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new country.
 * @return {uuid} - New country identifier
 * @throws IncorrectClassType - If type does not belong to 'country' class
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateCountry (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription  text default null,
  pAlpha2       text default null,
  pAlpha3       text default null,
  pDigital      integer default null,
  pFlag         text default null
) RETURNS       uuid
AS $$
DECLARE
  uReference    uuid;
  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetClassCode(uClass) <> 'country' THEN
    PERFORM IncorrectClassType();
  END IF;

  pCode := coalesce(pCode, 'ISO 3166-2:' || pAlpha2);

  uReference := CreateReference(pParent, pType, pCode, pName, pDescription);

  INSERT INTO db.country (id, reference, alpha2, alpha3, digital, flag)
  VALUES (uReference, uReference, pAlpha2, pAlpha3, pDigital, pFlag);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uReference, uMethod);

  RETURN uReference;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditCountry -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing country.
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditCountry (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null,
  pAlpha2       text default null,
  pAlpha3       text default null,
  pDigital      integer default null,
  pFlag         text default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;
BEGIN
  PERFORM EditReference(pId, pParent, pType, pCode, pName, pDescription, current_locale());

  UPDATE db.country
     SET alpha2 = coalesce(pAlpha2, alpha2),
         alpha3 = CheckNull(coalesce(pAlpha3, alpha3, '')),
         digital = CheckNull(coalesce(pDigital, digital, -1)),
         flag = CheckNull(coalesce(pFlag, flag, ''))
   WHERE id = pId;

  SELECT class INTO uClass FROM db.object WHERE id = pId;

  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetCountry ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a country identifier by numeric (digital) code.
 * @param {integer} pDigital - ISO 3166-1 numeric code
 * @return {uuid} - Country identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCountry (
  pDigital      integer
) RETURNS       uuid
AS $$
  SELECT id FROM db.country WHERE digital = pDigital;
$$ LANGUAGE sql STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetCountry ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a country identifier by alpha-2 or alpha-3 code.
 * @param {text} pCode - ISO alpha-2 or alpha-3 code
 * @return {uuid} - Country identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCountry (
  pCode         text
) RETURNS       uuid
AS $$
  SELECT id FROM db.country WHERE alpha2 = pCode OR alpha3 = pCode;
$$ LANGUAGE sql STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetCountryName -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a country name by identifier.
 * @param {uuid} pId - Country identifier
 * @return {text} - Country name
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCountryName (
  pId           uuid
) RETURNS       text
AS $$
BEGIN
  RETURN GetReferenceName(pId);
END;
$$ LANGUAGE plpgsql STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetCountryByISO ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a country identifier by ISO reference code.
 * @param {text} pISO - ISO reference code
 * @return {uuid} - Country identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCountryByISO (
  pISO          text
) RETURNS       uuid
AS $$
BEGIN
  RETURN GetReference(pISO, 'country');
END;
$$ LANGUAGE plpgsql STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
