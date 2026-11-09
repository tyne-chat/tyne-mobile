// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class ForkLocalizationsSk extends ForkLocalizations {
  ForkLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Zmeniť personu';

  @override
  String get chatAttachmentPanelVoice => 'Hlas';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Tlačidlo rýchleho prepínača';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Nahradiť tlačidlo hlasovej správy v poli správy tlačidlom rýchleho prepínača na rýchlu navigáciu';

  @override
  String get userSettingsCheckForUpdates => 'Skontrolovať aktualizácie';

  @override
  String get userSettingsCheckingForUpdates => 'Kontrolujú sa aktualizácie…';

  @override
  String get userSettingsAppUpToDate => 'Máte najnovšiu verziu Tyne';

  @override
  String get userSettingsUpdateAvailableTitle => 'K dispozícii je aktualizácia';

  @override
  String get userSettingsUpdateDownloadAction => 'Stiahnuť a nainštalovať';

  @override
  String get userSettingsUpdateInstallAction => 'Nainštalovať aktualizáciu';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Sťahuje sa aktualizácia ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Aktualizáciu sa nepodarilo skontrolovať ani stiahnuť.';

  @override
  String get personaSelectTitle => 'Vybrať personu';

  @override
  String get personaSettingsHeader => 'Nastavenia persón';

  @override
  String get personaManageAction => 'Spravovať';

  @override
  String get personaSearchPlaceholder => 'Hľadať persony, značky, zámená…';

  @override
  String get personaModeManual => 'Ručne';

  @override
  String get personaModeLast => 'Naposledy použitá';

  @override
  String get personaModeManualDescription =>
      'Vždy odosiela ako vybraná persona, kým ju nezmeníte.';

  @override
  String get personaModeLastDescription =>
      'Automaticky prepne na personu použitú vo vašej poslednej správe.';

  @override
  String get personaRecentHeader => 'NEDÁVNE PERSONY';

  @override
  String personaAllHeader(int count) {
    return 'VŠETKY PERSONY ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'VÝSLEDKY VYHĽADÁVANIA ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Hlavný účet (predvolený)';

  @override
  String get personaEmptyState =>
      'Zatiaľ nemáte nastavené žiadne persony. Vytvorte si nejakú v časti Spravovať persony.';

  @override
  String get personaEmptySearch => 'Nenašli sa žiadne zodpovedajúce persony.';

  @override
  String get personaEditTitle => 'Upraviť personu';

  @override
  String get personaCreateTitle => 'Vytvoriť personu';

  @override
  String get personaDisplayNameLabel => 'Zobrazované meno';

  @override
  String get personaPronounsLabel => 'Zámená';

  @override
  String get personaPronounsHint => 'napr. oni/ich';

  @override
  String get personaBioHint => 'Povedzte ostatným niečo o tejto persone…';

  @override
  String get personaUpdatedToast => 'Persona aktualizovaná';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Personu sa nepodarilo aktualizovať: $error';
  }

  @override
  String get personaSectionTitle => 'Persony';

  @override
  String get personaDisplayNameHint => 'Meno persony';

  @override
  String personaSendingAsTag(String name) {
    return 'Odosielate ako $name (podľa značky)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Odosielate ako $name (naposledy použitá)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Odosielate ako $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Uverejňujete ako $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Odosielate ako @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'Neodoslané: vaše persony sa ešte nenačítali.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Neodoslané: vaše persony sa ešte nenačítali. Odoslať správu namiesto toho ako @$username?';
  }

  @override
  String get personaSendAsAccountAction => 'Odoslať aj tak';

  @override
  String get personaMainAccount => 'Hlavný účet';

  @override
  String get personaEditPersona => 'Upraviť personu';

  @override
  String get userSettingsNavPersonas => 'Persony';

  @override
  String get personaSettingsDescription =>
      'Nastavte režim aktívnej persony a vlastnú zobrazovanú značku a spravujte jednotlivé persony.';

  @override
  String get personaDisplayTagSection => 'Zobrazovaná značka';

  @override
  String get personaDisplayTagDescription =>
      'Zobrazovaná značka sa ukáže vedľa mien všetkých persón v správach. Ak nie je nastavená, ukáže sa profilový obrázok vášho účtu.';

  @override
  String get personaDisplayTagLabel => 'Text zobrazovanej značky';

  @override
  String get personaDisplayTagHint => 'napr. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Ikona zobrazovanej značky';

  @override
  String get personaUploadTagIcon => 'Nahrať ikonu';

  @override
  String get personaChangeTagIcon => 'Zmeniť ikonu';

  @override
  String get personaRemoveTagIcon => 'Odstrániť ikonu';

  @override
  String get personaChatPreviewTitle => 'Ukážka chatu';

  @override
  String get personaChatPreviewSampleMessage =>
      'Ahoj! Takto vyzerajú správy s vašou zobrazovanou značkou a aktívnou personou.';

  @override
  String get personaListTitle => 'Nastavené persony';

  @override
  String get personaAddButton => 'Pridať personu';

  @override
  String get personaActiveBadge => 'Aktívna';

  @override
  String get personaMakeActive => 'Nastaviť ako aktívnu';

  @override
  String get personaDeleteTitle => 'Odstrániť personu';

  @override
  String personaDeleteMessage(String name) {
    return 'Naozaj chcete odstrániť „$name“? Túto akciu nie je možné vrátiť späť.';
  }

  @override
  String get personaDeleteConfirm => 'Odstrániť';

  @override
  String get personaDeletedToast => 'Persona odstránená';

  @override
  String get personaCreatedToast => 'Persona vytvorená';

  @override
  String personaCreateFailedToast(String error) {
    return 'Personu sa nepodarilo vytvoriť: $error';
  }

  @override
  String get personaChangeAvatar => 'Zmeniť avatar';

  @override
  String get personaRemoveAvatar => 'Odstrániť avatar';

  @override
  String get personaUploadAvatar => 'Nahrať avatar';

  @override
  String get personaTagsLabel => 'Značky persony';

  @override
  String get personaAutoTagDisabledLabel =>
      'Nerozpoznávať značky tejto persony';

  @override
  String get personaAutoTagDisabledDescription =>
      'Napísanie niektorej z týchto značiek neprepne na túto personu. Značka sa odošle tak, ako je napísaná.';

  @override
  String get personaTagPrefixLabel => 'Predpona';

  @override
  String get personaTagSuffixLabel => 'Prípona';

  @override
  String get personaVisibilityLabel => 'Viditeľnosť';

  @override
  String get personaVisibilityUnlisted => 'Nezaradené';

  @override
  String get personaVisibilityPublic => 'Verejné';

  @override
  String get personaVisibilityPrivate => 'Súkromné';

  @override
  String get personaNameRequired => 'Zadajte zobrazované meno persony';

  @override
  String get personaNameTooLong =>
      'Zobrazované meno persony môže mať najviac 100 znakov';

  @override
  String get personaTagPrefixTooLong =>
      'Predpona značky persony môže mať najviac 32 znakov';

  @override
  String get personaTagSuffixTooLong =>
      'Prípona značky persony môže mať najviac 32 znakov';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Značku „$tag“ už používa „$name“.';
  }

  @override
  String get chatInsertTimestamp => 'Vložiť časovú pečiatku';

  @override
  String get chatAttachmentSendVoiceMessage => 'Poslať hlasovú správu';

  @override
  String get timestampPickerTitle => 'Vložiť časovú pečiatku';

  @override
  String get timestampPickerInsert => 'Vložiť';

  @override
  String get timestampCopied => 'Časová pečiatka skopírovaná';

  @override
  String get timestampPickerTimeLabel => 'Čas';

  @override
  String get timestampPickerDateLabel => 'DÁTUM';

  @override
  String get timestampPickerTimeSectionLabel => 'ČAS';

  @override
  String get timestampPickerTimezoneLabel => 'ČASOVÉ PÁSMO';

  @override
  String get timestampPickerFormatPreviewLabel => 'UKÁŽKA FORMÁTU';

  @override
  String get timestampPickerNlpPlaceholder =>
      'napr. tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'Hľadať časové pásma…';

  @override
  String get userProfileTimezoneSettingLabel => 'Časové pásmo';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Slúži na zobrazenie vášho miestneho času vo vašom profile.';

  @override
  String get userProfileTimezoneNone => 'Žiadne';

  @override
  String get chatReactAs => 'Reagovať ako…';

  @override
  String get emojiCopy => 'Kopírovať emoji';

  @override
  String get emojiCopyLink => 'Kopírovať odkaz';

  @override
  String get emojiPin => 'Pripnúť emoji';

  @override
  String get emojiUnpin => 'Odopnúť emoji';

  @override
  String get emojiPinForPersona => 'Pripnúť pre túto personu';

  @override
  String get emojiUnpinForPersona => 'Odopnúť pre túto personu';

  @override
  String get personaSignatureEmojisLabel => 'Podpisové emoji';

  @override
  String get personaSignatureEmojisDescription =>
      'Keď reagujete podpisovým emoji, vždy reagujete ako táto persona bez ohľadu na aktívnu personu.';

  @override
  String get personaAddSignatureEmoji => 'Pridať emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Toto emoji už je pridané ako podpisové emoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Toto podpisové emoji už používa persona „$name“';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Odobrať podpisové emoji';

  @override
  String get signalBarLabel => 'Lišta signálov';

  @override
  String get signalBarShow => 'Zobraziť lištu signálov';

  @override
  String get signalBarHide => 'Skryť lištu signálov';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Tento signál nemá nikto zapnutý';

  @override
  String get signalBarReset => 'Vypnúť signál pre všetkých';

  @override
  String signalBarTurnOff(String name) {
    return 'Vypnúť signál pre $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Pre predvolenú inštanciu použite $domain alebo presnú adresu URL inej inštancie.';
  }

  @override
  String get instanceResetToDefault => 'Obnoviť predvolenú inštanciu';

  @override
  String get personaScopeTitle => 'Kde platí persona';

  @override
  String get personaScopeGlobal => 'Všade';

  @override
  String get personaScopeGlobalDescription =>
      'Jedna persona pre všetky kanály.';

  @override
  String get personaScopeChannel => 'V každom kanáli';

  @override
  String get personaScopeChannelDescription =>
      'Každý kanál si pamätá vlastnú personu. Nové kanály začínajú ako váš účet.';

  @override
  String get personaPickerChannelOnly => 'Len pre tento kanál';

  @override
  String get personaProfilePrivate => 'Profil tejto persony je súkromný.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Obrázok je príliš veľký. Vyberte súbor menší ako $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Hľadať v KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Aktualizáciu sa nepodarilo stiahnuť';

  @override
  String get appUpdateInstallFailed =>
      'Aktualizáciu sa nepodarilo nainštalovať';

  @override
  String get personaChangeMessageFailed =>
      'Personu správy sa nepodarilo zmeniť';

  @override
  String get personaActiveCleared => 'Aktívna persona zrušená';

  @override
  String get klipyPoweredBy => 'Využíva KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Duplicitný pár značiek „$pattern“ pri tejto persone';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Pridať pár značiek ($count/5)';
  }

  @override
  String get personaTagExampleText => 'text';

  @override
  String get personaPreviewNameFallback => 'Používateľ';

  @override
  String get crashReportingConsentSubtitle =>
      'Aplikácia Tyne sa neočakávane zavrela. Zdieľaním anonymných údajov o pádoch a chybách nám pomôžete rýchlejšie opraviť problémy.';

  @override
  String get crashReportingSectionDescription =>
      'Pomôžte opravovať chyby v Tyne zdieľaním údajov o pádoch a výkone. Predvolene je to vypnuté.';

  @override
  String get crashReportingDescription =>
      'Hlásenia sa odosielajú do vlastného nástroja Tyne na sledovanie chýb, aj keď ste prihlásení k inej inštancii. Neobsahujú názvy inštancií, ID ani obsah správ.';

  @override
  String get instanceOfflineTitle => 'Tyne je offline!';

  @override
  String get instanceOfflineBody => 'Zisťujeme, čo sa deje.';

  @override
  String get instanceStatusSignalLink =>
      'Pridajte sa do nášho chatu na Signale a sledujte novinky';

  @override
  String get convertEmoticonsLabel => 'Meniť textové smajlíky na emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Príkaz /$name sa nepodarilo spustiť: $detail';
  }

  @override
  String get guildCommandBroken => 'V jeho skripte je chyba.';

  @override
  String guildCommandOneLine(String name) {
    return 'To, čo napíšete za /$name, sa musí zmestiť na jeden riadok.';
  }

  @override
  String get permissionCreateCommands => 'Vytvárať príkazy';

  @override
  String get permissionManageCommands => 'Spravovať príkazy';

  @override
  String get permissionUseExternalCommands => 'Používať externé príkazy';

  @override
  String get permissionCreateCommandsDescription =>
      'Vytvárať príkazy pre túto komunitu a upravovať alebo odstraňovať vlastné.';

  @override
  String get permissionManageCommandsDescription =>
      'Upravovať alebo odstraňovať príkazy kohokoľvek v tejto komunite.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Používať príkazy z iných komunít.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Používať príkazy z iných komunít v tomto kanáli.';

  @override
  String get guildSettingsCategoryMessageTools => 'Nástroje správ';

  @override
  String get guildSettingsCommands => 'Príkazy';

  @override
  String get guildCommandsLoadFailed => 'Príkazy sa nepodarilo načítať.';

  @override
  String get guildCommandsSubtitle =>
      'Správy, ktoré môžu členovia poslať napísaním /name.';

  @override
  String get guildCommandsSlots => 'Miesta na príkazy';

  @override
  String get guildCommandsNew => 'Nový príkaz';

  @override
  String get guildCommandsSearch => 'Hľadať príkazy';

  @override
  String get guildCommandsEmptyTitle => 'Žiadne príkazy';

  @override
  String get guildCommandsEmptyBody =>
      'Táto komunita zatiaľ nemá žiadne príkazy.';

  @override
  String get guildCommandsSaved => 'Príkazy uložené';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Príkaz /$name sa nepodarilo uložiť: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Upraviť /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Odstrániť /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Túto akciu nie je možné vrátiť späť. Správy vytvorené týmto príkazom budú naďalej ukazovať, ktorý príkaz ich vytvoril.';

  @override
  String get guildCommandDelete => 'Odstrániť';

  @override
  String get guildCommandDeleteCommand => 'Odstrániť príkaz';

  @override
  String get guildCommandSectionCommand => 'Príkaz';

  @override
  String get guildCommandName => 'Názov';

  @override
  String get guildCommandNameInvalid =>
      'Použite malé písmená, číslice, - a _, najviac 32 znakov.';

  @override
  String get guildCommandNameTaken =>
      'Tento názov už má iný príkaz alebo vstavaný príkaz.';

  @override
  String get guildCommandDescription => 'Popis';

  @override
  String get guildCommandSectionInput => 'Vstup';

  @override
  String get guildCommandInputNone => 'Žiadny';

  @override
  String get guildCommandInputOptional => 'Voliteľný';

  @override
  String get guildCommandInputRequired => 'Povinný';

  @override
  String get guildCommandHint => 'Nápoveda';

  @override
  String get guildCommandMessage => 'Správa';

  @override
  String get guildCommandInsert => 'Vložiť:';

  @override
  String get guildCommandInsertPerson => 'Kto ho spúšťa';

  @override
  String get guildCommandInsertInput => 'Čo napíše';

  @override
  String get guildCommandPreview => 'Ukážka';

  @override
  String get guildCommandSampleInput => 'Ukážkový vstup';

  @override
  String guildCommandMadeWith(String name) {
    return 'Vytvorené pomocou /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Ak chcete použiť /$name, vyprázdnite pole správy';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Nič by sa neodoslalo, takže príkaz by zlyhal.';

  @override
  String get guildCommandUseScriptEditor => 'Použiť editor skriptov';

  @override
  String get guildCommandUseBasicEditor => 'Použiť základný editor';

  @override
  String get guildCommandScript => 'Skript';

  @override
  String get guildCommandRunAgain => 'Spustiť znova';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Značka s názvom $name neexistuje.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Filter s názvom $name neexistuje.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return 'Blok $name nie je nikde uzavretý.';
  }

  @override
  String get guildCommandIssueTooLong => 'Skript je príliš dlhý.';

  @override
  String get guildCommandIssueTooLarge => 'Skript vytvára príliš veľa textu.';

  @override
  String get guildCommandIssueTooSlow => 'Skript bežal príliš dlho.';

  @override
  String get guildCommandIssueInvalid => 'Túto časť nie je možné prečítať.';

  @override
  String get guildCommandIssueFailed => 'Táto časť skončila chybou.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Riadok $line, stĺpec $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Prehľad skriptovania';

  @override
  String get guildCommandReferencePerson => 'Kto ho spúšťa, ako zmienka';

  @override
  String get guildCommandReferencePersonName => 'Meno toho, kto ho spúšťa';

  @override
  String get guildCommandReferenceTarget =>
      'Prvá spomenutá osoba, ak nejaká je';

  @override
  String get guildCommandReferenceTargetName => 'Meno tejto osoby';

  @override
  String get guildCommandReferenceChannel => 'Kanál ako zmienka';

  @override
  String get guildCommandReferenceCommunity => 'Názov tejto komunity';

  @override
  String get guildCommandExampleRandom => 'Náhodne vybrať jednu možnosť';

  @override
  String get guildCommandExampleDepends =>
      'Zmeniť správu podľa toho, čo bolo napísané';

  @override
  String get guildCommandExampleOneWord => 'Náhodne vybrať jedno slovo';

  @override
  String get guildCommandExampleWordForNumber => 'Vybrať slovo podľa čísla';

  @override
  String get guildCommandExampleOrdinal => 'Napísať číslo ako 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Úplná príručka k skriptom';

  @override
  String get guildCommandCounters => 'Počítadlá';

  @override
  String get guildCommandCounterAdd => 'Pridať počítadlo';

  @override
  String get guildCommandCounterSeparately => 'Samostatne počítať podľa:';

  @override
  String get guildCommandCounterPersonMentioned => 'Spomenutá osoba';

  @override
  String get guildCommandCounterChannel => 'Kanál';

  @override
  String get guildCommandCounterPersonas => 'Počítať persony samostatne';

  @override
  String get guildCommandCounterRemove => 'Odobrať počítadlo';

  @override
  String get guildCommandCounterReset => 'Vynulovať počty';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Vynulovať počty pre $name? Túto akciu nie je možné vrátiť späť.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Použite malé písmená, číslice a _, začnite písmenom a nepoužívajte názov, ktorý už skripty používajú.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'V skripte ho použite ako $variable. Každé spustenie najprv pripočíta jednotku, takže pri prvom spustení bude mať hodnotu 1.';
  }

  @override
  String get notificationsAlertEveryMessageLabel => 'Upozorniť na každú správu';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Keď je vypnuté, rušná konverzácia upozorní iba raz a potom sa ticho aktualizuje, kým ju neprečítate alebo nezavriete.';

  @override
  String personaGalleryTitle(int count) {
    return 'Persony ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Hľadať v personách používateľa $name';
  }

  @override
  String get personaGallerySearchOwn => 'Hľadať vo vašich personách';

  @override
  String get personaGallerySortBy => 'Zoradiť podľa';

  @override
  String get personaGallerySortName => 'Meno (A–Z)';

  @override
  String get personaGallerySortMostUsed => 'Najpoužívanejšie';

  @override
  String get personaGallerySortRecentlyUsed => 'Naposledy použité';

  @override
  String get personaGalleryViewGallery => 'Galéria';

  @override
  String get personaGalleryViewList => 'Zoznam';

  @override
  String get personaGalleryViewAvatars => 'Avatary';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persón',
      many: '$count persony',
      few: '$count persony',
      one: '$count persona',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return 'Persony: $shown z $total';
  }

  @override
  String get personaGalleryNoMatch =>
      'Vyhľadávaniu nezodpovedá žiadna persona.';

  @override
  String get personaGalleryLoadFailed => 'Persony sa nepodarilo načítať.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verejných persón',
      many: '$count verejnej persony',
      few: '$count verejné persony',
      one: '$count verejnú personu',
    );
    return 'Ostatní vidia $_temp0.';
  }

  @override
  String get personaGalleryShowHidden => 'Zobraziť nezaradené a súkromné';

  @override
  String get personaGalleryManage => 'Spravovať persony';

  @override
  String get personaGalleryNonePublic =>
      'Žiadna z vašich persón zatiaľ nie je verejná. Ostatní tu personu uvidia, keď jej nastavíte viditeľnosť na „Verejné“.';

  @override
  String get personaGalleryNoBio => 'Zatiaľ bez popisu.';

  @override
  String personaGalleryCreated(String date) {
    return 'Vytvorená $date';
  }

  @override
  String get personaBulkSelect => 'Vybrať';

  @override
  String get personaBulkSelectAll => 'Vybrať všetky';

  @override
  String personaBulkSelectedCount(int count) {
    return 'Vybrané: $count';
  }

  @override
  String get personaFilterAll => 'Všetky';

  @override
  String get personaBulkMakePublic => 'Nastaviť ako verejné';

  @override
  String get personaBulkMakeUnlisted => 'Nastaviť ako nezaradené';

  @override
  String get personaBulkMakePrivate => 'Nastaviť ako súkromné';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persón ako verejné',
      many: '$count persony ako verejné',
      few: '$count persony ako verejné',
      one: '$count personu ako verejnú',
    );
    return 'Nastaviť $_temp0?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persón ako súkromné',
      many: '$count persony ako súkromné',
      few: '$count persony ako súkromné',
      one: '$count personu ako súkromnú',
    );
    return 'Nastaviť $_temp0?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persón',
      many: '$count persony',
      few: '$count persony',
      one: '$count personu',
    );
    return 'Odstrániť $_temp0?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Ostatní ich uvidia vo vašom zozname persón a budú môcť otvoriť ich profily. Kedykoľvek to môžete zmeniť späť.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Ich profily budú pred ostatnými skryté. Ich mená a avatary sa budú naďalej zobrazovať pri ich správach a reakciách.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Ich správy budú naďalej zobrazovať ich mená a avatary, ale už nebudete môcť posielať správy ako ony a ich značky a podpisové emoji sa uvoľnia. Túto akciu nie je možné vrátiť späť.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persón je teraz verejných',
      many: '$count persony je teraz verejných',
      few: '$count persony sú teraz verejné',
      one: '$count persona je teraz verejná',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persón je teraz nezaradených',
      many: '$count persony je teraz nezaradených',
      few: '$count persony sú teraz nezaradené',
      one: '$count persona je teraz nezaradená',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persón je teraz súkromných',
      many: '$count persony je teraz súkromných',
      few: '$count persony sú teraz súkromné',
      one: '$count persona je teraz súkromná',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Odstránených $count persón',
      many: 'Odstránené $count persony',
      few: 'Odstránené $count persony',
      one: 'Odstránená $count persona',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed =>
      'Persony sa nepodarilo zmeniť. Skúste to znova.';

  @override
  String get personaFilterEmpty => 'Žiadne persony.';

  @override
  String get personaGalleryChooseFeatured =>
      'Vyberte persony, ktoré chcete ukázať';

  @override
  String get personaUndo => 'Vrátiť späť';
}
