// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class ForkLocalizationsSl extends ForkLocalizations {
  ForkLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Zamenjaj persono';

  @override
  String get chatAttachmentPanelVoice => 'Glasovno';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Gumb za hitri preklopnik';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Gumb za glasovno sporočilo v polju za vnos zamenjajte z gumbom za hitri preklopnik, da se hitreje premikate po aplikaciji';

  @override
  String get userSettingsCheckForUpdates => 'Preveri posodobitve';

  @override
  String get userSettingsCheckingForUpdates => 'Preverjanje posodobitev …';

  @override
  String get userSettingsAppUpToDate => 'Aplikacija Tyne je posodobljena';

  @override
  String get userSettingsUpdateAvailableTitle => 'Na voljo je posodobitev';

  @override
  String get userSettingsUpdateDownloadAction => 'Prenesi in namesti';

  @override
  String get userSettingsUpdateInstallAction => 'Namesti posodobitev';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Prenašanje posodobitve ($percent %) …';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Posodobitve ni bilo mogoče preveriti ali prenesti.';

  @override
  String get personaSelectTitle => 'Izberite persono';

  @override
  String get personaSettingsHeader => 'Nastavitve person';

  @override
  String get personaManageAction => 'Upravljaj';

  @override
  String get personaSearchPlaceholder => 'Iščite persone, oznake, zaimke …';

  @override
  String get personaModeManual => 'Ročno';

  @override
  String get personaModeLast => 'Nazadnje uporabljena';

  @override
  String get personaModeManualDescription =>
      'Vedno pošilja kot izbrana persona, dokler je ne zamenjate.';

  @override
  String get personaModeLastDescription =>
      'Samodejno preklopi na persono, uporabljeno v vašem zadnjem sporočilu.';

  @override
  String get personaRecentHeader => 'NEDAVNE PERSONE';

  @override
  String personaAllHeader(int count) {
    return 'VSE PERSONE ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'REZULTATI ISKANJA ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Glavni račun (privzeto)';

  @override
  String get personaEmptyState =>
      'Persone še niso nastavljene. Ustvarite prvo z gumbom Upravljaj.';

  @override
  String get personaEmptySearch => 'Ni najdenih ustreznih person.';

  @override
  String get personaEditTitle => 'Uredi persono';

  @override
  String get personaCreateTitle => 'Ustvari persono';

  @override
  String get personaDisplayNameLabel => 'Prikazno ime';

  @override
  String get personaPronounsLabel => 'Zaimki';

  @override
  String get personaPronounsHint => 'npr. oni/njihov';

  @override
  String get personaBioHint => 'Povejte drugim nekaj o tej personi …';

  @override
  String get personaUpdatedToast => 'Persona je posodobljena';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Persone ni bilo mogoče posodobiti: $error';
  }

  @override
  String get personaSectionTitle => 'Persone';

  @override
  String get personaDisplayNameHint => 'Ime persone';

  @override
  String personaSendingAsTag(String name) {
    return 'Pošiljate kot $name (prepoznana po oznaki)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Pošiljate kot $name (ohranjena)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Pošiljate kot $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Objavljate kot $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Pošiljate kot @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'Ni poslano: vaše persone se še niso naložile.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Ni poslano: vaše persone se še niso naložile. Želite sporočilo poslati kot @$username?';
  }

  @override
  String get personaSendAsAccountAction => 'Vseeno pošlji';

  @override
  String get personaMainAccount => 'Glavni račun';

  @override
  String get personaEditPersona => 'Uredi persono';

  @override
  String get userSettingsNavPersonas => 'Persone';

  @override
  String get personaSettingsDescription =>
      'Nastavite način aktivne persone in svojo prikazno oznako ter upravljajte posamezne persone.';

  @override
  String get personaDisplayTagSection => 'Prikazna oznaka';

  @override
  String get personaDisplayTagDescription =>
      'Prikazna oznaka bo v sporočilih prikazana ob imenih vseh person. Če prikazna oznaka ni nastavljena, bo prikazana profilna slika vašega računa.';

  @override
  String get personaDisplayTagLabel => 'Besedilo prikazne oznake';

  @override
  String get personaDisplayTagHint => 'npr. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Ikona prikazne oznake';

  @override
  String get personaUploadTagIcon => 'Naloži ikono';

  @override
  String get personaChangeTagIcon => 'Zamenjaj ikono';

  @override
  String get personaRemoveTagIcon => 'Odstrani ikono';

  @override
  String get personaChatPreviewTitle => 'Predogled klepeta';

  @override
  String get personaChatPreviewSampleMessage =>
      'Živijo! Tako so videti sporočila z vašo prikazno oznako in aktivno persono.';

  @override
  String get personaListTitle => 'Nastavljene persone';

  @override
  String get personaAddButton => 'Dodaj persono';

  @override
  String get personaActiveBadge => 'Aktivna';

  @override
  String get personaMakeActive => 'Nastavi kot aktivno';

  @override
  String get personaDeleteTitle => 'Izbriši persono';

  @override
  String personaDeleteMessage(String name) {
    return 'Ali ste prepričani, da želite izbrisati „$name“? Izbrisane persone lahko pozneje obnovite pod Izbrisane persone (Nastavitve › Persone).';
  }

  @override
  String get personaDeleteConfirm => 'Izbriši';

  @override
  String get personaDeletedToast => 'Persona je izbrisana';

  @override
  String get personaCreatedToast => 'Persona je ustvarjena';

  @override
  String personaCreateFailedToast(String error) {
    return 'Persone ni bilo mogoče ustvariti: $error';
  }

  @override
  String get personaChangeAvatar => 'Zamenjaj avatar';

  @override
  String get personaRemoveAvatar => 'Odstrani avatar';

  @override
  String get personaUploadAvatar => 'Naloži avatar';

  @override
  String get personaTagsLabel => 'Oznake persone';

  @override
  String get personaAutoTagDisabledLabel => 'Ne prepoznavaj oznak te persone';

  @override
  String get personaAutoTagDisabledDescription =>
      'Če vpišete eno od teh oznak, aplikacija ne preklopi na to persono. Oznaka se pošlje tako, kot je napisana.';

  @override
  String get personaTagPrefixLabel => 'Predpona';

  @override
  String get personaTagSuffixLabel => 'Pripona';

  @override
  String get personaVisibilityLabel => 'Vidnost';

  @override
  String get personaVisibilityUnlisted => 'Nenavedeno';

  @override
  String get personaVisibilityPublic => 'Javno';

  @override
  String get personaVisibilityPrivate => 'Zasebno';

  @override
  String get personaNameRequired => 'Vnesite prikazno ime persone';

  @override
  String get personaNameTooLong =>
      'Prikazno ime persone ima lahko največ 100 znakov';

  @override
  String get personaTagPrefixTooLong =>
      'Predpona oznake persone ima lahko največ 32 znakov';

  @override
  String get personaTagSuffixTooLong =>
      'Pripona oznake persone ima lahko največ 32 znakov';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Oznako „$tag“ že uporablja „$name“.';
  }

  @override
  String get chatInsertTimestamp => 'Vstavi časovni žig';

  @override
  String get chatAttachmentSendVoiceMessage => 'Pošlji glasovno sporočilo';

  @override
  String get timestampPickerTitle => 'Vstavi časovni žig';

  @override
  String get timestampPickerInsert => 'Vstavi';

  @override
  String get timestampCopied => 'Časovni žig je kopiran';

  @override
  String get timestampPickerTimeLabel => 'Čas';

  @override
  String get timestampPickerDateLabel => 'DATUM';

  @override
  String get timestampPickerTimeSectionLabel => 'ČAS';

  @override
  String get timestampPickerTimezoneLabel => 'ČASOVNI PAS';

  @override
  String get timestampPickerFormatPreviewLabel => 'PREDOGLED OBLIKE';

  @override
  String get timestampPickerNlpPlaceholder =>
      'npr. tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'Iščite časovne pasove …';

  @override
  String get userProfileTimezoneSettingLabel => 'Časovni pas';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Uporablja se za prikaz vašega lokalnega časa na profilu.';

  @override
  String get userProfileTimezoneNone => 'Brez';

  @override
  String get chatReactAs => 'Odzovi se kot …';

  @override
  String get emojiCopy => 'Kopiraj emoji';

  @override
  String get emojiCopyLink => 'Kopiraj povezavo';

  @override
  String get emojiPin => 'Pripni emoji';

  @override
  String get emojiUnpin => 'Odpni emoji';

  @override
  String get emojiPinForPersona => 'Pripni za to persono';

  @override
  String get emojiUnpinForPersona => 'Odpni za to persono';

  @override
  String get personaSignatureEmojisLabel => 'Prepoznavni emojiji';

  @override
  String get personaSignatureEmojisDescription =>
      'Z odzivom s prepoznavnim emojijem se vedno odzovete kot ta persona, ne glede na aktivno persono.';

  @override
  String get personaAddSignatureEmoji => 'Dodaj emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Ta emoji je že dodan kot prepoznavni emoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Prepoznavni emoji že uporablja persona „$name“';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Odstrani prepoznavni emoji';

  @override
  String get signalBarLabel => 'Vrstica signalov';

  @override
  String get signalBarShow => 'Pokaži vrstico signalov';

  @override
  String get signalBarHide => 'Skrij vrstico signalov';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Nihče nima vklopljenega tega signala';

  @override
  String get signalBarReset => 'Ponastavi signal za vse';

  @override
  String signalBarTurnOff(String name) {
    return 'Izklopi signal za $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Za privzeto instanco uporabite $domain, za drugo instanco pa njen točen URL.';
  }

  @override
  String get instanceResetToDefault => 'Ponastavi na privzeto instanco';

  @override
  String get personaScopeTitle => 'Kje velja persona';

  @override
  String get personaScopeGlobal => 'Povsod';

  @override
  String get personaScopeGlobalDescription => 'Ena persona za vse kanale.';

  @override
  String get personaScopeChannel => 'V vsakem kanalu';

  @override
  String get personaScopeChannelDescription =>
      'Vsak kanal ohrani svojo persono. V novih kanalih sprva pišete v imenu svojega računa.';

  @override
  String get personaPickerChannelOnly => 'Samo za ta kanal';

  @override
  String get personaProfilePrivate => 'Profil te persone je zaseben.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Slikovna datoteka je prevelika. Izberite datoteko, manjšo od $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Iskanje v KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Posodobitve ni bilo mogoče prenesti';

  @override
  String get appUpdateInstallFailed => 'Posodobitve ni bilo mogoče namestiti';

  @override
  String get personaChangeMessageFailed =>
      'Persone sporočila ni bilo mogoče zamenjati';

  @override
  String get personaActiveCleared => 'Aktivna persona ni več izbrana';

  @override
  String get klipyPoweredBy => 'Poganja KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Podvojen par oznak „$pattern“ pri tej personi';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Dodaj par oznak ($count/5)';
  }

  @override
  String get personaTagExampleText => 'besedilo';

  @override
  String get personaPreviewNameFallback => 'Uporabnik';

  @override
  String get crashReportingConsentSubtitle =>
      'Aplikacija Tyne se je nepričakovano zaprla. Če delite anonimne podatke o sesutjih in napakah, nam pomagate hitreje odpravljati težave.';

  @override
  String get crashReportingSectionDescription =>
      'Pomagajte odpravljati napake v aplikaciji Tyne tako, da delite podatke o sesutjih in delovanju. Privzeto je izklopljeno.';

  @override
  String get crashReportingDescription =>
      'Poročila se pošiljajo v lastni sistem za sledenje napakam aplikacije Tyne, tudi ko ste prijavljeni na drugi instanci. Ne vsebujejo imen instanc, ID-jev ali vsebine sporočil.';

  @override
  String get instanceOfflineTitle => 'Tyne ni dosegljiv!';

  @override
  String get instanceOfflineBody => 'Raziskujemo, kaj se dogaja.';

  @override
  String get instanceStatusSignalLink =>
      'Za novosti se pridružite naši skupini v aplikaciji Signal';

  @override
  String get convertEmoticonsLabel => 'Pretvori besedilne smeške v emojije';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Ukaza /$name ni bilo mogoče zagnati: $detail';
  }

  @override
  String get guildCommandBroken => 'Njegov skript vsebuje napako.';

  @override
  String guildCommandOneLine(String name) {
    return 'Kar vpišete za /$name, mora biti v eni vrstici.';
  }

  @override
  String get permissionCreateCommands => 'Ustvarjanje ukazov';

  @override
  String get permissionManageCommands => 'Upravljanje ukazov';

  @override
  String get permissionUseExternalCommands => 'Uporaba zunanjih ukazov';

  @override
  String get permissionCreateCommandsDescription =>
      'Ustvarjanje ukazov za to skupnost ter urejanje in brisanje lastnih ukazov.';

  @override
  String get permissionManageCommandsDescription =>
      'Urejanje in brisanje ukazov vseh članov te skupnosti.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Uporaba ukazov iz drugih skupnosti.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Uporaba ukazov iz drugih skupnosti v tem kanalu.';

  @override
  String get guildSettingsCategoryMessageTools => 'Orodja za sporočila';

  @override
  String get guildSettingsCommands => 'Ukazi';

  @override
  String get guildCommandsLoadFailed => 'Ukazov ni bilo mogoče naložiti.';

  @override
  String get guildCommandsSubtitle =>
      'Sporočila, ki jih člani objavijo tako, da vpišejo /name.';

  @override
  String get guildCommandsSlots => 'Mesta za ukaze';

  @override
  String get guildCommandsNew => 'Nov ukaz';

  @override
  String get guildCommandsSearch => 'Išči ukaze';

  @override
  String get guildCommandsEmptyTitle => 'Ni ukazov';

  @override
  String get guildCommandsEmptyBody => 'Ta skupnost še nima ukazov.';

  @override
  String get guildCommandsSaved => 'Ukazi so shranjeni';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Ukaza /$name ni bilo mogoče shraniti: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Uredi /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Želite izbrisati /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Tega ni mogoče razveljaviti. Pri sporočilih, ustvarjenih z njim, bo še vedno navedeno, kateri ukaz jih je ustvaril.';

  @override
  String get guildCommandDelete => 'Izbriši';

  @override
  String get guildCommandDeleteCommand => 'Izbriši ukaz';

  @override
  String get guildCommandSectionCommand => 'Ukaz';

  @override
  String get guildCommandName => 'Ime';

  @override
  String get guildCommandNameInvalid =>
      'Uporabite male črke, številke, - in _, največ 32 znakov.';

  @override
  String get guildCommandNameTaken =>
      'To ime že ima drug ukaz ali vgrajeni ukaz.';

  @override
  String get guildCommandDescription => 'Opis';

  @override
  String get guildCommandSectionInput => 'Vnos';

  @override
  String get guildCommandInputNone => 'Brez';

  @override
  String get guildCommandInputOptional => 'Neobvezno';

  @override
  String get guildCommandInputRequired => 'Obvezno';

  @override
  String get guildCommandHint => 'Namig';

  @override
  String get guildCommandMessage => 'Sporočilo';

  @override
  String get guildCommandInsert => 'Vstavi:';

  @override
  String get guildCommandInsertPerson => 'Oseba, ki ga zažene';

  @override
  String get guildCommandInsertInput => 'Vneseno besedilo';

  @override
  String get guildCommandPreview => 'Predogled';

  @override
  String get guildCommandSampleInput => 'Vzorčni vnos';

  @override
  String guildCommandMadeWith(String name) {
    return 'Ustvarjeno z ukazom /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Izpraznite polje za sporočilo, če želite uporabiti /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'To ne bi objavilo ničesar, zato ukaz ne bi uspel.';

  @override
  String get guildCommandUseScriptEditor => 'Uporabi urejevalnik skriptov';

  @override
  String get guildCommandUseBasicEditor => 'Uporabi osnovni urejevalnik';

  @override
  String get guildCommandScript => 'Skript';

  @override
  String get guildCommandRunAgain => 'Zaženi znova';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Oznaka $name ne obstaja.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Filter $name ne obstaja.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return 'Blok $name ni nikjer zaprt.';
  }

  @override
  String get guildCommandIssueTooLong => 'Skript je predolg.';

  @override
  String get guildCommandIssueTooLarge => 'Skript ustvari preveč besedila.';

  @override
  String get guildCommandIssueTooSlow =>
      'Izvajanje skripta je trajalo predolgo.';

  @override
  String get guildCommandIssueInvalid => 'Tega dela ni mogoče prebrati.';

  @override
  String get guildCommandIssueFailed => 'Ta del se je ustavil z napako.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Vrstica $line, stolpec $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Priročnik za skripte';

  @override
  String get guildCommandReferencePerson => 'Oseba, ki ga zažene, kot omemba';

  @override
  String get guildCommandReferencePersonName => 'Njeno ime';

  @override
  String get guildCommandReferenceTarget => 'Prva omenjena oseba, če obstaja';

  @override
  String get guildCommandReferenceTargetName => 'Ime te osebe';

  @override
  String get guildCommandReferenceChannel => 'Kanal kot omemba';

  @override
  String get guildCommandReferenceCommunity => 'Ime te skupnosti';

  @override
  String get guildCommandExampleRandom => 'Naključno izberi eno možnost';

  @override
  String get guildCommandExampleDepends =>
      'Spremeni sporočilo glede na vneseno besedilo';

  @override
  String get guildCommandExampleOneWord => 'Naključno izberi eno besedo';

  @override
  String get guildCommandExampleWordForNumber =>
      'Izberi obliko besede glede na število';

  @override
  String get guildCommandExampleOrdinal =>
      'Zapiši število kot vrstilni števnik (1st, 2nd, 3rd)';

  @override
  String get guildCommandFullGuide => 'Celoten vodnik po skriptih';

  @override
  String get guildCommandCounters => 'Števci';

  @override
  String get guildCommandCounterAdd => 'Dodaj števec';

  @override
  String get guildCommandCounterSeparately => 'Štej ločeno glede na:';

  @override
  String get guildCommandCounterPersonMentioned => 'Omenjena oseba';

  @override
  String get guildCommandCounterChannel => 'Kanal';

  @override
  String get guildCommandCounterPersonas => 'Štej persone ločeno';

  @override
  String get guildCommandCounterRemove => 'Odstrani števec';

  @override
  String get guildCommandCounterReset => 'Ponastavi štetje';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Želite ponastaviti štetje števca $name? Tega ni mogoče razveljaviti.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Uporabite male črke, številke in _, začnite s črko in ne uporabite imena, ki ga skripti že uporabljajo.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'V skriptu ga uporabite kot $variable. Vsak zagon najprej poveča števec za 1, zato je ob prvem zagonu vrednost 1.';
  }

  @override
  String get notificationsAlertEveryMessageLabel =>
      'Opozori na vsako sporočilo';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Ko je izklopljeno, vas živahen pogovor opozori le enkrat, nato pa se tiho posodablja, dokler ga ne preberete ali obvestila ne opustite.';

  @override
  String personaGalleryTitle(int count) {
    return 'Persone ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Iščite med personami računa $name';
  }

  @override
  String get personaGallerySearchOwn => 'Iščite med svojimi personami';

  @override
  String get personaGallerySortBy => 'Razvrsti po';

  @override
  String get personaGallerySortName => 'Ime (A–Ž)';

  @override
  String get personaGallerySortMostUsed => 'Najpogosteje uporabljene';

  @override
  String get personaGallerySortRecentlyUsed => 'Nedavno uporabljene';

  @override
  String get personaGalleryViewGallery => 'Galerija';

  @override
  String get personaGalleryViewList => 'Seznam';

  @override
  String get personaGalleryViewAvatars => 'Avatarji';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person',
      few: '$count persone',
      two: '$count personi',
      one: '$count persona',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return '$shown od $total person';
  }

  @override
  String get personaGalleryNoMatch => 'Nobena persona se ne ujema z iskanjem.';

  @override
  String get personaGalleryLoadFailed => 'Person ni bilo mogoče naložiti.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count javnih person',
      few: '$count javne persone',
      two: '$count javni personi',
      one: '$count javno persono',
    );
    return 'Drugi vidijo $_temp0.';
  }

  @override
  String get personaGalleryShowHidden => 'Pokaži nenavedene in zasebne';

  @override
  String get personaGalleryManage => 'Upravljaj persone';

  @override
  String get personaGalleryNonePublic =>
      'Nobena vaša persona še ni javna. Drugi tukaj vidijo persono, ko njeno vidnost nastavite na Javno.';

  @override
  String get personaGalleryNoBio => 'Opisa še ni.';

  @override
  String personaGalleryCreated(String date) {
    return 'Ustvarjena $date';
  }

  @override
  String get personaBulkSelect => 'Izberi';

  @override
  String get personaBulkSelectAll => 'Izberi vse';

  @override
  String personaBulkSelectedCount(int count) {
    return 'Izbrano: $count';
  }

  @override
  String get personaFilterAll => 'Vse';

  @override
  String get personaBulkMakePublic => 'Nastavi kot javne';

  @override
  String get personaBulkMakeUnlisted => 'Nastavi kot nenavedene';

  @override
  String get personaBulkMakePrivate => 'Nastavi kot zasebne';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person spremeniti v javne',
      few: '$count persone spremeniti v javne',
      two: '$count personi spremeniti v javni',
      one: '$count persono spremeniti v javno',
    );
    return 'Želite $_temp0?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person spremeniti v zasebne',
      few: '$count persone spremeniti v zasebne',
      two: '$count personi spremeniti v zasebni',
      one: '$count persono spremeniti v zasebno',
    );
    return 'Želite $_temp0?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person',
      few: '$count persone',
      two: '$count personi',
      one: '$count persono',
    );
    return 'Želite izbrisati $_temp0?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Drugi jih bodo videli na vašem seznamu person in lahko odprejo njihove profile. To lahko kadar koli spremenite nazaj.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Njihovi profili bodo skriti pred drugimi. Njihova imena in avatarji bodo še vedno prikazani pri njihovih sporočilih in odzivih.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Izbrisane persone lahko pozneje obnovite pod Izbrisane persone (Nastavitve › Persone).';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person je zdaj javnih',
      few: '$count persone so zdaj javne',
      two: '$count personi sta zdaj javni',
      one: '$count persona je zdaj javna',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person je zdaj nenavedenih',
      few: '$count persone so zdaj nenavedene',
      two: '$count personi sta zdaj nenavedeni',
      one: '$count persona je zdaj nenavedena',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person je zdaj zasebnih',
      few: '$count persone so zdaj zasebne',
      two: '$count personi sta zdaj zasebni',
      one: '$count persona je zdaj zasebna',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person izbrisanih',
      few: '$count persone izbrisane',
      two: '$count personi izbrisani',
      one: '$count persona izbrisana',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed =>
      'Person ni bilo mogoče spremeniti. Poskusite znova.';

  @override
  String get personaFilterEmpty => 'Tukaj ni person.';

  @override
  String get personaGalleryChooseFeatured =>
      'Izberite persone, ki jih želite pokazati';

  @override
  String get personaUndo => 'Razveljavi';

  @override
  String get personaReactionsTitle => 'Vaši odzivi';

  @override
  String get personaReactionsEveryoneElse => 'VSI DRUGI';

  @override
  String get personaReactionsCurrent => 'TRENUTNA';

  @override
  String get personaReactionsAccount => 'Račun';

  @override
  String get personaReactionsSomeoneElse => 'Odzovi se kot nekdo drug …';

  @override
  String get personaReactionsDone => 'Končano';

  @override
  String get personaSettingsReactionsHeader => 'Odzivi';

  @override
  String get personaSettingsMultiReactions => 'Odzivanje kot več person hkrati';

  @override
  String get personaDuplicateButton => 'Podvoji persono';

  @override
  String personaCopyOf(String name) {
    return 'Kopija persone $name';
  }

  @override
  String signalsEverywhereTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count klepetov',
      few: '$count klepeti',
      two: '$count klepeta',
      one: '$count klepet',
    );
    return 'Vaši signali povsod · $_temp0';
  }

  @override
  String signalsEverywhereHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count klepetov',
      few: '$count klepeti',
      two: '$count klepeta',
      one: '$count klepet',
    );
    return 'Nastavi povsod ($_temp0)';
  }

  @override
  String signalsEverywhereSet(String label) {
    return 'Nastavi $label povsod';
  }

  @override
  String get signalsEverywhereTurnAllOff => 'Izklopi vse';

  @override
  String get signalsEverywhereRestore => 'Obnovi…';

  @override
  String get signalsEverywhereNone =>
      'Nobeden od vaših signalov ni nikjer vklopljen.';

  @override
  String get signalsRestoreTitle => 'Želite obnoviti svoje signale?';

  @override
  String signalsRestoreBeforeSet(String label, String time) {
    return 'Povrne stanje pred nastavitvijo signala $label povsod ($time). Kar je tam vklopljeno zdaj, se izklopi.';
  }

  @override
  String signalsRestoreBeforeOff(String time) {
    return 'Povrne stanje pred izklopom vseh signalov ($time). Kar je tam vklopljeno zdaj, se izklopi.';
  }

  @override
  String signalsRestoreBeforeRestore(String time) {
    return 'Povrne stanje pred vašo zadnjo obnovitvijo ($time). Kar je tam vklopljeno zdaj, se izklopi.';
  }

  @override
  String get signalsRestoreNow => 'Zdaj';

  @override
  String get signalsRestoreAfter => 'Potem';

  @override
  String signalsRestoreLeftOut(String chats) {
    return 'Izpuščeno, ker tam ne morete več pisati: $chats';
  }

  @override
  String get signalsRestoreConfirm => 'Obnovi';

  @override
  String get signalsRestoreUnavailable =>
      'Ni bilo mogoče naložiti, kaj bi spremenilo „Obnovi“. Poskusite znova.';

  @override
  String get signalsRestoreNothing => 'Ničesar ni za obnovitev.';

  @override
  String get signalsProfileMenu => 'Signali';

  @override
  String get signalsEverywhereTurnOffChat => 'Izklopi signale';

  @override
  String signalsRestoreBeforeChange(String time) {
    return 'Povrne stanje pred vašo zadnjo spremembo povsod ($time). Kar je tam vklopljeno zdaj, se izklopi.';
  }

  @override
  String get personaCopyBadge => 'Nova persona';

  @override
  String get deletedPersonasTitle => 'Izbrisane persone';

  @override
  String get deletedPersonasDescription =>
      'Izbrisane persone so še vedno prikazane pri svojih starih sporočilih, vendar jih nihče ne more izbrati in se ne štejejo v vašo omejitev. Če persono obnovite, se vrne ista persona z vso svojo zgodovino.';

  @override
  String get deletedPersonasShow => 'Pokaži izbrisane persone';

  @override
  String get deletedPersonasLoadFailed =>
      'Izbrisanih person ni bilo mogoče naložiti.';

  @override
  String get deletedPersonasEmpty => 'Ni izbrisanih person.';

  @override
  String deletedPersonaDeletedAt(String date) {
    return 'Izbrisana $date';
  }

  @override
  String deletedPersonaUseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uporabljena $count-krat',
      few: 'Uporabljena $count-krat',
      two: 'Uporabljena $count-krat',
      one: 'Uporabljena $count-krat',
    );
    return '$_temp0';
  }

  @override
  String get deletedPersonaRestore => 'Obnovi';

  @override
  String personaRestored(String name) {
    return '$name je spet tu.';
  }

  @override
  String personaRestoredWithout(String items) {
    return 'Vrnjena brez $items: zdaj jih ima druga persona.';
  }

  @override
  String get personaRestoreFailed => 'Persone ni bilo mogoče obnoviti.';

  @override
  String deletedPersonaRestoreLabel(String name) {
    return 'Obnovi $name';
  }
}
