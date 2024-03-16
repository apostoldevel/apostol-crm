--------------------------------------------------------------------------------
-- CreateAddress ---------------------------------------------------------------
--------------------------------------------------------------------------------

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

  -- current
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
 * Возвращает адрес объекта.
 * @param {uuid} pObject - Идентификатор объекта
 * @param {text} pKey - Ключ
 * @param {timestamp} pDate - Дата
 * @return {text}
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

CREATE OR REPLACE FUNCTION AddressStringToJsonb (
  pString   text,
  pAddress  jsonb DEFAULT null,
  pKey      text DEFAULT null
) RETURNS	jsonb
AS $$
DECLARE
  city      text[] = ARRAY['г.', 'город'];
  street    text[] = ARRAY['ул.', 'улица', 'пер.', 'переулок', 'пр-кт', 'проспект', 'пр-д', 'проезд', 'б-р', 'бульвар', 'ш.', 'шоссе', 'ш', 'шоссе'];
  house     text[] = ARRAY['д.', 'дом', 'зд.', 'здание'];
  building  text[] = ARRAY['к.', 'корпус', 'корп.', 'корпус'];
  structure text[] = ARRAY['стр.', 'строение'];
  apartment text[] = ARRAY['кв.', 'квартира'];
  tokens    text[];

  result    jsonb;

  c         int;
  nIndex    int;

  vCode     text;
  vIndex    text;

  key       text;
  str       text;
  part      text;
  token     text;

  parts     text[];
  address   text[];
BEGIN
  key := coalesce(pKey, 'apartment');

  tokens := array_cat(tokens, city);
  tokens := array_cat(tokens, street);
  tokens := array_cat(tokens, house);
  tokens := array_cat(tokens, building);
  tokens := array_cat(tokens, structure);
  tokens := array_cat(tokens, apartment);

  result := coalesce(pAddress, jsonb_build_object());

  parts := string_to_array(pString, ',');

  FOR i IN REVERSE array_length(parts, 1)..1
  LOOP
    part := parts[i];

    address := string_to_array(part, ' ');

	FOR j IN REVERSE array_length(address, 1)..1
	LOOP
	  token := nullif(trim(address[j]), '');

	  IF token IS NULL THEN
		CONTINUE;
	  END IF;

	  IF NOT result ? 'apartment' AND token = ANY (apartment) OR StrPos(token, apartment[1]) > 0 THEN
		key = 'apartment';
	  ELSIF NOT result ? 'structure' AND token = ANY (structure) OR StrPos(token, structure[1]) > 0 THEN
		key = 'structure';
	  ELSIF NOT result ? 'building' AND token = ANY (building) OR StrPos(token, building[1]) > 0 THEN
		key = 'building';
	  ELSIF NOT result ? 'house' AND token = ANY (house) OR StrPos(token, house[1]) > 0 THEN
		key = 'house';
	  ELSIF NOT result ? 'street' AND token = ANY (street) THEN
		IF NOT result ? 'structure' THEN
		  key = 'structure';
		ELSIF NOT result ? 'building' THEN
		  key = 'building';
		ELSIF NOT result ? 'house' THEN
		  key = 'house';
		ELSE
		  key = 'street';
		END IF;
	  ELSIF token = ANY (city) OR token = pAddress->>'city' THEN
		key = 'city';
	  ELSE
        c := ascii(SubStr(token, 1, 1));
		IF length(token) = 6 AND (c >= 48 AND c <= 57) THEN
		  key = 'index';
		END IF;
	  END IF;
	END LOOP;

    str := null;

	FOR j IN REVERSE array_length(address, 1)..1
	LOOP
 	  token := nullif(trim(address[j]), '');

 	  IF token IS NULL THEN
		CONTINUE;
	  END IF;

 	  IF token = ANY (tokens) THEN
        IF key = 'street' THEN
          nIndex := 1;
          WHILE nIndex < array_length(street, 1) AND street[nIndex] <> token LOOP
			nIndex := nIndex + 1;
		  END LOOP;

          IF nIndex <= array_length(street, 1) AND MOD(nIndex, 2) = 0 THEN
            token := street[nIndex - 1];
		  END IF;

 		  result := result || jsonb_build_object('short', rtrim(token, '.'));
		END IF;

		CONTINUE;
	  END IF;

	  IF key = 'structure' THEN
		IF StrPos(token, structure[1]) > 0 THEN
		  token := SubStr(token, length(structure[1]) + 1);
		ELSE
		  IF NOT coalesce(address[j-1] = ANY (structure), false) THEN
			key := 'building';
		  END IF;
		END IF;
	  END IF;

	  IF key = 'building' THEN
		IF StrPos(token, building[1]) > 0 THEN
		  token := SubStr(token, length(building[1]) + 1);
		ELSE
		  IF NOT coalesce(address[j-1] = ANY (building), false) THEN
			key := 'house';
		  END IF;
		END IF;
	  END IF;

	  IF key = 'house' THEN
		IF StrPos(token, house[1]) > 0 THEN
		  token := SubStr(token, length(house[1]) + 1);
		ELSE
		  c := ascii(SubStr(token, 1, 1));
		  IF NOT coalesce(address[j-1] = ANY (house), false) AND NOT (c >= 48 AND c <= 57) THEN
			key := 'street';
		  END IF;
		END IF;
	  END IF;

	  IF key = 'street' THEN
		IF str IS NULL THEN
		  str := token;
		ELSE
		  str := token || ' ' || str;
		END IF;

		token := str;
   	  END IF;

      result := result || jsonb_build_object(key, token);
	END LOOP;
  END LOOP;

  SELECT code, index INTO vCode, vIndex FROM db.address_tree WHERE parent = 2 AND name ILIKE result->>'street' AND short = coalesce(result->>'short', short);

  result := result || jsonb_build_object('code', vCode, 'index', vIndex);

  RETURN result;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
