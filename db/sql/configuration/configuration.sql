SELECT SignIn(CreateSystemOAuth2(), 'admin', 'admin');

SELECT RegSetValueEx(RegCreateKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Name', 3, pString => 'Apostol Web Service');
SELECT RegSetValueEx(RegCreateKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Host', 3, pString => 'http://apostol-web-service.ru');
SELECT RegSetValueEx(RegCreateKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Email', 3, pString => 'info@apostol-web-service.ru');
SELECT RegSetValueEx(RegCreateKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Support', 3, pString => 'support@apostol-web-service.ru');

SELECT InitConfiguration();

SELECT SignOut();