--------------------------------------------------------------------------------
-- CreateCompany ---------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Creates a new company
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pRoot - Root
 * @param {uuid} pNode - Node
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @param {integer} pSequence - Sort order
 * @return {uuid}
 * @throws IncorrectClassType
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateCompany (
  pParent           uuid,
  pType             uuid,
  pRoot             uuid,
  pNode             uuid,
  pCode             text,
  pName             text,
  pDescription	    text DEFAULT null,
  pSequence         integer default null
) RETURNS           uuid
AS $$
DECLARE
  uRoot			    uuid;
  uDocument         uuid;
  uCompany          uuid;
  uClass            uuid;
  uMethod           uuid;

  nLevel            integer;

  vTypeCode         text;
  vParentArea       text;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetClassCode(uClass) <> 'company' THEN
    PERFORM IncorrectClassType();
  END IF;

  nLevel := 0;
  pRoot := CheckNull(pRoot);
  pNode := CheckNull(pNode);

  IF pNode IS NOT NULL THEN
    SELECT root, level + 1 INTO uRoot, nLevel FROM db.company WHERE id = pNode;
  END IF;

  IF NULLIF(pSequence, 0) IS NULL THEN
    SELECT max(sequence) + 1 INTO pSequence FROM db.company WHERE node IS NOT DISTINCT FROM pNode;
  ELSE
    PERFORM SetCompanySequence(pNode, pSequence, 1);
  END IF;

  uDocument := CreateDocument(pParent, pType, pName, pDescription);

  pRoot := coalesce(pRoot, uRoot, uDocument);

  IF pRoot IS NOT DISTINCT FROM uDocument THEN
	pNode := null;
  END IF;

  INSERT INTO db.company (id, document, root, node, code, level, sequence)
  VALUES (uDocument, uDocument, pRoot, pNode, pCode, nLevel, coalesce(pSequence, 1))
  RETURNING id INTO uCompany;

  PERFORM FROM db.area WHERE id = uCompany;

  IF NOT FOUND THEN
    vTypeCode := GetTypeCode(pType);
    SELECT code INTO vParentArea FROM db.company WHERE id = pNode;

    PERFORM CreateArea(uCompany, GetArea(vParentArea), GetAreaType(SubStr(vTypeCode, 1, StrPos(vTypeCode, '.') - 1)), GetScope(current_database()), pCode, pName);
    PERFORM AddMemberToInterface(CreateGroup(pCode, pName, pDescription, uCompany), '00000000-0000-4004-a000-000000000002');

    PERFORM ChangeDocumentArea(uCompany, uCompany);
  END IF;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uCompany, uMethod);

  RETURN uCompany;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditCompany -----------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Edits an existing company
 * @param {uuid} pId - Record identifier
 * @param {uuid} pParent - Reference to parent object
 * @param {uuid} pType - Type identifier
 * @param {uuid} pRoot - Root
 * @param {uuid} pNode - Node
 * @param {text} pCode - Code
 * @param {text} pName - Name
 * @param {text} pDescription - Description
 * @param {integer} pSequence - Sort order
 * @return {void}
 * @throws ObjectNotFound
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EditCompany (
  pId               uuid,
  pParent           uuid DEFAULT null,
  pType             uuid DEFAULT null,
  pRoot             uuid DEFAULT null,
  pNode             uuid DEFAULT null,
  pCode             text DEFAULT null,
  pName             text DEFAULT null,
  pDescription	    text DEFAULT null,
  pSequence         integer default null
) RETURNS           void
AS $$
DECLARE
  uId			    uuid;
  uRoot             uuid;
  uNode             uuid;
  uClass            uuid;
  uMethod           uuid;

  nSequence         integer;
  nLevel	        integer;
BEGIN
  SELECT root, node, level, sequence INTO uRoot, uNode, nLevel, nSequence FROM db.company WHERE id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('company', 'id', pId);
  END IF;

  pRoot := coalesce(CheckNull(pRoot), uRoot);
  pNode := coalesce(CheckNull(pNode), uNode);
  pSequence := coalesce(pSequence, nSequence);

  IF pId IS NOT DISTINCT FROM pRoot THEN
	pNode := null;
  END IF;

  IF pNode IS NOT NULL THEN
	IF pId IS NOT DISTINCT FROM pNode THEN
	  pNode := uNode;
	ELSE
      SELECT node, level + 1 INTO uId, nLevel FROM db.company WHERE id = pNode;
	  IF uId IS NOT DISTINCT FROM pId THEN
		UPDATE db.company SET node = uNode WHERE id = pNode;
	  END IF;
	END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pName, pDescription);

  UPDATE db.company
     SET root = pRoot,
         node = pNode,
         code = coalesce(pCode, code),
         level = coalesce(nLevel, level),
         sequence = pSequence
   WHERE id = pId;

  IF uNode IS DISTINCT FROM pNode THEN
    SELECT max(sequence) + 1 INTO nSequence FROM db.company WHERE node IS NOT DISTINCT FROM pNode;
    PERFORM SortCompany(uNode);
  END IF;

  IF pSequence < nSequence THEN
    PERFORM SetCompanySequence(pId, pSequence, 1);
  END IF;

  IF pSequence > nSequence THEN
    PERFORM SetCompanySequence(pId, pSequence, -1);
  END IF;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCompany ------------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the company by code
 * @param {text} pCode - Code
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCompany (
  pCode         text
) RETURNS       uuid
AS $$
  SELECT id FROM db.company WHERE code = pCode
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCompanyCode --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the company code by identifier
 * @param {uuid} pId - Record identifier
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCompanyCode (
  pId           uuid
) RETURNS       text
AS $$
  SELECT code FROM db.company WHERE id = pId
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCompanyName --------------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Returns the company by code
 * @param {uuid} pId - Record identifier
 * @return {text}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetCompanyName (
  pId           uuid
) RETURNS       text
AS $$
  SELECT ot.label FROM db.company c INNER JOIN db.object_text ot ON c.id = ot.object WHERE c.id = pId AND ot.locale = current_locale()
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION SetCompanySequence -------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Sets the sort order for a company
 * @param {uuid} pId - Record identifier
 * @param {integer} pSequence - Sort order
 * @param {integer} pDelta - Sequence increment direction
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SetCompanySequence (
  pId		    uuid,
  pSequence	    integer,
  pDelta	    integer
) RETURNS 	    void
AS $$
DECLARE
  uId		    uuid;
  uNode         uuid;
BEGIN
  IF pDelta <> 0 THEN
    SELECT node INTO uNode FROM db.company WHERE id = pId;
    SELECT id INTO uId
      FROM db.company
     WHERE node IS NOT DISTINCT FROM uNode
       AND sequence = pSequence
       AND id <> pId;

    IF FOUND THEN
      PERFORM SetCompanySequence(uId, pSequence + pDelta, pDelta);
    END IF;
  END IF;

  UPDATE db.company SET sequence = pSequence WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION SortCompany --------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Re-sorts all company records for a client
 * @param {uuid} pNode - Node
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION SortCompany (
  pNode     uuid
) RETURNS 	void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN
    SELECT id, (row_number() OVER(order by sequence))::int as newsequence
      FROM db.company
     WHERE node IS NOT DISTINCT FROM pNode
  LOOP
    PERFORM SetCompanySequence(r.id, r.newsequence, 0);
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION current_company ----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief current_company
 * @param {varchar} pSession - Session
 * @return {uuid}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION current_company (
  pSession	varchar DEFAULT current_session()
)
RETURNS 	uuid
AS $$
DECLARE
  uId       uuid;
  uArea     uuid;
  uType     uuid;
BEGIN
  uArea := GetSessionArea(pSession);
  SELECT type INTO uType FROM db.area WHERE id = uArea;

  IF uType IN ('00000000-0000-4002-a000-000000000003', '00000000-0000-4002-a000-000000000002', '00000000-0000-4002-a000-000000000001', '00000000-0000-4002-a000-000000000000') THEN
    SELECT id INTO uArea FROM db.area WHERE type = '00000000-0000-4002-a001-000000000001'::uuid AND scope = current_scope() AND validfromdate <= Now() AND validtodate > Now() ORDER BY level, sequence LIMIT 1;
  END IF;

  SELECT id INTO uId FROM db.company WHERE id = uArea;

  RETURN coalesce(uId, '00000000-0000-4003-a001-000000000000');
END;
$$ LANGUAGE plpgsql STABLE STRICT
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
