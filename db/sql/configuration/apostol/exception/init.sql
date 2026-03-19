--------------------------------------------------------------------------------
-- InitConfigurationException --------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Registers project-specific errors in the error catalog.
 * Error code range: ERR-400-200 .. ERR-400-229
 * @return {void}
 * @since 1.2.0
 */
CREATE OR REPLACE FUNCTION InitConfigurationException()
RETURNS void
AS $$
BEGIN
  -- Account errors (ERR-400-200 .. ERR-400-204)

  -- ERR-400-200: AccountCodeExists
  PERFORM RegisterError('ERR-400-200', 400, 'E', 'entity', 'en', 'Account "%s" already exists.');
  PERFORM RegisterError('ERR-400-200', 400, 'E', 'entity', 'ru', 'Счёт "%s" уже существует.');
  PERFORM RegisterError('ERR-400-200', 400, 'E', 'entity', 'de', 'Konto "%s" existiert bereits.');
  PERFORM RegisterError('ERR-400-200', 400, 'E', 'entity', 'fr', 'Le compte "%s" existe déjà.');
  PERFORM RegisterError('ERR-400-200', 400, 'E', 'entity', 'it', 'Il conto "%s" esiste già.');
  PERFORM RegisterError('ERR-400-200', 400, 'E', 'entity', 'es', 'La cuenta "%s" ya existe.');

  -- ERR-400-201: AccountNotFound
  PERFORM RegisterError('ERR-400-201', 400, 'E', 'entity', 'en', 'Account "%s" not found.');
  PERFORM RegisterError('ERR-400-201', 400, 'E', 'entity', 'ru', 'Счёт "%s" не найден.');
  PERFORM RegisterError('ERR-400-201', 400, 'E', 'entity', 'de', 'Konto "%s" nicht gefunden.');
  PERFORM RegisterError('ERR-400-201', 400, 'E', 'entity', 'fr', 'Le compte "%s" est introuvable.');
  PERFORM RegisterError('ERR-400-201', 400, 'E', 'entity', 'it', 'Il conto "%s" non è stato trovato.');
  PERFORM RegisterError('ERR-400-201', 400, 'E', 'entity', 'es', 'La cuenta "%s" no fue encontrada.');

  -- ERR-400-202: AccountNotAssociated
  PERFORM RegisterError('ERR-400-202', 400, 'E', 'entity', 'en', 'Account "%s" not affiliated with the client.');
  PERFORM RegisterError('ERR-400-202', 400, 'E', 'entity', 'ru', 'Счёт "%s" не связан с клиентом.');
  PERFORM RegisterError('ERR-400-202', 400, 'E', 'entity', 'de', 'Konto "%s" ist nicht mit dem Kunden verknüpft.');
  PERFORM RegisterError('ERR-400-202', 400, 'E', 'entity', 'fr', 'Le compte "%s" n''est pas associé au client.');
  PERFORM RegisterError('ERR-400-202', 400, 'E', 'entity', 'it', 'Il conto "%s" non è associato al cliente.');
  PERFORM RegisterError('ERR-400-202', 400, 'E', 'entity', 'es', 'La cuenta "%s" no está asociada con el cliente.');

  -- ERR-400-203: InsufficientFunds
  PERFORM RegisterError('ERR-400-203', 400, 'E', 'entity', 'en', 'Insufficient funds in the account: %s. Balance: %s. Amount: %s.');
  PERFORM RegisterError('ERR-400-203', 400, 'E', 'entity', 'ru', 'Недостаточно средств на счете: %s. Баланс: %s. Сумма: %s.');
  PERFORM RegisterError('ERR-400-203', 400, 'E', 'entity', 'de', 'Unzureichende Mittel auf dem Konto: %s. Saldo: %s. Betrag: %s.');
  PERFORM RegisterError('ERR-400-203', 400, 'E', 'entity', 'fr', 'Fonds insuffisants sur le compte : %s. Solde : %s. Montant : %s.');
  PERFORM RegisterError('ERR-400-203', 400, 'E', 'entity', 'it', 'Fondi insufficienti sul conto: %s. Saldo: %s. Importo: %s.');
  PERFORM RegisterError('ERR-400-203', 400, 'E', 'entity', 'es', 'Fondos insuficientes en la cuenta: %s. Saldo: %s. Monto: %s.');

  -- ERR-400-204: IncorrectTurnover
  PERFORM RegisterError('ERR-400-204', 400, 'E', 'entity', 'en', 'Incorrect entry of the account turnover amount: %s.');
  PERFORM RegisterError('ERR-400-204', 400, 'E', 'entity', 'ru', 'Неправильный ввод суммы оборота по счету: %s.');
  PERFORM RegisterError('ERR-400-204', 400, 'E', 'entity', 'de', 'Falsche Eingabe des Kontoumsatzbetrags: %s.');
  PERFORM RegisterError('ERR-400-204', 400, 'E', 'entity', 'fr', 'Saisie incorrecte du montant du chiffre d''affaires du compte : %s.');
  PERFORM RegisterError('ERR-400-204', 400, 'E', 'entity', 'it', 'Inserimento errato dell''importo del fatturato del conto: %s.');
  PERFORM RegisterError('ERR-400-204', 400, 'E', 'entity', 'es', 'Entrada incorrecta del monto de facturación de la cuenta: %s.');

  -- Client errors (ERR-400-205 .. ERR-400-212)

  -- ERR-400-205: ClientCodeExists
  PERFORM RegisterError('ERR-400-205', 400, 'E', 'entity', 'en', 'A client with the code "%s" already exists.');
  PERFORM RegisterError('ERR-400-205', 400, 'E', 'entity', 'ru', 'Клиент с кодом "%s" уже существует.');
  PERFORM RegisterError('ERR-400-205', 400, 'E', 'entity', 'de', 'Ein Kunde mit dem Code "%s" existiert bereits.');
  PERFORM RegisterError('ERR-400-205', 400, 'E', 'entity', 'fr', 'Un client avec le code "%s" existe déjà.');
  PERFORM RegisterError('ERR-400-205', 400, 'E', 'entity', 'it', 'Un cliente con il codice "%s" esiste già.');
  PERFORM RegisterError('ERR-400-205', 400, 'E', 'entity', 'es', 'Un cliente con el código "%s" ya existe.');

  -- ERR-400-206: AccountNotClient
  PERFORM RegisterError('ERR-400-206', 400, 'E', 'entity', 'en', 'The account does not belong to the client.');
  PERFORM RegisterError('ERR-400-206', 400, 'E', 'entity', 'ru', 'Учётная запись не принадлежит клиенту.');
  PERFORM RegisterError('ERR-400-206', 400, 'E', 'entity', 'de', 'Das Konto gehört nicht dem Kunden.');
  PERFORM RegisterError('ERR-400-206', 400, 'E', 'entity', 'fr', 'Le compte n''appartient pas au client.');
  PERFORM RegisterError('ERR-400-206', 400, 'E', 'entity', 'it', 'L''account non appartiene al cliente.');
  PERFORM RegisterError('ERR-400-206', 400, 'E', 'entity', 'es', 'La cuenta no pertenece al cliente.');

  -- ERR-400-207: EmailAddressNotSet
  PERFORM RegisterError('ERR-400-207', 400, 'E', 'entity', 'en', 'No e-mail address set.');
  PERFORM RegisterError('ERR-400-207', 400, 'E', 'entity', 'ru', 'Не задан адрес электронной почты.');
  PERFORM RegisterError('ERR-400-207', 400, 'E', 'entity', 'de', 'Keine E-Mail-Adresse festgelegt.');
  PERFORM RegisterError('ERR-400-207', 400, 'E', 'entity', 'fr', 'Aucune adresse e-mail définie.');
  PERFORM RegisterError('ERR-400-207', 400, 'E', 'entity', 'it', 'Nessun indirizzo e-mail impostato.');
  PERFORM RegisterError('ERR-400-207', 400, 'E', 'entity', 'es', 'No se ha establecido una dirección de correo electrónico.');

  -- ERR-400-208: EmailAddressNotVerified
  PERFORM RegisterError('ERR-400-208', 400, 'E', 'entity', 'en', 'Email address "%s" is not verified.');
  PERFORM RegisterError('ERR-400-208', 400, 'E', 'entity', 'ru', 'Адрес электронной почты "%s" не подтверждён.');
  PERFORM RegisterError('ERR-400-208', 400, 'E', 'entity', 'de', 'Die E-Mail-Adresse "%s" ist nicht verifiziert.');
  PERFORM RegisterError('ERR-400-208', 400, 'E', 'entity', 'fr', 'L''adresse e-mail "%s" n''est pas vérifiée.');
  PERFORM RegisterError('ERR-400-208', 400, 'E', 'entity', 'it', 'L''indirizzo e-mail "%s" non è verificato.');
  PERFORM RegisterError('ERR-400-208', 400, 'E', 'entity', 'es', 'La dirección de correo electrónico "%s" no está verificada.');

  -- ERR-400-209: PhoneNumberNotSet
  PERFORM RegisterError('ERR-400-209', 400, 'E', 'entity', 'en', 'No phone number set.');
  PERFORM RegisterError('ERR-400-209', 400, 'E', 'entity', 'ru', 'Не задан номер телефона.');
  PERFORM RegisterError('ERR-400-209', 400, 'E', 'entity', 'de', 'Keine Telefonnummer festgelegt.');
  PERFORM RegisterError('ERR-400-209', 400, 'E', 'entity', 'fr', 'Aucun numéro de téléphone défini.');
  PERFORM RegisterError('ERR-400-209', 400, 'E', 'entity', 'it', 'Nessun numero di telefono impostato.');
  PERFORM RegisterError('ERR-400-209', 400, 'E', 'entity', 'es', 'No se ha establecido un número de teléfono.');

  -- ERR-400-210: PhoneNumberNotVerified
  PERFORM RegisterError('ERR-400-210', 400, 'E', 'entity', 'en', 'Phone "%s" is not verified.');
  PERFORM RegisterError('ERR-400-210', 400, 'E', 'entity', 'ru', 'Телефон "%s" не подтверждён.');
  PERFORM RegisterError('ERR-400-210', 400, 'E', 'entity', 'de', 'Telefon "%s" ist nicht verifiziert.');
  PERFORM RegisterError('ERR-400-210', 400, 'E', 'entity', 'fr', 'Le téléphone "%s" n''est pas vérifié.');
  PERFORM RegisterError('ERR-400-210', 400, 'E', 'entity', 'it', 'Il telefono "%s" non è verificato.');
  PERFORM RegisterError('ERR-400-210', 400, 'E', 'entity', 'es', 'El teléfono "%s" no está verificado.');

  -- ERR-400-211: InvalidClientId
  PERFORM RegisterError('ERR-400-211', 400, 'E', 'entity', 'en', 'Incorrect client ID, expected: %s.');
  PERFORM RegisterError('ERR-400-211', 400, 'E', 'entity', 'ru', 'Неверно указан идентификатор клиента, ожидается: %s.');
  PERFORM RegisterError('ERR-400-211', 400, 'E', 'entity', 'de', 'Falsche Kunden-ID, erwartet: %s.');
  PERFORM RegisterError('ERR-400-211', 400, 'E', 'entity', 'fr', 'Identifiant client incorrect, attendu : %s.');
  PERFORM RegisterError('ERR-400-211', 400, 'E', 'entity', 'it', 'ID cliente errato, previsto: %s.');
  PERFORM RegisterError('ERR-400-211', 400, 'E', 'entity', 'es', 'ID de cliente incorrecto, esperado: %s.');

  -- ERR-400-212: IncorrectDateValue
  PERFORM RegisterError('ERR-400-212', 400, 'E', 'entity', 'en', 'Incorrect date value: %s.');
  PERFORM RegisterError('ERR-400-212', 400, 'E', 'entity', 'ru', 'Неверное значение даты: %s.');
  PERFORM RegisterError('ERR-400-212', 400, 'E', 'entity', 'de', 'Falscher Datumswert: %s.');
  PERFORM RegisterError('ERR-400-212', 400, 'E', 'entity', 'fr', 'Valeur de date incorrecte : %s.');
  PERFORM RegisterError('ERR-400-212', 400, 'E', 'entity', 'it', 'Valore della data errato: %s.');
  PERFORM RegisterError('ERR-400-212', 400, 'E', 'entity', 'es', 'Valor de fecha incorrecto: %s.');

  -- Device errors (ERR-400-213 .. ERR-400-214)

  -- ERR-400-213: DeviceExists
  PERFORM RegisterError('ERR-400-213', 400, 'E', 'entity', 'en', 'The device with the identifier "%s" already exists.');
  PERFORM RegisterError('ERR-400-213', 400, 'E', 'entity', 'ru', 'Устройство с идентификатором "%s" уже существует.');
  PERFORM RegisterError('ERR-400-213', 400, 'E', 'entity', 'de', 'Das Gerät mit der Kennung "%s" existiert bereits.');
  PERFORM RegisterError('ERR-400-213', 400, 'E', 'entity', 'fr', 'L''appareil avec l''identifiant "%s" existe déjà.');
  PERFORM RegisterError('ERR-400-213', 400, 'E', 'entity', 'it', 'Il dispositivo con l''identificatore "%s" esiste già.');
  PERFORM RegisterError('ERR-400-213', 400, 'E', 'entity', 'es', 'El dispositivo con el identificador "%s" ya existe.');

  -- ERR-400-214: DeviceNotAssociated
  PERFORM RegisterError('ERR-400-214', 400, 'E', 'entity', 'en', 'The device with the identifier "%s" is not associated with the client.');
  PERFORM RegisterError('ERR-400-214', 400, 'E', 'entity', 'ru', 'Устройство с идентификатором "%s" не связано с клиентом.');
  PERFORM RegisterError('ERR-400-214', 400, 'E', 'entity', 'de', 'Das Gerät mit der Kennung "%s" ist nicht mit dem Kunden verknüpft.');
  PERFORM RegisterError('ERR-400-214', 400, 'E', 'entity', 'fr', 'L''appareil avec l''identifiant "%s" n''est pas associé au client.');
  PERFORM RegisterError('ERR-400-214', 400, 'E', 'entity', 'it', 'Il dispositivo con l''identificatore "%s" non è associato al cliente.');
  PERFORM RegisterError('ERR-400-214', 400, 'E', 'entity', 'es', 'El dispositivo con el identificador "%s" no está asociado con el cliente.');

  -- Identity errors (ERR-400-215 .. ERR-400-217)

  -- ERR-400-215: IdentityExists
  PERFORM RegisterError('ERR-400-215', 400, 'E', 'entity', 'en', 'Identity "%s" already exists.');
  PERFORM RegisterError('ERR-400-215', 400, 'E', 'entity', 'ru', 'Удостоверение личности "%s" уже существует.');
  PERFORM RegisterError('ERR-400-215', 400, 'E', 'entity', 'de', 'Identitätsnachweis "%s" existiert bereits.');
  PERFORM RegisterError('ERR-400-215', 400, 'E', 'entity', 'fr', 'La pièce d''identité "%s" existe déjà.');
  PERFORM RegisterError('ERR-400-215', 400, 'E', 'entity', 'it', 'Il documento d''identità "%s" esiste già.');
  PERFORM RegisterError('ERR-400-215', 400, 'E', 'entity', 'es', 'El documento de identidad "%s" ya existe.');

  -- ERR-400-216: IdentityNotFound
  PERFORM RegisterError('ERR-400-216', 400, 'E', 'entity', 'en', 'Identity "%s" not found.');
  PERFORM RegisterError('ERR-400-216', 400, 'E', 'entity', 'ru', 'Удостоверение личности "%s" не найдено.');
  PERFORM RegisterError('ERR-400-216', 400, 'E', 'entity', 'de', 'Identitätsnachweis "%s" nicht gefunden.');
  PERFORM RegisterError('ERR-400-216', 400, 'E', 'entity', 'fr', 'La pièce d''identité "%s" est introuvable.');
  PERFORM RegisterError('ERR-400-216', 400, 'E', 'entity', 'it', 'Il documento d''identità "%s" non è stato trovato.');
  PERFORM RegisterError('ERR-400-216', 400, 'E', 'entity', 'es', 'El documento de identidad "%s" no fue encontrado.');

  -- ERR-400-217: IdentityNotAssociated
  PERFORM RegisterError('ERR-400-217', 400, 'E', 'entity', 'en', 'Identity "%s" not affiliated with the client.');
  PERFORM RegisterError('ERR-400-217', 400, 'E', 'entity', 'ru', 'Удостоверение личности "%s" не связано с клиентом.');
  PERFORM RegisterError('ERR-400-217', 400, 'E', 'entity', 'de', 'Identitätsnachweis "%s" ist nicht mit dem Kunden verknüpft.');
  PERFORM RegisterError('ERR-400-217', 400, 'E', 'entity', 'fr', 'La pièce d''identité "%s" n''est pas associée au client.');
  PERFORM RegisterError('ERR-400-217', 400, 'E', 'entity', 'it', 'Il documento d''identità "%s" non è associato al cliente.');
  PERFORM RegisterError('ERR-400-217', 400, 'E', 'entity', 'es', 'El documento de identidad "%s" no está asociado con el cliente.');

  -- Invoice errors (ERR-400-218 .. ERR-400-221)

  -- ERR-400-218: InvoiceCodeExists
  PERFORM RegisterError('ERR-400-218', 400, 'E', 'entity', 'en', 'Invoice "%s" already exists.');
  PERFORM RegisterError('ERR-400-218', 400, 'E', 'entity', 'ru', 'Счёт с кодом "%s" уже существует.');
  PERFORM RegisterError('ERR-400-218', 400, 'E', 'entity', 'de', 'Rechnung "%s" existiert bereits.');
  PERFORM RegisterError('ERR-400-218', 400, 'E', 'entity', 'fr', 'La facture "%s" existe déjà.');
  PERFORM RegisterError('ERR-400-218', 400, 'E', 'entity', 'it', 'La fattura "%s" esiste già.');
  PERFORM RegisterError('ERR-400-218', 400, 'E', 'entity', 'es', 'La factura "%s" ya existe.');

  -- ERR-400-219: InvalidInvoiceAmount
  PERFORM RegisterError('ERR-400-219', 400, 'E', 'entity', 'en', 'Invalid order amount.');
  PERFORM RegisterError('ERR-400-219', 400, 'E', 'entity', 'ru', 'Неверная сумма заказа.');
  PERFORM RegisterError('ERR-400-219', 400, 'E', 'entity', 'de', 'Ungültiger Bestellbetrag.');
  PERFORM RegisterError('ERR-400-219', 400, 'E', 'entity', 'fr', 'Montant de commande invalide.');
  PERFORM RegisterError('ERR-400-219', 400, 'E', 'entity', 'it', 'Importo dell''ordine non valido.');
  PERFORM RegisterError('ERR-400-219', 400, 'E', 'entity', 'es', 'Monto de pedido no válido.');

  -- ERR-400-220: InvalidInvoiceBalance
  PERFORM RegisterError('ERR-400-220', 400, 'E', 'entity', 'en', 'There are not enough funds on the balance to pay the invoice. Please top up your balance.');
  PERFORM RegisterError('ERR-400-220', 400, 'E', 'entity', 'ru', 'На балансе недостаточно средств для оплаты счёта. Пожалуйста, пополните свой баланс.');
  PERFORM RegisterError('ERR-400-220', 400, 'E', 'entity', 'de', 'Das Guthaben reicht nicht aus, um die Rechnung zu bezahlen. Bitte laden Sie Ihr Guthaben auf.');
  PERFORM RegisterError('ERR-400-220', 400, 'E', 'entity', 'fr', 'Le solde est insuffisant pour payer la facture. Veuillez recharger votre solde.');
  PERFORM RegisterError('ERR-400-220', 400, 'E', 'entity', 'it', 'Il saldo non è sufficiente per pagare la fattura. Si prega di ricaricare il saldo.');
  PERFORM RegisterError('ERR-400-220', 400, 'E', 'entity', 'es', 'No hay fondos suficientes en el saldo para pagar la factura. Por favor, recargue su saldo.');

  -- ERR-400-221: UnsupportedInvoiceType
  PERFORM RegisterError('ERR-400-221', 400, 'E', 'entity', 'en', 'Unsupported invoice type.');
  PERFORM RegisterError('ERR-400-221', 400, 'E', 'entity', 'ru', 'Неподдерживаемый тип счета-фактуры.');
  PERFORM RegisterError('ERR-400-221', 400, 'E', 'entity', 'de', 'Nicht unterstützter Rechnungstyp.');
  PERFORM RegisterError('ERR-400-221', 400, 'E', 'entity', 'fr', 'Type de facture non pris en charge.');
  PERFORM RegisterError('ERR-400-221', 400, 'E', 'entity', 'it', 'Tipo di fattura non supportato.');
  PERFORM RegisterError('ERR-400-221', 400, 'E', 'entity', 'es', 'Tipo de factura no admitido.');

  -- Order errors (ERR-400-222 .. ERR-400-225)

  -- ERR-400-222: OrderCodeExists
  PERFORM RegisterError('ERR-400-222', 400, 'E', 'entity', 'en', 'Order "%s" already exists.');
  PERFORM RegisterError('ERR-400-222', 400, 'E', 'entity', 'ru', 'Заказ с кодом "%s" уже существует.');
  PERFORM RegisterError('ERR-400-222', 400, 'E', 'entity', 'de', 'Bestellung "%s" existiert bereits.');
  PERFORM RegisterError('ERR-400-222', 400, 'E', 'entity', 'fr', 'La commande "%s" existe déjà.');
  PERFORM RegisterError('ERR-400-222', 400, 'E', 'entity', 'it', 'L''ordine "%s" esiste già.');
  PERFORM RegisterError('ERR-400-222', 400, 'E', 'entity', 'es', 'El pedido "%s" ya existe.');

  -- ERR-400-223: InvalidOrderAccountCurrency
  PERFORM RegisterError('ERR-400-223', 400, 'E', 'entity', 'en', 'Invalid currency of the order account.');
  PERFORM RegisterError('ERR-400-223', 400, 'E', 'entity', 'ru', 'Неверная валюта счета заказа.');
  PERFORM RegisterError('ERR-400-223', 400, 'E', 'entity', 'de', 'Ungültige Währung des Bestellkontos.');
  PERFORM RegisterError('ERR-400-223', 400, 'E', 'entity', 'fr', 'Devise du compte de commande invalide.');
  PERFORM RegisterError('ERR-400-223', 400, 'E', 'entity', 'it', 'Valuta del conto dell''ordine non valida.');
  PERFORM RegisterError('ERR-400-223', 400, 'E', 'entity', 'es', 'Moneda de la cuenta del pedido no válida.');

  -- ERR-400-224: IncorrectOrderAmount
  PERFORM RegisterError('ERR-400-224', 400, 'E', 'entity', 'en', 'Invalid amount %s in the order: "%s".');
  PERFORM RegisterError('ERR-400-224', 400, 'E', 'entity', 'ru', 'Недопустимая сумма %s в заказе: "%s".');
  PERFORM RegisterError('ERR-400-224', 400, 'E', 'entity', 'de', 'Ungültiger Betrag %s in der Bestellung: "%s".');
  PERFORM RegisterError('ERR-400-224', 400, 'E', 'entity', 'fr', 'Montant invalide %s dans la commande : "%s".');
  PERFORM RegisterError('ERR-400-224', 400, 'E', 'entity', 'it', 'Importo non valido %s nell''ordine: "%s".');
  PERFORM RegisterError('ERR-400-224', 400, 'E', 'entity', 'es', 'Monto no válido %s en el pedido: "%s".');

  -- ERR-400-225: TransferringInactiveAccount
  PERFORM RegisterError('ERR-400-225', 400, 'E', 'entity', 'en', 'Transferring funds to an inactive account "%s" is unacceptable.');
  PERFORM RegisterError('ERR-400-225', 400, 'E', 'entity', 'ru', 'Перевод средств на неактивный счет "%s" неприемлем.');
  PERFORM RegisterError('ERR-400-225', 400, 'E', 'entity', 'de', 'Die Überweisung von Geldern auf ein inaktives Konto "%s" ist nicht zulässig.');
  PERFORM RegisterError('ERR-400-225', 400, 'E', 'entity', 'fr', 'Le transfert de fonds vers un compte inactif "%s" est inacceptable.');
  PERFORM RegisterError('ERR-400-225', 400, 'E', 'entity', 'it', 'Il trasferimento di fondi su un conto inattivo "%s" è inaccettabile.');
  PERFORM RegisterError('ERR-400-225', 400, 'E', 'entity', 'es', 'La transferencia de fondos a una cuenta inactiva "%s" es inaceptable.');

  -- Payment errors (ERR-400-226 .. ERR-400-227)

  -- ERR-400-226: PaymentCodeExists
  PERFORM RegisterError('ERR-400-226', 400, 'E', 'entity', 'en', 'Payment "%s" already exists.');
  PERFORM RegisterError('ERR-400-226', 400, 'E', 'entity', 'ru', 'Платёж "%s" уже существует.');
  PERFORM RegisterError('ERR-400-226', 400, 'E', 'entity', 'de', 'Zahlung "%s" existiert bereits.');
  PERFORM RegisterError('ERR-400-226', 400, 'E', 'entity', 'fr', 'Le paiement "%s" existe déjà.');
  PERFORM RegisterError('ERR-400-226', 400, 'E', 'entity', 'it', 'Il pagamento "%s" esiste già.');
  PERFORM RegisterError('ERR-400-226', 400, 'E', 'entity', 'es', 'El pago "%s" ya existe.');

  -- ERR-400-227: IncorrectPaymentData
  PERFORM RegisterError('ERR-400-227', 400, 'E', 'entity', 'en', 'Incorrect payment data.');
  PERFORM RegisterError('ERR-400-227', 400, 'E', 'entity', 'ru', 'Неверные платежные данные.');
  PERFORM RegisterError('ERR-400-227', 400, 'E', 'entity', 'de', 'Falsche Zahlungsdaten.');
  PERFORM RegisterError('ERR-400-227', 400, 'E', 'entity', 'fr', 'Données de paiement incorrectes.');
  PERFORM RegisterError('ERR-400-227', 400, 'E', 'entity', 'it', 'Dati di pagamento errati.');
  PERFORM RegisterError('ERR-400-227', 400, 'E', 'entity', 'es', 'Datos de pago incorrectos.');

  -- Transaction errors (ERR-400-228 .. ERR-400-229)

  -- ERR-400-228: TransactionCodeExists
  PERFORM RegisterError('ERR-400-228', 400, 'E', 'entity', 'en', 'Transaction "%s" already exists.');
  PERFORM RegisterError('ERR-400-228', 400, 'E', 'entity', 'ru', 'Транзакция с кодом "%s" уже существует.');
  PERFORM RegisterError('ERR-400-228', 400, 'E', 'entity', 'de', 'Transaktion "%s" existiert bereits.');
  PERFORM RegisterError('ERR-400-228', 400, 'E', 'entity', 'fr', 'La transaction "%s" existe déjà.');
  PERFORM RegisterError('ERR-400-228', 400, 'E', 'entity', 'it', 'La transazione "%s" esiste già.');
  PERFORM RegisterError('ERR-400-228', 400, 'E', 'entity', 'es', 'La transacción "%s" ya existe.');

  -- ERR-400-229: TariffNotFound
  PERFORM RegisterError('ERR-400-229', 400, 'E', 'entity', 'en', 'The tariff for the service "%s" and currency "%s" tag "%s" was not found.');
  PERFORM RegisterError('ERR-400-229', 400, 'E', 'entity', 'ru', 'Тариф услуги "%s" в валюте "%s" с меткой "%s" не найден.');
  PERFORM RegisterError('ERR-400-229', 400, 'E', 'entity', 'de', 'Der Tarif für den Dienst "%s" und die Währung "%s" mit dem Tag "%s" wurde nicht gefunden.');
  PERFORM RegisterError('ERR-400-229', 400, 'E', 'entity', 'fr', 'Le tarif pour le service "%s" et la devise "%s" avec le tag "%s" est introuvable.');
  PERFORM RegisterError('ERR-400-229', 400, 'E', 'entity', 'it', 'La tariffa per il servizio "%s" e la valuta "%s" con il tag "%s" non è stata trovata.');
  PERFORM RegisterError('ERR-400-229', 400, 'E', 'entity', 'es', 'No se encontró la tarifa para el servicio "%s" y la moneda "%s" con la etiqueta "%s".');

END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
