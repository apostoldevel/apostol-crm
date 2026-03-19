--------------------------------------------------------------------------------
-- FORMAT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.format ------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief API view for format records.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.format
AS
  SELECT * FROM ObjectFormat;

GRANT SELECT ON api.format TO administrator;

--------------------------------------------------------------------------------
-- api.add_format --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new format.
 * @return {uuid} - New format identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_format (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateFormat(pParent, coalesce(pType, GetType('data.format')), pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_format -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Updates an existing format.
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_format (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       void
AS $$
BEGIN
  PERFORM FROM db.format t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('format', 'id', pId);
  END IF;

  PERFORM EditFormat(pId, pParent, pType, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_format --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a format (upsert).
 * @return {SETOF api.format} - Updated format record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_format (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       SETOF api.format
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_format(pParent, pType, pCode, pName, pDescription);
  ELSE
    PERFORM api.update_format(pId, pParent, pType, pCode, pName, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.format WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_format --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a format by identifier.
 * @return {SETOF api.format} - Format record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_format (
  pId        uuid
) RETURNS    SETOF api.format
AS $$
  SELECT * FROM api.format WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_format ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the count of formats matching criteria.
 * @return {SETOF bigint} - Row count
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_format (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'format', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_format -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a list of formats.
 * @return {SETOF api.format} - Format records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_format (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.format
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'format', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
