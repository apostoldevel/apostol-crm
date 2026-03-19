--------------------------------------------------------------------------------
-- CUSTOMER AUTH ---------------------------------------------------------------
-- OAuth2 seed data: algorithms, providers, applications, issuers, audiences
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

SELECT AddIssuer(GetProvider('default'), 'accounts.' || current_setting('project.domain'), current_setting('project.name'));
SELECT AddIssuer(GetProvider('default'), 'https://accounts.' || current_setting('project.domain'), current_setting('project.name'));

SELECT AddIssuer(GetProvider('google'), 'accounts.google.com', 'Google account');
SELECT AddIssuer(GetProvider('google'), 'https://accounts.google.com', 'Google account');

SELECT CreateAudience(GetProvider('system'), GetApplication('system'), GetAlgorithm('HS512'), current_database(), GetSecretKey(), 'OAuth 2.0 Client Id for current data base.');

SELECT CreateAudience(GetProvider('default'), GetApplication('service'), GetAlgorithm('HS512'), 'service-' || current_setting('project.domain'), current_setting('secret.service'), 'OAuth 2.0 Client Id for Service Accounts.');
SELECT CreateAudience(GetProvider('default'), GetApplication('web'), GetAlgorithm('HS256'), 'web-' || current_setting('project.domain'), current_setting('secret.web'), 'OAuth 2.0 Client Id for Server-site and JavaScript Web applications.');
SELECT CreateAudience(GetProvider('default'), GetApplication('android'), GetAlgorithm('HS256'), 'android-' || current_setting('project.domain'), current_setting('secret.android'), 'OAuth 2.0 Client Id for Android mobile applications.');
SELECT CreateAudience(GetProvider('default'), GetApplication('ios'), GetAlgorithm('HS256'), 'ios-' || current_setting('project.domain'), current_setting('secret.ios'), 'OAuth 2.0 Client Id for iOS mobile applications.');

SELECT CreateAudience(GetProvider('google'), GetApplication('web'), GetAlgorithm('HS256'), current_setting('google.code'), current_setting('google.secret'), 'Google Client Id for ' || current_setting('project.name'));

SELECT AddMemberToGroup(CreateUser(code, secret, name, null,null, name, false, true), GetGroup('system')) FROM oauth2.audience;
