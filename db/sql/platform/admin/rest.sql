--------------------------------------------------------------------------------
-- REST ADMIN ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Запрос данных в формате REST JSON API (администратор).
 * @param {text} pPath - Путь
 * @param {jsonb} pPayload - JSON
 * @return {SETOF json} - Записи в JSON
 */
CREATE OR REPLACE FUNCTION rest.admin (
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

  CASE pPath
  WHEN '/admin/user/add' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['username', 'password', 'name', 'phone', 'email', 'description']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(username varchar, password text, name text, phone text, email text, description text)
      LOOP
        FOR e IN SELECT * FROM api.add_user(r.username, r.password, r.name, r.phone, r.email, r.description) AS id
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(username varchar, password text, name text, phone text, email text, description text)
      LOOP
        FOR e IN SELECT * FROM api.add_user(r.username, r.password, r.name, r.phone, r.email, r.description) AS id
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/admin/user/update' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'username', 'password', 'name', 'phone', 'email', 'description', 'passwordchange', 'passwordnotchange']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id numeric, username varchar, password text, name text, phone text, email text, description text, passwordchange boolean, passwordnotchange boolean)
      LOOP
        FOR e IN SELECT * FROM api.update_user(r.id, r.username, r.password, r.name, r.phone, r.email, r.description, r.passwordchange, r.passwordnotchange) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, username varchar, password text, name text, phone text, email text, description text, passwordchange boolean, passwordnotchange boolean)
      LOOP
        FOR e IN SELECT * FROM api.update_user(r.id, r.username, r.password, r.name, r.phone, r.email, r.description, r.passwordchange, r.passwordnotchange) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/admin/user/password' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'username', 'oldpass', 'newpass']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id numeric, username varchar, oldpass text, newpass text)
      LOOP
        FOR e IN SELECT * FROM api.change_password(coalesce(r.id, GetUser(r.username)), r.oldpass, r.newpass) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, username varchar, oldpass text, newpass text)
      LOOP
        FOR e IN SELECT * FROM api.change_password(coalesce(r.id, GetUser(r.username)), r.oldpass, r.newpass) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/admin/user/get' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id numeric)
      LOOP
        RETURN NEXT row_to_json(api.get_user(r.id));
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric)
      LOOP
        RETURN NEXT row_to_json(api.get_user(r.id));
      END LOOP;

    END IF;

  WHEN '/admin/user/list' THEN

    FOR r IN SELECT * FROM api.list_user()
    LOOP
      RETURN NEXT row_to_json(r);
    END LOOP;

  WHEN '/admin/user/member' THEN

    FOR r IN SELECT * FROM api.user_member()
    LOOP
      RETURN NEXT row_to_json(r);
    END LOOP;

  WHEN '/admin/user/lock' THEN

    IF pPayload IS NOT NULL THEN
      arKeys := array_cat(arKeys, ARRAY['id', 'username']);
      PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);
    ELSE
      pPayload := '{}';
    END IF;

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id numeric, username varchar)
      LOOP
        FOR e IN SELECT * FROM api.user_lock(coalesce(r.id, GetUser(r.username))) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, username varchar)
      LOOP
        FOR e IN SELECT * FROM api.user_lock(coalesce(r.id, GetUser(r.username))) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/admin/user/unlock' THEN

    IF pPayload IS NOT NULL THEN
      arKeys := array_cat(arKeys, ARRAY['id', 'username']);
      PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);
    ELSE
      pPayload := '{}';
    END IF;

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id numeric, username varchar)
      LOOP
        FOR e IN SELECT * FROM api.user_unlock(coalesce(r.id, GetUser(r.username))) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, username varchar)
      LOOP
        FOR e IN SELECT * FROM api.user_unlock(coalesce(r.id, GetUser(r.username))) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/admin/user/iptable/get' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'username', 'type']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id numeric, username varchar, type char)
      LOOP
        RETURN NEXT row_to_json(api.get_user_iptable(coalesce(r.id, GetUser(r.username)), r.type));
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, username varchar, type char)
      LOOP
        RETURN NEXT row_to_json(api.get_user_iptable(coalesce(r.id, GetUser(r.username)), r.type));
      END LOOP;

    END IF;

  WHEN '/admin/user/iptable/set' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'username', 'type', 'iptable']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id numeric, username varchar, type char, iptable text)
      LOOP
        FOR e IN SELECT * FROM api.set_user_iptable(coalesce(r.id, GetUser(r.username)), r.type, r.iptable) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, username varchar, type char, iptable text)
      LOOP
        FOR e IN SELECT * FROM api.set_user_iptable(coalesce(r.id, GetUser(r.username)), r.type, r.iptable) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/admin/group/get' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id numeric)
      LOOP
        FOR e IN SELECT * FROM api.get_group(r.id)
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric)
      LOOP
        FOR e IN SELECT * FROM api.get_group(r.id)
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/admin/group/list' THEN

    FOR r IN SELECT * FROM api.list_group()
    LOOP
      RETURN NEXT row_to_json(r);
    END LOOP;

  WHEN '/admin/group/add' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['code', 'name', 'description']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(code varchar, name text, description text)
      LOOP
        FOR e IN SELECT * FROM api.add_group(r.code, r.name, r.description) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(code varchar, name text, description text)
      LOOP
        FOR e IN SELECT * FROM api.add_group(r.code, r.name, r.description) AS success
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/admin/group/member' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'groupname']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, groupname varchar)
    LOOP
      FOR e IN SELECT * FROM api.group_member(coalesce(r.id, GetGroup(r.groupname)))
      LOOP
        RETURN NEXT row_to_json(e);
      END LOOP;
    END LOOP;

  WHEN '/admin/area/list' THEN

    FOR r IN SELECT * FROM api.list_area()
    LOOP
      RETURN NEXT row_to_json(r);
    END LOOP;

  WHEN '/admin/area/get' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id numeric, fields jsonb)
      LOOP
        FOR e IN SELECT * FROM api.get_area(r.id)
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, fields jsonb)
      LOOP
        FOR e IN SELECT * FROM api.get_area(r.id)
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/admin/area/member' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'code']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, code varchar)
    LOOP
        FOR e IN SELECT * FROM api.area_member(coalesce(r.id, GetArea(r.code)))
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
    END LOOP;

  WHEN '/admin/interface/member' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'sid']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, sid varchar)
    LOOP
      FOR e IN SELECT * FROM api.interface_member(coalesce(r.id, GetInterface(r.sid)))
      LOOP
        RETURN NEXT row_to_json(e);
      END LOOP;
    END LOOP;

  WHEN '/admin/member/user' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'username']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, username varchar)
    LOOP
      FOR e IN SELECT * FROM api.member_user(coalesce(r.id, GetUser(r.username)))
      LOOP
        RETURN NEXT row_to_json(e);
      END LOOP;
    END LOOP;

  WHEN '/admin/member/group' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'username']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, username varchar)
    LOOP
      FOR e IN SELECT * FROM api.member_group(coalesce(r.id, GetUser(r.username)))
      LOOP
        RETURN NEXT row_to_json(e);
      END LOOP;
    END LOOP;

  WHEN '/admin/member/area' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'username']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, username varchar)
    LOOP
      FOR e IN SELECT * FROM api.member_area(coalesce(r.id, GetUser(r.username)))
      LOOP
        RETURN NEXT row_to_json(e);
      END LOOP;
    END LOOP;

  WHEN '/admin/member/interface' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'username']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id numeric, username varchar)
    LOOP
      FOR e IN SELECT * FROM api.member_interface(coalesce(r.id, GetUser(r.username)))
      LOOP
        RETURN NEXT row_to_json(e);
      END LOOP;
    END LOOP;

  ELSE
    PERFORM RouteNotFound(pPath);
  END CASE;

  RETURN;
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, pg_temp;
