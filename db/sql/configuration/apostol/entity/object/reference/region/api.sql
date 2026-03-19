--------------------------------------------------------------------------------
-- FORMAT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.region ------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief API view for region records.
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.region
AS
  SELECT * FROM ObjectRegion;

GRANT SELECT ON api.region TO administrator;

--------------------------------------------------------------------------------
-- api.add_region --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new region.
 * @return {uuid} - New region identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.add_region (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pName         text,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateRegion(pParent, coalesce(pType, GetType('code.region')), pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_region -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Updates an existing region.
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.update_region (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       void
AS $$
BEGIN
  PERFORM FROM db.region t WHERE t.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('region', 'id', pId);
  END IF;

  PERFORM EditRegion(pId, pParent, pType, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_region --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates or updates a region (upsert).
 * @return {SETOF api.region} - Updated region record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.set_region (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pName         text default null,
  pDescription  text default null
) RETURNS       SETOF api.region
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_region(pParent, pType, pCode, pName, pDescription);
  ELSE
    PERFORM api.update_region(pId, pParent, pType, pCode, pName, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.region WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_region --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a region by identifier.
 * @return {SETOF api.region} - Region record
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.get_region (
  pId        uuid
) RETURNS    SETOF api.region
AS $$
  SELECT * FROM api.region WHERE id = pId AND CheckObjectAccess(id, B'100')
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.count_region ------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the count of regions matching criteria.
 * @return {SETOF bigint} - Row count
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.count_region (
  pSearch	jsonb default null,
  pFilter	jsonb default null
) RETURNS	SETOF bigint
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'region', pSearch, pFilter, 0, null, '{}'::jsonb, '["count(id)"]'::jsonb);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_region -------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns a list of regions.
 * @return {SETOF api.region} - Region records
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.list_region (
  pSearch   jsonb default null,
  pFilter   jsonb default null,
  pLimit    integer default null,
  pOffSet   integer default null,
  pOrderBy  jsonb default null
) RETURNS   SETOF api.region
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'region', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
