// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class ForkLocalizationsNb extends ForkLocalizations {
  ForkLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Endre persona';

  @override
  String get chatAttachmentPanelVoice => 'Tale';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Knapp for hurtigbytter';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Erstatt talemeldingsknappen i meldingsfeltet med en hurtigbytter for enklere navigering';

  @override
  String get userSettingsCheckForUpdates => 'Se etter oppdateringer';

  @override
  String get userSettingsCheckingForUpdates => 'Ser etter oppdateringer…';

  @override
  String get userSettingsAppUpToDate => 'Tyne er oppdatert';

  @override
  String get userSettingsUpdateAvailableTitle => 'Oppdatering tilgjengelig';

  @override
  String get userSettingsUpdateDownloadAction => 'Last ned og installer';

  @override
  String get userSettingsUpdateInstallAction => 'Installer oppdatering';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Laster ned oppdatering ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Kunne ikke søke etter eller laste ned oppdatering.';

  @override
  String get personaSelectTitle => 'Velg persona';

  @override
  String get personaSettingsHeader => 'Personainnstillinger';

  @override
  String get personaManageAction => 'Administrer';

  @override
  String get personaSearchPlaceholder =>
      'Søk etter personaer, tagger, pronomen...';

  @override
  String get personaModeManual => 'Manuell';

  @override
  String get personaModeLast => 'Sist brukt';

  @override
  String get personaModeManualDescription =>
      'Sender alltid som valgt persona til det endres.';

  @override
  String get personaModeLastDescription =>
      'Bytter automatisk til personaen som ble brukt i den siste meldingen din.';

  @override
  String get personaRecentHeader => 'NYLIGE PERSONAER';

  @override
  String personaAllHeader(int count) {
    return 'ALLE PERSONAER ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'SØKERESULTATER ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Hovedkonto (standard)';

  @override
  String get personaEmptyState =>
      'Ingen personaer er konfigurert ennå. Opprett en via Administrer personaer.';

  @override
  String get personaEmptySearch => 'Ingen samsvarende personaer funnet.';

  @override
  String get personaEditTitle => 'Rediger persona';

  @override
  String get personaCreateTitle => 'Opprett persona';

  @override
  String get personaDisplayNameLabel => 'Visningsnavn';

  @override
  String get personaPronounsLabel => 'Pronomen';

  @override
  String get personaPronounsHint => 'f.eks. de/dem';

  @override
  String get personaBioHint => 'Fortell andre om denne personaen...';

  @override
  String get personaUpdatedToast => 'Persona oppdatert';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Kunne ikke oppdatere persona: $error';
  }

  @override
  String get personaSectionTitle => 'Personaer';

  @override
  String get personaDisplayNameHint => 'Personanavn';

  @override
  String personaSendingAsTag(String name) {
    return 'Sender som $name (matchet via tag)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Sender som $name (låst)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Sender som $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Publiserer som $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Sender som @$username';
  }

  @override
  String get personaMainAccount => 'Hovedkonto';

  @override
  String get personaEditPersona => 'Rediger persona';

  @override
  String get userSettingsNavPersonas => 'Personaer';

  @override
  String get personaSettingsDescription =>
      'Konfigurer din aktive personamodus, tilpassede visningstag og administrer individuelle personaer.';

  @override
  String get personaDisplayTagSection => 'Visningstag';

  @override
  String get personaDisplayTagDescription =>
      'Visningstag vil vises ved siden av alle personanavn i meldinger. Hvis ingen visningstag er angitt, vises kontoprofilbildet ditt.';

  @override
  String get personaDisplayTagLabel => 'Visningstag-tekst';

  @override
  String get personaDisplayTagHint => 'f.eks. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Ikon for visningstag';

  @override
  String get personaUploadTagIcon => 'Last opp ikon';

  @override
  String get personaChangeTagIcon => 'Endre ikon';

  @override
  String get personaRemoveTagIcon => 'Fjern ikon';

  @override
  String get personaChatPreviewTitle => 'Forhåndsvisning av chat';

  @override
  String get personaChatPreviewSampleMessage =>
      'Hei! Dette er en forhåndsvisning av hvordan meldinger ser ut med din visningstag og aktive persona.';

  @override
  String get personaListTitle => 'Konfigurerte personaer';

  @override
  String get personaAddButton => 'Legg til persona';

  @override
  String get personaActiveBadge => 'Aktiv';

  @override
  String get personaMakeActive => 'Sett som aktiv';

  @override
  String get personaDeleteTitle => 'Slett persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Er du sikker på at du vil slette «$name»? Dette kan ikke angres.';
  }

  @override
  String get personaDeleteConfirm => 'Slett';

  @override
  String get personaDeletedToast => 'Persona slettet';

  @override
  String get personaCreatedToast => 'Persona opprettet';

  @override
  String personaCreateFailedToast(String error) {
    return 'Kunne ikke opprette persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Endre avatar';

  @override
  String get personaRemoveAvatar => 'Fjern avatar';

  @override
  String get personaUploadAvatar => 'Last opp avatar';

  @override
  String get personaTagsLabel => 'Personatagger';

  @override
  String get personaAutoTagDisabledLabel =>
      'Ikke gjenkjenn taggene til denne personaen';

  @override
  String get personaAutoTagDisabledDescription =>
      'Hvis du skriver en av disse taggene, byttes det ikke til denne personaen. Taggen sendes slik den er skrevet.';

  @override
  String get personaTagPrefixLabel => 'Prefiks';

  @override
  String get personaTagSuffixLabel => 'Suffiks';

  @override
  String get personaVisibilityLabel => 'Synlighet';

  @override
  String get personaVisibilityUnlisted => 'Uoppført';

  @override
  String get personaVisibilityPublic => 'Offentlig';

  @override
  String get personaVisibilityPrivate => 'Privat';

  @override
  String get personaNameRequired =>
      'Vennligst oppgi et visningsnavn for personaen';

  @override
  String get personaNameTooLong =>
      'Visningsnavnet for personaen kan maksimalt være 100 tegn';

  @override
  String get personaTagPrefixTooLong =>
      'Persona-taggprefikset kan maksimalt være 32 tegn';

  @override
  String get personaTagSuffixTooLong =>
      'Persona-taggsuffikset kan maksimalt være 32 tegn';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Taggen \'$tag\' er allerede i bruk av \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Sett inn tidsstempel';

  @override
  String get chatAttachmentSendVoiceMessage => 'Send talemelding';

  @override
  String get timestampPickerTitle => 'Sett inn tidsstempel';

  @override
  String get timestampPickerInsert => 'Sett inn';

  @override
  String get timestampCopied => 'Tidsstempel kopiert';

  @override
  String get timestampPickerTimeLabel => 'Tid';

  @override
  String get timestampPickerDateLabel => 'DATO';

  @override
  String get timestampPickerTimeSectionLabel => 'TID';

  @override
  String get timestampPickerTimezoneLabel => 'TIDSSONE';

  @override
  String get timestampPickerFormatPreviewLabel => 'FORHÅNDSVISNING AV FORMAT';

  @override
  String get timestampPickerNlpPlaceholder =>
      'f.eks. i morgen kl 15, om 2 timer, nå';

  @override
  String get timestampPickerSearchTimezones => 'Søk etter tidssoner...';

  @override
  String get userProfileTimezoneSettingLabel => 'Tidssone';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Brukes til å vise din lokale tid på profilen din.';

  @override
  String get userProfileTimezoneNone => 'Ingen';

  @override
  String get chatReactAs => 'Reager som...';

  @override
  String get emojiCopy => 'Kopier emoji';

  @override
  String get emojiCopyLink => 'Kopier lenke';

  @override
  String get emojiPin => 'Fest emoji';

  @override
  String get emojiUnpin => 'Løsne emoji';

  @override
  String get emojiPinForPersona => 'Fest for denne personaen';

  @override
  String get emojiUnpinForPersona => 'Løsne for denne personaen';

  @override
  String get personaSignatureEmojisLabel => 'Signaturemojier';

  @override
  String get personaSignatureEmojisDescription =>
      'Reaksjon med en signaturemoji vil alltid reagere som denne personaen, uavhengig av aktiv persona.';

  @override
  String get personaAddSignatureEmoji => 'Legg til emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Denne emojien er allerede lagt til som en signaturemoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Signaturemojien brukes allerede av personaen «$name»';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Fjern signaturemoji';

  @override
  String get signalBarLabel => 'Signallinje';

  @override
  String get signalBarShow => 'Vis signallinje';

  @override
  String get signalBarHide => 'Skjul signallinje';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Ingen har dette signalet på';

  @override
  String get signalBarReset => 'Tilbakestill signalet for alle';

  @override
  String signalBarTurnOff(String name) {
    return 'Slå av $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Bruk $domain for standardinstansen, eller den nøyaktige URL-en til en annen instans.';
  }

  @override
  String get instanceResetToDefault => 'Tilbakestill til standardinstansen';

  @override
  String get personaScopeTitle => 'Persona gjelder for';

  @override
  String get personaScopeGlobal => 'Overalt';

  @override
  String get personaScopeGlobalDescription => 'Én persona for alle kanaler.';

  @override
  String get personaScopeChannel => 'I hver kanal';

  @override
  String get personaScopeChannelDescription =>
      'Hver kanal beholder sin egen persona. Nye kanaler starter som kontoen din.';

  @override
  String get personaPickerChannelOnly => 'Bare for denne kanalen';

  @override
  String get personaProfilePrivate => 'Profilen til denne personaen er privat.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Bildefilen er for stor. Velg en fil som er mindre enn $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Søk i KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Kunne ikke laste ned oppdateringen';

  @override
  String get appUpdateInstallFailed => 'Kunne ikke installere oppdateringen';

  @override
  String get personaChangeMessageFailed =>
      'Kunne ikke endre meldingens persona';

  @override
  String get personaActiveCleared => 'Aktiv persona fjernet';

  @override
  String get klipyPoweredBy => 'Levert av KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Duplisert tag-par \'$pattern\' på denne personaen';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Legg til tag-par ($count/5)';
  }

  @override
  String get personaTagExampleText => 'tekst';

  @override
  String get personaPreviewNameFallback => 'Bruker';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne ble lukket uventet. Deling av anonyme krasj- og feildata hjelper oss med å rette problemer raskere.';

  @override
  String get crashReportingSectionDescription =>
      'Hjelp til med å rette feil i Tyne ved å dele krasj- og ytelsesdata. Dette er av som standard.';

  @override
  String get crashReportingDescription =>
      'Rapporter sendes til Tynes egen feilsporing, også når du er logget inn på en annen instans. De inneholder ikke instansnavn, ID-er eller meldingsinnhold.';

  @override
  String get instanceOfflineTitle => 'Tyne er frakoblet!';

  @override
  String get instanceOfflineBody => 'Vi undersøker saken.';

  @override
  String get instanceStatusSignalLink =>
      'Bli med i Signal-chatten vår for oppdateringer';

  @override
  String get convertEmoticonsLabel => 'Gjør tekstsmilefjes om til emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Kunne ikke kjøre /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Skriptet har et problem.';

  @override
  String guildCommandOneLine(String name) {
    return 'Det du skriver etter /$name, må få plass på én linje.';
  }

  @override
  String get permissionCreateCommands => 'Opprett kommandoer';

  @override
  String get permissionManageCommands => 'Administrer kommandoer';

  @override
  String get permissionUseExternalCommands => 'Bruk eksterne kommandoer';

  @override
  String get permissionCreateCommandsDescription =>
      'Opprett kommandoer for dette fellesskapet, og rediger eller slett dine egne.';

  @override
  String get permissionManageCommandsDescription =>
      'Rediger eller slett alles kommandoer i dette fellesskapet.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Bruk kommandoer fra andre fellesskap.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Bruk kommandoer fra andre fellesskap i denne kanalen.';

  @override
  String get guildSettingsCategoryMessageTools => 'Meldingsverktøy';

  @override
  String get guildSettingsCommands => 'Kommandoer';

  @override
  String get guildCommandsLoadFailed => 'Kunne ikke laste inn kommandoene.';

  @override
  String get guildCommandsSubtitle =>
      'Meldinger medlemmer kan sende ved å skrive /name.';

  @override
  String get guildCommandsSlots => 'Kommandoplasser';

  @override
  String get guildCommandsNew => 'Ny kommando';

  @override
  String get guildCommandsSearch => 'Søk etter kommandoer';

  @override
  String get guildCommandsEmptyTitle => 'Ingen kommandoer';

  @override
  String get guildCommandsEmptyBody =>
      'Dette fellesskapet har ingen kommandoer ennå.';

  @override
  String get guildCommandsSaved => 'Kommandoer lagret';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Kunne ikke lagre /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Rediger /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Slette /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Dette kan ikke angres. Meldinger laget med den viser fortsatt hvilken kommando som laget dem.';

  @override
  String get guildCommandDelete => 'Slett';

  @override
  String get guildCommandDeleteCommand => 'Slett kommando';

  @override
  String get guildCommandSectionCommand => 'Kommando';

  @override
  String get guildCommandName => 'Navn';

  @override
  String get guildCommandNameInvalid =>
      'Bruk små bokstaver, tall, - og _, høyst 32 tegn.';

  @override
  String get guildCommandNameTaken =>
      'En annen kommando eller en innebygd kommando har allerede dette navnet.';

  @override
  String get guildCommandDescription => 'Beskrivelse';

  @override
  String get guildCommandSectionInput => 'Inndata';

  @override
  String get guildCommandInputNone => 'Ingen';

  @override
  String get guildCommandInputOptional => 'Valgfritt';

  @override
  String get guildCommandInputRequired => 'Påkrevd';

  @override
  String get guildCommandHint => 'Tips';

  @override
  String get guildCommandMessage => 'Melding';

  @override
  String get guildCommandInsert => 'Sett inn:';

  @override
  String get guildCommandInsertPerson => 'Den som bruker den';

  @override
  String get guildCommandInsertInput => 'Det de skriver';

  @override
  String get guildCommandPreview => 'Forhåndsvisning';

  @override
  String get guildCommandSampleInput => 'Eksempeltekst';

  @override
  String guildCommandMadeWith(String name) {
    return 'Laget med /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Tøm meldingsfeltet for å bruke /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Dette ville ikke sende noe, så kommandoen ville mislykkes.';

  @override
  String get guildCommandUseScriptEditor => 'Bruk skriptredigering';

  @override
  String get guildCommandUseBasicEditor => 'Bruk enkel redigering';

  @override
  String get guildCommandScript => 'Skript';

  @override
  String get guildCommandRunAgain => 'Kjør igjen';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Det finnes ingen tagg som heter $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Det finnes ikke noe filter som heter $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name blir aldri lukket.';
  }

  @override
  String get guildCommandIssueTooLong => 'Skriptet er for langt.';

  @override
  String get guildCommandIssueTooLarge => 'Skriptet lager for mye tekst.';

  @override
  String get guildCommandIssueTooSlow =>
      'Skriptet brukte for lang tid på å kjøre.';

  @override
  String get guildCommandIssueInvalid => 'Denne delen kan ikke leses.';

  @override
  String get guildCommandIssueFailed => 'Denne delen stoppet med en feil.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Linje $line, kolonne $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Skriptreferanse';

  @override
  String get guildCommandReferencePerson => 'Den som bruker den, som omtale';

  @override
  String get guildCommandReferencePersonName => 'Navnet på den som bruker den';

  @override
  String get guildCommandReferenceTarget =>
      'Den første personen de omtaler, hvis det er noen';

  @override
  String get guildCommandReferenceTargetName => 'Navnet på den personen';

  @override
  String get guildCommandReferenceChannel => 'Kanalen som omtale';

  @override
  String get guildCommandReferenceCommunity => 'Navnet på dette fellesskapet';

  @override
  String get guildCommandExampleRandom => 'Velg et tilfeldig alternativ';

  @override
  String get guildCommandExampleDepends =>
      'Tilpass meldingen etter det de skrev';

  @override
  String get guildCommandExampleOneWord => 'Velg et tilfeldig ord';

  @override
  String get guildCommandExampleWordForNumber => 'Velg ordet etter et tall';

  @override
  String get guildCommandExampleOrdinal => 'Skriv et tall som 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Fullstendig skriptguide';

  @override
  String get guildCommandCounters => 'Tellere';

  @override
  String get guildCommandCounterAdd => 'Legg til teller';

  @override
  String get guildCommandCounterSeparately => 'Tell separat for hver:';

  @override
  String get guildCommandCounterPersonMentioned => 'Nevnt person';

  @override
  String get guildCommandCounterChannel => 'Kanal';

  @override
  String get guildCommandCounterPersonas => 'Tell personaer separat';

  @override
  String get guildCommandCounterRemove => 'Fjern teller';

  @override
  String get guildCommandCounterReset => 'Nullstill tellinger';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Vil du nullstille tellingene for $name? Dette kan ikke angres.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Bruk små bokstaver, tall og _, start med en bokstav, og ikke bruk et navn skript allerede bruker.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Bruk den i et skript som $variable. Hver kjøring legger først til én, så den første leser 1.';
  }
}
