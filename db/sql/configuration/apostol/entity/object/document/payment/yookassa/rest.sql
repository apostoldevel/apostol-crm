--------------------------------------------------------------------------------
-- REST API YOOKASSA -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Dispatches REST API requests for the YooKassa payment entity
 * @param {text} pPath - REST route path
 * @param {jsonb} pPayload - Additional data
 * @return {SETOF json} - Records as JSON
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION rest.yookassa (
  pPath         text,
  pPayload      jsonb DEFAULT null
) RETURNS       SETOF json
AS $$
DECLARE
  r             record;
  e             record;

  uPayment      uuid;
  vPayment      text;

  arKeys        text[];
BEGIN
  IF NULLIF(pPath, '') IS NULL THEN
    PERFORM RouteIsEmpty();
  END IF;

  CASE pPath
  WHEN '/yookassa/callback' THEN

    RETURN NEXT json_build_object('ok', api.yookassa_callback(pPayload));

  WHEN '/yookassa/type' THEN

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(fields jsonb)
    LOOP
      FOR e IN EXECUTE format('SELECT %s FROM api.type($1) WHERE class = $2', JsonbToFields(r.fields, GetColumns('type', 'api'))) USING GetEntity('payment'), GetClass('yookassa')
      LOOP
        RETURN NEXT row_to_json(e);
      END LOOP;
    END LOOP;

  WHEN '/yookassa/method' THEN

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

  ELSE

    vPayment := split_part(pPath, '/', 3);

    SELECT id INTO uPayment FROM db.payment WHERE code = vPayment;

    IF FOUND THEN
      RETURN NEXT json_build_object('ok', api.yookassa_callback(jsonb_build_object('type', 'notification', 'event', 'order.update', 'object', jsonb_build_object('metadata', jsonb_build_object('payment', uPayment)))));
    ELSE
      RETURN NEXT ExecuteDynamicMethod(pPath, pPayload);
    END IF;

  END CASE;

  RETURN;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, pg_temp;
