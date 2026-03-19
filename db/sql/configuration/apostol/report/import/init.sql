SELECT RegisterRoute('import', AddEndpoint('SELECT * FROM rest.import($1, $2);'));
