SELECT SignIn(CreateSystemOAuth2(), 'admin', 'admin');
SELECT InitConfiguration();
SELECT FillDataBase();
SELECT SignOut();