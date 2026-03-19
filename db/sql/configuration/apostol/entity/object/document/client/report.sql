--------------------------------------------------------------------------------
-- REPORT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- rfc_client_list -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Report form: Client list
 * @param {uuid} pForm - Form identifier
 * @param {jsonb} pParams - Parameters
 * @return {SETOF json} - Records as JSON
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION report.rfc_client_list (
  pForm             uuid,
  pParams           json default null
) RETURNS           json
AS $$
DECLARE
  r                 record;

  fields            jsonb;
  dtDay             timestamptz;
BEGIN
  dtDay := date_trunc('MONTH', Now());

  fields := json_build_array();

  FOR r IN SELECT * FROM json_to_record(pParams) AS x("dateFrom" timestamptz, "dateTo" timestamptz)
  LOOP
    fields := fields || jsonb_build_object('type', 'timestamp', 'key', 'dateFrom', 'label', 'Дата начала периода', 'value', coalesce(r."dateFrom", dtDay));
    fields := fields || jsonb_build_object('type', 'timestamp', 'key', 'dateTo', 'label', 'Дата окончания периода', 'value', coalesce(r."dateTo", dtDay + interval '1 mons' - interval '1 sec'));
  END LOOP;

  fields := fields || jsonb_build_object('type', 'select', 'key', 'type', 'label', 'Тип', 'data', GetForReportTypeJson(GetEntity('client')), 'mutable', false);
  fields := fields || jsonb_build_object('type', 'select', 'key', 'state', 'label', 'Состояние', 'data', GetForReportStateJson(GetClass('client')), 'mutable', false);

  RETURN json_build_object('form', pForm, 'fields', fields);
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- rpc_client_list -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Report: Client list
 * @param {uuid} pReady - Ready report identifier
 * @param {jsonb} pForm - Form data
 * @return {uuid} - Ready report identifier
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION report.rpc_client_list (
  pReady        uuid,
  pForm         jsonb default null
) RETURNS       void
AS $$
DECLARE
  l             record;
  s             record;

  uState        uuid;
  uType         uuid;

  dateFrom      timestamptz;
  dateTo        timestamptz;
  dateCurrent   timestamptz;

  bEmpty        boolean;

  vHTML         text;
  Lines         text[];

  vMessage      text;
  vContext      text;

  ErrorCode     int;
  ErrorMessage  text;
BEGIN
  dateFrom := pForm->>'dateFrom';
  dateTo := pForm->>'dateTo';

  uType := pForm->>'type';
  uState := pForm->>'state';

  IF dateFrom > dateTo THEN
    PERFORM DateValidityPeriod();
  END IF;

  dateCurrent := dateFrom;

  FOR l IN SELECT code FROM db.locale WHERE id = current_locale()
  LOOP
    IF l.code = 'ru' THEN
      Lines[1] := 'Список клиентов';
      Lines[2] := format(E'c %s по %s', DateToStr(dateFrom, 'DD.MM.YYYY HH24:MI:SS'), DateToStr(dateTo, 'DD.MM.YYYY HH24:MI:SS'));
      Lines[3] := 'по всем типам';
      Lines[4] := 'по всем состояниям';
	ELSE
      Lines[1] := 'Client list';
      Lines[2] := format(E'from %s to %s', DateToStr(dateFrom, 'YYYY-MM-DD HH24:MI:SS'), DateToStr(dateTo, 'YYYY-MM-DD HH24:MI:SS'));
      Lines[3] := 'for all types';
      Lines[4] := 'for all states';
	END IF;

	vHTML := E'<!DOCTYPE html>\n';

	vHTML := vHTML || format(E'<html lang="%s">\n', l.code);
    vHTML := vHTML || report.get_report_head(Lines[1]);

	vHTML := vHTML || E'<body>\n';
	vHTML := vHTML || E'<div>\n';

    vHTML := vHTML || E'  <div class="gx-text-center">\n';

    vHTML := vHTML || E'    <h2 class="mb-3">' || Lines[1] || E'</h2>\n';
    vHTML := vHTML || E'    <h4 class="mb-3">' || Lines[2] || E'</h4>\n';

	IF uType IS NOT NULL THEN
      vHTML := vHTML || E'    <h3 class="h3 mb-3">' || format(E'%s', GetTypeName(uType)) || E'</h3>\n';
    ELSE
      vHTML := vHTML || E'    <h3 class="h4 mb-3">' || Lines[3] || E'</h3>\n';
    END IF;

	IF uState IS NOT NULL THEN
      vHTML := vHTML || E'    <h3 class="mb-3">' || format(E'%s', GetStateLabel(uState)) || E'</h3>\n';
    ELSE
      vHTML := vHTML || E'    <h3 class="mb-3">' || Lines[4] || E'</h3>\n';
    END IF;

    vHTML := vHTML || E'  </div>\n';

	vHTML := vHTML || E'  <div class="ant-table ant-table-content">\n';
	vHTML := vHTML || E'    <table class="ant-table ant-table-bordered" style="table-layout: auto;">\n';
	vHTML := vHTML || E'      <thead class="ant-table-thead">\n';

	IF l.code = 'ru' THEN
	  vHTML := vHTML || E'        <tr class="gx-text-center">\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">Тип</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">Код</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">Наименование</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">Описание</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">Состояние</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">Создана</th>\n';
	  vHTML := vHTML || E'        </tr>\n';
	ELSE
	  vHTML := vHTML || E'        <tr class="gx-text-center">\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">Type</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">Code</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">Name</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">Description</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">State</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" scope="col">Created</th>\n';
	  vHTML := vHTML || E'        </tr>\n';
	END IF;

	vHTML := vHTML || E'      </thead>\n';
	vHTML := vHTML || E'      <tbody class="ant-table-tbody">\n';

	bEmpty := true;

    FOR s IN
      SELECT o.id, o.typename, o.code, o.label, o.description, o.statelabel, o.created
        FROM ObjectClient o
       WHERE o.type = coalesce(uType, o.type)
         AND o.state = coalesce(uState, o.state)
       ORDER BY o.created DESC
    LOOP
      bEmpty := false;


	  vHTML := vHTML || E'        <tr class="gx-text-center">\n';
	  vHTML := vHTML || format(E'          <td>%s</td>\n', s.typename);
	  vHTML := vHTML || format(E'          <td>%s</td>\n', s.code);
	  vHTML := vHTML || format(E'          <td>%s</td>\n', s.label);
	  vHTML := vHTML || format(E'          <td>%s</td>\n', s.description);
	  vHTML := vHTML || format(E'          <td>%s</td>\n', s.statelabel);

	  IF l.code = 'ru' THEN
	    vHTML := vHTML || format(E'          <td>%s</td>\n', DateToStr(s.created, 'DD.MM.YYYY HH24:MI:SS'));
	  ELSE
	    vHTML := vHTML || format(E'          <td>%s</td>\n', DateToStr(s.created, 'YYYY-MM-DD HH24:MI:SS'));
	  END IF;

	  vHTML := vHTML || E'        </tr>\n';
    END LOOP;

	IF bEmpty THEN
	  IF l.code = 'ru' THEN
		vHTML := vHTML || E'        <tr class="gx-text-center">\n';
		vHTML := vHTML || E'          <td class="ant-table-cell" scope="col" colspan="6" scope="col">Нет данных</th>\n';
		vHTML := vHTML || E'        </tr>\n';
	  ELSE
		vHTML := vHTML || E'        <tr class="gx-text-center">\n';
		vHTML := vHTML || E'          <td class="ant-table-cell" scope="col" colspan="6" scope="col">No data</th>\n';
		vHTML := vHTML || E'        </tr>\n';
	  END IF;
	END IF;

	vHTML := vHTML || E'      </tbody>\n';
	vHTML := vHTML || E'    </table>\n';
	vHTML := vHTML || E'  </div>\n';

    vHTML := vHTML || E'</div>\n';
    vHTML := vHTML || E'</body>\n';
    vHTML := vHTML || E'</html>\n';
  END LOOP;

  PERFORM SetObjectFile(pReady, null, 'index.html', null, length(vHTML), localtimestamp, vHTML::bytea, encode(digest(vHTML, 'md5'), 'hex'), Lines[1], 'data:text/html;base64,');

  PERFORM DoAction(pReady, 'complete');
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  SELECT * INTO ErrorCode, ErrorMessage FROM ParseMessage(vMessage);

  PERFORM WriteToEventLog('E', ErrorCode, ErrorMessage, pReady);
  PERFORM WriteToEventLog('D', ErrorCode, vContext, pReady);

  PERFORM DoAction(pReady, 'fail');

  vHTML := ReportErrorHTML(ErrorCode, ErrorMessage, vContext);

  PERFORM SetObjectFile(pReady, null, 'index.html', null, length(vHTML), localtimestamp, vHTML::bytea, encode(digest(vHTML, 'md5'), 'hex'), 'exception', 'data:text/html;base64,');
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, public, pg_temp;
