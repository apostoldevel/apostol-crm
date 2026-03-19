--------------------------------------------------------------------------------
-- GetRecoveryPasswordEmailText ------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Generate plain-text email body for password recovery
 * @param {text} pFullName - User's full name
 * @param {text} pUserName - Username (login)
 * @param {text} pTicket - Recovery ticket code
 * @param {text} pSecurityAnswer - Security answer for the recovery link
 * @param {text} pProject - Project name (used in greeting/signature)
 * @param {text} pHost - Base URL for the recovery link
 * @param {text} pSupport - Support email address
 * @param {uuid} pLocale - Locale identifier (determines language: 'ru' or English)
 * @return {text} - Plain-text email body
 * @since 1.0.0
 */
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
/**
 * @brief Generate HTML email body for password recovery
 * @param {text} pFullName - User's full name
 * @param {text} pUserName - Username (login)
 * @param {text} pTicket - Recovery ticket code
 * @param {text} pSecurityAnswer - Security answer for the recovery link
 * @param {text} pProject - Project name (used in greeting/signature)
 * @param {text} pHost - Base URL for the recovery link
 * @param {text} pSupport - Support email address
 * @param {uuid} pLocale - Locale identifier (determines language: 'ru' or English)
 * @return {text} - HTML email body
 * @since 1.0.0
 */
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
/**
 * @brief Generate plain-text email body for email address confirmation
 * @param {text} pFullName - User's full name
 * @param {text} pUserName - Username (login)
 * @param {text} pCode - Confirmation code
 * @param {text} pProject - Project name (used in greeting/signature)
 * @param {text} pHost - Base URL for the confirmation link
 * @param {text} pSupport - Support email address
 * @param {uuid} pLocale - Locale identifier (determines language: 'ru' or English)
 * @return {text} - Plain-text email body
 * @since 1.0.0
 */
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
/**
 * @brief Generate HTML email body for email address confirmation
 * @param {text} pFullName - User's full name
 * @param {text} pUserName - Username (login)
 * @param {text} pCode - Confirmation code
 * @param {text} pProject - Project name (used in greeting/signature)
 * @param {text} pHost - Base URL for the confirmation link
 * @param {text} pSupport - Support email address
 * @param {uuid} pLocale - Locale identifier (determines language: 'ru' or English)
 * @return {text} - HTML email body
 * @since 1.0.0
 */
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
-- GetVerificationEmailText ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Generate plain-text email body with a verification code
 * @param {text} pFullName - User's full name
 * @param {text} pUserName - Username (login)
 * @param {text} pCode - Verification code
 * @param {text} pProject - Project name (used in greeting/signature)
 * @param {text} pHost - Base URL (unused in text version, kept for signature consistency)
 * @param {text} pSupport - Support email address
 * @param {uuid} pLocale - Locale identifier (determines language: 'ru' or English)
 * @return {text} - Plain-text email body
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetVerificationEmailText (
  pFullName         text,
  pUserName         text,
  pCode             text,
  pProject          text,
  pHost             text,
  pSupport          text,
  pLocale           uuid DEFAULT current_locale()
) RETURNS           text
AS $$
DECLARE
  r                 record;

  vText             text;

  Lines             text[];
BEGIN
  FOR r IN SELECT code FROM db.locale WHERE id = pLocale
  LOOP
    if r.code = 'ru' THEN
      Lines[1] := 'Здравствуйте' || coalesce(format(', %s', coalesce(pFullName, pUserName)), '') || '!';
      Lines[2] := format('Спасибо, что присоединились к %s.', pProject);
      Lines[3] := 'Код верификации: ' || pCode;
      Lines[4] := 'Если у вас возникли проблемы, свяжитесь с нами';
      Lines[5] := format('- Команда %s', pProject);
    ELSE
      Lines[1] := 'Hey' || coalesce(format(', %s', coalesce(pFullName, pUserName)), '') || '!';
      Lines[2] := format(E'Thanks for joining %s.', pProject);
      Lines[3] := 'Verification code: ' || pCode;
      Lines[4] := 'If you have any problems, please contact us';
      Lines[5] := format('- %s Team.', pProject);
    END IF;

    vText := Lines[1];
    vText := vText || E'\n\n';
    vText := vText || Lines[2];
    vText := vText || E'\n\n';
    vText := vText || Lines[3];
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
-- GetVerificationEmailHTML ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Generate HTML email body with a styled verification code
 * @param {text} pFullName - User's full name
 * @param {text} pUserName - Username (login)
 * @param {text} pCode - Verification code
 * @param {text} pProject - Project name (used in header/footer)
 * @param {text} pHost - Base URL (unused in this variant, kept for signature consistency)
 * @param {text} pSupport - Support email address
 * @param {uuid} pLocale - Locale identifier (determines language: 'ru' or English)
 * @return {text} - HTML email body with styled verification code block
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION GetVerificationEmailHTML (
  pFullName         text,
  pUserName         text,
  pCode             text,
  pProject          text,
  pHost             text,
  pSupport          text,
  pLocale           uuid DEFAULT current_locale()
) RETURNS           text
AS $$
DECLARE
  r                 record;

  vHTML             text;
BEGIN
  FOR r IN SELECT code FROM db.locale WHERE id = pLocale
  LOOP
    vHTML := E'<!DOCTYPE html>\n';
    vHTML := vHTML || format(E'<html lang="%s">\n', r.code);
    vHTML := vHTML || E'<head>\n';
    vHTML := vHTML || E'  <meta charset="UTF-8">\n';
    vHTML := vHTML || E'  <title>Verify your account</title>\n';
    vHTML := vHTML || E'  <style type="text/css">\n';
    vHTML := vHTML || E'    @import url("https://fonts.googleapis.com/css?family=Inter");\n';
    vHTML := vHTML || E'    * {\n';
    vHTML := vHTML || E'      box-sizing: border-box;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    body {\n';
    vHTML := vHTML || E'      background-color: #fafafa;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .c-email {\n';
    vHTML := vHTML || E'      margin: 0 auto;\n';
    vHTML := vHTML || E'      width: 40vw;\n';
    vHTML := vHTML || E'      border-radius: 40px;\n';
    vHTML := vHTML || E'      overflow: hidden;\n';
    vHTML := vHTML || E'      box-shadow: 0 7px 22px 0 rgba(0, 0, 0, 0.1);\n';
    vHTML := vHTML || E'      font-family: "Inter", sans-serif;\n';
    vHTML := vHTML || E'      color: #F5F5F5;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .c-email__header {\n';
    vHTML := vHTML || E'      background: linear-gradient(97.22deg, #FBBF65 -106.12%, #FF6810 90.78%);\n';
    vHTML := vHTML || E'      width: 100%;\n';
    vHTML := vHTML || E'      height: 60px;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .c-email__header__title {\n';
    vHTML := vHTML || E'      font-size: 23px;\n';
    vHTML := vHTML || E'      height: 60px;\n';
    vHTML := vHTML || E'      line-height: 60px;\n';
    vHTML := vHTML || E'      margin: 0;\n';
    vHTML := vHTML || E'      text-align: center;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .c-email__content {\n';
    vHTML := vHTML || E'      width: 100%;\n';
    vHTML := vHTML || E'      height: 250px;\n';
    vHTML := vHTML || E'      background-color: #191919;\n';
    vHTML := vHTML || E'      padding: 15px;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .c-email__content__text {\n';
    vHTML := vHTML || E'      font-size: 20px;\n';
    vHTML := vHTML || E'      text-align: center;\n';
    vHTML := vHTML || E'      margin-top: 0;\n';
    vHTML := vHTML || E'      margin-bottom: 0;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .c-email__code {\n';
    vHTML := vHTML || E'      display: block;\n';
    vHTML := vHTML || E'      width: 60%;\n';
    vHTML := vHTML || E'      margin: 25px auto;\n';
    vHTML := vHTML || E'      background-color: #242424;\n';
    vHTML := vHTML || E'      border-radius: 10px;\n';
    vHTML := vHTML || E'      border: 1px solid #353535;\n';
    vHTML := vHTML || E'      padding: 20px;\n';
    vHTML := vHTML || E'      text-align: center;\n';
    vHTML := vHTML || E'      font-size: 36px;\n';
    vHTML := vHTML || E'      letter-spacing: 10px;\n';
    vHTML := vHTML || E'      box-shadow: 0 7px 22px 0 rgba(0, 0, 0, 0.1);\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .c-email__footer {\n';
    vHTML := vHTML || E'      width: 100%;\n';
    vHTML := vHTML || E'      height: 60px;\n';
    vHTML := vHTML || E'      background-color: #191919;\n';
    vHTML := vHTML || E'      padding: 20px 0;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .c-email__footer > span {\n';
    vHTML := vHTML || E'      display: block;\n';
    vHTML := vHTML || E'      text-align: center;\n';
    vHTML := vHTML || E'      font-size: 16px;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .text-title {\n';
    vHTML := vHTML || E'      margin-top: 5px;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .text-additional {\n';
    vHTML := vHTML || E'      font-size: 16px;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .text-italic {\n';
    vHTML := vHTML || E'      font-style: italic;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .opacity-70 {\n';
    vHTML := vHTML || E'      opacity: 0.7;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'    .mb-0 {\n';
    vHTML := vHTML || E'      margin-bottom: 0;\n';
    vHTML := vHTML || E'    }\n';
    vHTML := vHTML || E'  </style>\n';
    vHTML := vHTML || E'</head>\n';
    vHTML := vHTML || E'<body>\n';
    vHTML := vHTML || E'<div class="c-email">\n';
    vHTML := vHTML || E'  <div class="c-email__header">\n';
    vHTML := vHTML || E'    <h1 class="c-email__header__title">Your Verification Code</h1>\n';
    vHTML := vHTML || E'  </div>\n';
    vHTML := vHTML || E'  <div class="c-email__content">\n';
    vHTML := vHTML || E'    <p class="c-email__content__text text-title">\n';
    vHTML := vHTML || E'      Enter this verification code in field:\n';
    vHTML := vHTML || E'    </p>\n';
    vHTML := vHTML || E'    <div class="c-email__code">\n';
    vHTML := vHTML || E'      <span class="c-email__code__text">' || pCode || E'</span>\n';
    vHTML := vHTML || E'    </div>\n';
    vHTML := vHTML || E'    <p class="c-email__content__text text-italic opacity-70 text-additional mb-0">Verification code is valid only for 30 minutes</p>\n';
    vHTML := vHTML || E'  </div>\n';
    vHTML := vHTML || E'  <div class="c-email__footer">\n';
    vHTML := vHTML || E'    <span>© “' || pProject || E'”. All rights reserved.</span>\n';
    vHTML := vHTML || E'  </div>\n';
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
/**
 * @brief Generate plain-text email body with account credentials (public and secret keys)
 * @param {text} pFullName - User's full name
 * @param {text} pUserName - Username (public key)
 * @param {text} pSecret - Secret key
 * @param {text} pProject - Project name (used in greeting/signature)
 * @param {text} pSupport - Support email address
 * @param {uuid} pLocale - Locale identifier (determines language: 'ru' or English)
 * @return {text} - Plain-text email body
 * @since 1.0.0
 */
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
/**
 * @brief Generate HTML email body with account credentials (public and secret keys)
 * @param {text} pFullName - User's full name
 * @param {text} pUserName - Username (public key)
 * @param {text} pSecret - Secret key
 * @param {text} pProject - Project name (used in greeting/signature)
 * @param {text} pSupport - Support email address
 * @param {uuid} pLocale - Locale identifier (determines language: 'ru' or English)
 * @return {text} - HTML email body
 * @since 1.0.0
 */
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
