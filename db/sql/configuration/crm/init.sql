--------------------------------------------------------------------------------
-- InitConfiguration -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitConfiguration()
RETURNS     void
AS $$
DECLARE
  vLocaleCode	text;
BEGIN
  SELECT SubStr(setting, 1, 2) INTO vLocaleCode FROM pg_settings WHERE name = 'lc_messages';
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\System', 'LocaleCode', vLocaleCode);

  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Name', 'Apostol CRM');
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host', 'https://apostol-crm.ru');
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Domain', 'apostol-crm.ru');
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'SMTP', 'apostol-crm.ru');
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Currency', 'RUB');

  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\Firebase', 'ProjectId', 'apostolcrm');

  PERFORM InitConfigurationEntity();
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
) RETURNS 	void
AS $$
BEGIN
  PERFORM SetSessionLocale('ru');

  INSERT INTO db.scope_alias SELECT '00000000-0000-4006-a000-000000000000', 'http://localhost:8080';

  PERFORM CreateGroup('su', 'Суперпользователи', 'Группа для суперпользователей.', '00000000-0000-4000-a000-000000000007');
  PERFORM AddMemberToGroup(GetUser('admin'), '00000000-0000-4000-a000-000000000007');

  PERFORM InitMeasure();
  PERFORM InitCountry();
  PERFORM InitCurrency();

  PERFORM FillCalendar(CreateCalendar(null, GetType('workday.calendar'), 'default.calendar', 'Календарь рабочих дней', 5, ARRAY[6,7], ARRAY[[1,1], [1,7], [2,23], [3,8], [5,1], [5,9], [6,12], [11,4]], '9 hour', '8 hour', '13 hour', '1 hour', null, 'Календарь рабочих дней.'), date(date_trunc('year', Now())), date((date_trunc('year', Now()) + interval '1 year') - interval '1 day'));

  PERFORM CreateVendor(null, GetType('device.vendor'), 'unknown.vendor', 'Неизвестный', 'Неизвестный производитель устройств.');

  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'unknown.model', 'Unknown', 'Неизвестная модель устройства.');
  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'android.model', 'Android', 'Неизвестная модель устройства на ОС Android.');
  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'ios.model', 'iOS', 'Неизвестная модель устройства на ОС iOS.');

  PERFORM EditArea(GetArea(current_database()), pName => 'Apostol CRM');
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
