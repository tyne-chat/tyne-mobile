// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class ForkLocalizationsDe extends ForkLocalizations {
  ForkLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Persona wechseln';

  @override
  String get chatAttachmentPanelVoice => 'Sprache';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Quick-Switcher-Schaltfläche';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Ersetze die Sprachnachrichten-Schaltfläche im Eingabefeld durch eine Quick-Switcher-Schaltfläche für schnelle Navigation';

  @override
  String get userSettingsCheckForUpdates => 'Auf Updates überprüfen';

  @override
  String get userSettingsCheckingForUpdates => 'Nach Updates suchen…';

  @override
  String get userSettingsAppUpToDate => 'Tyne ist auf dem neuesten Stand';

  @override
  String get userSettingsUpdateAvailableTitle => 'Update verfügbar';

  @override
  String get userSettingsUpdateDownloadAction => 'Herunterladen & installieren';

  @override
  String get userSettingsUpdateInstallAction => 'Update installieren';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Update wird heruntergeladen ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Update konnte nicht geprüft oder heruntergeladen werden.';

  @override
  String get personaSelectTitle => 'Persona auswählen';

  @override
  String get personaSettingsHeader => 'Persona-Einstellungen';

  @override
  String get personaManageAction => 'Verwalten';

  @override
  String get personaSearchPlaceholder => 'Personas, Tags, Pronomen suchen...';

  @override
  String get personaModeManual => 'Manuell';

  @override
  String get personaModeLast => 'Zuletzt verwendet';

  @override
  String get personaModeManualDescription =>
      'Sendet immer als ausgewählte Persona, bis dies geändert wird.';

  @override
  String get personaModeLastDescription =>
      'Wechselt automatisch zu der Persona, die in deiner letzten Nachricht verwendet wurde.';

  @override
  String get personaRecentHeader => 'KÜRZLICH VERWENDETE PERSONAS';

  @override
  String personaAllHeader(int count) {
    return 'ALLE PERSONAS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'SUCHERGEBNISSE ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Hauptaccount (Standard)';

  @override
  String get personaEmptyState =>
      'Noch keine Personas konfiguriert. Erstelle eine über „Personas verwalten“.';

  @override
  String get personaEmptySearch => 'Keine passenden Personas gefunden.';

  @override
  String get personaEditTitle => 'Persona bearbeiten';

  @override
  String get personaCreateTitle => 'Persona erstellen';

  @override
  String get personaDisplayNameLabel => 'Anzeigename';

  @override
  String get personaPronounsLabel => 'Pronomen';

  @override
  String get personaPronounsHint => 'z. B. sie/ihr';

  @override
  String get personaBioHint => 'Erzähle anderen von dieser Persona...';

  @override
  String get personaUpdatedToast => 'Persona aktualisiert';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Persona konnte nicht aktualisiert werden: $error';
  }

  @override
  String get personaSectionTitle => 'Personas';

  @override
  String get personaDisplayNameHint => 'Persona-Name';

  @override
  String personaSendingAsTag(String name) {
    return 'Senden als $name (Über Tag zugeordnet)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Senden als $name (Fixiert)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Senden als $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Posten als $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Senden als @$username';
  }

  @override
  String get personaMainAccount => 'Hauptaccount';

  @override
  String get personaEditPersona => 'Persona bearbeiten';

  @override
  String get userSettingsNavPersonas => 'Personas';

  @override
  String get personaSettingsDescription =>
      'Konfiguriere deinen aktiven Persona-Modus, dein benutzerdefiniertes Anzeige-Tag und verwalte einzelne Personas.';

  @override
  String get personaDisplayTagSection => 'Anzeige-Tag';

  @override
  String get personaDisplayTagDescription =>
      'Das Anzeige-Tag wird neben allen Persona-Namen in Nachrichten angezeigt. Wenn kein Anzeige-Tag festgelegt ist, wird dein Account-Profilbild angezeigt.';

  @override
  String get personaDisplayTagLabel => 'Anzeige-Tag-Text';

  @override
  String get personaDisplayTagHint => 'z. B. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Anzeige-Tag-Icon';

  @override
  String get personaUploadTagIcon => 'Symbol hochladen';

  @override
  String get personaChangeTagIcon => 'Symbol ändern';

  @override
  String get personaRemoveTagIcon => 'Symbol entfernen';

  @override
  String get personaChatPreviewTitle => 'Chat-Vorschau';

  @override
  String get personaChatPreviewSampleMessage =>
      'Hallo! Dies ist eine Vorschau darauf, wie Nachrichten mit deinem Anzeige-Tag und deiner aktiven Persona aussehen.';

  @override
  String get personaListTitle => 'Konfigurierte Personas';

  @override
  String get personaAddButton => 'Persona hinzufügen';

  @override
  String get personaActiveBadge => 'Aktiv';

  @override
  String get personaMakeActive => 'Als aktiv festlegen';

  @override
  String get personaDeleteTitle => 'Persona löschen';

  @override
  String personaDeleteMessage(String name) {
    return 'Möchtest du „$name“ wirklich löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get personaDeleteConfirm => 'Löschen';

  @override
  String get personaDeletedToast => 'Persona gelöscht';

  @override
  String get personaCreatedToast => 'Persona erstellt';

  @override
  String personaCreateFailedToast(String error) {
    return 'Persona konnte nicht erstellt werden: $error';
  }

  @override
  String get personaChangeAvatar => 'Avatar ändern';

  @override
  String get personaRemoveAvatar => 'Avatar entfernen';

  @override
  String get personaUploadAvatar => 'Avatar hochladen';

  @override
  String get personaTagsLabel => 'Persona-Tags';

  @override
  String get personaTagPrefixLabel => 'Präfix';

  @override
  String get personaTagSuffixLabel => 'Suffix';

  @override
  String get personaVisibilityLabel => 'Sichtbarkeit';

  @override
  String get personaVisibilityUnlisted => 'Nicht gelistet';

  @override
  String get personaVisibilityPublic => 'Öffentlich';

  @override
  String get personaVisibilityPrivate => 'Privat';

  @override
  String get personaNameRequired => 'Bitte gib einen Persona-Anzeigenamen ein';

  @override
  String get personaNameTooLong =>
      'Der Persona-Anzeigename darf maximal 100 Zeichen lang sein';

  @override
  String get personaTagPrefixTooLong =>
      'Das Persona-Tag-Präfix darf maximal 32 Zeichen lang sein';

  @override
  String get personaTagSuffixTooLong =>
      'Das Persona-Tag-Suffix darf maximal 32 Zeichen lang sein';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Das Tag „$tag“ wird bereits von „$name“ verwendet.';
  }

  @override
  String get chatInsertTimestamp => 'Zeitstempel einfügen';

  @override
  String get chatAttachmentSendVoiceMessage => 'Sprachnachricht senden';

  @override
  String get timestampPickerTitle => 'Zeitstempel einfügen';

  @override
  String get timestampPickerInsert => 'Einfügen';

  @override
  String get timestampCopied => 'Zeitstempel kopiert';

  @override
  String get timestampPickerTimeLabel => 'Zeit';

  @override
  String get timestampPickerDateLabel => 'DATUM';

  @override
  String get timestampPickerTimeSectionLabel => 'UHRZEIT';

  @override
  String get timestampPickerTimezoneLabel => 'ZEITZONE';

  @override
  String get timestampPickerFormatPreviewLabel => 'FORMATVORSCHAU';

  @override
  String get timestampPickerNlpPlaceholder =>
      'z. B. morgen um 15 Uhr, in 2 Stunden, jetzt';

  @override
  String get timestampPickerSearchTimezones => 'Zeitzonen suchen...';

  @override
  String get userProfileTimezoneSettingLabel => 'Zeitzone';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Wird verwendet, um Ihre Ortszeit in Ihrem Profil anzuzeigen.';

  @override
  String get userProfileTimezoneNone => 'Keine';

  @override
  String get chatReactAs => 'Reagieren als...';

  @override
  String get emojiCopy => 'Emoji kopieren';

  @override
  String get emojiCopyLink => 'Link kopieren';

  @override
  String get emojiPin => 'Emoji anheften';

  @override
  String get emojiUnpin => 'Emoji lösen';

  @override
  String get emojiPinForPersona => 'Für diese Persona anheften';

  @override
  String get emojiUnpinForPersona => 'Für diese Persona lösen';

  @override
  String get personaSignatureEmojisLabel => 'Signatur-Emojis';

  @override
  String get personaSignatureEmojisDescription =>
      'Reaktionen mit einem Signatur-Emoji erfolgen immer als diese Persona, unabhängig von der aktiven Persona.';

  @override
  String get personaAddSignatureEmoji => 'Emoji hinzufügen';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Dieses Emoji wurde bereits als Signatur-Emoji hinzugefügt';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Signatur-Emoji wird bereits von Persona \"$name\" verwendet';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Signatur-Emoji entfernen';

  @override
  String get signalBarLabel => 'Signalleiste';

  @override
  String get signalBarShow => 'Signalleiste einblenden';

  @override
  String get signalBarHide => 'Signalleiste ausblenden';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Niemand hat dieses Signal eingeschaltet';

  @override
  String get signalBarReset => 'Signal für alle zurücksetzen';

  @override
  String signalBarTurnOff(String name) {
    return '$name ausschalten';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Verwende $domain für die Standardinstanz oder die genaue URL einer anderen Instanz.';
  }

  @override
  String get instanceResetToDefault => 'Auf Standardinstanz zurücksetzen';

  @override
  String get personaScopeTitle => 'Persona gilt für';

  @override
  String get personaScopeGlobal => 'Überall';

  @override
  String get personaScopeGlobalDescription => 'Eine Persona für alle Kanäle.';

  @override
  String get personaScopeChannel => 'In jedem Kanal';

  @override
  String get personaScopeChannelDescription =>
      'Jeder Kanal behält seine eigene Persona. Neue Kanäle beginnen mit deinem Account.';

  @override
  String get personaPickerChannelOnly => 'Nur für diesen Kanal';

  @override
  String get personaProfilePrivate => 'Das Profil dieser Persona ist privat.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Bilddatei ist zu groß. Bitte wähle eine Datei, die kleiner als $maxSize ist.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'KLIPY suchen';

  @override
  String get appUpdateDownloadFailed =>
      'Update konnte nicht heruntergeladen werden';

  @override
  String get appUpdateInstallFailed => 'Update konnte nicht installiert werden';

  @override
  String get personaChangeMessageFailed =>
      'Persona der Nachricht konnte nicht geändert werden';

  @override
  String get personaActiveCleared => 'Aktive Persona entfernt';

  @override
  String get klipyPoweredBy => 'Bereitgestellt von KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Doppeltes Tag-Paar „$pattern“ bei dieser Persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Tag-Paar hinzufügen ($count/5)';
  }

  @override
  String get personaTagExampleText => 'Text';

  @override
  String get personaPreviewNameFallback => 'Benutzer';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne wurde unerwartet beendet. Wenn du anonyme Absturz- und Fehlerdaten teilst, können wir Probleme schneller beheben.';

  @override
  String get crashReportingSectionDescription =>
      'Hilf mit, Fehler in Tyne zu beheben, indem du Absturz- und Leistungsdaten teilst. Standardmäßig deaktiviert.';

  @override
  String get crashReportingDescription =>
      'Berichte gehen an Tynes eigenes Fehlertracking, auch wenn du bei einer anderen Instanz angemeldet bist. Sie enthalten keine Instanznamen, IDs oder Nachrichteninhalte.';

  @override
  String get instanceOfflineTitle => 'Tyne ist offline!';

  @override
  String get instanceOfflineBody => 'Wir gehen der Sache nach.';

  @override
  String get instanceStatusSignalLink =>
      'Tritt unserem Signal-Chat bei, um auf dem Laufenden zu bleiben';

  @override
  String get convertEmoticonsLabel => 'Text-Smileys in Emojis umwandeln';

  @override
  String guildCommandFailed(String name, String detail) {
    return '/$name konnte nicht ausgeführt werden: $detail';
  }

  @override
  String get guildCommandBroken => 'Sein Skript hat ein Problem.';

  @override
  String guildCommandOneLine(String name) {
    return 'Was du nach /$name eingibst, muss in eine Zeile passen.';
  }

  @override
  String get permissionCreateCommands => 'Befehle erstellen';

  @override
  String get permissionManageCommands => 'Befehle verwalten';

  @override
  String get permissionUseExternalCommands => 'Externe Befehle verwenden';

  @override
  String get permissionCreateCommandsDescription =>
      'Befehle für diese Community erstellen und eigene bearbeiten oder löschen.';

  @override
  String get permissionManageCommandsDescription =>
      'Befehle aller Mitglieder dieser Community bearbeiten oder löschen.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Befehle aus anderen Communitys verwenden.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Befehle aus anderen Communitys in diesem Kanal verwenden.';

  @override
  String get guildSettingsCategoryMessageTools => 'Nachrichtenwerkzeuge';

  @override
  String get guildSettingsCommands => 'Befehle';

  @override
  String get guildCommandsLoadFailed =>
      'Die Befehle konnten nicht geladen werden.';

  @override
  String get guildCommandsSubtitle =>
      'Nachrichten, die Mitglieder mit /name posten können.';

  @override
  String get guildCommandsSlots => 'Befehls-Slots';

  @override
  String get guildCommandsNew => 'Neuer Befehl';

  @override
  String get guildCommandsSearch => 'Befehle suchen';

  @override
  String get guildCommandsEmptyTitle => 'Keine Befehle';

  @override
  String get guildCommandsEmptyBody =>
      'Diese Community hat noch keine Befehle.';

  @override
  String get guildCommandsSaved => 'Befehle gespeichert';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return '/$name konnte nicht gespeichert werden: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return '/$name bearbeiten';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return '/$name löschen?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Das kann nicht rückgängig gemacht werden. Damit erstellte Nachrichten zeigen weiterhin, mit welchem Befehl sie erstellt wurden.';

  @override
  String get guildCommandDelete => 'Löschen';

  @override
  String get guildCommandDeleteCommand => 'Befehl löschen';

  @override
  String get guildCommandSectionCommand => 'Befehl';

  @override
  String get guildCommandName => 'Name';

  @override
  String get guildCommandNameInvalid =>
      'Verwende Kleinbuchstaben, Zahlen, - und _, höchstens 32 Zeichen.';

  @override
  String get guildCommandNameTaken =>
      'Ein anderer Befehl oder ein integrierter Befehl hat bereits diesen Namen.';

  @override
  String get guildCommandDescription => 'Beschreibung';

  @override
  String get guildCommandSectionInput => 'Eingabe';

  @override
  String get guildCommandInputNone => 'Keine';

  @override
  String get guildCommandInputOptional => 'Optional';

  @override
  String get guildCommandInputRequired => 'Erforderlich';

  @override
  String get guildCommandHint => 'Hinweis';

  @override
  String get guildCommandMessage => 'Nachricht';

  @override
  String get guildCommandInsert => 'Einfügen:';

  @override
  String get guildCommandInsertPerson => 'Ausführende Person';

  @override
  String get guildCommandInsertInput => 'Was eingegeben wird';

  @override
  String get guildCommandPreview => 'Vorschau';

  @override
  String get guildCommandSampleInput => 'Beispieleingabe';

  @override
  String guildCommandMadeWith(String name) {
    return 'Erstellt mit /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Leere das Nachrichtenfeld, um /$name zu verwenden';
  }

  @override
  String get guildCommandScriptReadOnly =>
      'Dieser Befehl ist ein Skript. Bearbeite ihn in der Web- oder Desktop-App.';

  @override
  String get guildCommandEmptyMessage =>
      'Das würde nichts posten, daher würde der Befehl fehlschlagen.';
}
