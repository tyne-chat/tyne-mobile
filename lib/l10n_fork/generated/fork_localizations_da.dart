// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class ForkLocalizationsDa extends ForkLocalizations {
  ForkLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Skift persona';

  @override
  String get chatAttachmentPanelVoice => 'Stemme';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Knap til hurtigskifter';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Erstat knappen til stemmemeddelelser i beskedfeltet med en hurtigskifter for nemmere navigation';

  @override
  String get userSettingsCheckForUpdates => 'Søg efter opdateringer';

  @override
  String get userSettingsCheckingForUpdates => 'Søger efter opdateringer…';

  @override
  String get userSettingsAppUpToDate => 'Tyne er opdateret';

  @override
  String get userSettingsUpdateAvailableTitle => 'Opdatering tilgængelig';

  @override
  String get userSettingsUpdateDownloadAction => 'Download og installer';

  @override
  String get userSettingsUpdateInstallAction => 'Installer opdatering';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Downloader opdatering ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Kunne ikke søge efter eller downloade opdatering.';

  @override
  String get personaSelectTitle => 'Vælg persona';

  @override
  String get personaSettingsHeader => 'Personaindstillinger';

  @override
  String get personaManageAction => 'Administrer';

  @override
  String get personaSearchPlaceholder =>
      'Søg efter personaer, tags, pronominer...';

  @override
  String get personaModeManual => 'Manuel';

  @override
  String get personaModeLast => 'Senest brugt';

  @override
  String get personaModeManualDescription =>
      'Sender altid som den valgte persona, indtil det ændres.';

  @override
  String get personaModeLastDescription =>
      'Skifter automatisk til den persona, der blev brugt i din sidste besked.';

  @override
  String get personaRecentHeader => 'SENASTE PERSONAER';

  @override
  String personaAllHeader(int count) {
    return 'ALLE PERSONAER ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'SØGERESULTATER ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Hovedkonto (standard)';

  @override
  String get personaEmptyState =>
      'Ingen personaer konfigureret endnu. Opret en via Administrer personaer.';

  @override
  String get personaEmptySearch => 'Fandt ingen matchende personaer.';

  @override
  String get personaEditTitle => 'Rediger persona';

  @override
  String get personaCreateTitle => 'Opret persona';

  @override
  String get personaDisplayNameLabel => 'Visningsnavn';

  @override
  String get personaPronounsLabel => 'Pronominer';

  @override
  String get personaPronounsHint => 'f.eks. de/dem';

  @override
  String get personaBioHint => 'Fortæl andre om denne persona...';

  @override
  String get personaUpdatedToast => 'Persona opdateret';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Kunne ikke opdatere persona: $error';
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
    return 'Slår op som $name';
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
      'Konfigurer din aktive persona-tilstand, dit brugerdefinerede visningstag, og administrer individuelle personaer.';

  @override
  String get personaDisplayTagSection => 'Visningstag';

  @override
  String get personaDisplayTagDescription =>
      'Visningstagget vises ved siden af alle personanavne i beskeder. Hvis der ikke er angivet et visningstag, vises din kontos profilbillede.';

  @override
  String get personaDisplayTagLabel => 'Visningstag-tekst';

  @override
  String get personaDisplayTagHint => 'f.eks. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Ikon for visningstag';

  @override
  String get personaUploadTagIcon => 'Upload ikon';

  @override
  String get personaChangeTagIcon => 'Skift ikon';

  @override
  String get personaRemoveTagIcon => 'Fjern ikon';

  @override
  String get personaChatPreviewTitle => 'Forhåndsvisning af chat';

  @override
  String get personaChatPreviewSampleMessage =>
      'Hej! Dette er en forhåndsvisning af, hvordan beskeder ser ud med dit visningstag og din aktive persona.';

  @override
  String get personaListTitle => 'Konfigurerede personaer';

  @override
  String get personaAddButton => 'Tilføj persona';

  @override
  String get personaActiveBadge => 'Aktiv';

  @override
  String get personaMakeActive => 'Gør aktiv';

  @override
  String get personaDeleteTitle => 'Slet persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Er du sikker på, at du vil slette \"$name\"? Dette kan ikke fortrydes.';
  }

  @override
  String get personaDeleteConfirm => 'Slet';

  @override
  String get personaDeletedToast => 'Persona slettet';

  @override
  String get personaCreatedToast => 'Persona oprettet';

  @override
  String personaCreateFailedToast(String error) {
    return 'Kunne ikke oprette persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Skift avatar';

  @override
  String get personaRemoveAvatar => 'Fjern avatar';

  @override
  String get personaUploadAvatar => 'Upload avatar';

  @override
  String get personaTagsLabel => 'Persona-tags';

  @override
  String get personaTagPrefixLabel => 'Præfiks';

  @override
  String get personaTagSuffixLabel => 'Suffiks';

  @override
  String get personaVisibilityLabel => 'Synlighed';

  @override
  String get personaVisibilityUnlisted => 'Skjult';

  @override
  String get personaVisibilityPublic => 'Offentlig';

  @override
  String get personaVisibilityPrivate => 'Privat';

  @override
  String get personaNameRequired =>
      'Indtast venligst et visningsnavn for personaen';

  @override
  String get personaNameTooLong =>
      'Personaens visningsnavn må højst være på 100 tegn';

  @override
  String get personaTagPrefixTooLong =>
      'Persona-tagpræfiks må højst være på 32 tegn';

  @override
  String get personaTagSuffixTooLong =>
      'Persona-tagsuffiks må højst være på 32 tegn';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Tagget \'$tag\' er allerede i brug af \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Indsæt tidsstempel';

  @override
  String get chatAttachmentSendVoiceMessage => 'Send talebesked';

  @override
  String get timestampPickerTitle => 'Indsæt tidsstempel';

  @override
  String get timestampPickerInsert => 'Indsæt';

  @override
  String get timestampCopied => 'Tidsstempel kopieret';

  @override
  String get timestampPickerTimeLabel => 'Tid';

  @override
  String get timestampPickerDateLabel => 'DATO';

  @override
  String get timestampPickerTimeSectionLabel => 'TIDSPUNKT';

  @override
  String get timestampPickerTimezoneLabel => 'TIDSZONE';

  @override
  String get timestampPickerFormatPreviewLabel => 'FORMATFORHÅNDSVISNING';

  @override
  String get timestampPickerNlpPlaceholder =>
      'f.eks. i morgen kl. 15, om 2 timer, nu';

  @override
  String get timestampPickerSearchTimezones => 'Søg efter tidszoner...';

  @override
  String get userProfileTimezoneSettingLabel => 'Tidszone';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Bruges til at vise din lokale tid på din profil.';

  @override
  String get userProfileTimezoneNone => 'Ingen';

  @override
  String get chatReactAs => 'Reager som...';

  @override
  String get emojiCopy => 'Kopiér emoji';

  @override
  String get emojiCopyLink => 'Kopiér link';

  @override
  String get emojiPin => 'Fastgør emoji';

  @override
  String get emojiUnpin => 'Frigør emoji';

  @override
  String get emojiPinForPersona => 'Fastgør for denne persona';

  @override
  String get emojiUnpinForPersona => 'Frigør for denne persona';

  @override
  String get personaSignatureEmojisLabel => 'Signatur-emojis';

  @override
  String get personaSignatureEmojisDescription =>
      'Reaktion med en signatur-emoji vil altid reagere som denne persona, uanset aktiv persona.';

  @override
  String get personaAddSignatureEmoji => 'Tilføj emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Denne emoji er allerede tilføjet som en signatur-emoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Signatur-emoji bruges allerede af personaen \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Fjern signatur-emoji';

  @override
  String get signalBarLabel => 'Signalbjælke';

  @override
  String get signalBarShow => 'Vis signalbjælke';

  @override
  String get signalBarHide => 'Skjul signalbjælke';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Ingen har dette signal slået til';

  @override
  String get signalBarReset => 'Nulstil signal for alle';

  @override
  String signalBarTurnOff(String name) {
    return 'Slå $name fra';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Brug $domain til standardinstansen, eller den nøjagtige URL til en anden instans.';
  }

  @override
  String get instanceResetToDefault => 'Nulstil til standardinstansen';

  @override
  String get personaScopeTitle => 'Persona gælder for';

  @override
  String get personaScopeGlobal => 'Overalt';

  @override
  String get personaScopeGlobalDescription => 'Én persona for alle kanaler.';

  @override
  String get personaScopeChannel => 'I hver kanal';

  @override
  String get personaScopeChannelDescription =>
      'Hver kanal beholder sin egen persona. Nye kanaler starter som din konto.';

  @override
  String get personaPickerChannelOnly => 'Kun for denne kanal';

  @override
  String get personaProfilePrivate => 'Denne personas profil er privat.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Billedfilen er for stor. Vælg venligst en fil, der er mindre end $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Søg i KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Opdateringen kunne ikke downloades';

  @override
  String get appUpdateInstallFailed => 'Opdateringen kunne ikke installeres';

  @override
  String get personaChangeMessageFailed =>
      'Beskedens persona kunne ikke ændres';

  @override
  String get personaActiveCleared => 'Aktiv persona ryddet';

  @override
  String get klipyPoweredBy => 'Leveret af KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Tagparret \'$pattern\' findes allerede på denne persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Tilføj tagpar ($count/5)';
  }

  @override
  String get personaTagExampleText => 'tekst';

  @override
  String get personaPreviewNameFallback => 'Bruger';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne lukkede uventet. Deling af anonyme nedbruds- og fejldata hjælper os med at rette problemer hurtigere.';

  @override
  String get crashReportingSectionDescription =>
      'Hjælp med at rette fejl i Tyne ved at dele nedbruds- og ydeevnedata. Dette er slået fra som standard.';

  @override
  String get crashReportingDescription =>
      'Rapporter sendes til Tynes egen fejlsporing, også når du er logget ind på en anden instans. De indeholder ikke instansnavne, id\'er eller beskedindhold.';

  @override
  String get instanceOfflineTitle => 'Tyne er offline!';

  @override
  String get instanceOfflineBody => 'Vi undersøger det.';

  @override
  String get instanceStatusSignalLink =>
      'Deltag i vores Signal-chat for at få opdateringer';

  @override
  String get convertEmoticonsLabel => 'Erstat tekstsmileyer med emojis';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Kunne ikke køre /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Scriptet har et problem.';

  @override
  String guildCommandOneLine(String name) {
    return 'Det, du skriver efter /$name, skal kunne være på én linje.';
  }

  @override
  String get permissionCreateCommands => 'Opret kommandoer';

  @override
  String get permissionManageCommands => 'Administrer kommandoer';

  @override
  String get permissionUseExternalCommands => 'Brug eksterne kommandoer';

  @override
  String get permissionCreateCommandsDescription =>
      'Opret kommandoer til dette fællesskab, og rediger eller slet dine egne.';

  @override
  String get permissionManageCommandsDescription =>
      'Rediger eller slet alles kommandoer i dette fællesskab.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Brug kommandoer fra andre fællesskaber.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Brug kommandoer fra andre fællesskaber i denne kanal.';

  @override
  String get guildSettingsCategoryMessageTools => 'Beskedværktøjer';

  @override
  String get guildSettingsCommands => 'Kommandoer';

  @override
  String get guildCommandsLoadFailed => 'Kunne ikke indlæse kommandoerne.';

  @override
  String get guildCommandsSubtitle =>
      'Beskeder, som medlemmer kan sende ved at skrive /name.';

  @override
  String get guildCommandsSlots => 'Kommandopladser';

  @override
  String get guildCommandsNew => 'Ny kommando';

  @override
  String get guildCommandsSearch => 'Søg efter kommandoer';

  @override
  String get guildCommandsEmptyTitle => 'Ingen kommandoer';

  @override
  String get guildCommandsEmptyBody =>
      'Dette fællesskab har ingen kommandoer endnu.';

  @override
  String get guildCommandsSaved => 'Kommandoer gemt';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Kunne ikke gemme /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Rediger /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Slet /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Det kan ikke fortrydes. Beskeder lavet med den viser stadig, hvilken kommando der lavede dem.';

  @override
  String get guildCommandDelete => 'Slet';

  @override
  String get guildCommandDeleteCommand => 'Slet kommando';

  @override
  String get guildCommandSectionCommand => 'Kommando';

  @override
  String get guildCommandName => 'Navn';

  @override
  String get guildCommandNameInvalid =>
      'Brug små bogstaver, tal, - og _, højst 32 tegn.';

  @override
  String get guildCommandNameTaken =>
      'En anden kommando eller en indbygget kommando har allerede dette navn.';

  @override
  String get guildCommandDescription => 'Beskrivelse';

  @override
  String get guildCommandSectionInput => 'Indtastning';

  @override
  String get guildCommandInputNone => 'Ingen';

  @override
  String get guildCommandInputOptional => 'Valgfri';

  @override
  String get guildCommandInputRequired => 'Påkrævet';

  @override
  String get guildCommandHint => 'Tip';

  @override
  String get guildCommandMessage => 'Besked';

  @override
  String get guildCommandInsert => 'Indsæt:';

  @override
  String get guildCommandInsertPerson => 'Den, der bruger den';

  @override
  String get guildCommandInsertInput => 'Det, de skriver';

  @override
  String get guildCommandPreview => 'Forhåndsvisning';

  @override
  String get guildCommandSampleInput => 'Eksempeltekst';

  @override
  String guildCommandMadeWith(String name) {
    return 'Lavet med /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Tøm beskedfeltet for at bruge /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Dette ville ikke sende noget, så kommandoen ville mislykkes.';

  @override
  String get guildCommandUseScriptEditor => 'Brug scripteditoren';

  @override
  String get guildCommandUseBasicEditor => 'Brug den enkle editor';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Kør igen';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Der findes intet tag med navnet $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Der findes intet filter med navnet $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name bliver aldrig lukket.';
  }

  @override
  String get guildCommandIssueTooLong => 'Scriptet er for langt.';

  @override
  String get guildCommandIssueTooLarge => 'Scriptet laver for meget tekst.';

  @override
  String get guildCommandIssueTooSlow => 'Scriptet var for længe om at køre.';

  @override
  String get guildCommandIssueInvalid => 'Denne del kan ikke læses.';

  @override
  String get guildCommandIssueFailed => 'Denne del stoppede med en fejl.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Linje $line, kolonne $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Scriptreference';

  @override
  String get guildCommandReferencePerson => 'Den, der bruger den, som omtale';

  @override
  String get guildCommandReferencePersonName => 'Navnet på den, der bruger den';

  @override
  String get guildCommandReferenceTarget =>
      'Den første person, de omtaler, hvis der er en';

  @override
  String get guildCommandReferenceTargetName => 'Navnet på den person';

  @override
  String get guildCommandReferenceChannel => 'Kanalen som omtale';

  @override
  String get guildCommandReferenceCommunity => 'Navnet på dette fællesskab';

  @override
  String get guildCommandExampleRandom => 'Vælg en tilfældig mulighed';

  @override
  String get guildCommandExampleDepends =>
      'Tilpas beskeden efter det, de skrev';

  @override
  String get guildCommandExampleOneWord => 'Vælg et tilfældigt ord';

  @override
  String get guildCommandExampleWordForNumber => 'Vælg ordet efter et tal';

  @override
  String get guildCommandExampleOrdinal => 'Skriv et tal som 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Komplet scriptguide';

  @override
  String get guildCommandCounters => 'Tællere';

  @override
  String get guildCommandCounterAdd => 'Tilføj tæller';

  @override
  String get guildCommandCounterSeparately => 'Tæl separat for hver:';

  @override
  String get guildCommandCounterPersonMentioned => 'Nævnt person';

  @override
  String get guildCommandCounterChannel => 'Kanal';

  @override
  String get guildCommandCounterPersonas => 'Tæl personaer separat';

  @override
  String get guildCommandCounterRemove => 'Fjern tæller';

  @override
  String get guildCommandCounterReset => 'Nulstil optællinger';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Vil du nulstille optællingerne for $name? Dette kan ikke fortrydes.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Brug små bogstaver, tal og _, start med et bogstav, og brug ikke et navn, scripts allerede bruger.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Brug den i et script som $variable. Hver kørsel lægger først én til, så den første kørsel læser 1.';
  }
}
