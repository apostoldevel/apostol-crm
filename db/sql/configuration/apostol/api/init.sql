SELECT RegisterRoute('callback', AddEndpoint('SELECT * FROM rest.callback($1, $2);'));
