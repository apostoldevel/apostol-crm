--------------------------------------------------------------------------------
-- CURRENT ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.whoami ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает информацию о виртуальном пользователе.
 * @out param {numeric} id - Идентификатор клиента
 * @out param {numeric} userid - Идентификатор виртуального пользователя (учётной записи)
 * @out param {numeric} suid - Идентификатор системного пользователя (учётной записи)
 * @out param {boolean} admin - Признак администратора системы
 * @out param {json} profile - Профиль пользователя
 * @out param {json} name - Ф.И.О. клиента
 * @out param {json} email - Справочник электронных адресов клиента
 * @out param {json} phone - Телефоный справочник клиента
 * @out param {json} session - Сессия
 * @out param {json} locale - Язык
 * @out param {json} area - Зона
 * @out param {json} interface - Интерфейс
 * @return {table}
 */
CREATE OR REPLACE FUNCTION api.whoami (
) RETURNS TABLE (
  id                numeric,
  userid            numeric,
  suid              numeric,
  admin             boolean,
  profile           json,
  name              json,
  email             json,
  phone             json,
  session           json,
  locale            json,
  area              json,
  interface         json
)
AS $$
  WITH cs AS (
      SELECT current_session() AS session, oper_date() AS oper_date
  )
  SELECT c.id, s.userid, s.suid, IsUserRole(1001, s.userid) AS admin,
         row_to_json(u.*) AS profile,
         json_build_object('name', c.fullname, 'short', c.shortname, 'first', c.firstname, 'last', c.lastname, 'middle', c.middlename) AS name,
         c.email::json, c.phone::json,
         json_build_object('code', s.code, 'created', s.created, 'updated', s.updated, 'agent', s.agent, 'host', s.host) AS session,
         row_to_json(l.*) AS locale,
         row_to_json(a.*) AS area,
         row_to_json(i.*) AS interface
    FROM db.session s INNER JOIN cs ON s.code = cs.session
                      INNER JOIN users u ON u.id = s.userid
                      INNER JOIN db.locale l ON l.id = s.locale
                      INNER JOIN db.area a ON a.id = s.area
                      INNER JOIN db.interface i ON i.id = s.interface
                       LEFT JOIN client c ON c.userid = s.userid
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.current_session ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает текущую сессии.
 * @return {session} - Сессия
 */
CREATE OR REPLACE FUNCTION api.current_session()
RETURNS     SETOF session
AS $$
  SELECT * FROM session WHERE code = current_session()
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.current_user ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает учётную запись текущего пользователя.
 * @return {users} - Учётная запись пользователя
 */
CREATE OR REPLACE FUNCTION api.current_user (
) RETURNS   SETOF users
AS $$
  SELECT * FROM users WHERE id = current_userid()
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.current_userid ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает идентификатор авторизированного пользователя.
 * @return {numeric} - Идентификатор пользователя: users.id
 */
CREATE OR REPLACE FUNCTION api.current_userid()
RETURNS         numeric
AS $$
BEGIN
  RETURN current_userid();
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.current_username --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает имя авторизированного пользователя.
 * @return {text} - Имя (username) пользователя: users.username
 */
CREATE OR REPLACE FUNCTION api.current_username()
RETURNS         text
AS $$
BEGIN
  RETURN current_username();
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.current_area ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает данные текущей зоны.
 * @return {area} - Зона
 */
CREATE OR REPLACE FUNCTION api.current_area (
) RETURNS        SETOF area
AS $$
  SELECT * FROM area WHERE id = current_area();
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.current_interface -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает данные текущего интерфейса.
 * @return {interface} - Интерфейс
 */
CREATE OR REPLACE FUNCTION api.current_interface (
) RETURNS         SETOF interface
AS $$
  SELECT * FROM interface WHERE id = current_interface();
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.current_locale ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает данные текущего языка.
 * @return {locale} - Язык
 */
CREATE OR REPLACE FUNCTION api.current_locale (
) RETURNS         SETOF locale
AS $$
  SELECT * FROM locale WHERE id = current_locale();
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.oper_date ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает дату операционного дня.
 * @return {timestamp} - Дата операционного дня
 */
CREATE OR REPLACE FUNCTION api.oper_date()
RETURNS         timestamp
AS $$
BEGIN
  RETURN oper_date();
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
