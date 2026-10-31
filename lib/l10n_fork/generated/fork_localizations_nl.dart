// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class ForkLocalizationsNl extends ForkLocalizations {
  ForkLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Persona wijzigen';

  @override
  String get chatAttachmentPanelVoice => 'Spraak';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'Snelschakelaar-knop';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Vervang de spraakbericht-knop in het invoerveld door een snelschakelaar voor snelle navigatie';

  @override
  String get userSettingsCheckForUpdates => 'Controleren op updates';

  @override
  String get userSettingsCheckingForUpdates => 'Controleren op updates…';

  @override
  String get userSettingsAppUpToDate => 'Tyne is up-to-date';

  @override
  String get userSettingsUpdateAvailableTitle => 'Update beschikbaar';

  @override
  String get userSettingsUpdateDownloadAction => 'Downloaden & installeren';

  @override
  String get userSettingsUpdateInstallAction => 'Update installeren';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Update downloaden ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Kan niet controleren op of downloaden van update.';

  @override
  String get personaSelectTitle => 'Persona kiezen';

  @override
  String get personaSettingsHeader => 'Persona-instellingen';

  @override
  String get personaManageAction => 'Beheren';

  @override
  String get personaSearchPlaceholder =>
      'Zoek persona\'s, tags, voornaamwoorden...';

  @override
  String get personaModeManual => 'Handmatig';

  @override
  String get personaModeLast => 'Laatst gebruikt';

  @override
  String get personaModeManualDescription =>
      'Verzendt altijd als geselecteerde persona totdat dit wordt gewijzigd.';

  @override
  String get personaModeLastDescription =>
      'Schakelt automatisch over naar de persona die in je laatste bericht is gebruikt.';

  @override
  String get personaRecentHeader => 'RECENTE PERSONA\'S';

  @override
  String personaAllHeader(int count) {
    return 'ALLE PERSONA\'S ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'ZOEKRESULTATEN ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Hoofdaccount (Standaard)';

  @override
  String get personaEmptyState =>
      'Nog geen persona\'s geconfigureerd. Maak er een aan via Persona\'s beheren.';

  @override
  String get personaEmptySearch => 'Geen overeenkomende persona\'s gevonden.';

  @override
  String get personaEditTitle => 'Persona bewerken';

  @override
  String get personaCreateTitle => 'Persona aanmaken';

  @override
  String get personaDisplayNameLabel => 'Weergavenaam';

  @override
  String get personaPronounsLabel => 'Voornaamwoorden';

  @override
  String get personaPronounsHint => 'bijv. die/hen';

  @override
  String get personaBioHint => 'Vertel anderen over deze persona...';

  @override
  String get personaUpdatedToast => 'Persona bijgewerkt';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Kon persona niet bijwerken: $error';
  }

  @override
  String get personaSectionTitle => 'Persona\'s';

  @override
  String get personaDisplayNameHint => 'Personanaam';

  @override
  String personaSendingAsTag(String name) {
    return 'Verzenden als $name (Gekoppeld via tag)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Verzenden als $name (Vastgezet)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Verzenden als $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Plaatsen als $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Verzenden als @$username';
  }

  @override
  String get personaMainAccount => 'Hoofdaccount';

  @override
  String get personaEditPersona => 'Persona bewerken';

  @override
  String get userSettingsNavPersonas => 'Persona\'s';

  @override
  String get personaSettingsDescription =>
      'Configureer je actieve persona-modus, aangepaste weergavetag en beheer individuele persona\'s.';

  @override
  String get personaDisplayTagSection => 'Weergavetag';

  @override
  String get personaDisplayTagDescription =>
      'De weergavetag verschijnt naast alle personanamen in berichten. Als er geen weergavetag is ingesteld, wordt de profielfoto van je account weergegeven.';

  @override
  String get personaDisplayTagLabel => 'Tekst van weergavetag';

  @override
  String get personaDisplayTagHint => 'bijv. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Pictogram van weergavetag';

  @override
  String get personaUploadTagIcon => 'Pictogram uploaden';

  @override
  String get personaChangeTagIcon => 'Pictogram wijzigen';

  @override
  String get personaRemoveTagIcon => 'Pictogram verwijderen';

  @override
  String get personaChatPreviewTitle => 'Chatvoorbeeld';

  @override
  String get personaChatPreviewSampleMessage =>
      'Hallo! Dit is een voorbeeld van hoe berichten eruitzien met je weergavetag en actieve persona.';

  @override
  String get personaListTitle => 'Geconfigureerde persona\'s';

  @override
  String get personaAddButton => 'Persona toevoegen';

  @override
  String get personaActiveBadge => 'Actief';

  @override
  String get personaMakeActive => 'Als actief instellen';

  @override
  String get personaDeleteTitle => 'Persona verwijderen';

  @override
  String personaDeleteMessage(String name) {
    return 'Weet je zeker dat je \"$name\" wilt verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get personaDeleteConfirm => 'Verwijderen';

  @override
  String get personaDeletedToast => 'Persona verwijderd';

  @override
  String get personaCreatedToast => 'Persona aangemaakt';

  @override
  String personaCreateFailedToast(String error) {
    return 'Kon persona niet aanmaken: $error';
  }

  @override
  String get personaChangeAvatar => 'Avatar wijzigen';

  @override
  String get personaRemoveAvatar => 'Avatar verwijderen';

  @override
  String get personaUploadAvatar => 'Avatar uploaden';

  @override
  String get personaTagsLabel => 'Persona-tags';

  @override
  String get personaAutoTagDisabledLabel =>
      'Tags van deze persona niet herkennen';

  @override
  String get personaAutoTagDisabledDescription =>
      'Als je een van deze tags typt, wissel je niet naar deze persona. De tag wordt verzonden zoals die is geschreven.';

  @override
  String get personaTagPrefixLabel => 'Voorvoegsel';

  @override
  String get personaTagSuffixLabel => 'Achtervoegsel';

  @override
  String get personaVisibilityLabel => 'Zichtbaarheid';

  @override
  String get personaVisibilityUnlisted => 'Niet vermeld';

  @override
  String get personaVisibilityPublic => 'Openbaar';

  @override
  String get personaVisibilityPrivate => 'Privé';

  @override
  String get personaNameRequired => 'Voer een weergavenaam voor de persona in';

  @override
  String get personaNameTooLong =>
      'Weergavenaam van persona mag maximaal 100 tekens bevatten';

  @override
  String get personaTagPrefixTooLong =>
      'Persona-tagvoorvoegsel mag maximaal 32 tekens bevatten';

  @override
  String get personaTagSuffixTooLong =>
      'Persona-tagachtervoegsel mag maximaal 32 tekens bevatten';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'De tag \'$tag\' is al in gebruik door \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Tijdstempel invoegen';

  @override
  String get chatAttachmentSendVoiceMessage => 'Spraakbericht verzenden';

  @override
  String get timestampPickerTitle => 'Tijdstempel invoegen';

  @override
  String get timestampPickerInsert => 'Invoegen';

  @override
  String get timestampCopied => 'Tijdstempel gekopieerd';

  @override
  String get timestampPickerTimeLabel => 'Tijd';

  @override
  String get timestampPickerDateLabel => 'DATUM';

  @override
  String get timestampPickerTimeSectionLabel => 'TIJD';

  @override
  String get timestampPickerTimezoneLabel => 'TIJDZONE';

  @override
  String get timestampPickerFormatPreviewLabel => 'VOORBEELD VAN FORMAT';

  @override
  String get timestampPickerNlpPlaceholder =>
      'bijv. morgen om 15:00, over 2 uur, nu';

  @override
  String get timestampPickerSearchTimezones => 'Tijdzones zoeken...';

  @override
  String get userProfileTimezoneSettingLabel => 'Tijdzone';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Wordt gebruikt om uw lokale tijd op uw profiel te tonen.';

  @override
  String get userProfileTimezoneNone => 'Geen';

  @override
  String get chatReactAs => 'Reageren als...';

  @override
  String get emojiCopy => 'Emoji kopiëren';

  @override
  String get emojiCopyLink => 'Link kopiëren';

  @override
  String get emojiPin => 'Emoji vastpinnen';

  @override
  String get emojiUnpin => 'Emoji losmaken';

  @override
  String get emojiPinForPersona => 'Vastpinnen voor deze persona';

  @override
  String get emojiUnpinForPersona => 'Losmaken voor deze persona';

  @override
  String get personaSignatureEmojisLabel => 'Handtekening-emoji\'s';

  @override
  String get personaSignatureEmojisDescription =>
      'Reageren met een handtekening-emoji reageert altijd als deze persona, ongeacht de actieve persona.';

  @override
  String get personaAddSignatureEmoji => 'Emoji toevoegen';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Deze emoji is al toegevoegd als handtekening-emoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Handtekening-emoji is al in gebruik door persona \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Handtekening-emoji verwijderen';

  @override
  String get signalBarLabel => 'Signaalbalk';

  @override
  String get signalBarShow => 'Signaalbalk tonen';

  @override
  String get signalBarHide => 'Signaalbalk verbergen';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Niemand heeft dit signaal aan staan';

  @override
  String get signalBarReset => 'Signaal voor iedereen resetten';

  @override
  String signalBarTurnOff(String name) {
    return '$name uitzetten';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Gebruik $domain voor de standaardinstantie, of de exacte URL van een andere instantie.';
  }

  @override
  String get instanceResetToDefault => 'Terugzetten naar standaardinstantie';

  @override
  String get personaScopeTitle => 'Persona geldt voor';

  @override
  String get personaScopeGlobal => 'Overal';

  @override
  String get personaScopeGlobalDescription => 'Eén persona voor alle kanalen.';

  @override
  String get personaScopeChannel => 'In elk kanaal';

  @override
  String get personaScopeChannelDescription =>
      'Elk kanaal houdt zijn eigen persona. Nieuwe kanalen beginnen als je account.';

  @override
  String get personaPickerChannelOnly => 'Alleen voor dit kanaal';

  @override
  String get personaProfilePrivate => 'Het profiel van deze persona is privé.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Bestand te groot. Kies een bestand van minder dan $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Zoek KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Update downloaden mislukt';

  @override
  String get appUpdateInstallFailed => 'Update installeren mislukt';

  @override
  String get personaChangeMessageFailed =>
      'Persona van bericht wijzigen mislukt';

  @override
  String get personaActiveCleared => 'Actieve persona gewist';

  @override
  String get klipyPoweredBy => 'Mogelijk gemaakt door KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Dubbel tagpaar \'$pattern\' bij deze persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Tagpaar toevoegen ($count/5)';
  }

  @override
  String get personaTagExampleText => 'tekst';

  @override
  String get personaPreviewNameFallback => 'Gebruiker';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne is onverwacht afgesloten. Door anonieme crash- en foutgegevens te delen, kunnen we problemen sneller oplossen.';

  @override
  String get crashReportingSectionDescription =>
      'Help bugs in Tyne op te lossen door crash- en prestatiegegevens te delen. Dit staat standaard uit.';

  @override
  String get crashReportingDescription =>
      'Rapporten gaan naar de eigen foutentracker van Tyne, ook als je bij een andere instantie bent ingelogd. Ze bevatten geen instantienamen, ID\'s of berichtinhoud.';

  @override
  String get instanceOfflineTitle => 'Tyne is offline!';

  @override
  String get instanceOfflineBody => 'We zoeken het uit.';

  @override
  String get instanceStatusSignalLink =>
      'Doe mee met onze Signal-chat voor updates';

  @override
  String get convertEmoticonsLabel => 'Zet tekstsmileys om in emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Kon /$name niet uitvoeren: $detail';
  }

  @override
  String get guildCommandBroken => 'Het script heeft een probleem.';

  @override
  String guildCommandOneLine(String name) {
    return 'Wat je na /$name typt, moet op één regel passen.';
  }

  @override
  String get permissionCreateCommands => 'Opdrachten maken';

  @override
  String get permissionManageCommands => 'Opdrachten beheren';

  @override
  String get permissionUseExternalCommands => 'Externe opdrachten gebruiken';

  @override
  String get permissionCreateCommandsDescription =>
      'Opdrachten voor deze community maken, en je eigen opdrachten bewerken of verwijderen.';

  @override
  String get permissionManageCommandsDescription =>
      'Opdrachten van iedereen in deze community bewerken of verwijderen.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Opdrachten uit andere community\'s gebruiken.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Opdrachten uit andere community\'s in dit kanaal gebruiken.';

  @override
  String get guildSettingsCategoryMessageTools => 'Berichthulpmiddelen';

  @override
  String get guildSettingsCommands => 'Opdrachten';

  @override
  String get guildCommandsLoadFailed => 'Kon de opdrachten niet laden.';

  @override
  String get guildCommandsSubtitle =>
      'Berichten die leden kunnen plaatsen door /name te typen.';

  @override
  String get guildCommandsSlots => 'Opdrachtplaatsen';

  @override
  String get guildCommandsNew => 'Nieuwe opdracht';

  @override
  String get guildCommandsSearch => 'Opdrachten zoeken';

  @override
  String get guildCommandsEmptyTitle => 'Geen opdrachten';

  @override
  String get guildCommandsEmptyBody =>
      'Deze community heeft nog geen opdrachten.';

  @override
  String get guildCommandsSaved => 'Opdrachten opgeslagen';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Kon /$name niet opslaan: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return '/$name bewerken';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return '/$name verwijderen?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Dit kan niet ongedaan worden gemaakt. Berichten die ermee zijn gemaakt, laten nog steeds zien met welke opdracht ze zijn gemaakt.';

  @override
  String get guildCommandDelete => 'Verwijderen';

  @override
  String get guildCommandDeleteCommand => 'Opdracht verwijderen';

  @override
  String get guildCommandSectionCommand => 'Opdracht';

  @override
  String get guildCommandName => 'Naam';

  @override
  String get guildCommandNameInvalid =>
      'Gebruik kleine letters, cijfers, - en _, maximaal 32 tekens.';

  @override
  String get guildCommandNameTaken =>
      'Een andere opdracht of een ingebouwde opdracht heeft deze naam al.';

  @override
  String get guildCommandDescription => 'Beschrijving';

  @override
  String get guildCommandSectionInput => 'Invoer';

  @override
  String get guildCommandInputNone => 'Geen';

  @override
  String get guildCommandInputOptional => 'Optioneel';

  @override
  String get guildCommandInputRequired => 'Vereist';

  @override
  String get guildCommandHint => 'Aanwijzing';

  @override
  String get guildCommandMessage => 'Bericht';

  @override
  String get guildCommandInsert => 'Invoegen:';

  @override
  String get guildCommandInsertPerson => 'Wie hem gebruikt';

  @override
  String get guildCommandInsertInput => 'Wat ze typen';

  @override
  String get guildCommandPreview => 'Voorbeeld';

  @override
  String get guildCommandSampleInput => 'Voorbeeldinvoer';

  @override
  String guildCommandMadeWith(String name) {
    return 'Gemaakt met /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Maak het berichtvak leeg om /$name te gebruiken';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Dit zou niets plaatsen, dus de opdracht zou mislukken.';

  @override
  String get guildCommandUseScriptEditor => 'Scripteditor gebruiken';

  @override
  String get guildCommandUseBasicEditor => 'Basiseditor gebruiken';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Opnieuw uitvoeren';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Er is geen tag met de naam $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Er is geen filter met de naam $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name wordt nooit afgesloten.';
  }

  @override
  String get guildCommandIssueTooLong => 'Het script is te lang.';

  @override
  String get guildCommandIssueTooLarge => 'Het script maakt te veel tekst.';

  @override
  String get guildCommandIssueTooSlow => 'Het script deed er te lang over.';

  @override
  String get guildCommandIssueInvalid => 'Dit deel kan niet worden gelezen.';

  @override
  String get guildCommandIssueFailed => 'Dit deel is gestopt met een fout.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Regel $line, kolom $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Scriptreferentie';

  @override
  String get guildCommandReferencePerson => 'Wie hem gebruikt, als vermelding';

  @override
  String get guildCommandReferencePersonName => 'De naam van wie hem gebruikt';

  @override
  String get guildCommandReferenceTarget =>
      'De eerste persoon die wordt vermeld, als die er is';

  @override
  String get guildCommandReferenceTargetName => 'De naam van die persoon';

  @override
  String get guildCommandReferenceChannel => 'Het kanaal, als vermelding';

  @override
  String get guildCommandReferenceCommunity => 'De naam van deze community';

  @override
  String get guildCommandExampleRandom => 'Een willekeurige optie kiezen';

  @override
  String get guildCommandExampleDepends =>
      'Het bericht aanpassen aan wat er is getypt';

  @override
  String get guildCommandExampleOneWord => 'Een willekeurig woord kiezen';

  @override
  String get guildCommandExampleWordForNumber =>
      'Het woord bij een getal kiezen';

  @override
  String get guildCommandExampleOrdinal =>
      'Een getal schrijven als 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Volledige scriptgids';

  @override
  String get guildCommandCounters => 'Tellers';

  @override
  String get guildCommandCounterAdd => 'Teller toevoegen';

  @override
  String get guildCommandCounterSeparately => 'Apart tellen voor elke:';

  @override
  String get guildCommandCounterPersonMentioned => 'Genoemde persoon';

  @override
  String get guildCommandCounterChannel => 'Kanaal';

  @override
  String get guildCommandCounterPersonas => 'Persona’s apart tellen';

  @override
  String get guildCommandCounterRemove => 'Teller verwijderen';

  @override
  String get guildCommandCounterReset => 'Tellingen resetten';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Tellingen van $name resetten? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Gebruik kleine letters, cijfers en _, begin met een letter en kies geen naam die scripts al gebruiken.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Gebruik hem in een script als $variable. Elke uitvoering telt eerst één op, dus de eerste leest 1.';
  }
}
