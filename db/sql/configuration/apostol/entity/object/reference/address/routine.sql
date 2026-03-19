--------------------------------------------------------------------------------
-- CreateAddress ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Creates a new address record.
 * @param {uuid} pParent - Parent object identifier (inherits fields if set)
 * @param {uuid} pType - Type identifier (must belong to 'address' class)
 * @param {uuid} pCountry - Country identifier (defaults to Russia/643)
 * @param {text} pCode - Reference code
 * @param {text} pKladr - KLADR code: FF SS RRR GGG PPP UUUU (country, region, district, city, settlement, street)
 * @param {text} pIndex - Postal index
 * @param {text} pRegion - Region name
 * @param {text} pDistrict - District name
 * @param {text} pCity - City name
 * @param {text} pSettlement - Settlement name
 * @param {text} pStreet - Street name
 * @param {text} pHouse - House number
 * @param {text} pBuilding - Building number
 * @param {text} pStructure - Structure number
 * @param {text} pApartment - Apartment number
 * @param {text} pAddressText - Full address as text (overrides auto-generated)
 * @return {uuid} - Address identifier
 * @throws IncorrectClassType - If type does not belong to 'address' class
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateAddress (
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
DECLARE
  r             db.address%rowtype;

  sList         text[];
  sShort        text;
  sAddress      text;

  uAddress      uuid;
  uClass        uuid;
  uReference    uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetClassCode(uClass) <> 'address' THEN
    PERFORM IncorrectClassType();
  END IF;

  pCountry := coalesce(pCountry, GetCountry(643));

  IF pParent IS NOT NULL THEN
    SELECT * INTO r FROM db.address a WHERE a.id = pParent;
    IF FOUND THEN
	  pCountry := coalesce(pCountry, r.country);
	  pKladr := coalesce(pKladr, r.kladr);
	  pIndex := CheckNull(coalesce(pIndex, r.index, ''));
	  pRegion := CheckNull(coalesce(pRegion, r.region, ''));
	  pDistrict := CheckNull(coalesce(pDistrict, r.district, ''));
	  pCity := CheckNull(coalesce(pCity, r.city, ''));
	  pSettlement := CheckNull(coalesce(pSettlement, r.settlement, ''));
	  pStreet := CheckNull(coalesce(pStreet, r.street, ''));
	  pHouse := CheckNull(coalesce(pHouse, r.house, ''));
	  pBuilding := CheckNull(coalesce(pBuilding, r.building, ''));
	  pStructure := CheckNull(coalesce(pStructure, r.structure, ''));
	  pApartment := CheckNull(coalesce(pApartment, r.apartment, ''));
    END IF;
  END IF;

  sAddress := pAddressText;

  IF sAddress IS NULL THEN

    sList[1] := pCity;
    sList[2] := pSettlement;
    sList[3] := pStreet;
    sList[4] := pHouse;
    sList[5] := pBuilding;
    sList[6] := pStructure;
    sList[7] := pApartment;

    sList[8] := null;
    sList[9] := null;

    IF pKladr IS NULL THEN
      FOR nIndex IN 1..3
      LOOP
        IF sList[nIndex] IS NOT NULL THEN
          IF sList[8] IS NULL THEN
            sList[8] := coalesce(sShort, '') || sList[nIndex];
          ELSE
            sList[8] := sList[8] || ', ' || coalesce(sShort, '') || sList[nIndex];
          END IF;
        END IF;
      END LOOP;
    ELSE
      sList[8] := GetAddressTreeString(pKladr, 1, 1);
    END IF;

    FOR nIndex IN 4..7
    LOOP
      IF sList[nIndex] IS NOT NULL THEN
        CASE nIndex
        WHEN 4 THEN
          sShort := 'дом ';
        WHEN 5 THEN
          sShort := 'к';
        WHEN 6 THEN
          sShort := ', стр. ';
        WHEN 7 THEN
          sShort := ', кв. ';
        END CASE;

        IF sList[9] IS NULL THEN
          sList[9] := coalesce(sShort, '') || sList[nIndex];
        ELSE
          sList[9] := sList[9] || coalesce(sShort, '') || sList[nIndex];
        END IF;
      END IF;
    END LOOP;

    sShort := sList[9];

    IF sList[8] IS NULL THEN
      sAddress := sList[9];
    ELSE
      IF sList[9] IS NULL THEN
        sAddress := sList[8];
      ELSE
        sAddress := sList[8] || ', ' || sList[9];
      END IF;
    END IF;
  END IF;

  uReference := CreateReference(pParent, pType, pCode, coalesce(pAddressText, sAddress), sAddress);

  INSERT INTO db.address (id, reference, country, kladr, index, region, district, city, settlement, street, house, building, structure, apartment, sortnum)
  VALUES (uReference, uReference, pCountry, pKladr, pIndex, pRegion, pDistrict, pCity, pSettlement, pStreet, pHouse, pBuilding, pStructure, pApartment, 0)
  RETURNING id INTO uAddress;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uAddress, uMethod);

  RETURN uAddress;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditAddress -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Updates an existing address record.
 * @param {uuid} pId - Address identifier
 * @param {uuid} pParent - Parent object identifier
 * @param {uuid} pType - Type identifier
 * @param {uuid} pCountry - Country identifier
 * @param {text} pCode - Reference code
 * @param {text} pKladr - KLADR code
 * @param {text} pIndex - Postal index
 * @param {text} pRegion - Region name
 * @param {text} pDistrict - District name
 * @param {text} pCity - City name
 * @param {text} pSettlement - Settlement name
 * @param {text} pStreet - Street name
 * @param {text} pHouse - House number
 * @param {text} pBuilding - Building number
 * @param {text} pStructure - Structure number
 * @param {text} pApartment - Apartment number
 * @param {text} pAddressText - Full address as text (overrides auto-generated)
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditAddress (
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
  r             db.address%rowtype;

  sList		    text[];
  sShort		text;
  sAddress	    text;

  uClass        uuid;
  uMethod       uuid;

  -- current values
  cParent	    uuid;
BEGIN
  SELECT parent INTO cParent FROM db.object WHERE id = pId;

  pParent := coalesce(pParent, cParent, null_uuid());

  IF CheckNull(pParent) IS NOT NULL THEN

    SELECT * INTO r FROM db.address a WHERE a.id = pParent;
    IF FOUND THEN
	  pCountry := coalesce(pCountry, r.country);
	  pKladr := coalesce(pKladr, r.kladr);
	  pIndex := CheckNull(coalesce(pIndex, r.index, ''));
	  pRegion := CheckNull(coalesce(pRegion, r.region, ''));
	  pDistrict := CheckNull(coalesce(pDistrict, r.district, ''));
	  pCity := CheckNull(coalesce(pCity, r.city, ''));
	  pSettlement := CheckNull(coalesce(pSettlement, r.settlement, ''));
	  pStreet := CheckNull(coalesce(pStreet, r.street, ''));
	  pHouse := CheckNull(coalesce(pHouse, r.house, ''));
	  pBuilding := CheckNull(coalesce(pBuilding, r.building, ''));
	  pStructure := CheckNull(coalesce(pStructure, r.structure, ''));
	  pApartment := CheckNull(coalesce(pApartment, r.apartment, ''));
	END IF;

  ELSE

    SELECT * INTO r FROM db.address WHERE id = pId;

    pCountry := coalesce(pCountry, r.country);
    pKladr := coalesce(pKladr, r.kladr);
    pIndex := CheckNull(coalesce(pIndex, r.index, ''));
    pRegion := CheckNull(coalesce(pRegion, r.region, ''));
    pDistrict := CheckNull(coalesce(pDistrict, r.district, ''));
    pCity := CheckNull(coalesce(pCity, r.city, ''));
    pSettlement := CheckNull(coalesce(pSettlement, r.settlement, ''));
    pStreet := CheckNull(coalesce(pStreet, r.street, ''));
    pHouse := CheckNull(coalesce(pHouse, r.house, ''));
    pBuilding := CheckNull(coalesce(pBuilding, r.building, ''));
    pStructure := CheckNull(coalesce(pStructure, r.structure, ''));
    pApartment := CheckNull(coalesce(pApartment, r.apartment, ''));

  END IF;

  sAddress := pAddressText;

  IF sAddress IS NULL THEN

    sList[1] := pCity;
    sList[2] := pSettlement;
    sList[3] := pStreet;
    sList[4] := pHouse;
    sList[5] := pBuilding;
    sList[6] := pStructure;
    sList[7] := pApartment;

    sList[8] := null;
    sList[9] := null;

    IF pKladr IS NULL THEN
      FOR nIndex IN 1..3
      LOOP
        IF sList[nIndex] IS NOT NULL THEN
          IF sList[8] IS NULL THEN
            sList[8] := coalesce(sShort, '') || sList[nIndex];
          ELSE
            sList[8] := sList[8] || ', ' || coalesce(sShort, '') || sList[nIndex];
          END IF;
        END IF;
      END LOOP;
    ELSE
      sList[8] := GetAddressTreeString(pKladr, 1, 1);
    END IF;

    FOR nIndex IN 4..7
    LOOP
      IF sList[nIndex] IS NOT NULL THEN
        CASE nIndex
        WHEN 4 THEN
          sShort := 'дом ';
        WHEN 5 THEN
          sShort := 'к';
        WHEN 6 THEN
          sShort := ', стр. ';
        WHEN 7 THEN
          sShort := ', кв. ';
        END CASE;

        IF sList[9] IS NULL THEN
          sList[9] := coalesce(sShort, '') || sList[nIndex];
        ELSE
          sList[9] := sList[9] || coalesce(sShort, '') || sList[nIndex];
        END IF;
      END IF;
    END LOOP;

    sShort := sList[9];

    IF sList[8] IS NULL THEN
      sAddress := sList[9];
    ELSE
      IF sList[9] IS NULL THEN
        sAddress := sList[8];
      ELSE
        sAddress := sList[8] || ', ' || sList[9];
      END IF;
    END IF;
  END IF;

  PERFORM EditReference(pId, pParent, pType, pCode, coalesce(pAddressText, sShort), sAddress, current_locale());

  UPDATE db.address
     SET country = pCountry,
         kladr = pKladr,
         index = pIndex,
         region = pRegion,
         district = pDistrict,
         city = pCity,
         settlement = pSettlement,
         street = pStreet,
         house = pHouse,
         building = pBuilding,
         structure = pStructure,
         apartment = pApartment
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAddress ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns an address identifier by code.
 * @param {text} pCode - Address reference code
 * @return {uuid} - Address identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetAddress (
  pCode		text
) RETURNS 	uuid
AS $$
BEGIN
  RETURN GetReference(pCode, 'address');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAddressString ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Builds a full address string from address components.
 * @param {uuid} pId - Address identifier
 * @return {text} - Formatted address string
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetAddressString (
  pId		uuid
) RETURNS   text
AS $$
DECLARE
  r         db.address%rowtype;
  sList		text[];
  sDelim	text;
  sShort	text;
  sAddress	text;
BEGIN
  SELECT * INTO r FROM db.address WHERE id = pId;

  sList[ 1] := r.index;
  sList[ 2] := GetCountryName(r.country);
  sList[ 3] := r.region;
  sList[ 4] := r.district;
  sList[ 5] := r.city;
  sList[ 6] := r.settlement;
  sList[ 7] := r.street;
  sList[ 8] := r.house;
  sList[ 9] := r.building;
  sList[10] := r.structure;
  sList[11] := r.apartment;

  IF r.kladr IS NULL THEN
    FOR nIndex IN 1..7
    LOOP
      IF sList[nIndex] IS NOT NULL THEN
        IF sAddress IS NULL THEN
          sAddress := sList[nIndex];
        ELSE
          sAddress := sAddress || ', ' || sList[nIndex];
        END IF;
      END IF;
    END LOOP;
  ELSE
    sAddress := GetAddressTreeString(r.kladr, 1, 0);
  END IF;

  FOR nIndex IN 8..11
  LOOP
    IF sList[nIndex] IS NOT NULL THEN

      IF sAddress IS NOT NULL THEN
        sDelim := ', ';
      END IF;

      CASE nIndex
      WHEN 8 THEN
        sShort := 'дом ';
      WHEN 9 THEN
        sDelim := '';
        sShort := 'к';
      WHEN 10 THEN
        sShort := 'стр. ';
      WHEN 11 THEN
        sShort := 'кв. ';
      END CASE;

      IF sAddress IS NULL THEN
        sAddress := sList[nIndex];
      ELSE
        sAddress := sAddress || sDelim || sShort || sList[nIndex];
      END IF;
    END IF;
  END LOOP;

  RETURN sAddress;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectAddress ---------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns an object's address as a string by link key.
 * @param {uuid} pObject - Object identifier
 * @param {text} pKey - Link key (address type code)
 * @param {timestamp} pDate - Effective date
 * @return {text} - Formatted address string
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetObjectAddress (
  pObject	uuid,
  pKey	    text,
  pDate		timestamp DEFAULT oper_date()
) RETURNS	text
AS $$
DECLARE
  uAddress		uuid;
BEGIN
  SELECT linked INTO uAddress
    FROM db.object_link
   WHERE object = pObject
     AND key = pKey
     AND validFromDate <= pDate
     AND validToDate > pDate;

  RETURN GetAddressString(uAddress);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectAddresses ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns all addresses linked to an object as a text array.
 * @param {uuid} pObject - Object identifier
 * @param {timestamp} pDate - Effective date
 * @return {text[]} - Array of [id, key, kladr, address] tuples
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetObjectAddresses (
  pObject	uuid,
  pDate		timestamp DEFAULT oper_date()
) RETURNS	text[]
AS $$
DECLARE
  arResult	text[];
  r		    ObjectAddresses%rowtype;
BEGIN
  FOR r IN
    SELECT address AS id, key, kladr, GetAddressString(address) AS address
      FROM ObjectAddresses
     WHERE object = pObject
       AND validFromDate <= pDate
       AND validToDate > pDate
  LOOP
    arResult := array_cat(arResult, ARRAY[r.id, r.key, r.kladr, r.address]);
  END LOOP;

  RETURN arResult;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectAddressesJson ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns all addresses linked to an object as JSON.
 * @param {uuid} pObject - Object identifier
 * @param {timestamp} pDate - Effective date
 * @return {json} - JSON array of address records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetObjectAddressesJson (
  pObject	uuid,
  pDate		timestamp DEFAULT oper_date()
) RETURNS	json
AS $$
DECLARE
  arResult	json[];
  r		    record;
BEGIN
  FOR r IN
    SELECT address AS id, key, kladr, GetAddressString(address) AS address
      FROM ObjectAddresses
     WHERE object = pObject
       AND validFromDate <= pDate
       AND validToDate > pDate
  LOOP
    arResult := array_append(arResult, row_to_json(r));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectAddressesJsonb -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Returns all addresses linked to an object as JSONB.
 * @param {uuid} pObject - Object identifier
 * @param {timestamp} pDate - Effective date
 * @return {jsonb} - JSONB array of address records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetObjectAddressesJsonb (
  pObject	uuid,
  pDate		timestamp DEFAULT oper_date()
) RETURNS	jsonb
AS $$
BEGIN
  RETURN GetObjectAddressesJson(pObject, pDate);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- AddressStringToJsonb --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Parses a free-form address string into structured JSONB fields.
 * @param {text} pString - Free-form address string
 * @param {jsonb} pAddress - Pre-filled address fields to merge with
 * @return {jsonb} - Structured address with keys: index, city, street, house, building, structure, apartment, short, code
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION AddressStringToJsonb (
  pString       text,
  pAddress      jsonb DEFAULT null
) RETURNS       jsonb
AS $$
DECLARE
  s             text;
  parts         text[];
  part          text;
  i             integer;

  -- Result
  result        jsonb := coalesce(pAddress, '{}'::jsonb);

  -- Temporary variables
  m             text[];
  type_raw      text;
  street_name   text;
  short_type    text;
  long_type     text;

  vCode         text;
  vIndex        text;

  -- Registry of recognized street type patterns (synonyms) for REGEXP matching.
  -- Note: these are detection patterns only; KLADR abbreviation canonicalization is done separately below.
  vTypeRe       text := '(?:'
                       || 'ул\.?|улица'
                       || '|мкр|микрорайон'
                       || '|пер\.?|переул(?:ок)?'
                       || '|переезд'
                       || '|просп(?:\.|ект)?|пр-кт|пр-т|пр\.?|пр'
                       || '|пр-д|проезд'
                       || '|б-р|бульв(?:\.|ар)?'
                       || '|ш(?:\.|оссе)?'
                       || '|наб\.?|набережная'
                       || '|пл\.?|площадь'
                       || '|аллея'
                       || '|сквер'
                       || '|спуск'
                       || '|туп(?:\.|ик)?'
                       || '|тракт'
                       || '|линия'
                       || '|просек|просека'
                       || '|проулок'
                       || '|сад'
                       || '|дор(?:\.|ога)?'
                       || '|автодорога'
                       || '|кв-л|квартал'
                       || '|платф|платформа'
                       || '|уч-?к|участок'
                       || '|ус\.?|усадьба'
                       || ')';
BEGIN
  -- Normalize the input string
  s := coalesce(pString, '');
  -- Remove duplicates like 'кв. кв.' -> 'кв.'
  s := regexp_replace(s, '(?i)\mкв\.\s*кв\.', 'кв.', 'g');
  s := regexp_replace(s, '(?i)\mквартира\s*кв\.', 'кв.', 'g');
  -- Unify spaces and commas
  s := regexp_replace(s, '\s+', ' ', 'g');
  s := regexp_replace(s, '\s*,\s*', ', ', 'g');
  s := regexp_replace(s, '(,\s*){2,}', ', ', 'g');
  s := btrim(s, ' ,');

  parts := regexp_split_to_array(s, '\s*,\s*');

  FOR i IN 1..coalesce(array_length(parts,1),0)
  LOOP
    part := btrim(parts[i]);
    IF part IS NULL OR part = '' THEN
      CONTINUE;
    END IF;

    -- Postal index: 6 consecutive digits
    IF NOT (result ? 'index') THEN
      SELECT substring(part FROM '\m\d{6}\M') INTO vIndex;
      IF vIndex IS NOT NULL THEN
        result := result || jsonb_build_object('index', vIndex);
        part := btrim(regexp_replace(part, '\m\d{6}\M', ' ', 'g'));
      END IF;
    END IF;

    -- Apartment: requires 'кв.' or 'кв ' or 'квартира ' prefix
    IF NOT (result ? 'apartment') THEN
      SELECT regexp_match(part, '(?i)\m(?:кв\.\s*|кв\s+|квартира\s*)([[:alnum:]\-\/]+)') INTO m;
      IF m IS NOT NULL THEN
        result := result || jsonb_build_object('apartment', m[1]);
        part := btrim(regexp_replace(part, '(?i)\m(?:кв\.\s*|кв\s+|квартира\s*)([[:alnum:]\-\/]+)', ' ', 'g'));
      END IF;
    END IF;

    -- Structure: 'стр.' or 'стр ' or 'строение ' prefix
    IF NOT (result ? 'structure') THEN
      SELECT regexp_match(part, '(?i)\m(?:стр\.\s*|стр\s+|строение\s*)([[:alnum:]\-\/]+)') INTO m;
      IF m IS NOT NULL THEN
        result := result || jsonb_build_object('structure', m[1]);
        part := btrim(regexp_replace(part, '(?i)\m(?:стр\.\s*|стр\s+|строение\s*)([[:alnum:]\-\/]+)', ' ', 'g'));
      END IF;
    END IF;

    -- Building (к., к , корп., корпус)
    IF NOT (result ? 'building') THEN
      SELECT regexp_match(part, '(?i)\m(?:к\.\s*|к\s+|корп(?:\.|ус)\s*)([[:alnum:]\-\/]+)') INTO m;
      IF m IS NOT NULL THEN
        result := result || jsonb_build_object('building', m[1]);
        part := btrim(regexp_replace(part, '(?i)\m(?:к\.\s*|к\s+|корп(?:\.|ус)\s*)([[:alnum:]\-\/]+)', ' ', 'g'));
      END IF;
    END IF;

    -- House (д., д , дом)
    IF NOT (result ? 'house') THEN
      SELECT regexp_match(part, '(?i)\m(?:д\.\s*|д\s+|дом\s*)([[:alnum:]\-\/]+)') INTO m;
      IF m IS NOT NULL THEN
        result := result || jsonb_build_object('house', m[1]);
        part := btrim(regexp_replace(part, '(?i)\m(?:д\.\s*|д\s+|дом\s*)([[:alnum:]\-\/]+)', ' ', 'g'));
      END IF;
    END IF;

    -- City (if not already set in input jsonb)
    IF NOT (result ? 'city') THEN
      -- Matches: г. Москва / город Москва
      SELECT regexp_match(part, '(?i)^\s*(?:г\.|город)\s*([[:alpha:]\.\- ]+)\s*$') INTO m;
      IF m IS NOT NULL THEN
        result := result || jsonb_build_object('city', btrim(m[1]));
        part := '';
      ELSIF (pAddress ? 'city') AND lower(part) = lower(pAddress->>'city') THEN
        result := result || jsonb_build_object('city', pAddress->>'city');
        part := '';
      END IF;
    END IF;

    -- Street (type + name) or (name + type)
    IF NOT (result ? 'street') THEN
      -- type + name
      SELECT regexp_match(part, '(?i)^\s*(' || vTypeRe || ')\s+(.+)$') INTO m;
      IF m IS NOT NULL THEN
        type_raw := lower(btrim(m[1], ' .'));
        street_name := btrim(m[2], ' .');
      ELSE
        -- name + type
        SELECT regexp_match(part, '(?i)^(.+?)\s+(' || vTypeRe || ')\.?\s*$') INTO m;
        IF m IS NOT NULL THEN
          street_name := btrim(m[1], ' .');
          type_raw := lower(btrim(m[2], ' .'));
        END IF;
      END IF;

      IF street_name IS NOT NULL THEN
        -- Canonicalize street type to KLADR abbreviations.
        -- Normalize key: remove dots, dashes, and extra spaces.
        DECLARE
          type_key text;
        BEGIN
          type_key := type_raw;
          type_key := replace(type_key, '.', '');
          type_key := replace(type_key, '-', '');
          type_key := regexp_replace(type_key, '\s+', ' ', 'g');

          IF type_key IN ('ул','улица') THEN
            short_type := 'ул';   long_type := 'улица';
          ELSIF type_key IN ('мкр','микрорайон') THEN
            short_type := 'мкр';  long_type := 'микрорайон';
          ELSIF type_key IN ('пер','переул','переулок') THEN
            short_type := 'пер';  long_type := 'переулок';
          ELSIF type_key IN ('переезд') THEN
            short_type := 'переезд'; long_type := 'переезд';
          ELSIF type_key IN ('просп','прт','пркт','проспект') THEN
            short_type := 'пр-кт'; long_type := 'проспект';
          ELSIF type_key IN ('пр', 'прд','прд','проезд') THEN
            short_type := 'проезд'; long_type := 'проезд';
          ELSIF type_key IN ('бр','бульв','бульвар') THEN
            short_type := 'б-р';  long_type := 'бульвар';
          ELSIF type_key IN ('ш','шоссе') THEN
            short_type := 'ш';    long_type := 'шоссе';
          ELSIF type_key IN ('наб','набережная') THEN
            short_type := 'наб';  long_type := 'набережная';
          ELSIF type_key IN ('пл','площадь') THEN
            short_type := 'пл';   long_type := 'площадь';
          ELSIF type_key IN ('аллея') THEN
            short_type := 'аллея'; long_type := 'аллея';
          ELSIF type_key IN ('сквер') THEN
            short_type := 'сквер'; long_type := 'сквер';
          ELSIF type_key IN ('спуск') THEN
            short_type := 'спуск'; long_type := 'спуск';
          ELSIF type_key IN ('туп','тупик') THEN
            short_type := 'туп';   long_type := 'тупик';
          ELSIF type_key IN ('тракт') THEN
            short_type := 'тракт'; long_type := 'тракт';
          ELSIF type_key IN ('линия') THEN
            short_type := 'линия'; long_type := 'линия';
          ELSIF type_key IN ('просек') THEN
            short_type := 'просек'; long_type := 'просек';
          ELSIF type_key IN ('просека') THEN
            short_type := 'просека'; long_type := 'просека';
          ELSIF type_key IN ('проулок') THEN
            short_type := 'проулок'; long_type := 'проулок';
          ELSIF type_key IN ('сад') THEN
            short_type := 'сад'; long_type := 'сад';
          ELSIF type_key IN ('дор','дорога') THEN
            short_type := 'дор'; long_type := 'дорога';
          ELSIF type_key IN ('автодорога') THEN
            short_type := 'автодорога'; long_type := 'автодорога';
          ELSIF type_key IN ('квл','квартал') THEN
            short_type := 'кв-л'; long_type := 'квартал';
          ELSIF type_key IN ('платф','платформа') THEN
            short_type := 'платф'; long_type := 'платформа';
          ELSIF type_key IN ('учк','участок') THEN
            short_type := 'уч-к'; long_type := 'участок';
          ELSIF type_key IN ('ус','усадьба') THEN
            short_type := 'ус.'; long_type := 'усадьба';
          ELSE
            -- Default: keep original (trimmed of trailing dots/spaces)
            short_type := btrim(type_raw, ' .');
            long_type  := btrim(type_raw, ' .');
          END IF;
        END;

        result := result
          || jsonb_build_object('short', short_type)
          || jsonb_build_object('street', street_name);

        part := '';
      END IF;
    END IF;
  END LOOP;

  -- Directory lookup: name = street name (without type), short = KLADR type abbreviation
  IF (result ? 'street') THEN
    IF vIndex IS NOT NULL THEN
      result := result || jsonb_build_object('index', vIndex);

      SELECT code
        INTO vCode
        FROM db.address_tree
       WHERE index = vIndex
         AND name ILIKE result->>'street'
         AND short = coalesce(result->>'short', short)
       LIMIT 1;
    ELSE
      SELECT code, index
        INTO vCode, vIndex
        FROM db.address_tree
       WHERE parent = 2
         AND name ILIKE result->>'street'
         AND short = coalesce(result->>'short', short)
       LIMIT 1;

      IF vIndex IS NOT NULL THEN
        -- Directory index takes priority only if not NULL
        result := result || jsonb_build_object('index', vIndex);
      END IF;
    END IF;

    IF vCode IS NOT NULL THEN
      result := result || jsonb_build_object('code', vCode);
    END IF;
  END IF;

  RETURN result;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
