--------------------------------------------------------------------------------
-- REPORT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- rpc_import_files ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Отчёт: Импорт файлов
 * @param {uuid} pReady - Идентификатор готового отчёта
 * @param {jsonb} pForm - Форма
 * @return {uuid} - Идентификатор готового отчёта
 */
CREATE OR REPLACE FUNCTION report.rpc_import_files (
  pReady        uuid,
  pForm         jsonb default null
) RETURNS       void
AS $$
DECLARE
  html_file     bytea;

  l             record;
  r             record;

  bEmpty        boolean;

  jFiles        json;

  vHTML         text;

  arLines       text[];
  arKeys        text[];

  vMessage      text;
  vContext      text;

  ErrorCode     int;
  ErrorMessage  text;
BEGIN
  jFiles := pForm->>'files';

  FOR l IN SELECT code FROM db.locale WHERE id = current_locale()
  LOOP
    IF l.code = 'ru' THEN
      arLines[1] := 'Импорт файлов';
	ELSE
      arLines[1] := 'Importing files';
	END IF;

	vHTML := E'<!DOCTYPE html>\n';

	vHTML := vHTML || format(E'<html lang="%s">\n', l.code);
    vHTML := vHTML || report.get_report_head(arLines[1]);

	vHTML := vHTML || E'<body>\n';
	vHTML := vHTML || E'<div>\n';

    vHTML := vHTML || E'  <div class="text-center">\n';
    vHTML := vHTML || E'    <h2 class="mb-3">' || arLines[1] || E'</h2>\n';
    vHTML := vHTML || E'  </div>\n';

    vHTML := vHTML || E'  <div class="table-responsive">\n';

    vHTML := vHTML || E'    <table class="table table-bordered">\n';
    vHTML := vHTML || E'      <thead class="thead-light">\n';

    IF l.code = 'ru' THEN
	  vHTML := vHTML || E'        <tr>\n';
	  vHTML := vHTML || E'          <th>Имя</th>\n';
	  vHTML := vHTML || E'          <th>Путь</th>\n';
	  vHTML := vHTML || E'          <th>Размер</th>\n';
	  vHTML := vHTML || E'          <th>Дата</th>\n';
	  vHTML := vHTML || E'          <th>Текст</th>\n';
	  vHTML := vHTML || E'          <th>Тип</th>\n';
	  vHTML := vHTML || E'        </tr>\n';
	ELSE
	  vHTML := vHTML || E'        <tr>\n';
	  vHTML := vHTML || E'          <th>Name</th>\n';
	  vHTML := vHTML || E'          <th>Path</th>\n';
	  vHTML := vHTML || E'          <th>Size</th>\n';
	  vHTML := vHTML || E'          <th>Date</th>\n';
	  vHTML := vHTML || E'          <th>Text</th>\n';
	  vHTML := vHTML || E'          <th>Type</th>\n';
	  vHTML := vHTML || E'        </tr>\n';
    END IF;

    vHTML := vHTML || E'      </thead>\n';
    vHTML := vHTML || E'      <tbody>\n';

	bEmpty := true;

	IF jFiles IS NOT NULL THEN
	  arKeys := array_cat(arKeys, ARRAY['name', 'path', 'size', 'date', 'data', 'hash', 'text', 'type']);
	  PERFORM CheckJsonKeys('/report/import/files', arKeys, jFiles);

	  FOR r IN SELECT * FROM json_to_recordset(jFiles) AS files(name text, path text, size int, date timestamptz, data text, hash text, text text, type text)
	  LOOP
        vHTML := vHTML || E'        <tr>\n';
        vHTML := vHTML || format(E'          <td>%s</td>\n', r.name);
        vHTML := vHTML || format(E'          <td>%s</td>\n', r.path);
        vHTML := vHTML || format(E'          <td>%s</td>\n', r.size);

        IF l.code = 'ru' THEN
          vHTML := vHTML || format(E'          <td>%s</td>\n', DateToStr(r.date, 'DD.MM.YYYY HH24:MI:SS'));
        ELSE
          vHTML := vHTML || format(E'          <td>%s</td>\n', DateToStr(r.date, 'YYYY-MM-DD HH24:MI:SS'));
        END IF;

        vHTML := vHTML || format(E'          <td>%s</td>\n', r.text);
        vHTML := vHTML || format(E'          <td>%s</td>\n', r.type);
        vHTML := vHTML || E'        </tr>\n';

		PERFORM SetObjectFile(pReady, r.name, r.path, r.size, r.date, decode(r.data, 'base64'), r.hash, r.text, r.type);
	  END LOOP;
	END IF;

	IF bEmpty THEN
	  IF l.code = 'ru' THEN
		vHTML := vHTML || E'        <tr class="text-center">\n';
		vHTML := vHTML || E'          <th colspan="6">Нет данных</th>\n';
		vHTML := vHTML || E'        </tr>\n';
	  ELSE
		vHTML := vHTML || E'        <tr class="text-center">\n';
		vHTML := vHTML || E'          <th colspan="6">No data</th>\n';
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

  html_file := convert_to(vHTML, 'utf8');

  PERFORM SetObjectFile(pReady, null, 'index.html', '~/', length(html_file), localtimestamp, html_file, encode(digest(html_file, 'md5'), 'hex'), arLines[1], 'data:text/html;base64,');

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

  html_file := convert_to(vHTML, 'utf8');

  PERFORM SetObjectFile(pReady, null, 'index.html', '~/', length(html_file), localtimestamp, html_file, encode(digest(html_file, 'md5'), 'hex'), 'exception', 'data:text/html;base64,');
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, public, pg_temp;
