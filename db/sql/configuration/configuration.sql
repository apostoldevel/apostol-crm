SELECT SignIn(CreateSystemOAuth2(), 'admin', 'admin');

SELECT GetErrorMessage();

SELECT SetDefaultArea(GetArea('default'));
SELECT SetArea(GetArea('default'));

SELECT RegSetValueEx(RegCreateKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Name', 3, pString => 'Apostol Web Service');
SELECT RegSetValueEx(RegCreateKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Host', 3, pString => 'http://apostol-web-service.ru');
SELECT RegSetValueEx(RegCreateKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Email', 3, pString => 'info@apostol-web-service.ru');
SELECT RegSetValueEx(RegCreateKey('CURRENT_CONFIG', 'CONFIG\CurrentProject'), 'Support', 3, pString => 'support@apostol-web-service.ru');

SELECT CreateClassTree();
SELECT CreateObjectType();
SELECT KernelInit();

SELECT FillCalendar(CreateCalendar(null, GetType('workday.calendar'), 'default.calendar', 'Календарь рабочих дней', 5, ARRAY[6,7], ARRAY[[1,1], [1,7], [2,23], [3,8], [5,1], [5,9], [6,12], [11,4]], '9 hour', '9 hour', '13 hour', '1 hour', 'Календарь рабочих дней.'), '2020/01/01', '2020/12/31');

SELECT CreateVendor(null, GetType('service.vendor'), 'null.vendor', 'Нет', 'Не указан.');
SELECT CreateVendor(null, GetType('service.vendor'), 'system.vendor', 'Система', 'Системные услуги.');
SELECT CreateVendor(null, GetType('service.vendor'), 'mts.vendor', 'МТС', 'ПАО "МТС" (Мобитьные ТелеСистемы).');

SELECT CreateAgent(null, GetType('system.agent'), 'system.agent', 'System', GetVendor('system.vendor'), 'Агент для обработки системных сообщений.');
SELECT CreateAgent(null, GetType('system.agent'), 'event.agent', 'Event', GetVendor('system.vendor'), 'Агент для обработки системных событий.');
SELECT CreateAgent(null, GetType('email.agent'), 'smtp.agent', 'SMTP', GetVendor('null.vendor'), 'Агент для передачи электронной почты по протоколу SMTP.');
SELECT CreateAgent(null, GetType('email.agent'), 'pop3.agent', 'POP3', GetVendor('null.vendor'), 'Агент для прёма электронной почты по протоколу POP3.');
SELECT CreateAgent(null, GetType('sms.agent'), 'm2m.agent', 'M2M', GetVendor('mts.vendor'), 'Агент для прёма и передачи коротких сообщений через сервис МТС Коммуникатор.');
SELECT CreateAgent(null, GetType('stream.agent'), 'udp.agent', 'UDP', GetVendor('null.vendor'), 'Агент для обработки данных по протоколу UDP.');

SELECT SignOut();