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
 * Fill the database with seed data.
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

  PERFORM CreateGroup('su', 'Superusers', 'Superusers group.', '00000000-0000-4000-a000-000000000007');
  PERFORM AddMemberToGroup(GetUser('admin'), '00000000-0000-4000-a000-000000000007');

  uInterface := CreateInterface('employee', 'Employees', 'Employee interface', '00000000-0000-4004-a000-100000000001');
  PERFORM AddMemberToInterface(CreateGroup('employee', 'Employees', 'System employees group.', '00000000-0000-4000-a001-100000000001'), uInterface);

  uInterface := CreateInterface('customer', 'Customers', 'Customer interface', '00000000-0000-4004-a000-100000000002');
  PERFORM AddMemberToInterface(CreateGroup('customer', 'Customers', 'Customers group.', '00000000-0000-4000-a001-100000000002'), uInterface);

  uInterface := CreateInterface('accountant', 'Accountant', 'Accounting staff interface', '00000000-0000-4004-a000-100000000004');
  PERFORM AddMemberToInterface(CreateGroup('accountant', 'Accountants', 'Accounting staff group.', '00000000-0000-4000-a001-100000000004'), uInterface);

  uCountry := GetCountry('RU');

  PERFORM CreateCategory(null, GetType('account.category'), 'company.category', 'Company', 'Company.');
  PERFORM CreateCategory(null, GetType('account.category'), 'customer.category', 'Customer', 'Customer.');

  PERFORM CreateCategory(null, GetType('service.category'), 'service.category', 'Services', 'Services.');

  PERFORM DoEnable(id) FROM api.region WHERE code IN ('77', '50');

  PERFORM SetSessionArea('00000000-0000-4003-a001-000000000000'::uuid);

  PERFORM SetVar('object', 'id', current_area());
  PERFORM DoEnable(CreateCompany(null, GetType('all.company'), null, null, 'all', 'All', 'All companies.'));
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
  PERFORM DoEnable(CreateAccount(uClient, GetType('active-passive.account'), DefaultCurrency(), uClient, GetCategory('company.category'), vCode, vCode, 'Technical account.'));

  PERFORM CreateIdentity(uClient, GetType('kpp.identity'), uCountry, uClient, null, current_setting('company.kpp'));
  PERFORM CreateIdentity(uClient, GetType('ogrn.identity'), uCountry, uClient, null, current_setting('company.ogrn'));
  PERFORM CreateIdentity(uClient, GetType('account.identity'), uCountry, uClient, null, current_setting('company.account'), null, current_setting('company.account_issued'));
  PERFORM CreateIdentity(uClient, GetType('cor-account.identity'), uCountry, uClient, null, current_setting('company.cor_account'));
  PERFORM CreateIdentity(uClient, GetType('bic.identity'), uCountry, uClient, null, current_setting('company.bic'));

  PERFORM FillCalendar(CreateCalendar(null, GetType('workday.calendar'), 'default.calendar', 'Work days calendar', 5, ARRAY[6,7], ARRAY[[1,1], [1,7], [2,23], [3,8], [5,1], [5,9], [6,12], [11,4]], '9 hour', '8 hour', '13 hour', '1 hour', null, 'Work days calendar.'), date(date_trunc('year', Now())), date((date_trunc('year', Now()) + interval '1 year') - interval '1 day'));

  PERFORM CreateProgram(null, GetType('plpgsql.program'), 'CHECK_INVOICE', 'Check invoices', 'SELECT api.check_invoice();', 'Check invoices.');
  PERFORM CreateJob(null, GetType('periodic.job'), GetScheduler('EACH_01_MINUTES'), GetProgram('CHECK_INVOICE'), Now(), 'CHECK_INVOICE_EACH_01_MINUTES', 'Check invoices every minute', 'Check invoices every minute.');

  PERFORM CreateProgram(null, GetType('plpgsql.program'), 'GARBAGE_COLLECTOR', 'Garbage collector', 'SELECT api.garbage_collector();', 'Garbage collector.');
  PERFORM CreateJob(null, GetType('periodic.job'), GetScheduler('EACH_01_MINUTES'), GetProgram('GARBAGE_COLLECTOR'), Now(), 'GARBAGE_COLLECTOR_EACH_01_MINUTES', 'Garbage collector', 'Garbage collector.');

  PERFORM CreateVendor(null, GetType('device.vendor'), 'unknown.vendor', 'Unknown', 'Unknown device vendor.');

  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'unknown.model', 'Unknown', 'Unknown device model.');
  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'android.model', 'Android', 'Unknown Android device model.');
  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'ios.model', 'iOS', 'Unknown iOS device model.');

  PERFORM CreateFormat(null, GetType('data.format'), 'raw.format', 'RAW', 'RAW data format.');

  PERFORM CreateService(null, GetType('rent.service'), GetCategory('service.category'), GetMeasure('355'), 'time.service', 'Time', 60, 'Time-based service (minute).');
  PERFORM CreateService(null, GetType('rent.service'), GetCategory('service.category'), GetMeasure('256'), 'volume.service', 'Volume', 1024, 'Volume-based service (kilobyte).');

  PERFORM EditDocumentText(CreateProduct(null, GetType('service.product'), 'default.product', 'Default', pLabel => 'Default', pDescription => 'Default product for base station rentals.'), 'The default product for base station rentals.', GetLocale('en'));
  PERFORM EditObjectText(GetProduct('default.product'), 'Default', 'Default', GetLocale('en'));

  FOR i IN 1..array_length(exAmounts, 1)
  LOOP
    uPrice := CreatePrice(null, GetType('one_off.price'), DefaultCurrency(), GetProduct('default.product'), null, exAmounts[i], pDescription => 'Personal account top-up in Russian rubles.');
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

  PERFORM api.signup(null, 'demo', 'demo', 'Demo', null, null, 'Demo client.');
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--
DROP TRIGGER IF EXISTS t_log_after_insert ON db.log;
