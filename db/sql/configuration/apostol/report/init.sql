--------------------------------------------------------------------------------
-- InitConfigurationReport -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitConfigurationReport()
RETURNS     	void
AS $$
DECLARE
  uRoot         uuid;
  uNode         uuid;
  uForm         uuid;
  uType         uuid;
BEGIN
  uType := GetType('report.report');

  uRoot := CreateReportTree(null, GetType('root.report_tree'), null, null, 'root', 'Report tree', 'Report tree.');

  uForm := CreateReportForm(null, GetType('json.report_form'), 'rfc_identifier_form', 'Object identifier form', 'rfc_identifier_form', 'Object identifier form.');

  PERFORM InitObjectReport(null, uRoot, uForm, GetClass('object'), 'object_info', 'Object info', 'Detailed object information.');

  uNode := CreateReportTree(null, GetType('node.report_tree'), uRoot, uRoot, 'general', 'General', 'General reports.');

  PERFORM InitReport(null, GetType('report.report'), uNode, 'client_list', 'Client list', 'Client list.');

  uNode := CreateReportTree(null, GetType('node.report_tree'), uRoot, uRoot, 'admin', 'Administration', 'System administrator reports.');

  PERFORM chmodo(uNode, '000000', GetGroup('user'));

  PERFORM chmodo(InitReport(null, uType, uNode, 'user_list', 'Users', 'List of system user accounts.'), '000000', GetGroup('user'));
  PERFORM chmodo(InitReport(null, uType, uNode, 'session_list', 'Sessions', 'List of active sessions.'), '000000', GetGroup('user'));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
