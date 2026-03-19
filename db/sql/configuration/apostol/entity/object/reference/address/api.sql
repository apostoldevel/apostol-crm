--------------------------------------------------------------------------------
-- ADDRESS ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.address -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.address
AS
  SELECT * FROM ObjectAddress;

GRANT SELECT ON api.address TO administrator;

--------------------------------------------------------------------------------
-- api.add_address -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new address.
 * @param {uuid} pParent - Parent object identifier | null
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCountry - Country identifier
 * @param {text} pCode - Reference code
 * @param {text} pKladr - KLADR code: FF SS RRR GGG PPP UUUU (country, region, district, city, settlement, street)
 * @param {text} pIndex - Postal index
 * @param {text} pRegion - Region
 * @param {text} pDistrict - District
 * @param {text} pCity - City
 * @param {text} pSettlement - Settlement
 * @param {text} pStreet - Street
 * @param {text} pHouse - House number
 * @param {text} pBuilding - Building number
 * @param {text} pStructure - Structure number
 * @param {text} pApartment - Apartment number
 * @param {text} pAddressText - Full address text
 * @return {uuid} - New address identifier
 * @since 1.0.0
 */
/**
 * @brief Creates a new address.
 * @return {uuid} - New address identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_address (
  pParent       uuid,
  pType         uuid,
  pCountry      uuid,
  pCode         text,
  pKladr        text,
  pIndex        text,
  pRegion       text,
  pDistrict     text,
  pCity         text,
  pSettlement   text,
  pStreet       text,
  pHouse        text,
  pBuilding     text,
  pStructure    text,
  pApartment    text,
  pAddressText  text DEFAULT null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateAddress(pParent, coalesce(pType, GetType('post.address')), pCountry, pCode, pKladr, pIndex, pRegion, pDistrict, pCity, pSettlement, pStreet, pHouse, pBuilding, pStructure, pApartment, pAddressText);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_address ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates address data.
 * @param {uuid} pId - Address identifier
 * @param {uuid} pParent - Parent object identifier | null
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCountry - Country identifier
 * @param {text} pCode - Reference code
 * @param {text} pKladr - KLADR code: FF SS RRR GGG PPP UUUU (country, region, district, city, settlement, street)
 * @param {text} pIndex - Postal index
 * @param {text} pRegion - Region
 * @param {text} pDistrict - District
 * @param {text} pCity - City
 * @param {text} pSettlement - Settlement
 * @param {text} pStreet - Street
 * @param {text} pHouse - House number
 * @param {text} pBuilding - Building number
 * @param {text} pStructure - Structure number
 * @param {text} pApartment - Apartment number
 * @param {text} pAddressText - Full address text
 * @return {void}
 * @throws ObjectNotFound - If address with given id does not exist
 * @since 1.0.0
 */
/**
 * @brief Updates an existing address.
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_address (
  pId           uuid,
  pParent       uuid DEFAULT null,
  pType         uuid DEFAULT null,
  pCountry      uuid DEFAULT null,
  pCode         text DEFAULT null,
  pKladr        text DEFAULT null,
  pIndex        text DEFAULT null,
  pRegion       text DEFAULT null,
  pDistrict     text DEFAULT null,
  pCity         text DEFAULT null,
  pSettlement   text DEFAULT null,
  pStreet       text DEFAULT null,
  pHouse        text DEFAULT null,
  pBuilding     text DEFAULT null,
  pStructure    text DEFAULT null,
  pApartment    text DEFAULT null,
  pAddressText  text DEFAULT null
) RETURNS       void
AS $$
DECLARE
  uAddress      uuid;
BEGIN
  SELECT a.id INTO uAddress FROM db.address a WHERE a.id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('адрес', 'id', pId);
  END IF;

  PERFORM EditAddress(uAddress, pParent, pType, pCountry, pCode, pKladr, pIndex, pRegion, pDistrict, pCity, pSettlement, pStreet, pHouse, pBuilding, pStructure, pApartment, pAddressText);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_address -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates or updates an address (upsert).
 * @param {uuid} pId - Address identifier (null to create)
 * @param {uuid} pParent - Parent object identifier
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCountry - Country identifier
 * @param {text} pCode - Reference code
 * @param {text} pKladr - KLADR code
 * @param {text} pIndex - Postal index
 * @param {text} pRegion - Region
 * @param {text} pDistrict - District
 * @param {text} pCity - City
 * @param {text} pSettlement - Settlement
 * @param {text} pStreet - Street
 * @param {text} pHouse - House number
 * @param {text} pBuilding - Building number
 * @param {text} pStructure - Structure number
 * @param {text} pApartment - Apartment number
 * @param {text} pAddressText - Full address text
 * @return {SETOF api.address} - Updated address record
 * @since 1.0.0
 */
/**
 * @brief Creates or updates a address (upsert).
 * @return {SETOF api.address} - Updated address record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_address (
  pId           uuid,
  pParent       uuid DEFAULT null,
  pType         uuid DEFAULT null,
  pCountry      uuid DEFAULT null,
  pCode         text DEFAULT null,
  pKladr        text DEFAULT null,
  pIndex        text DEFAULT null,
  pRegion       text DEFAULT null,
  pDistrict     text DEFAULT null,
  pCity         text DEFAULT null,
  pSettlement   text DEFAULT null,
  pStreet       text DEFAULT null,
  pHouse        text DEFAULT null,
  pBuilding     text DEFAULT null,
  pStructure    text DEFAULT null,
  pApartment    text DEFAULT null,
  pAddressText  text DEFAULT null
) RETURNS       SETOF api.address
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_address(pParent, pType, pCountry, pCode, pKladr, pIndex, pRegion, pDistrict, pCity, pSettlement, pStreet, pHouse, pBuilding, pStructure, pApartment, pAddressText);
  ELSE
    PERFORM api.update_address(pId, pParent, pType, pCountry, pCode, pKladr, pIndex, pRegion, pDistrict, pCity, pSettlement, pStreet, pHouse, pBuilding, pStructure, pApartment, pAddressText);
  END IF;

  RETURN QUERY SELECT * FROM api.address WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_address -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns an address by identifier.
 * @param {uuid} pId - Address identifier
 * @return {api.address} - Address record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_address (
  pId		uuid
) RETURNS	SETOF api.address
AS $$
  SELECT * FROM api.address WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_address -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns the count of addresses matching search/filter criteria.
 * @param {jsonb} pSearch - Search conditions
 * @param {jsonb} pFilter - Filter criteria
 * @return {SETOF bigint} - Row count
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_address (
  pSearch    jsonb default null,
  pFilter    jsonb default null
) RETURNS    SETOF bigint
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'address', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_address ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a list of addresses.
 * @param {jsonb} pSearch - Search conditions: '[{"condition": "AND|OR", "field": "<field>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<value>"}, ...]'
 * @param {jsonb} pFilter - Filter: '{"<field>": "<value>"}'
 * @param {integer} pLimit - Row limit
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort by fields array
 * @return {SETOF api.address} - Address records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_address (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.address
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'address', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_address_string ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns an address as a formatted string.
 * @param {uuid} pId - Address identifier
 * @return {text} - Formatted address string
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_address_string (
  pId           uuid
) RETURNS       text
AS $$
BEGIN
  RETURN GetAddressString(pId);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- OBJECT ADDRESS --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.object_address ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief API view for object-address links.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.object_address
AS
  SELECT * FROM ObjectAddresses;

GRANT SELECT ON api.object_address TO administrator;

--------------------------------------------------------------------------------
-- api.set_object_addresses ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates/updates an address and links it to an object.
 * @param {uuid} pObject - Object identifier
 * @param {uuid} pAddress - Address identifier (null to create)
 * @param {uuid} pParent - Parent object identifier
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCountry - Country identifier
 * @param {text} pCode - Reference code
 * @param {text} pKladr - KLADR code
 * @param {text} pIndex - Postal index
 * @param {text} pRegion - Region
 * @param {text} pDistrict - District
 * @param {text} pCity - City
 * @param {text} pSettlement - Settlement
 * @param {text} pStreet - Street
 * @param {text} pHouse - House number
 * @param {text} pBuilding - Building number
 * @param {text} pStructure - Structure number
 * @param {text} pApartment - Apartment number
 * @param {text} pAddressText - Full address text
 * @return {SETOF api.object_address} - Object-address link record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_object_addresses (
  pObject       uuid,
  pAddress      uuid,
  pParent       uuid,
  pType         uuid,
  pCountry      uuid,
  pCode         text,
  pKladr        text,
  pIndex        text,
  pRegion       text,
  pDistrict     text,
  pCity         text,
  pSettlement   text,
  pStreet       text,
  pHouse        text,
  pBuilding     text,
  pStructure    text,
  pApartment    text,
  pAddressText  text DEFAULT null
) RETURNS       SETOF api.object_address
AS $$
BEGIN
  SELECT id INTO pAddress FROM api.set_address(pAddress, pParent, pType, pCountry, pCode, pKladr, pIndex, pRegion, pDistrict, pCity, pSettlement, pStreet, pHouse, pBuilding, pStructure, pApartment, pAddressText);
  RETURN QUERY SELECT * FROM api.set_object_address(pObject, pAddress);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_object_addresses_json -----------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Sets multiple object addresses from JSON array.
 * @param {uuid} pObject - Object identifier
 * @param {json} pAddresses - JSON array of address records
 * @return {SETOF api.object_address} - Object-address link records
 * @throws ObjectNotFound - If object does not exist
 * @throws JsonIsEmpty - If pAddresses is null
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_object_addresses_json (
  pObject       uuid,
  pAddresses    json
) RETURNS       SETOF api.object_address
AS $$
DECLARE
  r             record;
  uId           uuid;
  arKeys        text[];
BEGIN
  SELECT o.id INTO uId FROM db.object o WHERE o.id = pObject;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('объект', 'id', pObject);
  END IF;

  IF pAddresses IS NOT NULL THEN
    arKeys := array_cat(arKeys, GetRoutines('set_address', 'api', false));
    PERFORM CheckJsonKeys('/object/address/addresses', arKeys, pAddresses);

    FOR r IN SELECT * FROM json_to_recordset(pAddresses) AS addresses(id uuid, parent uuid, type uuid, country uuid, code text, kladr text, index text, region text, district text, city text, settlement text, street text, house text, building text, structure text, apartment text, addresstext text)
    LOOP
      RETURN NEXT api.set_object_addresses(pObject, r.id, r.parent, r.type, r.country, r.code, r.kladr, r.index, r.region, r.district, r.city, r.settlement, r.street, r.house, r.building, r.structure, r.apartment, r.addresstext);
    END LOOP;
  ELSE
    PERFORM JsonIsEmpty();
  END IF;

  RETURN;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_object_addresses_jsonb ----------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Sets multiple object addresses from JSONB array.
 * @param {uuid} pObject - Object identifier
 * @param {jsonb} pAddresses - JSONB array of address records
 * @return {SETOF api.object_address} - Object-address link records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_object_addresses_jsonb (
  pObject       uuid,
  pAddresses	jsonb
) RETURNS       SETOF api.object_address
AS $$
BEGIN
  RETURN QUERY SELECT * FROM api.set_object_addresses_json(pObject, pAddresses::json);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_addresses_json -----------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns all addresses linked to an object as JSON.
 * @param {uuid} pObject - Object identifier
 * @return {json} - JSON array of address records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_object_addresses_json (
  pObject	uuid
) RETURNS	json
AS $$
BEGIN
  RETURN GetObjectAddressesJson(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_addresses_jsonb ----------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns all addresses linked to an object as JSONB.
 * @param {uuid} pObject - Object identifier
 * @return {jsonb} - JSONB array of address records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_object_addresses_jsonb (
  pObject	uuid
) RETURNS	jsonb
AS $$
BEGIN
  RETURN GetObjectAddressesJsonb(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_object_address ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Links an address to an object.
 * @param {uuid} pObject - Object identifier
 * @param {uuid} pAddress - Address identifier
 * @param {timestamp} pDateFrom - Effective date
 * @return {SETOF api.object_address} - Object-address link record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_object_address (
  pObject     uuid,
  pAddress    uuid,
  pDateFrom   timestamp DEFAULT oper_date()
) RETURNS     SETOF api.object_address
AS $$
BEGIN
  PERFORM SetObjectLink(pObject, pAddress, GetObjectTypeCode(pAddress), pDateFrom);
  RETURN QUERY SELECT * FROM api.get_object_address(pObject, pAddress);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.delete_object_address ---------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Unlinks an address from an object.
 * @param {uuid} pObject - Object identifier
 * @param {uuid} pAddress - Address identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.delete_object_address (
  pObject     uuid,
  pAddress    uuid
) RETURNS     void
AS $$
BEGIN
  PERFORM SetObjectLink(pObject, null, GetObjectTypeCode(pAddress));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_address ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns an address link for an object.
 * @param {uuid} pObject - Object identifier
 * @param {uuid} pAddress - Address identifier
 * @return {SETOF api.object_address} - Object-address link record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_object_address (
  pObject       uuid,
  pAddress      uuid
) RETURNS       SETOF api.object_address
AS $$
  SELECT * FROM api.object_address WHERE object = pObject AND address = pAddress;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_object_address -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns a list of object-address links.
 * @param {jsonb} pSearch - Search conditions: '[{"condition": "AND|OR", "field": "<field>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<value>"}, ...]'
 * @param {jsonb} pFilter - Filter: '{"<field>": "<value>"}'
 * @param {integer} pLimit - Row limit
 * @param {integer} pOffSet - Number of rows to skip
 * @param {jsonb} pOrderBy - Sort by fields array
 * @return {SETOF api.object_address} - Object-address link records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_object_address (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.object_address
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'object_address', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
