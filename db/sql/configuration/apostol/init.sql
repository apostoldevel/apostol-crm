--------------------------------------------------------------------------------
-- InitConfiguration -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitConfiguration()
RETURNS     	void
AS $$
BEGIN
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\System', 'LocaleCode', current_setting('project.locale'));

  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Name', current_setting('project.name'));
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host', current_setting('project.url'));
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Domain', current_setting('project.domain'));
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'SMTP', current_setting('project.smtp'));
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Currency', current_setting('project.currency'));
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'PaymentSystem', current_setting('project.payment_system'));
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Deployment', 'prod');

  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject\Default', 'Product', 'Default');
  PERFORM RegSetValueInteger('CURRENT_CONFIG', 'CONFIG\CurrentProject\Default', 'Country', 643);
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject\Default', 'Region', '77');

  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentCompany', 'Code', current_setting('company.code'));
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentCompany', 'Name', current_setting('company.name'));

  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject\API\Route', 'Blacklist', '/api/.env,/api/.git/config,/api/vendor/phpunit/phpunit/src/util/php/eval-stdin.php,/check-version');

  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\Firebase', 'ProjectId', current_setting('project.id'));

  PERFORM SetSessionLocale('ru');

  PERFORM InitConfigurationException();
  PERFORM InitConfigurationEntity();
  PERFORM InitConfigurationReport();
  PERFORM InitMeasure();
  PERFORM InitCountry();
  PERFORM InitCurrency();
  PERFORM InitRegion();
  PERFORM FillDataBase();
  PERFORM InitTariffScheme();
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FillDataBase ----------------------------------------------------------------
--------------------------------------------------------------------------------
/*
 * Заполнить базу данных тестовыми данными.
 * @return {void}
*/
CREATE OR REPLACE FUNCTION FillDataBase (
) RETURNS       void
AS $$
DECLARE
  uPrice        uuid;
  uClient       uuid;
  uCompany      uuid;
  uCountry      uuid;
  uInterface    uuid;

  vCode         text;
  vCurrency     text;
  vCompanyCode  text;

  exAmounts     numeric[];
BEGIN
  exAmounts := ARRAY[100, 200, 300, 500, 1000, 1500, 2000, 2500, 3000, 5000];

  PERFORM SetSessionLocale('ru');

  INSERT INTO db.scope_alias SELECT '00000000-0000-4006-a000-000000000000', current_setting('project.scope_alias');
  INSERT INTO db.scope_alias SELECT '00000000-0000-4006-a000-000000000000', 'http://localhost:8080';

  PERFORM SetDefaultArea('00000000-0000-4003-a001-000000000000'::uuid, GetUser('apibot'));

  PERFORM CreateGroup('su', 'Суперпользователи', 'Группа для суперпользователей.', '00000000-0000-4000-a000-000000000007');
  PERFORM AddMemberToGroup(GetUser('admin'), '00000000-0000-4000-a000-000000000007');

  uInterface := CreateInterface('employee', 'Сотрудники', 'Интерфейс для сотрудников', '00000000-0000-4004-a000-100000000001');
  PERFORM AddMemberToInterface(CreateGroup('employee', 'Сотрудники', 'Группа для сотрудников системы.', '00000000-0000-4000-a001-100000000001'), uInterface);

  uInterface := CreateInterface('customer', 'Клиенты', 'Интерфейс для клиентов', '00000000-0000-4004-a000-100000000002');
  PERFORM AddMemberToInterface(CreateGroup('customer', 'Клиенты', 'Группа для клиентов.', '00000000-0000-4000-a001-100000000002'), uInterface);

  uInterface := CreateInterface('accountant', 'Бухгалтер', 'Интерфейс для сотрудников бухгалтерии', '00000000-0000-4004-a000-100000000004');
  PERFORM AddMemberToInterface(CreateGroup('accountant', 'Бухгалтеры', 'Группа для сотрудников бухгалтерии.', '00000000-0000-4000-a001-100000000004'), uInterface);

  uCountry := GetCountry('RU');

  PERFORM CreateCategory(null, GetType('account.category'), 'company.category', 'Компания', 'Компания.');
  PERFORM CreateCategory(null, GetType('account.category'), 'customer.category', 'Пользователь', 'Пользователь.');

  PERFORM CreateCategory(null, GetType('service.category'), 'service.category', 'Услуги', 'Услуги.');

  PERFORM DoEnable(id) FROM api.region WHERE code IN ('77', '50');

  PERFORM SetSessionArea('00000000-0000-4003-a001-000000000000'::uuid);

  PERFORM SetVar('object', 'id', current_area());
  PERFORM DoEnable(CreateCompany(null, GetType('all.company'), null, null, 'all', 'Все', 'Все компании.'));
  PERFORM SetVar('object', 'id', null);

  vCompanyCode := current_setting('company.code');
  uCompany := CreateCompany(current_area(), GetType('main.company'), current_area(), current_area(), vCompanyCode, current_setting('company.name'), current_setting('company.description'));

  PERFORM SetSessionArea(uCompany);

  PERFORM DoEnable(uCompany);

  uClient := GetClient(vCompanyCode);

  PERFORM ChangeDocumentArea(uClient, uCompany);

  PERFORM EditClient(uClient, pAddress := current_setting('company.address'));

  vCurrency := IntToStr(GetCurrencyDigital(DefaultCurrency()));

  vCode := '000.' || vCurrency || '.' || vCompanyCode ||'.0001';
  PERFORM DoEnable(CreateAccount(uClient, GetType('active-passive.account'), DefaultCurrency(), uClient, GetCategory('company.category'), vCode, vCode, 'Технический счёт.'));

  PERFORM CreateIdentity(uClient, GetType('kpp.identity'), uCountry, uClient, null, current_setting('company.kpp'));
  PERFORM CreateIdentity(uClient, GetType('ogrn.identity'), uCountry, uClient, null, current_setting('company.ogrn'));
  PERFORM CreateIdentity(uClient, GetType('account.identity'), uCountry, uClient, null, current_setting('company.account'), null, current_setting('company.account_issued'));
  PERFORM CreateIdentity(uClient, GetType('cor-account.identity'), uCountry, uClient, null, current_setting('company.cor_account'));
  PERFORM CreateIdentity(uClient, GetType('bic.identity'), uCountry, uClient, null, current_setting('company.bic'));

  PERFORM FillCalendar(CreateCalendar(null, GetType('workday.calendar'), 'default.calendar', 'Календарь рабочих дней', 5, ARRAY[6,7], ARRAY[[1,1], [1,7], [2,23], [3,8], [5,1], [5,9], [6,12], [11,4]], '9 hour', '8 hour', '13 hour', '1 hour', null, 'Календарь рабочих дней.'), date(date_trunc('year', Now())), date((date_trunc('year', Now()) + interval '1 year') - interval '1 day'));

  PERFORM CreateProgram(null, GetType('plpgsql.program'), 'CHECK_INVOICE', 'Проверяет счета', 'SELECT api.check_invoice();', 'Проверяет счета.');
  PERFORM CreateJob(null, GetType('periodic.job'), GetScheduler('EACH_01_MINUTES'), GetProgram('CHECK_INVOICE'), Now(), 'CHECK_INVOICE_EACH_01_MINUTES', 'Проверяет счета каждую минуту', 'Проверяет счета каждую минуту.');

  PERFORM CreateProgram(null, GetType('plpgsql.program'), 'GARBAGE_COLLECTOR', 'Сборщик мусора', 'SELECT api.garbage_collector();', 'Сборщик мусора.');
  PERFORM CreateJob(null, GetType('periodic.job'), GetScheduler('EACH_01_MINUTES'), GetProgram('GARBAGE_COLLECTOR'), Now(), 'GARBAGE_COLLECTOR_EACH_01_MINUTES', 'Сборщик мусора', 'Сборщик мусора.');

  PERFORM CreateVendor(null, GetType('device.vendor'), 'unknown.vendor', 'Неизвестный', 'Неизвестный производитель устройств.');

  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'unknown.model', 'Unknown', 'Неизвестная модель устройства.');
  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'android.model', 'Android', 'Неизвестная модель устройства на ОС Android.');
  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'ios.model', 'iOS', 'Неизвестная модель устройства на ОС iOS.');

  PERFORM CreateFormat(null, GetType('data.format'), 'raw.format', 'RAW', 'RAW data format.');

  PERFORM CreateService(null, GetType('rent.service'), GetCategory('service.category'), GetMeasure('355'), 'time.service', 'Время', 60, 'Услуга по времени (минута).');
  PERFORM CreateService(null, GetType('rent.service'), GetCategory('service.category'), GetMeasure('256'), 'volume.service', 'Объём', 1024, 'Услуга по объёму данных (килобайт).');

  PERFORM EditDocumentText(CreateProduct(null, GetType('service.product'), 'default.product', 'Default', pLabel => 'По умолчанию', pDescription => 'Продукт по умолчанию для аренды базовой станции.'), 'The default product for base station rentals.', GetLocale('en'));
  PERFORM EditObjectText(GetProduct('default.product'), 'Default', 'Default', GetLocale('en'));

  FOR i IN 1..array_length(exAmounts, 1)
  LOOP
    uPrice := CreatePrice(null, GetType('one_off.price'), DefaultCurrency(), GetProduct('default.product'), null, exAmounts[i], pDescription => 'Пополнение лицевого счёта в рублях РФ.');
    PERFORM EditDocumentText(uPrice, 'Replenishment of personal account in Russian rubles.', GetLocale('en'));
    PERFORM DoEnable(uPrice);
  END LOOP;

  PERFORM chmodc(GetClass('product'), B'0000010100', GetGroup('system'), true, true);
  PERFORM chmodc(GetClass('price'), B'0000010100', GetGroup('system'), true, true);
  PERFORM chmodc(GetClass('format'), B'0000010100', GetGroup('system'), true, true);

  PERFORM chmodc(GetClass('reference'), B'0000010100', GetGroup('employee'), true, true);
  PERFORM chmodc(GetClass('client'), B'0000010100', GetGroup('employee'), true, true);
  PERFORM chmodc(GetClass('device'), B'0000010100', GetGroup('employee'), true, true);

  PERFORM chmodc(GetClass('account'), B'0000011110', GetGroup('accountant'), true, true);
  PERFORM chmodc(GetClass('card'), B'0000011110', GetGroup('accountant'), true, true);
  PERFORM chmodc(GetClass('client'), B'0000011110', GetGroup('accountant'), true, true);
  PERFORM chmodc(GetClass('identity'), B'0000011110', GetGroup('accountant'), true, true);
  PERFORM chmodc(GetClass('invoice'), B'0000011110', GetGroup('accountant'), true, true);
  PERFORM chmodc(GetClass('order'), B'0000011110', GetGroup('accountant'), true, true);
  PERFORM chmodc(GetClass('payment'), B'0000011110', GetGroup('accountant'), true, true);
  PERFORM chmodc(GetClass('transaction'), B'0000011110', GetGroup('accountant'), true, true);

  PERFORM api.signup(null, 'demo', 'demo', 'Демонстрация', null, null, 'Демонстрационный клиент.');
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--
DROP TRIGGER IF EXISTS t_log_after_insert ON db.log;
