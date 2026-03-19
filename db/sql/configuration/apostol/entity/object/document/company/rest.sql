--------------------------------------------------------------------------------
-- REST COMPANY ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Dispatches REST API requests for the company entity
 * @param {text} pPath - REST route path
 * @param {jsonb} pPayload - JSON
 * @return {SETOF json} - Records as JSON
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION rest.company (
  pPath       text,
  pPayload    jsonb default null
) RETURNS     SETOF json
AS $$
DECLARE
  r           record;
  e           record;

  arKeys      text[];
BEGIN
  IF pPath IS NULL THEN
    PERFORM RouteIsEmpty();
  END IF;

  IF current_session() IS NULL THEN
    PERFORM LoginFailed();
  END IF;

  CASE pPath
  WHEN '/company/type' THEN

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(fields jsonb)
    LOOP
      FOR e IN EXECUTE format('SELECT %s FROM api.type($1)', JsonbToFields(r.fields, GetColumns('type', 'api'))) USING GetEntity('company')
      LOOP
        RETURN NEXT row_to_json(e);
      END LOOP;
    END LOOP;

  WHEN '/company/method' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id uuid)
      LOOP
        FOR e IN SELECT * FROM api.get_object_methods(r.id) ORDER BY sequence
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id uuid)
      LOOP
        FOR e IN SELECT * FROM api.get_object_methods(r.id) ORDER BY sequence
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/company/set' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, GetRoutines('set_company', 'api', false));
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN EXECUTE format('SELECT row_to_json(api.set_company(%s)) FROM jsonb_to_recordset($1) AS x(%s)', array_to_string(GetRoutines('set_company', 'api', false, 'x'), ', '), array_to_string(GetRoutines('set_company', 'api', true), ', ')) USING pPayload
      LOOP
        RETURN NEXT r;
      END LOOP;

    ELSE

      FOR r IN EXECUTE format('SELECT row_to_json(api.set_company(%s)) FROM jsonb_to_record($1) AS x(%s)', array_to_string(GetRoutines('set_company', 'api', false, 'x'), ', '), array_to_string(GetRoutines('set_company', 'api', true), ', ')) USING pPayload
      LOOP
        RETURN NEXT r;
      END LOOP;

    END IF;

  WHEN '/company/get' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'fields']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id uuid, fields jsonb)
      LOOP
        FOR e IN EXECUTE format('SELECT %s FROM api.get_company($1)', JsonbToFields(r.fields, GetColumns('company', 'api'))) USING r.id
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id uuid, fields jsonb)
      LOOP
        FOR e IN EXECUTE format('SELECT %s FROM api.get_company($1)', JsonbToFields(r.fields, GetColumns('company', 'api'))) USING r.id
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/company/count' THEN

    IF pPayload IS NOT NULL THEN
      arKeys := array_cat(arKeys, ARRAY['search', 'filter', 'reclimit', 'recoffset', 'orderby']);
      PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);
    ELSE
      pPayload := '{}';
    END IF;

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(search jsonb, filter jsonb)
      LOOP
        FOR e IN SELECT * FROM api.count_company(r.search, r.filter) AS count
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(search jsonb, filter jsonb)
      LOOP
        FOR e IN SELECT * FROM api.count_company(r.search, r.filter) AS count
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/company/list' THEN

    IF pPayload IS NOT NULL THEN
      arKeys := array_cat(arKeys, ARRAY['fields', 'search', 'filter', 'reclimit', 'recoffset', 'orderby', 'groupby']);
      PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);
    ELSE
      pPayload := '{}';
    END IF;

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(fields jsonb, search jsonb, filter jsonb, reclimit integer, recoffset integer, orderby jsonb, groupby jsonb)
    LOOP
      IF r.groupby IS NOT NULL THEN
        FOR e IN EXECUTE format('SELECT %s FROM api.list_company($1, $2, $3, $4, $5) GROUP BY %s ORDER BY %s', array_to_string(array_quote_literal_json(JsonbToStrArray(r.fields)), ','), array_to_string(array_quote_literal_json(JsonbToStrArray(r.groupby)), ','), array_to_string(array_quote_literal_json(JsonbToStrArray(r.orderby)), ',')) USING r.search, r.filter, r.reclimit, r.recoffset, '{}'::jsonb
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      ELSE
		FOR e IN EXECUTE format('SELECT %s FROM api.list_company($1, $2, $3, $4, $5)', JsonbToFields(r.fields, GetColumns('company', 'api'))) USING r.search, r.filter, r.reclimit, r.recoffset, r.orderby
		LOOP
		  RETURN NEXT row_to_json(e);
		END LOOP;
	  END IF;
    END LOOP;

  ELSE
    RETURN NEXT ExecuteDynamicMethod(pPath, pPayload);
  END CASE;

  RETURN;
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, pg_temp;
