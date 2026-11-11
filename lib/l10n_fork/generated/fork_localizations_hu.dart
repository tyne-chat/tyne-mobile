// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class ForkLocalizationsHu extends ForkLocalizations {
  ForkLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Persona váltása';

  @override
  String get chatAttachmentPanelVoice => 'Hang';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'Gyorsváltó gomb';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'A hangüzenet gomb lecserélése a beviteli mezőben gyorsváltóra a gyorsabb navigációért';

  @override
  String get userSettingsCheckForUpdates => 'Frissítések keresése';

  @override
  String get userSettingsCheckingForUpdates => 'Frissítések keresése…';

  @override
  String get userSettingsAppUpToDate => 'A Tyne naprakész';

  @override
  String get userSettingsUpdateAvailableTitle => 'Frissítés érhető el';

  @override
  String get userSettingsUpdateDownloadAction => 'Letöltés és telepítés';

  @override
  String get userSettingsUpdateInstallAction => 'Frissítés telepítése';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Frissítés letöltése ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Nem sikerült a frissítést ellenőrizni vagy letölteni.';

  @override
  String get personaSelectTitle => 'Persona kiválasztása';

  @override
  String get personaSettingsHeader => 'Persona beállítások';

  @override
  String get personaManageAction => 'Kezelés';

  @override
  String get personaSearchPlaceholder => 'Personák, címkék, pronév keresése...';

  @override
  String get personaModeManual => 'Kézi';

  @override
  String get personaModeLast => 'Legutóbb használt';

  @override
  String get personaModeManualDescription =>
      'Mindig a kiválasztott personaként küldi el, amíg meg nem változtatod.';

  @override
  String get personaModeLastDescription =>
      'Automatikusan átvált az utolsó üzenetedben használt personára.';

  @override
  String get personaRecentHeader => 'LEGUTÓBBI PERSONÁK';

  @override
  String personaAllHeader(int count) {
    return 'ÖSSZES PERSONA ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'KERESÉSI EREDMÉNYEK ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Fő fiók (Alapértelmezett)';

  @override
  String get personaEmptyState =>
      'Még nincsenek personák beállítva. Hozz létre egyet a Personák kezelése menüpontban.';

  @override
  String get personaEmptySearch => 'Nem található megfelelő persona.';

  @override
  String get personaEditTitle => 'Persona szerkesztése';

  @override
  String get personaCreateTitle => 'Persona létrehozása';

  @override
  String get personaDisplayNameLabel => 'Megjelenítendő név';

  @override
  String get personaPronounsLabel => 'Névmások';

  @override
  String get personaPronounsHint => 'pl. ő/ők';

  @override
  String get personaBioHint => 'Mesélj másoknak erről a personáról...';

  @override
  String get personaUpdatedToast => 'Persona frissítve';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Nem sikerült frissíteni a personát: $error';
  }

  @override
  String get personaSectionTitle => 'Personák';

  @override
  String get personaDisplayNameHint => 'Persona neve';

  @override
  String personaSendingAsTag(String name) {
    return 'Küldés mint $name (Címke alapján)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Küldés mint $name (Rögzítve)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Küldés mint $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Közzététel mint $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Küldés mint @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'Nincs elküldve: a personáid még nem töltődtek be.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Nincs elküldve: a personáid még nem töltődtek be. Elküldöd inkább @$username néven?';
  }

  @override
  String get personaSendAsAccountAction => 'Küldés mégis';

  @override
  String get personaMainAccount => 'Fő fiók';

  @override
  String get personaEditPersona => 'Persona szerkesztése';

  @override
  String get userSettingsNavPersonas => 'Personák';

  @override
  String get personaSettingsDescription =>
      'Állítsd be az aktív persona módot, az egyéni megjelenítési címkét, és kezeld az egyéni personákat.';

  @override
  String get personaDisplayTagSection => 'Megjelenítési címke';

  @override
  String get personaDisplayTagDescription =>
      'A megjelenítési címke minden persona neve mellett megjelenik az üzenetekben. Ha nincs beállítva megjelenítési címke, a fiókod profilképe fog megjelenni.';

  @override
  String get personaDisplayTagLabel => 'Megjelenítési címke szövege';

  @override
  String get personaDisplayTagHint => 'pl. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Megjelenítési címke ikonja';

  @override
  String get personaUploadTagIcon => 'Ikon feltöltése';

  @override
  String get personaChangeTagIcon => 'Ikon módosítása';

  @override
  String get personaRemoveTagIcon => 'Ikon eltávolítása';

  @override
  String get personaChatPreviewTitle => 'Csevegés előnézete';

  @override
  String get personaChatPreviewSampleMessage =>
      'Helló! Ez egy előnézet arról, hogyan fognak kinézni az üzenetek a megjelenítési címkéddel és az aktív personáddal.';

  @override
  String get personaListTitle => 'Beállított personák';

  @override
  String get personaAddButton => 'Persona hozzáadása';

  @override
  String get personaActiveBadge => 'Aktív';

  @override
  String get personaMakeActive => 'Beállítás aktívként';

  @override
  String get personaDeleteTitle => 'Persona törlése';

  @override
  String personaDeleteMessage(String name) {
    return 'Biztosan törölni szeretnéd a(z) „$name” personát? Ezt a műveletet nem lehet visszavonni.';
  }

  @override
  String get personaDeleteConfirm => 'Törlés';

  @override
  String get personaDeletedToast => 'Persona törölve';

  @override
  String get personaCreatedToast => 'Persona létrehozva';

  @override
  String personaCreateFailedToast(String error) {
    return 'Nem sikerült létrehozni a personát: $error';
  }

  @override
  String get personaChangeAvatar => 'Profilkép módosítása';

  @override
  String get personaRemoveAvatar => 'Profilkép eltávolítása';

  @override
  String get personaUploadAvatar => 'Profilkép feltöltése';

  @override
  String get personaTagsLabel => 'Persona címkék';

  @override
  String get personaAutoTagDisabledLabel =>
      'Ne ismerje fel ennek a personának a címkéit';

  @override
  String get personaAutoTagDisabledDescription =>
      'Ha beírod valamelyik címkét, nem vált erre a personára. A címke úgy kerül elküldésre, ahogy beírtad.';

  @override
  String get personaTagPrefixLabel => 'Előtag';

  @override
  String get personaTagSuffixLabel => 'Utótag';

  @override
  String get personaVisibilityLabel => 'Láthatóság';

  @override
  String get personaVisibilityUnlisted => 'Nem listázott';

  @override
  String get personaVisibilityPublic => 'Nyilvános';

  @override
  String get personaVisibilityPrivate => 'Privát';

  @override
  String get personaNameRequired =>
      'Kérjük, add meg a persona megjelenített nevét';

  @override
  String get personaNameTooLong =>
      'A persona megjelenített neve legfeljebb 100 karakter lehet';

  @override
  String get personaTagPrefixTooLong =>
      'A persona címke előtagja legfeljebb 32 karakter lehet';

  @override
  String get personaTagSuffixTooLong =>
      'A persona címke utótagja legfeljebb 32 karakter lehet';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'A(z) \'$tag\' címkét már használja \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Időbélyegző beszúrása';

  @override
  String get chatAttachmentSendVoiceMessage => 'Hangüzenet küldése';

  @override
  String get timestampPickerTitle => 'Időbélyegző beszúrása';

  @override
  String get timestampPickerInsert => 'Beszúrás';

  @override
  String get timestampCopied => 'Időbélyegző másolva';

  @override
  String get timestampPickerTimeLabel => 'Idő';

  @override
  String get timestampPickerDateLabel => 'DÁTUM';

  @override
  String get timestampPickerTimeSectionLabel => 'IDŐPONT';

  @override
  String get timestampPickerTimezoneLabel => 'IDŐZÓNA';

  @override
  String get timestampPickerFormatPreviewLabel => 'FORMÁTUM ELŐNÉZETE';

  @override
  String get timestampPickerNlpPlaceholder =>
      'pl. holnap 15:00-kor, 2 óra múlva, most';

  @override
  String get timestampPickerSearchTimezones => 'Időzónák keresése...';

  @override
  String get userProfileTimezoneSettingLabel => 'Időzóna';

  @override
  String get userProfileTimezoneSettingDescription =>
      'A helyi idő megjelenítésére szolgál a profilodban.';

  @override
  String get userProfileTimezoneNone => 'Nincs';

  @override
  String get chatReactAs => 'Reakció mint...';

  @override
  String get emojiCopy => 'Emoji másolása';

  @override
  String get emojiCopyLink => 'Link másolása';

  @override
  String get emojiPin => 'Hangulatjel rögzítése';

  @override
  String get emojiUnpin => 'Hangulatjel feloldása';

  @override
  String get emojiPinForPersona => 'Rögzítés ehhez a personához';

  @override
  String get emojiUnpinForPersona => 'Feloldás ennél a personánál';

  @override
  String get personaSignatureEmojisLabel => 'Aláírási hangulatjelek';

  @override
  String get personaSignatureEmojisDescription =>
      'Az aláírási hangulatjellel való reagálás mindig ezen személyként történik, a függetlenül az aktív személytől.';

  @override
  String get personaAddSignatureEmoji => 'Hangulatjel hozzáadása';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Ez a hangulatjel már hozzá van adva aláírási hangulatjelként';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Ezt az aláírási hangulatjelet már használja a(z) \"$name\" személy';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Aláírási hangulatjel eltávolítása';

  @override
  String get signalBarLabel => 'Jelzősáv';

  @override
  String get signalBarShow => 'Jelzősáv megjelenítése';

  @override
  String get signalBarHide => 'Jelzősáv elrejtése';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Senkinél sincs bekapcsolva ez a jelzés';

  @override
  String get signalBarReset => 'Jelzés visszaállítása mindenkinél';

  @override
  String signalBarTurnOff(String name) {
    return '$name kikapcsolása';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Az alapértelmezett példányhoz használd ezt: $domain, vagy add meg egy másik példány pontos URL-címét.';
  }

  @override
  String get instanceResetToDefault =>
      'Visszaállítás az alapértelmezett példányra';

  @override
  String get personaScopeTitle => 'A persona érvényessége';

  @override
  String get personaScopeGlobal => 'Mindenhol';

  @override
  String get personaScopeGlobalDescription => 'Egy persona minden csatornához.';

  @override
  String get personaScopeChannel => 'Minden csatornában';

  @override
  String get personaScopeChannelDescription =>
      'Minden csatorna megtartja a saját personáját. Az új csatornák a fiókoddal indulnak.';

  @override
  String get personaPickerChannelOnly => 'Csak ehhez a csatornához';

  @override
  String get personaProfilePrivate => 'Ennek a personának a profilja privát.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'A képfájl túl nagy. Válassz kisebb, $maxSize alatti fájlt.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'KLIPY keresése';

  @override
  String get appUpdateDownloadFailed => 'A frissítés letöltése nem sikerült';

  @override
  String get appUpdateInstallFailed => 'A frissítés telepítése nem sikerült';

  @override
  String get personaChangeMessageFailed =>
      'Az üzenet personájának módosítása nem sikerült';

  @override
  String get personaActiveCleared => 'Aktív persona törölve';

  @override
  String get klipyPoweredBy => 'A szolgáltatást a KLIPY nyújtja';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Ismétlődő \'$pattern\' címkepár ennél a personánál';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Címkepár hozzáadása ($count/5)';
  }

  @override
  String get personaTagExampleText => 'szöveg';

  @override
  String get personaPreviewNameFallback => 'Felhasználó';

  @override
  String get crashReportingConsentSubtitle =>
      'A Tyne váratlanul bezárult. Ha névtelen összeomlási és hibaadatokat osztasz meg, gyorsabban javíthatjuk a problémákat.';

  @override
  String get crashReportingSectionDescription =>
      'Segíts kijavítani a Tyne hibáit összeomlási és teljesítményadatok megosztásával. Alapértelmezés szerint ki van kapcsolva.';

  @override
  String get crashReportingDescription =>
      'A jelentések a Tyne saját hibakövetőjébe kerülnek, akkor is, ha egy másik instanciába vagy bejelentkezve. Nem tartalmaznak instancianeveket, azonosítókat vagy üzenettartalmat.';

  @override
  String get instanceOfflineTitle => 'A Tyne nem érhető el!';

  @override
  String get instanceOfflineBody => 'Vizsgáljuk a hibát.';

  @override
  String get instanceStatusSignalLink =>
      'Csatlakozz a Signal-csevegésünkhöz a friss hírekért';

  @override
  String get convertEmoticonsLabel => 'Szöveges emotikonok cseréje emojikra';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Nem sikerült futtatni: /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'A szkriptjével probléma van.';

  @override
  String guildCommandOneLine(String name) {
    return 'Amit a /$name után írsz, annak egy sorba kell férnie.';
  }

  @override
  String get permissionCreateCommands => 'Parancsok létrehozása';

  @override
  String get permissionManageCommands => 'Parancsok kezelése';

  @override
  String get permissionUseExternalCommands => 'Külső parancsok használata';

  @override
  String get permissionCreateCommandsDescription =>
      'Parancsok létrehozása ehhez a közösséghez, a sajátjaid szerkesztése vagy törlése.';

  @override
  String get permissionManageCommandsDescription =>
      'Bárki parancsainak szerkesztése vagy törlése ebben a közösségben.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Más közösségek parancsainak használata.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Más közösségek parancsainak használata ebben a csatornában.';

  @override
  String get guildSettingsCategoryMessageTools => 'Üzeneteszközök';

  @override
  String get guildSettingsCommands => 'Parancsok';

  @override
  String get guildCommandsLoadFailed => 'Nem sikerült betölteni a parancsokat.';

  @override
  String get guildCommandsSubtitle =>
      'Üzenetek, amelyeket a tagok a /name beírásával küldhetnek.';

  @override
  String get guildCommandsSlots => 'Parancshelyek';

  @override
  String get guildCommandsNew => 'Új parancs';

  @override
  String get guildCommandsSearch => 'Parancsok keresése';

  @override
  String get guildCommandsEmptyTitle => 'Nincsenek parancsok';

  @override
  String get guildCommandsEmptyBody =>
      'Ennek a közösségnek még nincsenek parancsai.';

  @override
  String get guildCommandsSaved => 'Parancsok mentve';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Nem sikerült menteni: /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return '/$name szerkesztése';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Törlöd ezt: /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Ez nem vonható vissza. A vele készült üzenetek továbbra is mutatják, melyik parancs készítette őket.';

  @override
  String get guildCommandDelete => 'Törlés';

  @override
  String get guildCommandDeleteCommand => 'Parancs törlése';

  @override
  String get guildCommandSectionCommand => 'Parancs';

  @override
  String get guildCommandName => 'Név';

  @override
  String get guildCommandNameInvalid =>
      'Használj kisbetűket, számokat, - és _ jelet, legfeljebb 32 karaktert.';

  @override
  String get guildCommandNameTaken =>
      'Egy másik parancsnak vagy egy beépített parancsnak már ez a neve.';

  @override
  String get guildCommandDescription => 'Leírás';

  @override
  String get guildCommandSectionInput => 'Bevitel';

  @override
  String get guildCommandInputNone => 'Nincs';

  @override
  String get guildCommandInputOptional => 'Nem kötelező';

  @override
  String get guildCommandInputRequired => 'Kötelező';

  @override
  String get guildCommandHint => 'Tipp';

  @override
  String get guildCommandMessage => 'Üzenet';

  @override
  String get guildCommandInsert => 'Beszúrás:';

  @override
  String get guildCommandInsertPerson => 'Aki használja';

  @override
  String get guildCommandInsertInput => 'Amit beírnak';

  @override
  String get guildCommandPreview => 'Előnézet';

  @override
  String get guildCommandSampleInput => 'Mintabevitel';

  @override
  String guildCommandMadeWith(String name) {
    return 'Készült ezzel: /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Ürítsd ki az üzenetmezőt a(z) /$name használatához';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Ez semmit sem küldene el, ezért a parancs sikertelen lenne.';

  @override
  String get guildCommandUseScriptEditor => 'Szkriptszerkesztő használata';

  @override
  String get guildCommandUseBasicEditor => 'Alapszerkesztő használata';

  @override
  String get guildCommandScript => 'Szkript';

  @override
  String get guildCommandRunAgain => 'Futtatás újra';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Nincs $name nevű címke.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Nincs $name nevű szűrő.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name soha nem záródik le.';
  }

  @override
  String get guildCommandIssueTooLong => 'A szkript túl hosszú.';

  @override
  String get guildCommandIssueTooLarge =>
      'A szkript túl sok szöveget hoz létre.';

  @override
  String get guildCommandIssueTooSlow =>
      'A szkript futtatása túl sokáig tartott.';

  @override
  String get guildCommandIssueInvalid => 'Ez a rész nem olvasható.';

  @override
  String get guildCommandIssueFailed => 'Ez a rész hibával leállt.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return '$line. sor, $column. oszlop: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Szkriptreferencia';

  @override
  String get guildCommandReferencePerson => 'Aki használja, említésként';

  @override
  String get guildCommandReferencePersonName => 'Annak a neve, aki használja';

  @override
  String get guildCommandReferenceTarget =>
      'Az első említett személy, ha van ilyen';

  @override
  String get guildCommandReferenceTargetName => 'Annak a személynek a neve';

  @override
  String get guildCommandReferenceChannel => 'A csatorna említésként';

  @override
  String get guildCommandReferenceCommunity => 'Ennek a közösségnek a neve';

  @override
  String get guildCommandExampleRandom =>
      'Egy lehetőség véletlenszerű kiválasztása';

  @override
  String get guildCommandExampleDepends =>
      'Az üzenet módosítása a beírtak alapján';

  @override
  String get guildCommandExampleOneWord => 'Egy szó véletlenszerű kiválasztása';

  @override
  String get guildCommandExampleWordForNumber =>
      'A számhoz illő szó kiválasztása';

  @override
  String get guildCommandExampleOrdinal => 'Szám írása így: 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Teljes szkriptútmutató';

  @override
  String get guildCommandCounters => 'Számlálók';

  @override
  String get guildCommandCounterAdd => 'Számláló hozzáadása';

  @override
  String get guildCommandCounterSeparately => 'Külön számlálás mindegyikhez:';

  @override
  String get guildCommandCounterPersonMentioned => 'Megemlített személy';

  @override
  String get guildCommandCounterChannel => 'Csatorna';

  @override
  String get guildCommandCounterPersonas => 'Personák külön számlálása';

  @override
  String get guildCommandCounterRemove => 'Számláló eltávolítása';

  @override
  String get guildCommandCounterReset => 'Számok nullázása';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Nullázod a(z) $name számait? Ez nem vonható vissza.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Használj kisbetűket, számokat és _ jelet, betűvel kezdj, és ne olyan nevet, amelyet a szkriptek már használnak.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Szkriptben így használd: $variable. Minden futás előbb hozzáad egyet, így az első 1-et olvas.';
  }

  @override
  String get notificationsAlertEveryMessageLabel =>
      'Értesítés minden üzenetről';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Kikapcsolva egy élénk beszélgetés csak egyszer értesít, utána csendben frissül, amíg el nem olvasod vagy el nem veted.';

  @override
  String personaGalleryTitle(int count) {
    return 'Personák ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Keresés $name personái között';
  }

  @override
  String get personaGallerySearchOwn => 'Keresés a personáid között';

  @override
  String get personaGallerySortBy => 'Rendezés';

  @override
  String get personaGallerySortName => 'Név (A–Z)';

  @override
  String get personaGallerySortMostUsed => 'Leggyakrabban használt';

  @override
  String get personaGallerySortRecentlyUsed => 'Nemrég használt';

  @override
  String get personaGalleryViewGallery => 'Galéria';

  @override
  String get personaGalleryViewList => 'Lista';

  @override
  String get personaGalleryViewAvatars => 'Profilképek';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return '$shown/$total persona';
  }

  @override
  String get personaGalleryNoMatch => 'Egy persona sem felel meg a keresésnek.';

  @override
  String get personaGalleryLoadFailed => 'Nem sikerült betölteni a personákat.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nyilvános personát',
      one: '$count nyilvános personát',
    );
    return 'Mások $_temp0 látnak.';
  }

  @override
  String get personaGalleryShowHidden =>
      'Nem listázott és privát personák mutatása';

  @override
  String get personaGalleryManage => 'Personák kezelése';

  @override
  String get personaGalleryNonePublic =>
      'Még egyik personád sem nyilvános. Mások akkor látnak itt egy personát, ha a láthatóságát Nyilvánosra állítod.';

  @override
  String get personaGalleryNoBio => 'Még nincs bemutatkozás.';

  @override
  String personaGalleryCreated(String date) {
    return 'Létrehozva: $date';
  }

  @override
  String get personaBulkSelect => 'Kijelölés';

  @override
  String get personaBulkSelectAll => 'Összes kijelölése';

  @override
  String personaBulkSelectedCount(int count) {
    return '$count kiválasztva';
  }

  @override
  String get personaFilterAll => 'Összes';

  @override
  String get personaBulkMakePublic => 'Legyen nyilvános';

  @override
  String get personaBulkMakeUnlisted => 'Legyen nem listázott';

  @override
  String get personaBulkMakePrivate => 'Legyen privát';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return '$_temp0 legyen nyilvános?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return '$_temp0 legyen privát?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return '$_temp0 törlése?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Mások látni fogják őket a Personák listádban, és megnyithatják a profiljukat. Ezt bármikor visszaállíthatod.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'A profiljuk rejtve lesz mások elől. A nevük és avatarjuk továbbra is látszik az üzeneteiknél és reakcióiknál.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Az üzeneteik továbbra is a nevüket és avatarjukat mutatják, de már nem küldhetsz a nevükben, és a címkéik és aláírási hangulatjeleik felszabadulnak. Ez nem vonható vissza.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona mostantól nyilvános',
      one: '$count persona mostantól nyilvános',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona mostantól nem listázott',
      one: '$count persona mostantól nem listázott',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona mostantól privát',
      one: '$count persona mostantól privát',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona törölve',
      one: '$count persona törölve',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed =>
      'Nem sikerült módosítani a personákat. Próbáld újra.';

  @override
  String get personaFilterEmpty => 'Itt nincsenek personák.';

  @override
  String get personaGalleryChooseFeatured => 'Kiemelendő personák kiválasztása';

  @override
  String get personaUndo => 'Visszavonás';

  @override
  String get personaReactionsTitle => 'Reakcióid';

  @override
  String get personaReactionsEveryoneElse => 'MINDENKI MÁS';

  @override
  String get personaReactionsCurrent => 'JELENLEGI';

  @override
  String get personaReactionsAccount => 'Fiók';

  @override
  String get personaReactionsSomeoneElse => 'Reakció mint valaki más...';

  @override
  String get personaReactionsDone => 'Kész';

  @override
  String get personaSettingsReactionsHeader => 'Reakciók';

  @override
  String get personaSettingsMultiReactions =>
      'Reagálás egyszerre több personaként';

  @override
  String get personaDuplicateButton => 'Persona másolása';

  @override
  String personaCopyOf(String name) {
    return '$name másolata';
  }

  @override
  String signalsEverywhereTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beszélgetés',
      one: '$count beszélgetés',
    );
    return 'Jelzéseid mindenhol · $_temp0';
  }

  @override
  String signalsEverywhereHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beszélgetés',
      one: '$count beszélgetés',
    );
    return 'Beállítás mindenhol ($_temp0)';
  }

  @override
  String signalsEverywhereSet(String label) {
    return '$label beállítása mindenhol';
  }

  @override
  String get signalsEverywhereTurnAllOff => 'Összes kikapcsolása';

  @override
  String get signalsEverywhereRestore => 'Visszaállítás…';

  @override
  String get signalsEverywhereNone => 'Egyik jelzésed sincs bekapcsolva sehol.';

  @override
  String get signalsRestoreTitle => 'Visszaállítod a jelzéseidet?';

  @override
  String signalsRestoreBeforeSet(String label, String time) {
    return 'Visszaállítja, ami be volt kapcsolva, mielőtt mindenhol beállítottad a(z) $label jelzést ($time). Ami ott most be van kapcsolva, kikapcsol.';
  }

  @override
  String signalsRestoreBeforeOff(String time) {
    return 'Visszaállítja, ami be volt kapcsolva, mielőtt mindet kikapcsoltad ($time). Ami ott most be van kapcsolva, kikapcsol.';
  }

  @override
  String signalsRestoreBeforeRestore(String time) {
    return 'Visszaállítja, ami a legutóbbi visszaállításod ($time) előtt be volt kapcsolva. Ami ott most be van kapcsolva, kikapcsol.';
  }

  @override
  String get signalsRestoreNow => 'Most';

  @override
  String get signalsRestoreAfter => 'Utána';

  @override
  String signalsRestoreMoreChats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ még $count beszélgetés',
      one: '+ még $count beszélgetés',
    );
    return '$_temp0';
  }

  @override
  String signalsRestoreLeftOut(String chats) {
    return 'Kimaradnak, mert ott már nem írhatsz: $chats';
  }

  @override
  String get signalsRestoreConfirm => 'Visszaállítás';

  @override
  String get signalsRestoreUnavailable =>
      'Nem sikerült betölteni, mit változtatna a Visszaállítás. Próbáld újra.';

  @override
  String get signalsRestoreNothing => 'Nincs mit visszaállítani.';

  @override
  String get signalsProfileMenu => 'Jelzések';
}
