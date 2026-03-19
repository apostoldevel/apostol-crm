# message

> Configuration entity -- document (thin override) | Loaded by `document/create.psql` line 13

Overrides platform message routines with comprehensive messaging infrastructure. Provides multi-channel message delivery (email, SMS, push notifications, FCM) and password recovery/registration flows. `CreateMessage` generates messages with RFC 1342 encoded subjects and HTML email bodies from templates.

## Overridden Functions

**kernel schema (15):**
- `CreateMessage(pParent, pType, pAgent, pProfile, pAddress, pSubject, pText, pLabel, pDescription)` -- creates message with encoded subject and HTML body
- `EditMessage(pId, ...)` -- updates message fields
- `GetMessageCode(pId)` -- returns message code
- `GetMessageState(pCode)` -- returns state code for message
- `GetEncodedTextRFC1342(pText)` -- base64-encodes text per RFC 1342
- `EncodingSubject(pSubject)` -- wraps subject in `=?UTF-8?B?...?=` encoding
- `CreateMailBody(pSubject, pText, pProject, pHost, pCopyright)` -- generates HTML email from template
- `SendMessage(pId)` -- dispatches message by agent type (email/m2m/fcm/sms)
- `SendMail(pUserId, pSubject, pText, pHTML)` -- sends email via SMTP agent
- `SendM2M(pUserId, pSubject, pText, pData)` -- sends M2M notification
- `SendFCM(pUserId, pSubject, pText)` -- sends Firebase Cloud Messaging push
- `SendSMS(pUserId, pText)` -- sends SMS via configured agent
- `SendPush(pUserId, pSubject, pText)` -- sends push notification through all agents
- `SendPushData(pUserId, pSubject, pData)` -- sends push with JSON data payload
- `RecoveryPasswordByEmail(pUserId)` -- generates verification code and sends recovery email
- `RecoveryPasswordByPhone(pUserId)` -- generates verification code and sends recovery SMS
- `RegistrationCodeByPhone(pUserId)` -- sends registration verification code via SMS
- `RegistrationCodeByEmail(pUserId)` -- sends registration verification code via email

## File Manifest

| File | In create | In update | Purpose |
|------|:---------:|:---------:|---------|
| `routine.sql` | yes | yes | 15+ kernel messaging functions |
| `event.sql` | yes | yes | (empty) |
| `create.psql` | -- | -- | Loads routine.sql and event.sql |
| `update.psql` | -- | -- | Loads routine.sql and event.sql |
