--------------------------------------------------------------------------------
-- OBJECT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.object_force_delete -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Принудительно "удаляет" документ (минуя события документооборота).
 * @param {numeric} pObject - Идентификатор объекта
 * @out param {numeric} id - Идентификатор
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.object_force_delete (
  pObject	    numeric
) RETURNS	    void
AS $$
DECLARE
  nId		    numeric;
  nState	    numeric;
BEGIN
  SELECT o.id INTO nId FROM db.object o WHERE o.id = pObject;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('объект', 'id', pObject);
  END IF;

  SELECT s.id INTO nState FROM db.state s WHERE s.class = GetObjectClass(pObject) AND s.code = 'deleted';

  IF NOT FOUND THEN
    PERFORM StateByCodeNotFound(pObject, 'deleted');
  END IF;

  PERFORM AddObjectState(pObject, nState);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- TYPE ------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.type
AS
  SELECT * FROM Type;

GRANT SELECT ON api.type TO daemon;

--------------------------------------------------------------------------------
-- api.type --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.type (
  pEssence	numeric
) RETURNS	SETOF api.type
AS $$
  SELECT * FROM api.type WHERE essence = pEssence;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.add_type ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт тип.
 * @param {numeric} pClass - Идентификатор класса
 * @param {varchar} pCode - Код
 * @param {varchar} pName - Наименование
 * @param {text} pDescription - Описание
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.add_type (
  pClass	    numeric,
  pCode		    varchar,
  pName		    varchar,
  pDescription  text DEFAULT null
) RETURNS 	    numeric
AS $$
BEGIN
  RETURN AddType(pClass, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_type -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет тип.
 * @param {numeric} pId - Идентификатор типа
 * @param {numeric} pClass - Идентификатор класса
 * @param {varchar} pCode - Код
 * @param {varchar} pName - Наименование
 * @param {text} pDescription - Описание
 * @out param {numeric} id - Идентификатор типа
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_type (
  pId           numeric,
  pClass        numeric DEFAULT null,
  pCode         varchar DEFAULT null,
  pName         varchar DEFAULT null,
  pDescription	text DEFAULT null
) RETURNS       void
AS $$
BEGIN
  PERFORM EditType(pId, pClass, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.delete_type -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет тип.
 * @param {numeric} pId - Идентификатор типа
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.delete_type (
  pId         numeric
) RETURNS     void
AS $$
BEGIN
  PERFORM DeleteType(pId);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_type ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает тип.
 * @return {Type} - Тип
 */
CREATE OR REPLACE FUNCTION api.get_type (
  pId         numeric
) RETURNS     SETOF api.type
AS $$
  SELECT * FROM api.type WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_type ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает тип объекта по коду.
 * @param {varchar} pCode - Код типа объекта
 * @return {numeric} - Тип объекта
 */
CREATE OR REPLACE FUNCTION api.get_type (
  pCode		varchar
) RETURNS	numeric
AS $$
BEGIN
  RETURN GetType(pCode);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_type ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает тип списоком.
 * @return {SETOF record} - Записи
 */
CREATE OR REPLACE FUNCTION api.list_type (
) RETURNS   SETOF api.type
AS $$
  SELECT * FROM api.type
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- OBJECT FILE -----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.object_file -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.object_file
AS
  SELECT * FROM ObjectFile;

GRANT SELECT ON api.object_file TO daemon;

--------------------------------------------------------------------------------
-- api.set_object_files_json ---------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_object_files_json (
  pObject	    numeric,
  pFiles	    json
) RETURNS 	    numeric
AS $$
DECLARE
  r             record;
  arKeys	    text[];
  nId		    numeric;
BEGIN
  SELECT o.id INTO nId FROM db.object o WHERE o.id = pObject;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('объект', 'id', pObject);
  END IF;

  IF pFiles IS NOT NULL THEN
    arKeys := array_cat(arKeys, ARRAY['id', 'hash', 'name', 'path', 'size', 'date', 'delete']);
    PERFORM CheckJsonKeys('/object/file/files', arKeys, pFiles);

    FOR r IN SELECT * FROM json_to_recordset(pFiles) AS files(id numeric, hash text, name text, path text, size int, date timestamp, delete boolean)
    LOOP
      IF r.id IS NOT NULL THEN

        SELECT o.id INTO nId FROM db.object_file o WHERE o.id = r.id AND object = pObject;

        IF NOT FOUND THEN
          PERFORM ObjectNotFound('файл', r.name, r.id);
        END IF;

        IF coalesce(r.delete, false) THEN
          PERFORM DeleteObjectFile(r.id);
        ELSE
          PERFORM EditObjectFile(r.id, r.hash, r.name, r.path, r.size, r.date);
        END IF;
      ELSE
        nId := AddObjectFile(pObject, r.hash, r.name, r.path, r.size, r.date);
      END IF;
    END LOOP;
  ELSE
    PERFORM JsonIsEmpty();
  END IF;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_object_files_jsonb --------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_object_files_jsonb (
  pObject       numeric,
  pFiles        jsonb
) RETURNS       numeric
AS $$
BEGIN
  RETURN api.set_object_files_json(pObject, pFiles::json);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_files_json ---------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_object_files_json (
  pObject	numeric
) RETURNS	json
AS $$
BEGIN
  RETURN GetObjectFilesJson(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_files_jsonb --------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_object_files_jsonb (
  pObject	numeric
) RETURNS	jsonb
AS $$
BEGIN
  RETURN GetObjectFilesJsonb(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_file ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает файлы объекта
 * @param {numeric} pId - Идентификатор объекта
 * @return {api.object_file}
 */
CREATE OR REPLACE FUNCTION api.get_object_file (
  pId		numeric
) RETURNS	SETOF api.object_file
AS $$
  SELECT * FROM api.object_file WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_object_file --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список файлов объекта.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.object_file}
 */
CREATE OR REPLACE FUNCTION api.list_object_file (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.object_file
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'object_file', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- OBJECT DATA -----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.object_data_type --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.object_data_type
AS
  SELECT * FROM ObjectDataType;

GRANT SELECT ON api.object_data_type TO daemon;

--------------------------------------------------------------------------------
-- api.get_object_data_type_by_code --------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_object_data_type_by_code (
  pCode		varchar
) RETURNS	numeric
AS $$
BEGIN
  RETURN GetObjectDataType(pCode);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.object_data -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.object_data
AS
  SELECT * FROM ObjectData;

GRANT SELECT ON api.object_data TO daemon;

--------------------------------------------------------------------------------
-- api.set_object_data ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Устанавливает данные объекта
 * @param {numeric} pObject - Идентификатор объекта
 * @param {varchar} pType - Код типа данных
 * @param {varchar} pCode - Код
 * @param {text} pData - Данные
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.set_object_data (
  pObject       numeric,
  pType         varchar,
  pCode         varchar,
  pData         text
) RETURNS       numeric
AS $$
DECLARE
  r             record;
  nType         numeric;
  arTypes       text[];
BEGIN
  pType := lower(pType);

  FOR r IN SELECT code FROM db.object_data_type
  LOOP
    arTypes := array_append(arTypes, r.code);
  END LOOP;

  IF array_position(arTypes, pType::text) IS NULL THEN
    PERFORM IncorrectCode(pType, arTypes);
  END IF;

  nType := GetObjectDataType(pType);

  RETURN SetObjectData(pObject, nType, pCode, pData);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_object_data_json ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_object_data_json (
  pObject       numeric,
  pData	        json
) RETURNS       numeric
AS $$
DECLARE
  nId           numeric;
  nType         numeric;

  arKeys        text[];
  arTypes       text[];

  r             record;
BEGIN
  SELECT o.id INTO nId FROM db.object o WHERE o.id = pObject;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('объект', 'id', pObject);
  END IF;

  IF pData IS NOT NULL THEN
    arKeys := array_cat(arKeys, ARRAY['id', 'type', 'code', 'data']);
    PERFORM CheckJsonKeys('/object/data', arKeys, pData);

    FOR r IN SELECT code FROM db.object_data_type
    LOOP
      arTypes := array_append(arTypes, r.code);
    END LOOP;

    FOR r IN SELECT * FROM json_to_recordset(pData) AS data(id numeric, type varchar, code varchar, data text)
    LOOP
      IF array_position(arTypes, r.type::text) IS NULL THEN
        PERFORM IncorrectCode(r.type, arTypes);
      END IF;

      nType := GetObjectDataType(r.type);

      IF r.id IS NOT NULL THEN
        SELECT o.id INTO nId FROM db.object_data o WHERE o.id = r.id AND object = pObject;

        IF NOT FOUND THEN
          PERFORM ObjectNotFound('данные', r.code, r.id);
        END IF;

        IF NULLIF(r.data, '') IS NULL THEN
          PERFORM DeleteObjectData(r.id);
        ELSE
          PERFORM EditObjectData(r.id, pObject, nType, r.code, r.data);
        END IF;
      ELSE
        nId := AddObjectData(pObject, nType, r.code, r.data);
      END IF;
    END LOOP;
  ELSE
    PERFORM JsonIsEmpty();
  END IF;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_object_data_jsonb ---------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_object_data_jsonb (
  pObject     numeric,
  pData       jsonb
) RETURNS     numeric
AS $$
BEGIN
  RETURN api.set_object_data_json(pObject, pData::json);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_data_json ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_object_data_json (
  pObject	numeric
) RETURNS	json
AS $$
BEGIN
  RETURN GetObjectDataJson(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_data_jsonb ---------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_object_data_jsonb (
  pObject	numeric
) RETURNS	jsonb
AS $$
BEGIN
  RETURN GetObjectDataJsonb(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_data ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает данные объекта
 * @param {numeric} pId - Идентификатор объекта
 * @return {api.object_data}
 */
CREATE OR REPLACE FUNCTION api.get_object_data (
  pId		numeric
) RETURNS	SETOF api.object_data
AS $$
  SELECT * FROM api.object_data WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_object_data --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список данных объекта.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.object_data}
 */
CREATE OR REPLACE FUNCTION api.list_object_data (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.object_data
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'object_data', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- OBJECT COORDINATES ----------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.object_coordinates ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.object_coordinates
AS
  SELECT * FROM ObjectCoordinates;

GRANT SELECT ON api.object_coordinates TO daemon;

--------------------------------------------------------------------------------
-- api.set_object_coordinates --------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Устанавливает координаты объекта
 * @param {numeric} pObject - Идентификатор объекта
 * @param {varchar} pCode - Код
 * @param {varchar} pName - Наименование
 * @param {numeric} pLatitude - Широта
 * @param {numeric} pLongitude - Долгота
 * @param {numeric} pAccuracy - Точность (высота над уровнем моря)
 * @param {text} pDescription - Описание
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.set_object_coordinates (
  pObject       numeric,
  pCode         varchar,
  pName         varchar,
  pLatitude     numeric,
  pLongitude    numeric,
  pAccuracy     numeric,
  pDescription  text
) RETURNS       numeric
AS $$
DECLARE
  nId           numeric;
  nDataId       numeric;
  nType         numeric;
BEGIN
  pCode := coalesce(pCode, 'geo');

  SELECT d.id INTO nId FROM db.object_coordinates d WHERE d.object = pObject AND d.code = pCode;
  SELECT d.id INTO nDataId FROM db.object_data d WHERE d.object = pObject AND d.code = 'geo';

  IF pName IS NOT NULL THEN
    IF nId IS NULL THEN
      nId := AddObjectCoordinates(pObject, pCode, pName, pLatitude, pLongitude, pAccuracy, pDescription);
    ELSE
      PERFORM EditObjectCoordinates(nId, pObject, pCode, pName, pLatitude, pLongitude, pAccuracy, pDescription);
    END IF;

    nType := GetObjectDataType('json');
    IF nDataId IS NULL THEN
      nDataId := AddObjectData(pObject, nType, 'geo',GetObjectCoordinatesJson(pObject)::text);
    ELSE
      PERFORM EditObjectData(nDataId, pObject, nType, 'geo',GetObjectCoordinatesJson(pObject)::text);
    END IF;
  ELSE
    PERFORM DeleteObjectData(nDataId);
    PERFORM DeleteObjectCoordinates(nId);
  END IF;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_object_coordinates_json ---------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_object_coordinates_json (
  pObject       numeric,
  pCoordinates  json
) RETURNS       numeric
AS $$
DECLARE
  r             record;
  nId           numeric;
  nDataId       numeric;
  nType         numeric;
  arKeys        text[];
BEGIN
  SELECT o.id INTO nId FROM db.object o WHERE o.id = pObject;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('объект', 'id', pObject);
  END IF;

  IF pCoordinates IS NOT NULL THEN
    arKeys := array_cat(arKeys, ARRAY['id', 'code', 'name', 'latitude', 'longitude', 'accuracy', 'description']);
    PERFORM CheckJsonKeys('/object/coordinates', arKeys, pCoordinates);

    nType := GetObjectDataType('json');

    FOR r IN SELECT * FROM json_to_recordset(pCoordinates) AS coordinates(id numeric, code varchar, name varchar, latitude numeric, longitude numeric, accuracy numeric, description text)
    LOOP
      IF r.id IS NOT NULL THEN

        r.code := coalesce(NULLIF(r.code, ''), 'geo');

        SELECT o.id INTO nId FROM db.object_coordinates o WHERE o.id = r.id AND o.object = pObject;

        IF NOT FOUND THEN
          PERFORM ObjectNotFound('координаты', r.code, r.id);
        END IF;

        SELECT o.id INTO nDataId FROM db.object_data o WHERE o.object = pObject AND o.code = 'geo';

        IF coalesce(r.name, true) THEN
          PERFORM DeleteObjectData(nDataId);
          PERFORM DeleteObjectCoordinates(r.id);
        ELSE
          PERFORM EditObjectCoordinates(r.id, pObject, r.code, r.name, r.latitude, r.longitude, r.accuracy, r.description);
          PERFORM EditObjectData(nDataId, pObject, nType, 'geo', pCoordinates::text);
        END IF;
      ELSE
        nId := AddObjectCoordinates(pObject, r.code, r.name, r.latitude, r.longitude, r.accuracy, r.description);
        nDataId := AddObjectData(pObject, nType, 'geo', pCoordinates::text);
      END IF;
    END LOOP;
  ELSE
    PERFORM JsonIsEmpty();
  END IF;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_object_coordinates_jsonb --------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_object_coordinates_jsonb (
  pObject       numeric,
  pCoordinates  jsonb
) RETURNS       numeric
AS $$
BEGIN
  RETURN api.set_object_coordinates_json(pObject, pCoordinates::json);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_coordinates_json ---------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_object_coordinates_json (
  pObject	numeric
) RETURNS	json
AS $$
BEGIN
  RETURN GetObjectCoordinatesJson(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_coordinates_jsonb --------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_object_coordinates_jsonb (
  pObject	numeric
) RETURNS	jsonb
AS $$
BEGIN
  RETURN GetObjectCoordinatesJsonb(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_object_coordinates --------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает данные объекта
 * @param {numeric} pId - Идентификатор объекта
 * @return {api.object_coordinates}
 */
CREATE OR REPLACE FUNCTION api.get_object_coordinates (
  pId		numeric
) RETURNS	SETOF api.object_coordinates
AS $$
  SELECT * FROM api.object_coordinates WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_object_coordinates -------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список данных объекта.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.object_coordinates}
 */
CREATE OR REPLACE FUNCTION api.list_object_coordinates (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.object_coordinates
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'object_coordinates', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
