--------------------------------------------------------------------------------
-- CUSTOMER AUTH ---------------------------------------------------------------
--------------------------------------------------------------------------------

SELECT AddAlgorithm('HS256', 'SHA256');
SELECT AddAlgorithm('HS384', 'SHA384');
SELECT AddAlgorithm('HS512', 'SHA512');

SELECT AddProvider('I', 'system', 'OAuth 2.0 system provider');
SELECT AddProvider('I', 'default', 'OAuth 2.0 default provider');

SELECT AddProvider('E', 'google', 'Google');

SELECT AddApplication('S', 'system', 'Current system');
SELECT AddApplication('S', 'service', 'Service application');
SELECT AddApplication('W', 'web', 'Server-site Web application');
SELECT AddApplication('N', 'android', 'Android mobile application');
SELECT AddApplication('N', 'ios', 'iOS mobile application');

SELECT AddIssuer(GetProvider('default'), 'accounts.apostol-crm.ru', 'Apostol CRM');

SELECT AddIssuer(GetProvider('google'), 'accounts.google.com', 'Google account');
SELECT AddIssuer(GetProvider('google'), 'https://accounts.google.com', 'Google account');

SELECT CreateAudience(GetProvider('system'), GetApplication('system'), GetAlgorithm('HS512'), current_database(), GetSecretKey(), 'OAuth 2.0 Client Id for current data base.');

SELECT CreateAudience(GetProvider('default'), GetApplication('service'), GetAlgorithm('HS512'), 'service-apostol-crm.ru', 'CQrv6PfUzV9dbT22pKNgQvNO', 'OAuth 2.0 Client Id for Service Accounts.');
SELECT CreateAudience(GetProvider('default'), GetApplication('web'), GetAlgorithm('HS256'), 'web-apostol-crm.ru', 'blgqv0vOOnvZMrnLxrQ7agSX', 'OAuth 2.0 Client Id for Server-site and JavaScript Web applications.');
SELECT CreateAudience(GetProvider('default'), GetApplication('android'), GetAlgorithm('HS256'), 'android-apostol-crm.ru', 'zUc0shAhWnRmcbjHD88rhu3b', 'OAuth 2.0 Client Id for Android mobile applications.');
SELECT CreateAudience(GetProvider('default'), GetApplication('ios'), GetAlgorithm('HS256'), 'ios-apostol-crm.ru', 'zUKUW1LsAEeHDDxqaVpkW78v', 'OAuth 2.0 Client Id for iOS mobile applications.');

--SELECT CreateAudience(GetProvider('google'), GetApplication('web'), GetAlgorithm('HS256'), '.apps.googleusercontent.com', '', 'Google Client Id for apostol-crm.ru');

SELECT AddMemberToGroup(CreateUser(code, secret, 'OAuth 2.0 Client Id', null, null, name, false, true), GetGroup('system')) FROM oauth2.audience;
