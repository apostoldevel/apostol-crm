--------------------------------------------------------------------------------
-- CUSTOMER SECURITY -----------------------------------------------------------
--------------------------------------------------------------------------------

INSERT INTO db.interface (sid, name, description) VALUES ('I:1:0:0', 'Все', 'Интерфейс для всех');
INSERT INTO db.interface (sid, name, description) VALUES ('I:1:0:1', 'Администраторы', 'Интерфейс для администраторов');
INSERT INTO db.interface (sid, name, description) VALUES ('I:1:0:2', 'Операторы', 'Интерфейс для операторов системы');
INSERT INTO db.interface (sid, name, description) VALUES ('I:1:0:3', 'Пользователи', 'Интерфейс для пользователей');

SELECT CreateArea(null, GetAreaType('root'), 'root', 'Корень');
SELECT CreateArea(GetArea('root'), GetAreaType('default'), 'default', 'По умолчанию');
SELECT CreateArea(GetArea('root'), GetAreaType('main'), 'main', 'Головной офис');
SELECT CreateArea(GetArea('main'), GetAreaType('department'), 'department', 'Подразделение');

SELECT AddMemberToInterface(CreateGroup('system', 'Система', 'Группа для системных пользователей'), GetInterface('I:1:0:0'));
SELECT AddMemberToInterface(CreateGroup('administrator', 'Администратор', 'Группа для администраторов системы'), GetInterface('I:1:0:1'));
SELECT AddMemberToInterface(CreateGroup('operator', 'Операторы', 'Группа для операторов системы'), GetInterface('I:1:0:2'));
SELECT AddMemberToInterface(CreateGroup('user', 'Пользователи', 'Группа для внешних пользователей системы'), GetInterface('I:1:0:3'));

SELECT AddMemberToGroup(CreateUser('admin', 'admin', 'Администратор', null,null, 'Администратор системы', true, false, GetArea('default')), 1001);

SELECT CreateUser('daemon', 'daemon', 'Демон', null, null, 'Пользователь для вызова методов API', false, true, GetArea('root'));
SELECT CreateUser('apibot', 'apibot', 'Системная служба API', null, null, 'API клиент', false, true, GetArea('root'));
SELECT CreateUser('mailbot', 'mailbot', 'Почтовый клиент', null, null, 'Почтовый клиент', false, true, GetArea('root'));
