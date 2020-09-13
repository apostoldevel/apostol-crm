SELECT SignIn(CreateSystemOAuth2(), 'admin', 'admin');

SELECT GetErrorMessage();

SELECT SetDefaultArea(GetArea('default'));
SELECT SetArea(GetArea('default'));

SELECT RegSetValue(RegCreateKey('CURRENT_CONFIG', 'CONFIG\Department' || E'\u005C' || A.code), 'LocalIP', (3, null, null, null, '127.0.0.1, 192.168.0.*', null)::Variant) FROM area AS A;
SELECT RegSetValue(RegCreateKey('CURRENT_CONFIG', 'CONFIG\Department' || E'\u005C' || A.code), 'EntrustedIP', (3, null, null, null, null, null)::Variant) FROM area AS A;

SELECT CreateClassTree();
SELECT CreateObjectType();
SELECT KernelInit();

SELECT FillCalendar(CreateCalendar(null, GetType('workday.calendar'), 'default.calendar', 'Календарь рабочих дней', 5, ARRAY[6,7], ARRAY[[1,1], [1,7], [2,23], [3,8], [5,1], [5,9], [6,12], [11,4]], '9 hour', '9 hour', '13 hour', '1 hour', 'Календарь рабочих дней.'), '2020/01/01', '2020/12/31');

SELECT CreateVendor(null, GetType('device.vendor'), 'incotex.vendor', 'Инкотекс', 'Группа компаний ИНКОТЕКС');

SELECT CreateModel(null, GetType('phase1.model'), 'mercury_200.model', 'Меркурий 200', GetVendor('incotex'), 'Однофазный счётчик ватт-часов активной энергии переменного тока.');
SELECT CreateModel(null, GetType('phase1.model'), 'mercury_201.model', 'Меркурий 201', GetVendor('incotex'), 'Однофазный счётчик ватт-часов активной энергии переменного тока.');
SELECT CreateModel(null, GetType('phase1.model'), 'mercury_202.model', 'Меркурий 202', GetVendor('incotex'), 'Однофазный счётчик ватт-часов активной энергии переменного тока.');
SELECT CreateModel(null, GetType('phase1.model'), 'mercury_203.model', 'Меркурий 203', GetVendor('incotex'), 'Однофазный счётчик ватт-часов активной энергии переменного тока.');
SELECT CreateModel(null, GetType('phase1.model'), 'mercury_206.model', 'Меркурий 206', GetVendor('incotex'), 'Однофазный счётчик ватт-часов активной энергии переменного тока.');
SELECT CreateModel(null, GetType('phase1.model'), 'mercury_208.model', 'Меркурий 208', GetVendor('incotex'), 'Однофазный счётчик ватт-часов активной энергии переменного тока.');

SELECT CreateModel(null, GetType('phase3.model'), 'mercury_230.model', 'Меркурий 230', GetVendor('incotex'), 'Трехфазный счётчик ватт-часов активной энергии переменного тока.');
SELECT CreateModel(null, GetType('phase3.model'), 'mercury_231.model', 'Меркурий 231', GetVendor('incotex'), 'Трехфазный счётчик ватт-часов активной энергии переменного тока.');
SELECT CreateModel(null, GetType('phase3.model'), 'mercury_234.model', 'Меркурий 234', GetVendor('incotex'), 'Трехфазный счётчик ватт-часов активной энергии переменного тока.');
SELECT CreateModel(null, GetType('phase3.model'), 'mercury_236.model', 'Меркурий 236', GetVendor('incotex'), 'Трехфазный счётчик ватт-часов активной энергии переменного тока.');
SELECT CreateModel(null, GetType('phase3.model'), 'mercury_238.model', 'Меркурий 238', GetVendor('incotex'), 'Трехфазный счётчик ватт-часов активной энергии переменного тока.');

SELECT SignOut();