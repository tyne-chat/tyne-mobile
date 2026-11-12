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
  String get personaSendHeldNotLoaded =>
      'Nicht gesendet: Deine Personas sind noch nicht geladen.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Nicht gesendet: Deine Personas sind noch nicht geladen. Stattdessen als @$username senden?';
  }

  @override
  String get personaSendAsAccountAction => 'Trotzdem senden';

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
    return 'Möchtest du „$name“ wirklich löschen? Gelöschte Personas kannst du später unter Einstellungen › Personas im Bereich „Gelöschte Personas“ wiederherstellen.';
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
  String get personaAutoTagDisabledLabel =>
      'Tags dieser Persona nicht erkennen';

  @override
  String get personaAutoTagDisabledDescription =>
      'Wenn du einen dieser Tags eingibst, wird nicht zu dieser Persona gewechselt. Der Tag wird so gesendet, wie er geschrieben wurde.';

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
  String get guildCommandEmptyMessage =>
      'Das würde nichts posten, daher würde der Befehl fehlschlagen.';

  @override
  String get guildCommandUseScriptEditor => 'Skripteditor verwenden';

  @override
  String get guildCommandUseBasicEditor => 'Einfachen Editor verwenden';

  @override
  String get guildCommandScript => 'Skript';

  @override
  String get guildCommandRunAgain => 'Erneut ausführen';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Es gibt kein Tag namens $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Es gibt keinen Filter namens $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name wird nie geschlossen.';
  }

  @override
  String get guildCommandIssueTooLong => 'Das Skript ist zu lang.';

  @override
  String get guildCommandIssueTooLarge => 'Das Skript erzeugt zu viel Text.';

  @override
  String get guildCommandIssueTooSlow =>
      'Die Ausführung des Skripts hat zu lange gedauert.';

  @override
  String get guildCommandIssueInvalid =>
      'Dieser Teil kann nicht gelesen werden.';

  @override
  String get guildCommandIssueFailed =>
      'Dieser Teil wurde mit einem Fehler abgebrochen.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Zeile $line, Spalte $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Skriptreferenz';

  @override
  String get guildCommandReferencePerson =>
      'Die ausführende Person als Erwähnung';

  @override
  String get guildCommandReferencePersonName =>
      'Der Name der ausführenden Person';

  @override
  String get guildCommandReferenceTarget =>
      'Die erste erwähnte Person, falls vorhanden';

  @override
  String get guildCommandReferenceTargetName => 'Der Name dieser Person';

  @override
  String get guildCommandReferenceChannel => 'Der Kanal als Erwähnung';

  @override
  String get guildCommandReferenceCommunity => 'Der Name dieser Community';

  @override
  String get guildCommandExampleRandom => 'Zufällig eine Option auswählen';

  @override
  String get guildCommandExampleDepends =>
      'Die Nachricht je nach Eingabe ändern';

  @override
  String get guildCommandExampleOneWord => 'Zufällig ein Wort auswählen';

  @override
  String get guildCommandExampleWordForNumber =>
      'Das passende Wort zu einer Zahl wählen';

  @override
  String get guildCommandExampleOrdinal =>
      'Eine Zahl als 1st, 2nd, 3rd schreiben';

  @override
  String get guildCommandFullGuide => 'Vollständige Skriptanleitung';

  @override
  String get guildCommandCounters => 'Zähler';

  @override
  String get guildCommandCounterAdd => 'Zähler hinzufügen';

  @override
  String get guildCommandCounterSeparately => 'Getrennt zählen für jede:n:';

  @override
  String get guildCommandCounterPersonMentioned => 'Erwähnte Person';

  @override
  String get guildCommandCounterChannel => 'Kanal';

  @override
  String get guildCommandCounterPersonas => 'Personas getrennt zählen';

  @override
  String get guildCommandCounterRemove => 'Zähler entfernen';

  @override
  String get guildCommandCounterReset => 'Zählerstände zurücksetzen';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Zählerstände von $name zurücksetzen? Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Verwende Kleinbuchstaben, Zahlen und _, beginne mit einem Buchstaben und nimm keinen Namen, den Skripte schon verwenden.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Verwende ihn in einem Skript als $variable. Jede Ausführung zählt zuerst eins hoch, die erste liest also 1.';
  }

  @override
  String get notificationsAlertEveryMessageLabel =>
      'Bei jeder Nachricht benachrichtigen';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Wenn aus, meldet sich eine aktive Unterhaltung nur einmal und wird danach still aktualisiert, bis du sie liest oder wegwischst.';

  @override
  String personaGalleryTitle(int count) {
    return 'Personas ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Personas von $name durchsuchen';
  }

  @override
  String get personaGallerySearchOwn => 'Deine Personas durchsuchen';

  @override
  String get personaGallerySortBy => 'Sortieren nach';

  @override
  String get personaGallerySortName => 'Name (A–Z)';

  @override
  String get personaGallerySortMostUsed => 'Am häufigsten genutzt';

  @override
  String get personaGallerySortRecentlyUsed => 'Zuletzt genutzt';

  @override
  String get personaGalleryViewGallery => 'Galerie';

  @override
  String get personaGalleryViewList => 'Liste';

  @override
  String get personaGalleryViewAvatars => 'Avatare';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personas',
      one: '$count Persona',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return '$shown von $total Personas';
  }

  @override
  String get personaGalleryNoMatch => 'Keine Persona passt zu deiner Suche.';

  @override
  String get personaGalleryLoadFailed =>
      'Personas konnten nicht geladen werden.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öffentliche Personas',
      one: '$count öffentliche Persona',
    );
    return 'Andere sehen $_temp0.';
  }

  @override
  String get personaGalleryShowHidden => 'Nicht gelistete und private anzeigen';

  @override
  String get personaGalleryManage => 'Personas verwalten';

  @override
  String get personaGalleryNonePublic =>
      'Noch keine deiner Personas ist öffentlich. Andere sehen eine Persona hier, sobald du ihre Sichtbarkeit auf „Öffentlich“ stellst.';

  @override
  String get personaGalleryNoBio => 'Noch keine Bio.';

  @override
  String personaGalleryCreated(String date) {
    return 'Erstellt am $date';
  }

  @override
  String get personaBulkSelect => 'Auswählen';

  @override
  String get personaBulkSelectAll => 'Alle auswählen';

  @override
  String personaBulkSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get personaFilterAll => 'Alle';

  @override
  String get personaBulkMakePublic => 'Öffentlich machen';

  @override
  String get personaBulkMakeUnlisted => 'Nicht listen';

  @override
  String get personaBulkMakePrivate => 'Privat machen';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personas',
      one: '$count Persona',
    );
    return '$_temp0 öffentlich machen?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personas',
      one: '$count Persona',
    );
    return '$_temp0 privat machen?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personas',
      one: '$count Persona',
    );
    return '$_temp0 löschen?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Andere sehen sie in deiner Personas-Liste und können ihre Profile öffnen. Du kannst das jederzeit zurückändern.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Ihre Profile werden vor anderen verborgen. Ihre Namen und Avatare erscheinen weiterhin bei ihren Nachrichten und Reaktionen.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Gelöschte Personas kannst du später unter Einstellungen › Personas im Bereich „Gelöschte Personas“ wiederherstellen.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personas sind',
      one: '$count Persona ist',
    );
    return '$_temp0 jetzt öffentlich';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personas sind',
      one: '$count Persona ist',
    );
    return '$_temp0 jetzt nicht gelistet';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personas sind',
      one: '$count Persona ist',
    );
    return '$_temp0 jetzt privat';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personas',
      one: '$count Persona',
    );
    return '$_temp0 gelöscht';
  }

  @override
  String get personaBulkFailed =>
      'Die Personas konnten nicht geändert werden. Versuch es noch einmal.';

  @override
  String get personaFilterEmpty => 'Hier gibt es keine Personas.';

  @override
  String get personaGalleryChooseFeatured => 'Personas zum Zeigen auswählen';

  @override
  String get personaUndo => 'Rückgängig';

  @override
  String get personaReactionsTitle => 'Deine Reaktionen';

  @override
  String get personaReactionsEveryoneElse => 'ALLE ANDEREN';

  @override
  String get personaReactionsCurrent => 'AKTUELL';

  @override
  String get personaReactionsAccount => 'Konto';

  @override
  String get personaReactionsSomeoneElse => 'Als jemand anderes reagieren...';

  @override
  String get personaReactionsDone => 'Fertig';

  @override
  String get personaSettingsReactionsHeader => 'Reaktionen';

  @override
  String get personaSettingsMultiReactions =>
      'Als mehrere Personas gleichzeitig reagieren';

  @override
  String get personaDuplicateButton => 'Persona duplizieren';

  @override
  String personaCopyOf(String name) {
    return 'Kopie von $name';
  }

  @override
  String signalsEverywhereTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Chats',
      one: '$count Chat',
    );
    return 'Deine Signale überall · $_temp0';
  }

  @override
  String signalsEverywhereHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Chats',
      one: '$count Chat',
    );
    return 'Überall setzen ($_temp0)';
  }

  @override
  String signalsEverywhereSet(String label) {
    return '$label überall setzen';
  }

  @override
  String get signalsEverywhereTurnAllOff => 'Alle ausschalten';

  @override
  String get signalsEverywhereRestore => 'Wiederherstellen…';

  @override
  String get signalsEverywhereNone =>
      'Keines deiner Signale ist irgendwo eingeschaltet.';

  @override
  String get signalsRestoreTitle => 'Deine Signale wiederherstellen?';

  @override
  String signalsRestoreBeforeSet(String label, String time) {
    return 'Stellt wieder her, was du eingeschaltet hattest, bevor du $label überall gesetzt hast ($time). Was du dort jetzt eingeschaltet hast, wird ausgeschaltet.';
  }

  @override
  String signalsRestoreBeforeOff(String time) {
    return 'Stellt wieder her, was du eingeschaltet hattest, bevor du alle ausgeschaltet hast ($time). Was du dort jetzt eingeschaltet hast, wird ausgeschaltet.';
  }

  @override
  String signalsRestoreBeforeRestore(String time) {
    return 'Stellt wieder her, was du vor deiner letzten Wiederherstellung ($time) eingeschaltet hattest. Was du dort jetzt eingeschaltet hast, wird ausgeschaltet.';
  }

  @override
  String get signalsRestoreNow => 'Jetzt';

  @override
  String get signalsRestoreAfter => 'Danach';

  @override
  String signalsRestoreLeftOut(String chats) {
    return 'Ausgelassen, weil du dort nicht mehr schreiben kannst: $chats';
  }

  @override
  String get signalsRestoreConfirm => 'Wiederherstellen';

  @override
  String get signalsRestoreUnavailable =>
      'Was „Wiederherstellen“ ändern würde, konnte nicht geladen werden. Versuch es noch einmal.';

  @override
  String get signalsRestoreNothing => 'Es gibt nichts wiederherzustellen.';

  @override
  String get signalsProfileMenu => 'Signale';

  @override
  String get signalsEverywhereTurnOffChat => 'Signale ausschalten';

  @override
  String signalsRestoreBeforeChange(String time) {
    return 'Stellt wieder her, was du eingeschaltet hattest, bevor du zuletzt überall etwas geändert hast ($time). Was du dort jetzt eingeschaltet hast, wird ausgeschaltet.';
  }

  @override
  String get personaCopyBadge => 'Neue Persona';

  @override
  String get deletedPersonasTitle => 'Gelöschte Personas';

  @override
  String get deletedPersonasDescription =>
      'Gelöschte Personas erscheinen weiterhin bei ihren alten Nachrichten, aber niemand kann sie auswählen, und sie zählen nicht zu deinem Limit. Wenn du eine wiederherstellst, kommt dieselbe Persona mit ihrem Verlauf zurück.';

  @override
  String get deletedPersonasShow => 'Gelöschte Personas anzeigen';

  @override
  String get deletedPersonasLoadFailed =>
      'Die gelöschten Personas konnten nicht geladen werden.';

  @override
  String get deletedPersonasEmpty => 'Keine gelöschten Personas.';

  @override
  String deletedPersonaDeletedAt(String date) {
    return 'Gelöscht am $date';
  }

  @override
  String deletedPersonaUseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mal verwendet',
      one: 'Einmal verwendet',
    );
    return '$_temp0';
  }

  @override
  String get deletedPersonaRestore => 'Wiederherstellen';

  @override
  String personaRestored(String name) {
    return '$name ist zurück.';
  }

  @override
  String personaRestoredWithout(String items) {
    return 'Ohne $items wiederhergestellt: Eine andere Persona hat sie jetzt.';
  }

  @override
  String get personaRestoreFailed =>
      'Die Persona konnte nicht wiederhergestellt werden.';

  @override
  String deletedPersonaRestoreLabel(String name) {
    return '$name wiederherstellen';
  }
}
