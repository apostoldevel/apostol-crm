--------------------------------------------------------------------------------
-- REPORT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- rpc_object_info -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Отчёт: Информация об объекте
 * @param {uuid} pReady - Идентификатор готового отчёта
 * @param {jsonb} pForm - Форма
 * @return {uuid} - Идентификатор готового отчёта
 */
CREATE OR REPLACE FUNCTION report.rpc_object_info (
  pReady        uuid,
  pForm         jsonb default null
) RETURNS       void
AS $$
DECLARE
  o             record;
  l             record;
  f             record;
  d             record;

  uObject       uuid;

  bEmpty        boolean;

  vHTML         text;

  Lines         text[];

  vMessage      text;
  vContext      text;

  ErrorCode     int;
  ErrorMessage  text;
BEGIN
  uObject := pForm->>'identifier';

  FOR l IN SELECT code FROM db.locale WHERE id = current_locale()
  LOOP
    IF l.code = 'ru' THEN
      Lines[1] := 'Информация об объекте';
	ELSE
      Lines[1] := 'Information about the object';
	END IF;

	vHTML := E'<!DOCTYPE html>\n';

	vHTML := vHTML || format(E'<html lang="%s">\n', l.code);
    vHTML := vHTML || report.get_report_head(Lines[1]);

	vHTML := vHTML || E'<body>\n';
	vHTML := vHTML || E'<div>\n';

    vHTML := vHTML || E'  <div class="gx-text-center">\n';
    vHTML := vHTML || E'    <h2 class="mb-3">' || Lines[1] || E'</h2>\n';
    vHTML := vHTML || E'  </div>\n';

    vHTML := vHTML || E'  <div class="ant-table ant-table-content">\n';

    vHTML := vHTML || E'    <table class="ant-table ant-table-bordered">\n';
    vHTML := vHTML || E'      <thead class="ant-table-thead">\n';

    IF l.code = 'ru' THEN
	  vHTML := vHTML || E'        <tr>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" style="width: 20%!important;">Поле</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell">Данные</th>\n';
	  vHTML := vHTML || E'        </tr>\n';
	ELSE
	  vHTML := vHTML || E'        <tr>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell" style="width: 20%!important;">Field</th>\n';
	  vHTML := vHTML || E'          <th class="ant-table-cell">Data</th>\n';
	  vHTML := vHTML || E'        </tr>\n';
    END IF;

    vHTML := vHTML || E'      </thead>\n';
    vHTML := vHTML || E'      <tbody class="ant-table-tbody">\n';

	bEmpty := true;

    FOR o IN
      SELECT *
        FROM Object
       WHERE id = uObject
    LOOP
      bEmpty := false;

      FOR f IN SELECT * FROM all_tab_columns WHERE table_name = 'object' ORDER BY column_id
      LOOP
		vHTML := vHTML || E'        <tr class="ant-table-row">\n';
		vHTML := vHTML || format(E'          <td class="ant-table-cell"><span class="ant-table-column-title">%s</span></th>\n', f.column_name);

        FOR d IN EXECUTE format('SELECT $1->>%L AS value', f.column_name) USING row_to_json(o)
        LOOP
		  vHTML := vHTML || format(E'          <td class="ant-table-cell">%s</th>\n', d.value);
        END LOOP;

		vHTML := vHTML || E'        </tr>\n';
	  END LOOP;

	END LOOP;

	IF bEmpty THEN
	  IF l.code = 'ru' THEN
		vHTML := vHTML || E'        <tr class="ant-table-row ant-table-row-level-0 gx-text-center">\n';
		vHTML := vHTML || E'          <td class="ant-table-cell" colspan="2">Нет данных</td>\n';
		vHTML := vHTML || E'        </tr>\n';
	  ELSE
		vHTML := vHTML || E'        <tr class="ant-table-row ant-table-row-level-0 gx-text-center">\n';
		vHTML := vHTML || E'          <td class="ant-table-cell" colspan="2">No data</td>\n';
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
