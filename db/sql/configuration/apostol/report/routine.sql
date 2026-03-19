--------------------------------------------------------------------------------
-- report.get_report_style -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION report.get_report_style (
  orientation   text
) RETURNS       text
AS $$
DECLARE
  html      text;
BEGIN
  html := E'  <style type="text/css">\n';
  html := html || E'    @page {\n';
  html := html || format(E'      size: A4 %s;\n', orientation);
  html := html || E'      margin: 1cm;\n';
  html := html || E'    }\n';
  html := html || E'    @media print {\n';
  html := html || E'      .pb-after { page-break-after: always; }\n';
  html := html || E'      .pb-inside { page-break-inside: avoid; }\n';
  html := html || E'      p {\n';
  html := html || E'        orphans: 3;\n';
  html := html || E'        widows: 3;\n';
  html := html || E'      }\n';
  html := html || E'      .report-font-size {\n';
  html := html || E'        font-size: 0.65rem;\n';
  html := html || E'      }\n';
  html := html || E'      .report-text {\n';
  html := html || E'        font-size: small;\n';
  html := html || E'        padding: 10px;\n';
  html := html || E'      }\n';
  html := html || E'      .report-header {\n';
  html := html || E'        font-size: small;\n';
  html := html || E'        margin-top: 15px;\n';
  html := html || E'        margin-left: 50%;\n';
  html := html || E'      }\n';
  html := html || E'      .report-header p {\n';
  html := html || E'        margin: 0;\n';
  html := html || E'        padding: 0;\n';
  html := html || E'      }\n';
  html := html || E'      .report-text p {\n';
  html := html || E'        text-indent: 20px;\n';
  html := html || E'       }\n';
  html := html || E'      .report-li li {\n';
  html := html || E'        margin-top: 5px;\n';
  html := html || E'      }\n';
  html := html || E'    }\n';
  html := html || E'    body {\n';
  html := html || E'      overflow: auto;\n';
  html := html || E'    }\n';
  html := html || E'  </style>\n';

  RETURN html;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER;

--------------------------------------------------------------------------------
-- report.get_report_head ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION report.get_report_head (
  title         text,
  orientation   text DEFAULT 'portrait'
) RETURNS       text
AS $$
DECLARE
  html          text;
  host          text;
BEGIN
  host := RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host');

  html := E'<head>\n';
  html := html || E'  <meta charset="UTF-8">\n';
  html := html || format(E'  <title>%s</title>\n', title);
  html := html || format(E'  <link href="%s/css/style.css" rel="stylesheet">\n', host);
  html := html || report.get_report_style(orientation);
  html := html || E'</head>\n';

  RETURN html;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER;
