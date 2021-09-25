--------------------------------------------------------------------------------
-- GetRecoveryPasswordEmailText ------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetRecoveryPasswordEmailText (
  pFullName			text,
  pUserName			text,
  pTicket			text,
  pSecurityAnswer	text,
  pProject			text,
  pHost				text,
  pSupport			text,
  pLocale			uuid DEFAULT current_locale()
) RETURNS			text
AS $$
DECLARE
  r					record;

  vText				text;

  Lines				text[];
BEGIN
  FOR r IN SELECT code FROM db.locale WHERE id = pLocale
  LOOP
    if r.code = 'ru' THEN
	  Lines[1] := 'Здравствуйте' || coalesce(format(', %s', coalesce(pFullName, pUserName)), '') || '!';
	  Lines[2] := 'Вы недавно запросили сброс пароля. Чтобы продолжить, перейдите по ссылке ниже.';
      Lines[3] := 'Сбросить пароль';
	  Lines[4] := 'Если Вы не вносили изменений или считаете, что посторонние лица получили доступ к Вашей учетной записи, немедленно смените пароль или свяжитесь с нами';
	  Lines[5] := format('- Команда %s', pProject);
	ELSE
	  Lines[1] := 'Hey' || coalesce(format(', %s', coalesce(pFullName, pUserName)), '') || '!';
	  Lines[2] := 'You recently requested a password reset. Follow the link below to continue.';
      Lines[3] := 'Reset the password';
	  Lines[4] := 'If you have not made any changes or believe that unauthorized persons have gained access to your account, immediately change your password or contact us';
	  Lines[5] := format('- %s Team.', pProject);
	END IF;

	vText := Lines[1];
	vText := vText || E'\n\n';
	vText := vText || Lines[2];
	vText := vText || E'\n\n';
	vText := vText || format('%s: %s/user/password/recovery/%s/%s', Lines[3], pHost, pTicket, pSecurityAnswer);
	vText := vText || E'\n\n';
	vText := vText || format(E'%s: %s', Lines[4], pSupport);
	vText := vText || E'\n\n';
	vText := vText || Lines[5];
  END LOOP;

  RETURN vText;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetRecoveryPasswordEmailHTML ------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetRecoveryPasswordEmailHTML (
  pFullName			text,
  pUserName			text,
  pTicket			text,
  pSecurityAnswer	text,
  pProject			text,
  pHost				text,
  pSupport			text,
  pLocale			uuid DEFAULT current_locale()
) RETURNS			text
AS $$
DECLARE
  r					record;

  vHTML         	text;

  Lines         	text[];
BEGIN
  FOR r IN SELECT code FROM db.locale WHERE id = pLocale
  LOOP
	vHTML := E'<!DOCTYPE html>\n';

	vHTML := vHTML || format(E'<html lang="%s">\n', r.code);
	vHTML := vHTML || E'<head>\n';
	vHTML := vHTML || E'  <meta charset="UTF-8">\n';
	vHTML := vHTML || E'  <title>Verify your account</title>\n';
	vHTML := vHTML || E'</head>\n';

	vHTML := vHTML || E'<body>\n';
	vHTML := vHTML || E'<div style="margin: 0 auto; font-family: Helvetica,sans-serif; color: #333333; text-align: center; max-width: 550px; padding: 0 20px">\n';
	vHTML := vHTML || E'    <div style="text-align: center; padding: 25px 0">\n';
	vHTML := vHTML || E'    </div>\n';

    if r.code = 'ru' THEN
	  Lines[1] := 'Здравствуйте' || coalesce(format(', %s', coalesce(pFullName, pUserName)), '') || '!';
	  Lines[2] := 'Вы недавно запросили сброс пароля. Чтобы продолжить, перейдите по ссылке ниже.';
      Lines[3] := 'Сбросить пароль';
	  Lines[4] := 'Если Вы не вносили изменений или считаете, что посторонние лица получили доступ к Вашей учетной записи, немедленно смените пароль или свяжитесь с нами: ';
	  Lines[5] := format('- Команда %s', pProject);
	ELSE
	  Lines[1] := 'Hey' || coalesce(format(', %s', coalesce(pFullName, pUserName)), '') || '!';
	  Lines[2] := 'You recently requested a password reset. Follow the link below to continue.';
      Lines[3] := 'Reset the password';
	  Lines[4] := 'If you have not made any changes or believe that unauthorized persons have gained access to your account, immediately change your password or contact us: ';
	  Lines[5] := format('- %s Team.', pProject);
	END IF;

	vHTML := vHTML || E'    <div style="font-size: 16px; text-align: left">\n';
	vHTML := vHTML || E'        <div style="line-height: 150%">\n';
	vHTML := vHTML || E'            <div style="font-size: 20px">\n';
	vHTML := vHTML || E'              ' || Lines[1];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'            <div style="margin: 15px 0">\n';
	vHTML := vHTML || E'              ' || Lines[2];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'        </div>\n';
	vHTML := vHTML || E'        <div>\n';
	vHTML := vHTML || E'            ' || format(E'<a href="%s/user/password/recovery/%s/%s" style="background: #007bff; padding: 9px; width: 230px; color: #fff; text-decoration: none; display: inline-block; font-weight: bold; text-align: center; letter-spacing: 0.5px; border-radius: 4px" rel="noreferrer" target="_blank">%s</a>\n', pHost, pTicket, pSecurityAnswer, Lines[3]);
	vHTML := vHTML || E'        </div>\n';
	vHTML := vHTML || E'        <div style="line-height: 150%">\n';
	vHTML := vHTML || E'            <div style="margin: 15px 0">\n';
	vHTML := vHTML || E'                ' || Lines[4] || format(E'<a href="mailto:%s" style="color: #007bff; text-decoration: none!important" rel="noreferrer">%s</a>\n', pSupport, pSupport);
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'            <div style="color: #828282; margin: 15px 0 75px">\n';
	vHTML := vHTML || E'                ' || Lines[5];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'        </div>\n';
	vHTML := vHTML || E'    </div>\n';
    vHTML := vHTML || E'</div>\n';
    vHTML := vHTML || E'</body>\n';
    vHTML := vHTML || E'</html>\n';
  END LOOP;

  RETURN vHTML;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetConfirmEmailText ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetConfirmEmailText (
  pFullName		text,
  pUserName		text,
  pCode			text,
  pProject		text,
  pHost			text,
  pSupport		text,
  pLocale		uuid DEFAULT current_locale()
) RETURNS       text
AS $$
DECLARE
  r				record;

  vText         text;

  Lines         text[];
BEGIN
  FOR r IN SELECT code FROM db.locale WHERE id = pLocale
  LOOP
    if r.code = 'ru' THEN
	  Lines[1] := 'Здравствуйте' || coalesce(format(', %s', coalesce(pFullName, pUserName)), '') || '!';
	  Lines[2] := format('Спасибо, что присоединились к %s. Чтобы завершить регистрацию и подтвердить свою учетную запись, нажмите на ссылку ниже.', pProject);
      Lines[3] := 'Подтвердить email адрес';
	  Lines[4] := 'Если у вас возникли проблемы, свяжитесь с нами';
	  Lines[5] := format('- Команда %s', pProject);
	ELSE
	  Lines[1] := 'Hey' || coalesce(format(', %s', coalesce(pFullName, pUserName)), '') || '!';
	  Lines[2] := format(E'Thanks for joining %s. To finish registration, please click the button below to verify your account.', pProject);
      Lines[3] := 'Verify email address';
	  Lines[4] := 'If you have any problems, please contact us';
	  Lines[5] := format('- %s Team.', pProject);
	END IF;

	vText := Lines[1];
	vText := vText || E'\n\n';
	vText := vText || Lines[2];
	vText := vText || E'\n\n';
	vText := vText || format('%s: %s/confirm/email/%s/', Lines[3], pHost, pCode);
	vText := vText || E'\n\n';
	vText := vText || format(E'%s: %s', Lines[4], pSupport);
	vText := vText || E'\n\n';
	vText := vText || Lines[5];
  END LOOP;

  RETURN vText;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetConfirmEmailHTML ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetConfirmEmailHTML (
  pFullName		text,
  pUserName		text,
  pCode			text,
  pProject		text,
  pHost			text,
  pSupport		text,
  pLocale		uuid DEFAULT current_locale()
) RETURNS       text
AS $$
DECLARE
  r				record;

  vHTML         text;

  Lines         text[];
BEGIN
  FOR r IN SELECT code FROM db.locale WHERE id = pLocale
  LOOP
	vHTML := E'<!DOCTYPE html>\n';

	vHTML := vHTML || format(E'<html lang="%s">\n', r.code);
	vHTML := vHTML || E'<head>\n';
	vHTML := vHTML || E'  <meta charset="UTF-8">\n';
	vHTML := vHTML || E'  <title>Verify your account</title>\n';
	vHTML := vHTML || E'</head>\n';

	vHTML := vHTML || E'<body>\n';
	vHTML := vHTML || E'<div style="margin: 0 auto; font-family: Helvetica,sans-serif; color: #333333; text-align: center; max-width: 550px; padding: 0 20px">\n';
	vHTML := vHTML || E'    <div style="text-align: center; padding: 25px 0">\n';
	vHTML := vHTML || E'    </div>\n';

    if r.code = 'ru' THEN
	  Lines[1] := 'Здравствуйте' || coalesce(format(E', %s', coalesce(pFullName, pUserName)), '') || E'!\n';
	  Lines[2] := format(E'Спасибо, что присоединились к <strong>%s</strong>. Чтобы завершить регистрацию и подтвердить свою учетную запись, нажмите на кнопку ниже.\n', pProject);
      Lines[3] := 'Подтвердить email адрес';
	  Lines[4] := 'Если у вас возникли проблемы, свяжитесь с нами: ';
	  Lines[5] := format(E'- Команда %s\n', pProject);
	ELSE
	  Lines[1] := 'Hey' || coalesce(format(E', %s', coalesce(pFullName, pUserName)), '') || E'!\n';
	  Lines[2] := format(E'Thanks for joining <strong>%s</strong>. To finish registration, please click the button below to verify your account.\n', pProject);
      Lines[3] := 'Verify email address';
	  Lines[4] := 'If you have any problems, please contact us: ';
	  Lines[5] := format(E'- %s Team\n', pProject);
	END IF;

	vHTML := vHTML || E'    <div style="font-size: 16px; text-align: left">\n';
	vHTML := vHTML || E'        <div style="line-height: 150%">\n';
	vHTML := vHTML || E'            <div style="font-size: 20px">\n';
	vHTML := vHTML || E'              ' || Lines[1];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'            <div style="margin: 15px 0">\n';
	vHTML := vHTML || E'              ' || Lines[2];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'        </div>\n';
	vHTML := vHTML || E'        <div>\n';
	vHTML := vHTML || E'            ' || format(E'<a href="%s/confirm/email/%s/" style="background: #007bff; padding: 9px; width: 230px; color: #fff; text-decoration: none; display: inline-block; font-weight: bold; text-align: center; letter-spacing: 0.5px; border-radius: 4px" rel="noreferrer" target="_blank">%s</a>\n', pHost, pCode, Lines[3]);
	vHTML := vHTML || E'        </div>\n';
	vHTML := vHTML || E'        <div style="line-height: 150%">\n';
	vHTML := vHTML || E'            <div style="margin: 15px 0">\n';
	vHTML := vHTML || E'                ' || Lines[4] || format(E'<a href="mailto:%s" style="color: #007bff; text-decoration: none!important" rel="noreferrer">%s</a>\n', pSupport, pSupport);
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'            <div style="color: #828282; margin: 15px 0 75px">\n';
	vHTML := vHTML || E'                ' || Lines[5];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'        </div>\n';
	vHTML := vHTML || E'    </div>\n';
    vHTML := vHTML || E'</div>\n';
    vHTML := vHTML || E'</body>\n';
    vHTML := vHTML || E'</html>\n';
  END LOOP;

  RETURN vHTML;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAccountInfoText ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetAccountInfoText (
  pFullName		text,
  pUserName		text,
  pSecret       text,
  pProject		text,
  pSupport		text,
  pLocale		uuid DEFAULT current_locale()
) RETURNS       text
AS $$
DECLARE
  r				record;

  vText         text;

  Lines         text[];
BEGIN
  FOR r IN SELECT code FROM db.locale WHERE id = pLocale
  LOOP
    if r.code = 'ru' THEN
	  Lines[1] := 'Здравствуйте' || coalesce(format(', %s', coalesce(pFullName, pUserName)), '') || '!';
	  Lines[2] := format('Добро пожаловать в %s.', pProject);
      Lines[3] := 'Информация о вашей учетной записи:';
	  Lines[4] := 'Открытый ключ';
	  Lines[5] := 'Секретный ключ';
	  Lines[6] := 'Пожалуйста, сохраните свои данные в надежном месте. Они вам понадобятся при авторизации в системе на новых устройствах.';
	  Lines[7] := 'Если у вас возникли проблемы, свяжитесь с нами';
	  Lines[8] := format('- Команда %s.', pProject);
	ELSE
	  Lines[1] := 'Hey' || coalesce(format(', %s', coalesce(pFullName, pUserName)), '') || '!';
	  Lines[2] := format('Welcome to the %s.', pProject);
      Lines[3] := 'Your account info:';
	  Lines[4] := 'Public key';
	  Lines[5] := 'Secret key';
	  Lines[6] := 'Please keep your data in a safe place. You will need them when you sign in on new devices.';
	  Lines[7] := 'If you have any problems, please contact us';
	  Lines[8] := format('- %s Team.', pProject);
	END IF;

	vText := Lines[1];
	vText := vText || E'\n\n';
	vText := vText || Lines[2];
	vText := vText || E'\n\n';
	vText := vText || Lines[3];
	vText := vText || E'\n\n';
	vText := vText || format(E'%s: %s', Lines[4], pUserName);
	vText := vText || E'\n\n';
	vText := vText || format(E'%s: %s', Lines[5], pSecret);
	vText := vText || E'\n\n';
	vText := vText || Lines[6];
	vText := vText || E'\n\n';
	vText := vText || format(E'%s: %s', Lines[7], pSupport);
	vText := vText || E'\n\n';
	vText := vText || Lines[8];
  END LOOP;

  RETURN vText;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAccountInfoHTML ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetAccountInfoHTML (
  pFullName		text,
  pUserName		text,
  pSecret       text,
  pProject		text,
  pSupport		text,
  pLocale		uuid DEFAULT current_locale()
) RETURNS       text
AS $$
DECLARE
  r				record;

  vHTML         text;

  Lines         text[];
BEGIN
  FOR r IN SELECT code FROM db.locale WHERE id = pLocale
  LOOP
	vHTML := E'<!DOCTYPE html>\n';

	vHTML := vHTML || format(E'<html lang="%s">\n', r.code);
	vHTML := vHTML || E'<head>\n';
	vHTML := vHTML || E'  <meta charset="UTF-8">\n';
	vHTML := vHTML || E'  <title>Your account info</title>\n';
	vHTML := vHTML || E'</head>\n';

	vHTML := vHTML || E'<body>\n';
	vHTML := vHTML || E'<div style="margin: 0 auto; font-family: Helvetica,sans-serif; color: #333333; text-align: center; max-width: 650px; padding: 0 20px">\n';
	vHTML := vHTML || E'    <div style="text-align: center; padding: 25px 0">\n';
	vHTML := vHTML || E'    </div>\n';

    if r.code = 'ru' THEN
	  Lines[1] := 'Здравствуйте' || coalesce(format(E', %s', coalesce(pFullName, pUserName)), '') || E'!\n';
	  Lines[2] := format(E'Добро пожаловать в <strong>%s</strong>.\n', pProject);
      Lines[3] := 'Информация о вашей учетной записи:';
	  Lines[4] := E'<b>Открытый ключ</b>:\n';
	  Lines[5] := E'<b>Секретный ключ</b>:\n';
	  Lines[6] := 'Пожалуйста, сохраните свои данные в надежном месте. Они вам понадобятся при авторизации в системе на новых устройствах.';
	  Lines[7] := 'Если у вас возникли проблемы, свяжитесь с нами: ';
	  Lines[8] := format(E'- Команда %s\n', pProject);
	ELSE
	  Lines[1] := 'Hey' || coalesce(format(E', %s', coalesce(pFullName, pUserName)), '') || E'!\n';
	  Lines[2] := format(E'Welcome to the <strong>%s</strong>.\n', pProject);
      Lines[3] := 'Your account info';
	  Lines[4] := E'<b>Public key</b>:\n';
	  Lines[5] := E'<b>Secret key</b>:\n';
	  Lines[6] := 'Please keep your data in a safe place. You will need them when you sign in on new devices.';
	  Lines[7] := 'If you have any problems, please contact us: ';
	  Lines[8] := format(E'- %s Team\n', pProject);
	END IF;

	vHTML := vHTML || E'    <div style="font-size: 16px; text-align: left">\n';
	vHTML := vHTML || E'        <div style="word-wrap: break-word; line-height: 150%">\n';
	vHTML := vHTML || E'            <div style="font-size: 20px">\n';
	vHTML := vHTML || E'              ' || Lines[1];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'            <div style="margin: 15px 0">\n';
	vHTML := vHTML || E'                ' || Lines[2];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'            <div style="margin: 5px 0">\n';
	vHTML := vHTML || E'                ' || Lines[3];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'            <div style="margin: 5px 0">\n';
	vHTML := vHTML || E'                ' || Lines[4];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'            <code style="margin: 5px 0">\n';
	vHTML := vHTML || E'                ' || pUserName;
	vHTML := vHTML || E'            </code>\n';
	vHTML := vHTML || E'            <div style="margin: 5px 0">\n';
	vHTML := vHTML || E'                ' || Lines[5];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'            <code style="margin: 5px 0">\n';
	vHTML := vHTML || E'                ' || pSecret;
	vHTML := vHTML || E'            </code>\n';
	vHTML := vHTML || E'            <div style="margin: 15px 0">\n';
	vHTML := vHTML || E'                ' || Lines[6];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'        </div>\n';
	vHTML := vHTML || E'        <div style="line-height: 150%">\n';
	vHTML := vHTML || E'            <div style="margin: 15px 0">\n';
	vHTML := vHTML || E'                ' || Lines[7] || format(E'<a href="mailto:%s" style="color: #007bff; text-decoration: none!important" rel="noreferrer">%s</a>\n', pSupport, pSupport);
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'            <div style="color: #828282; margin: 15px 0 75px">\n';
	vHTML := vHTML || E'                ' || Lines[8];
	vHTML := vHTML || E'            </div>\n';
	vHTML := vHTML || E'        </div>\n';
	vHTML := vHTML || E'    </div>\n';
    vHTML := vHTML || E'</div>\n';
    vHTML := vHTML || E'</body>\n';
    vHTML := vHTML || E'</html>\n';
  END LOOP;

  RETURN vHTML;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
