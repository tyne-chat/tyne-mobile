// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class ForkLocalizationsSv extends ForkLocalizations {
  ForkLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Byt persona';

  @override
  String get chatAttachmentPanelVoice => 'Röst';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'Snabbväxlarknapp';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Ersätt knappen för röstmeddelande i inmatningsfältet med en snabbväxlare för smidig navigering';

  @override
  String get userSettingsCheckForUpdates => 'Sök efter uppdateringar';

  @override
  String get userSettingsCheckingForUpdates => 'Söker efter uppdateringar…';

  @override
  String get userSettingsAppUpToDate => 'Tyne är uppdaterad';

  @override
  String get userSettingsUpdateAvailableTitle => 'Uppdatering tillgänglig';

  @override
  String get userSettingsUpdateDownloadAction => 'Ladda ner och installera';

  @override
  String get userSettingsUpdateInstallAction => 'Installera uppdatering';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Laddar ner uppdatering ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Kunde inte söka efter eller ladda ner uppdatering.';

  @override
  String get personaSelectTitle => 'Välj persona';

  @override
  String get personaSettingsHeader => 'Personainställningar';

  @override
  String get personaManageAction => 'Hantera';

  @override
  String get personaSearchPlaceholder => 'Sök personas, taggar, pronomen...';

  @override
  String get personaModeManual => 'Manuellt';

  @override
  String get personaModeLast => 'Senast använd';

  @override
  String get personaModeManualDescription =>
      'Skickar alltid som vald persona tills det ändras.';

  @override
  String get personaModeLastDescription =>
      'Växlar automatiskt till den persona som användes i ditt senaste meddelande.';

  @override
  String get personaRecentHeader => 'SENASTE PERSONAS';

  @override
  String personaAllHeader(int count) {
    return 'ALLA PERSONAS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'SÖKRESULTAT ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Huvudkonto (standard)';

  @override
  String get personaEmptyState =>
      'Inga personas har konfigurerats än. Skapa en via Hantera personas.';

  @override
  String get personaEmptySearch => 'Hittade inga matchande personas.';

  @override
  String get personaEditTitle => 'Redigera persona';

  @override
  String get personaCreateTitle => 'Skapa persona';

  @override
  String get personaDisplayNameLabel => 'Visningsnamn';

  @override
  String get personaPronounsLabel => 'Pronomen';

  @override
  String get personaPronounsHint => 't.ex. hen/henom';

  @override
  String get personaBioHint => 'Berätta för andra om denna persona...';

  @override
  String get personaUpdatedToast => 'Persona uppdaterad';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Kunde inte uppdatera persona: $error';
  }

  @override
  String get personaSectionTitle => 'Personas';

  @override
  String get personaDisplayNameHint => 'Personanamn';

  @override
  String personaSendingAsTag(String name) {
    return 'Skickar som $name (matchad av tagg)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Skickar som $name (låst)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Skickar som $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Publicerar som $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Skickar som @$username';
  }

  @override
  String get personaMainAccount => 'Huvudkonto';

  @override
  String get personaEditPersona => 'Redigera persona';

  @override
  String get userSettingsNavPersonas => 'Personas';

  @override
  String get personaSettingsDescription =>
      'Konfigurera ditt aktiva persona-läge, anpassade visningstagg och hantera enskilda personas.';

  @override
  String get personaDisplayTagSection => 'Visningstagg';

  @override
  String get personaDisplayTagDescription =>
      'Visningstaggen visas bredvid alla personanamn i meddelanden. Om ingen visningstagg anges, visas din kontoprofilbild.';

  @override
  String get personaDisplayTagLabel => 'Visningstaggtext';

  @override
  String get personaDisplayTagHint => 't.ex. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Ikon för visningstagg';

  @override
  String get personaUploadTagIcon => 'Ladda upp ikon';

  @override
  String get personaChangeTagIcon => 'Ändra ikon';

  @override
  String get personaRemoveTagIcon => 'Ta bort ikon';

  @override
  String get personaChatPreviewTitle => 'Förhandsvisning av chatt';

  @override
  String get personaChatPreviewSampleMessage =>
      'Hej! Detta är en förhandsvisning av hur meddelanden ser ut med din visningstagg och aktiva persona.';

  @override
  String get personaListTitle => 'Konfigurerade personas';

  @override
  String get personaAddButton => 'Lägg till persona';

  @override
  String get personaActiveBadge => 'Aktiv';

  @override
  String get personaMakeActive => 'Sätt som aktiv';

  @override
  String get personaDeleteTitle => 'Ta bort persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Är du säker på att du vill ta bort \"$name\"? Detta kan inte ångras.';
  }

  @override
  String get personaDeleteConfirm => 'Ta bort';

  @override
  String get personaDeletedToast => 'Persona borttagen';

  @override
  String get personaCreatedToast => 'Persona skapad';

  @override
  String personaCreateFailedToast(String error) {
    return 'Kunde inte skapa persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Ändra avatar';

  @override
  String get personaRemoveAvatar => 'Ta bort avatar';

  @override
  String get personaUploadAvatar => 'Ladda upp avatar';

  @override
  String get personaTagsLabel => 'Personataggar';

  @override
  String get personaAutoTagDisabledLabel =>
      'Känn inte igen den här personans taggar';

  @override
  String get personaAutoTagDisabledDescription =>
      'Om du skriver en av de här taggarna byter du inte till den här personan. Taggen skickas som den är skriven.';

  @override
  String get personaTagPrefixLabel => 'Prefix';

  @override
  String get personaTagSuffixLabel => 'Suffix';

  @override
  String get personaVisibilityLabel => 'Synlighet';

  @override
  String get personaVisibilityUnlisted => 'Olistad';

  @override
  String get personaVisibilityPublic => 'Offentlig';

  @override
  String get personaVisibilityPrivate => 'Privat';

  @override
  String get personaNameRequired => 'Ange ett visningsnamn för personan';

  @override
  String get personaNameTooLong =>
      'Personans visningsnamn får vara högst 100 tecken';

  @override
  String get personaTagPrefixTooLong =>
      'Personataggens prefix får vara högst 32 tecken';

  @override
  String get personaTagSuffixTooLong =>
      'Personataggens suffix får vara högst 32 tecken';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Taggen \'$tag\' används redan av \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Infoga tidsstämpel';

  @override
  String get chatAttachmentSendVoiceMessage => 'Skicka röstmeddelande';

  @override
  String get timestampPickerTitle => 'Infoga tidsstämpel';

  @override
  String get timestampPickerInsert => 'Infoga';

  @override
  String get timestampCopied => 'Tidsstämpel kopierad';

  @override
  String get timestampPickerTimeLabel => 'Tid';

  @override
  String get timestampPickerDateLabel => 'DATUM';

  @override
  String get timestampPickerTimeSectionLabel => 'TID';

  @override
  String get timestampPickerTimezoneLabel => 'TIDSZON';

  @override
  String get timestampPickerFormatPreviewLabel => 'FÖRHANDSVISNING AV FORMAT';

  @override
  String get timestampPickerNlpPlaceholder =>
      't.ex. imorgon kl 15, om 2 timmar, nu';

  @override
  String get timestampPickerSearchTimezones => 'Sök tidszoner...';

  @override
  String get userProfileTimezoneSettingLabel => 'Tidszon';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Används för att visa din lokala tid på din profil.';

  @override
  String get userProfileTimezoneNone => 'Ingen';

  @override
  String get chatReactAs => 'Reagera som...';

  @override
  String get emojiCopy => 'Kopiera emoji';

  @override
  String get emojiCopyLink => 'Kopiera länk';

  @override
  String get emojiPin => 'Fäst emoji';

  @override
  String get emojiUnpin => 'Lossa emoji';

  @override
  String get emojiPinForPersona => 'Fäst för denna persona';

  @override
  String get emojiUnpinForPersona => 'Lossa för denna persona';

  @override
  String get personaSignatureEmojisLabel => 'Signaturemojier';

  @override
  String get personaSignatureEmojisDescription =>
      'Att reagera med en signaturemoji reagerar alltid som den här personan, oavsett aktiv persona.';

  @override
  String get personaAddSignatureEmoji => 'Lägg till emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Den här emojin har redan lagts till som en signaturemoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Signaturemojin används redan av personan \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Ta bort signaturemoji';

  @override
  String get signalBarLabel => 'Signalfält';

  @override
  String get signalBarShow => 'Visa signalfältet';

  @override
  String get signalBarHide => 'Dölj signalfältet';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Ingen har den här signalen på';

  @override
  String get signalBarReset => 'Återställ signalen för alla';

  @override
  String signalBarTurnOff(String name) {
    return 'Stäng av $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Använd $domain för standardinstansen, eller den exakta URL:en till en annan instans.';
  }

  @override
  String get instanceResetToDefault => 'Återställ till standardinstansen';

  @override
  String get personaScopeTitle => 'Persona gäller för';

  @override
  String get personaScopeGlobal => 'Överallt';

  @override
  String get personaScopeGlobalDescription => 'En persona för alla kanaler.';

  @override
  String get personaScopeChannel => 'I varje kanal';

  @override
  String get personaScopeChannelDescription =>
      'Varje kanal behåller sin egen persona. Nya kanaler börjar som ditt konto.';

  @override
  String get personaPickerChannelOnly => 'Endast för den här kanalen';

  @override
  String get personaProfilePrivate => 'Den här personans profil är privat.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Bildfilen är för stor. Välj en fil som är mindre än $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Sök KLIPY';

  @override
  String get appUpdateDownloadFailed =>
      'Det gick inte att ladda ned uppdateringen';

  @override
  String get appUpdateInstallFailed =>
      'Det gick inte att installera uppdateringen';

  @override
  String get personaChangeMessageFailed =>
      'Det gick inte att ändra meddelandets persona';

  @override
  String get personaActiveCleared => 'Aktiv persona rensad';

  @override
  String get klipyPoweredBy => 'Drivs av KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Dubblett av taggparet \'$pattern\' på denna persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Lägg till taggpar ($count/5)';
  }

  @override
  String get personaTagExampleText => 'text';

  @override
  String get personaPreviewNameFallback => 'Användare';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne stängdes oväntat. Genom att dela anonym krasch- och feldata hjälper du oss att åtgärda problem snabbare.';

  @override
  String get crashReportingSectionDescription =>
      'Hjälp till att åtgärda buggar i Tyne genom att dela krasch- och prestandadata. Detta är avstängt som standard.';

  @override
  String get crashReportingDescription =>
      'Rapporter skickas till Tynes egen felspårning, även när du är inloggad på en annan instans. De innehåller inga instansnamn, ID:n eller meddelandeinnehåll.';

  @override
  String get instanceOfflineTitle => 'Tyne är offline!';

  @override
  String get instanceOfflineBody => 'Vi undersöker saken.';

  @override
  String get instanceStatusSignalLink =>
      'Gå med i vår Signal-chatt för uppdateringar';

  @override
  String get convertEmoticonsLabel => 'Ersätt textsmileys med emojier';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Kunde inte köra /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Skriptet har ett problem.';

  @override
  String guildCommandOneLine(String name) {
    return 'Det du skriver efter /$name måste få plats på en rad.';
  }

  @override
  String get permissionCreateCommands => 'Skapa kommandon';

  @override
  String get permissionManageCommands => 'Hantera kommandon';

  @override
  String get permissionUseExternalCommands => 'Använd externa kommandon';

  @override
  String get permissionCreateCommandsDescription =>
      'Skapa kommandon för den här communityn och redigera eller ta bort dina egna.';

  @override
  String get permissionManageCommandsDescription =>
      'Redigera eller ta bort vems kommandon som helst i den här communityn.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Använd kommandon från andra communities.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Använd kommandon från andra communities i den här kanalen.';

  @override
  String get guildSettingsCategoryMessageTools => 'Meddelandeverktyg';

  @override
  String get guildSettingsCommands => 'Kommandon';

  @override
  String get guildCommandsLoadFailed => 'Kunde inte läsa in kommandona.';

  @override
  String get guildCommandsSubtitle =>
      'Meddelanden som medlemmar kan skicka genom att skriva /name.';

  @override
  String get guildCommandsSlots => 'Kommandoplatser';

  @override
  String get guildCommandsNew => 'Nytt kommando';

  @override
  String get guildCommandsSearch => 'Sök bland kommandon';

  @override
  String get guildCommandsEmptyTitle => 'Inga kommandon';

  @override
  String get guildCommandsEmptyBody =>
      'Den här communityn har inga kommandon än.';

  @override
  String get guildCommandsSaved => 'Kommandon sparade';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Kunde inte spara /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Redigera /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Ta bort /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Det här kan inte ångras. Meddelanden som gjorts med det visar fortfarande vilket kommando som gjorde dem.';

  @override
  String get guildCommandDelete => 'Ta bort';

  @override
  String get guildCommandDeleteCommand => 'Ta bort kommando';

  @override
  String get guildCommandSectionCommand => 'Kommando';

  @override
  String get guildCommandName => 'Namn';

  @override
  String get guildCommandNameInvalid =>
      'Använd gemener, siffror, - och _, högst 32 tecken.';

  @override
  String get guildCommandNameTaken =>
      'Ett annat kommando eller ett inbyggt kommando har redan det här namnet.';

  @override
  String get guildCommandDescription => 'Beskrivning';

  @override
  String get guildCommandSectionInput => 'Inmatning';

  @override
  String get guildCommandInputNone => 'Ingen';

  @override
  String get guildCommandInputOptional => 'Valfri';

  @override
  String get guildCommandInputRequired => 'Obligatoriskt';

  @override
  String get guildCommandHint => 'Tips';

  @override
  String get guildCommandMessage => 'Meddelande';

  @override
  String get guildCommandInsert => 'Infoga:';

  @override
  String get guildCommandInsertPerson => 'Den som använder det';

  @override
  String get guildCommandInsertInput => 'Det de skriver';

  @override
  String get guildCommandPreview => 'Förhandsgranska';

  @override
  String get guildCommandSampleInput => 'Exempeltext';

  @override
  String guildCommandMadeWith(String name) {
    return 'Gjort med /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Töm meddelanderutan för att använda /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Det här skulle inte skicka något, så kommandot skulle misslyckas.';

  @override
  String get guildCommandUseScriptEditor => 'Använd skriptredigeraren';

  @override
  String get guildCommandUseBasicEditor => 'Använd den enkla redigeraren';

  @override
  String get guildCommandScript => 'Skript';

  @override
  String get guildCommandRunAgain => 'Kör igen';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Det finns ingen tagg som heter $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Det finns inget filter som heter $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name stängs aldrig.';
  }

  @override
  String get guildCommandIssueTooLong => 'Skriptet är för långt.';

  @override
  String get guildCommandIssueTooLarge => 'Skriptet skapar för mycket text.';

  @override
  String get guildCommandIssueTooSlow => 'Skriptet tog för lång tid att köra.';

  @override
  String get guildCommandIssueInvalid => 'Den här delen går inte att läsa.';

  @override
  String get guildCommandIssueFailed => 'Den här delen stoppades av ett fel.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Rad $line, kolumn $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Skriptreferens';

  @override
  String get guildCommandReferencePerson =>
      'Den som använder det, som omnämnande';

  @override
  String get guildCommandReferencePersonName =>
      'Namnet på den som använder det';

  @override
  String get guildCommandReferenceTarget =>
      'Den första personen de nämner, om det finns någon';

  @override
  String get guildCommandReferenceTargetName => 'Namnet på den personen';

  @override
  String get guildCommandReferenceChannel => 'Kanalen, som omnämnande';

  @override
  String get guildCommandReferenceCommunity => 'Namnet på den här communityn';

  @override
  String get guildCommandExampleRandom => 'Välj ett slumpmässigt alternativ';

  @override
  String get guildCommandExampleDepends =>
      'Anpassa meddelandet efter vad de skrev';

  @override
  String get guildCommandExampleOneWord => 'Välj ett slumpmässigt ord';

  @override
  String get guildCommandExampleWordForNumber => 'Välj ordet efter ett tal';

  @override
  String get guildCommandExampleOrdinal => 'Skriv ett tal som 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Fullständig skriptguide';

  @override
  String get guildCommandCounters => 'Räknare';

  @override
  String get guildCommandCounterAdd => 'Lägg till räknare';

  @override
  String get guildCommandCounterSeparately => 'Räkna separat för varje:';

  @override
  String get guildCommandCounterPersonMentioned => 'Nämnd person';

  @override
  String get guildCommandCounterChannel => 'Kanal';

  @override
  String get guildCommandCounterPersonas => 'Räkna personor separat';

  @override
  String get guildCommandCounterRemove => 'Ta bort räknare';

  @override
  String get guildCommandCounterReset => 'Återställ antal';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Vill du återställa antalen för $name? Det går inte att ångra.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Använd små bokstäver, siffror och _, börja med en bokstav och välj inget namn som skript redan använder.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Använd den i ett skript som $variable. Varje körning lägger först till ett, så den första läser 1.';
  }
}
