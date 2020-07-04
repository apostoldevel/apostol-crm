--------------------------------------------------------------------------------
-- CURRENT ---------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.whoami ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает информацию о виртуальном пользователе.
 * @out param {numeric} id - Идентификатор
 * @out param {numeric} userid - Идентификатор виртуального пользователя (учётной записи)
 * @out param {varchar} username - Имя виртуального пользователя (login)
 * @out param {text} name - Ф.И.О. виртуального пользователя
 * @out param {text} phone - Телефон виртуального пользователя
 * @out param {text} email - Электронный адрес виртуального пользователя
 * @out param {numeric} session_userid - Идентификатор учётной записи виртуального пользователя сессии
 * @out param {varchar} session_username - Имя виртуального пользователя сессии (login)
 * @out param {text} session_fullname - Ф.И.О. виртуального пользователя сессии
 * @return {record}
 */
CREATE OR REPLACE FUNCTION api.whoami (
) RETURNS TABLE (
  id                numeric,
  userid            numeric,
  username          varchar,
  name              text,
  phone             text,
  email             text,
  session_userid    numeric,
  session_username  varchar,
  session_fullname  text,
  area              numeric,
  area_code         varchar,
  area_name	        varchar,
  interface         numeric,
  interface_sid     varchar,
  interface_name    varchar
)
AS $$
  WITH cs AS (
      SELECT current_session() AS session
  )
  SELECT p.id, s.userid, cu.username, cu.name, cu.phone, cu.email,
         s.suid, su.username, su.name,
         s.area, a.code, a.name,
         s.interface, i.sid, i.name
    FROM db.session s INNER JOIN cs ON cs.session = s.code
                      INNER JOIN users cu ON cu.id = s.userid
                      INNER JOIN users su ON su.id = s.suid
                      INNER JOIN db.area a ON a.id = s.area
                      INNER JOIN db.interface i ON i.id = s.interface
  		               LEFT JOIN db.client p ON p.userid = s.userid;
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
RETURNS 	numeric
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
RETURNS 	text
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
) RETURNS	SETOF area
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
) RETURNS 	SETOF interface
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
) RETURNS 	SETOF locale
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
RETURNS 	timestamp
AS $$
BEGIN
  RETURN oper_date();
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
