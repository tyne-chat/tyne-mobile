// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class ForkLocalizationsCs extends ForkLocalizations {
  ForkLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Změnit personu';

  @override
  String get chatAttachmentPanelVoice => 'Hlas';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Tlačítko rychlého přepínače';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Nahradit tlačítko hlasové zprávy v poli pro zadávání tlačítkem rychlého přepínače pro svižnou navigaci';

  @override
  String get userSettingsCheckForUpdates => 'Zkontrolovat aktualizace';

  @override
  String get userSettingsCheckingForUpdates => 'Kontrola aktualizací…';

  @override
  String get userSettingsAppUpToDate => 'Tyne je aktuální';

  @override
  String get userSettingsUpdateAvailableTitle => 'Je k dispozici aktualizace';

  @override
  String get userSettingsUpdateDownloadAction => 'Stáhnout a instalovat';

  @override
  String get userSettingsUpdateInstallAction => 'Instalovat aktualizaci';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Stahování aktualizace ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Kontrola nebo stažení aktualizace se nezdařilo.';

  @override
  String get personaSelectTitle => 'Vyberte personu';

  @override
  String get personaSettingsHeader => 'Nastavení person';

  @override
  String get personaManageAction => 'Spravovat';

  @override
  String get personaSearchPlaceholder => 'Hledat persony, značky, zájmena...';

  @override
  String get personaModeManual => 'Ručně';

  @override
  String get personaModeLast => 'Naposledy použito';

  @override
  String get personaModeManualDescription =>
      'Vždy odesílá jako vybraná persona až do změny.';

  @override
  String get personaModeLastDescription =>
      'Automaticky přepne na personu použitou v poslední zprávě.';

  @override
  String get personaRecentHeader => 'NEDÁVNÉ PERSONY';

  @override
  String personaAllHeader(int count) {
    return 'VŠECHNY PERSONY ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'VÝSLEDKY VYHLEDÁVÁNÍ ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Hlavní účet (Výchozí)';

  @override
  String get personaEmptyState =>
      'Zatím nejsou nastaveny žádné persony. Vytvořte si ji v nabídce „Spravovat persony“.';

  @override
  String get personaEmptySearch =>
      'Nebyly nalezeny žádné odpovídající persony.';

  @override
  String get personaEditTitle => 'Upravit personu';

  @override
  String get personaCreateTitle => 'Vytvořit personu';

  @override
  String get personaDisplayNameLabel => 'Zobrazované jméno';

  @override
  String get personaPronounsLabel => 'Zájmena';

  @override
  String get personaPronounsHint => 'např. oni/jejich';

  @override
  String get personaBioHint => 'Řekněte ostatním něco o této personě...';

  @override
  String get personaUpdatedToast => 'Persona aktualizována';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Nepodařilo se aktualizovat personu: $error';
  }

  @override
  String get personaSectionTitle => 'Persony';

  @override
  String get personaDisplayNameHint => 'Jméno persony';

  @override
  String personaSendingAsTag(String name) {
    return 'Odesílá se jako $name (Přiřazeno podle značky)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Odesílá se jako $name (Uzamčeno)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Odesílá se jako $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Publikuje se jako $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Odesílá se jako @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'Neodesláno: vaše persony se ještě nenačetly.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Neodesláno: vaše persony se ještě nenačetly. Odeslat místo toho jako @$username?';
  }

  @override
  String get personaSendAsAccountAction => 'Přesto odeslat';

  @override
  String get personaMainAccount => 'Hlavní účet';

  @override
  String get personaEditPersona => 'Upravit personu';

  @override
  String get userSettingsNavPersonas => 'Persony';

  @override
  String get personaSettingsDescription =>
      'Nakonfigurujte si režim aktivní persony, vlastní zobrazovanou značku a spravujte jednotlivé persony.';

  @override
  String get personaDisplayTagSection => 'Zobrazovaná značka';

  @override
  String get personaDisplayTagDescription =>
      'Zobrazovaná značka se objeví vedle jmen všech person ve zprávách. Pokud není nastavena žádná zobrazovaná značka, zobrazí se vaše profilová fotka účtu.';

  @override
  String get personaDisplayTagLabel => 'Text zobrazované značky';

  @override
  String get personaDisplayTagHint => 'např. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Ikona zobrazované značky';

  @override
  String get personaUploadTagIcon => 'Nahrát ikonu';

  @override
  String get personaChangeTagIcon => 'Změnit ikonu';

  @override
  String get personaRemoveTagIcon => 'Odebrat ikonu';

  @override
  String get personaChatPreviewTitle => 'Náhled chatu';

  @override
  String get personaChatPreviewSampleMessage =>
      'Ahoj! Toto je náhled toho, jak vypadají zprávy s vaší zobrazovanou značkou a aktivní personou.';

  @override
  String get personaListTitle => 'Nakonfigurované persony';

  @override
  String get personaAddButton => 'Přidat personu';

  @override
  String get personaActiveBadge => 'Aktivní';

  @override
  String get personaMakeActive => 'Nastavit jako aktivní';

  @override
  String get personaDeleteTitle => 'Smazat personu';

  @override
  String personaDeleteMessage(String name) {
    return 'Opravdu chcete smazat „$name“? Tuto akci nelze vrátit zpět.';
  }

  @override
  String get personaDeleteConfirm => 'Smazat';

  @override
  String get personaDeletedToast => 'Persona smazána';

  @override
  String get personaCreatedToast => 'Persona vytvořena';

  @override
  String personaCreateFailedToast(String error) {
    return 'Nepodařilo se vytvořit personu: $error';
  }

  @override
  String get personaChangeAvatar => 'Změnit avatar';

  @override
  String get personaRemoveAvatar => 'Odebrat avatar';

  @override
  String get personaUploadAvatar => 'Nahrát avatar';

  @override
  String get personaTagsLabel => 'Značky persony';

  @override
  String get personaAutoTagDisabledLabel => 'Nerozpoznávat značky této persony';

  @override
  String get personaAutoTagDisabledDescription =>
      'Zadání některé z těchto značek nepřepne na tuto personu. Značka se odešle tak, jak je napsaná.';

  @override
  String get personaTagPrefixLabel => 'Předpona';

  @override
  String get personaTagSuffixLabel => 'Přípona';

  @override
  String get personaVisibilityLabel => 'Viditelnost';

  @override
  String get personaVisibilityUnlisted => 'Neuvedeno';

  @override
  String get personaVisibilityPublic => 'Veřejné';

  @override
  String get personaVisibilityPrivate => 'Soukromé';

  @override
  String get personaNameRequired => 'Zadejte zobrazované jméno persony';

  @override
  String get personaNameTooLong =>
      'Zobrazované jméno persony musí mít maximálně 100 znaků';

  @override
  String get personaTagPrefixTooLong =>
      'Předpona tagu persony musí mít maximálně 32 znaků';

  @override
  String get personaTagSuffixTooLong =>
      'Přípona tagu persony musí mít maximálně 32 znaků';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Tag \'$tag\' již používá \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Vložit časové razítko';

  @override
  String get chatAttachmentSendVoiceMessage => 'Odeslat hlasovou zprávu';

  @override
  String get timestampPickerTitle => 'Vložit časové razítko';

  @override
  String get timestampPickerInsert => 'Vložit';

  @override
  String get timestampCopied => 'Časové razítko zkopírováno';

  @override
  String get timestampPickerTimeLabel => 'Čas';

  @override
  String get timestampPickerDateLabel => 'DATUM';

  @override
  String get timestampPickerTimeSectionLabel => 'ČAS';

  @override
  String get timestampPickerTimezoneLabel => 'ČASOVÉ PÁSMO';

  @override
  String get timestampPickerFormatPreviewLabel => 'NÁHLED FORMÁTU';

  @override
  String get timestampPickerNlpPlaceholder =>
      'např. zítra v 15:00, za 2 hodiny, teď';

  @override
  String get timestampPickerSearchTimezones => 'Hledat časová pásma...';

  @override
  String get userProfileTimezoneSettingLabel => 'Časové pásmo';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Slouží k zobrazení vašeho místního času na profilu.';

  @override
  String get userProfileTimezoneNone => 'Žádné';

  @override
  String get chatReactAs => 'Reagovat jako...';

  @override
  String get emojiCopy => 'Kopírovat emoji';

  @override
  String get emojiCopyLink => 'Kopírovat odkaz';

  @override
  String get emojiPin => 'Připnout emoji';

  @override
  String get emojiUnpin => 'Odepnout emoji';

  @override
  String get emojiPinForPersona => 'Připnout pro tuto personu';

  @override
  String get emojiUnpinForPersona => 'Odepnout pro tuto personu';

  @override
  String get personaSignatureEmojisLabel => 'Podpisové emoji';

  @override
  String get personaSignatureEmojisDescription =>
      'Reagování podpisovým emoji vždy zareaguje jako tato persona, bez ohledu na aktivní personu.';

  @override
  String get personaAddSignatureEmoji => 'Přidat emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Toto emoji je již přidáno jako podpisové emoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Podpisové emoji již používá persona \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Odebrat podpisové emoji';

  @override
  String get signalBarLabel => 'Lišta signálů';

  @override
  String get signalBarShow => 'Zobrazit lištu signálů';

  @override
  String get signalBarHide => 'Skrýt lištu signálů';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Tento signál nemá nikdo zapnutý';

  @override
  String get signalBarReset => 'Resetovat signál pro všechny';

  @override
  String signalBarTurnOff(String name) {
    return 'Vypnout $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Pro výchozí instanci použijte $domain, nebo zadejte přesnou adresu URL jiné instance.';
  }

  @override
  String get instanceResetToDefault => 'Obnovit výchozí instanci';

  @override
  String get personaScopeTitle => 'Persona platí pro';

  @override
  String get personaScopeGlobal => 'Všude';

  @override
  String get personaScopeGlobalDescription =>
      'Jedna persona pro všechny kanály.';

  @override
  String get personaScopeChannel => 'V každém kanálu';

  @override
  String get personaScopeChannelDescription =>
      'Každý kanál si drží vlastní personu. Nové kanály začínají jako váš účet.';

  @override
  String get personaPickerChannelOnly => 'Jen pro tento kanál';

  @override
  String get personaProfilePrivate => 'Profil této persony je soukromý.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Soubor obrázku je příliš velký. Vyberte soubor menší než $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Hledat KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Aktualizaci se nepodařilo stáhnout';

  @override
  String get appUpdateInstallFailed => 'Aktualizaci se nepodařilo nainstalovat';

  @override
  String get personaChangeMessageFailed =>
      'Personu zprávy se nepodařilo změnit';

  @override
  String get personaActiveCleared => 'Aktivní persona zrušena';

  @override
  String get klipyPoweredBy => 'Využívá KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Duplicitní pár značek \'$pattern\' u této persony';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Přidat pár značek ($count/5)';
  }

  @override
  String get personaTagExampleText => 'text';

  @override
  String get personaPreviewNameFallback => 'Uživatel';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne se neočekávaně ukončil. Sdílení anonymních údajů o pádech a chybách nám pomáhá opravovat problémy rychleji.';

  @override
  String get crashReportingSectionDescription =>
      'Pomozte opravovat chyby v Tyne sdílením údajů o pádech a výkonu. Ve výchozím nastavení je vypnuto.';

  @override
  String get crashReportingDescription =>
      'Hlášení se odesílají do vlastního systému pro sledování chyb Tyne, i když jste přihlášeni k jiné instanci. Neobsahují názvy instancí, ID ani obsah zpráv.';

  @override
  String get instanceOfflineTitle => 'Tyne je offline!';

  @override
  String get instanceOfflineBody => 'Zjišťujeme, co se děje.';

  @override
  String get instanceStatusSignalLink =>
      'Připojte se k našemu chatu na Signalu pro novinky';

  @override
  String get convertEmoticonsLabel => 'Převádět textové emotikony na emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Nepodařilo se spustit /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Jeho skript má problém.';

  @override
  String guildCommandOneLine(String name) {
    return 'Co napíšete za /$name, se musí vejít na jeden řádek.';
  }

  @override
  String get permissionCreateCommands => 'Vytvářet příkazy';

  @override
  String get permissionManageCommands => 'Spravovat příkazy';

  @override
  String get permissionUseExternalCommands => 'Používat externí příkazy';

  @override
  String get permissionCreateCommandsDescription =>
      'Vytvářet příkazy pro tuto komunitu a upravovat nebo mazat vlastní.';

  @override
  String get permissionManageCommandsDescription =>
      'Upravovat nebo mazat příkazy kohokoli v této komunitě.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Používat příkazy z jiných komunit.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Používat příkazy z jiných komunit v tomto kanálu.';

  @override
  String get guildSettingsCategoryMessageTools => 'Nástroje zpráv';

  @override
  String get guildSettingsCommands => 'Příkazy';

  @override
  String get guildCommandsLoadFailed => 'Příkazy se nepodařilo načíst.';

  @override
  String get guildCommandsSubtitle =>
      'Zprávy, které členové mohou odeslat napsáním /name.';

  @override
  String get guildCommandsSlots => 'Sloty na příkazy';

  @override
  String get guildCommandsNew => 'Nový příkaz';

  @override
  String get guildCommandsSearch => 'Hledat příkazy';

  @override
  String get guildCommandsEmptyTitle => 'Žádné příkazy';

  @override
  String get guildCommandsEmptyBody =>
      'Tato komunita zatím nemá žádné příkazy.';

  @override
  String get guildCommandsSaved => 'Příkazy uloženy';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Nepodařilo se uložit /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Upravit /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Smazat /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Tuto akci nelze vrátit zpět. Zprávy vytvořené tímto příkazem stále ukazují, který příkaz je vytvořil.';

  @override
  String get guildCommandDelete => 'Smazat';

  @override
  String get guildCommandDeleteCommand => 'Smazat příkaz';

  @override
  String get guildCommandSectionCommand => 'Příkaz';

  @override
  String get guildCommandName => 'Název';

  @override
  String get guildCommandNameInvalid =>
      'Použijte malá písmena, číslice, - a _, nejvýše 32 znaků.';

  @override
  String get guildCommandNameTaken =>
      'Tento název už má jiný příkaz nebo vestavěný příkaz.';

  @override
  String get guildCommandDescription => 'Popis';

  @override
  String get guildCommandSectionInput => 'Vstup';

  @override
  String get guildCommandInputNone => 'Žádné';

  @override
  String get guildCommandInputOptional => 'Volitelné';

  @override
  String get guildCommandInputRequired => 'Povinné';

  @override
  String get guildCommandHint => 'Nápověda';

  @override
  String get guildCommandMessage => 'Zpráva';

  @override
  String get guildCommandInsert => 'Vložit:';

  @override
  String get guildCommandInsertPerson => 'Kdo ho používá';

  @override
  String get guildCommandInsertInput => 'Co napíšou';

  @override
  String get guildCommandPreview => 'Náhled';

  @override
  String get guildCommandSampleInput => 'Ukázkový vstup';

  @override
  String guildCommandMadeWith(String name) {
    return 'Vytvořeno pomocí /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Vyprázdněte pole zprávy, abyste mohli použít /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Nic by se neodeslalo, takže by příkaz selhal.';

  @override
  String get guildCommandUseScriptEditor => 'Použít editor skriptů';

  @override
  String get guildCommandUseBasicEditor => 'Použít základní editor';

  @override
  String get guildCommandScript => 'Skript';

  @override
  String get guildCommandRunAgain => 'Spustit znovu';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Značka s názvem $name neexistuje.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Filtr s názvem $name neexistuje.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name se nikdy neuzavírá.';
  }

  @override
  String get guildCommandIssueTooLong => 'Skript je příliš dlouhý.';

  @override
  String get guildCommandIssueTooLarge => 'Skript vytváří příliš mnoho textu.';

  @override
  String get guildCommandIssueTooSlow =>
      'Spuštění skriptu trvalo příliš dlouho.';

  @override
  String get guildCommandIssueInvalid => 'Tuto část nelze přečíst.';

  @override
  String get guildCommandIssueFailed => 'Tato část skončila chybou.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Řádek $line, sloupec $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Nápověda ke skriptům';

  @override
  String get guildCommandReferencePerson => 'Kdo ho používá, jako zmínka';

  @override
  String get guildCommandReferencePersonName => 'Jméno toho, kdo ho používá';

  @override
  String get guildCommandReferenceTarget =>
      'První zmíněná osoba, pokud nějaká je';

  @override
  String get guildCommandReferenceTargetName => 'Jméno této osoby';

  @override
  String get guildCommandReferenceChannel => 'Kanál jako zmínka';

  @override
  String get guildCommandReferenceCommunity => 'Název této komunity';

  @override
  String get guildCommandExampleRandom => 'Náhodně vybrat jednu možnost';

  @override
  String get guildCommandExampleDepends =>
      'Změnit zprávu podle toho, co bylo napsáno';

  @override
  String get guildCommandExampleOneWord => 'Náhodně vybrat jedno slovo';

  @override
  String get guildCommandExampleWordForNumber => 'Vybrat slovo podle čísla';

  @override
  String get guildCommandExampleOrdinal => 'Napsat číslo jako 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Úplný průvodce skripty';

  @override
  String get guildCommandCounters => 'Počítadla';

  @override
  String get guildCommandCounterAdd => 'Přidat počítadlo';

  @override
  String get guildCommandCounterSeparately => 'Počítat zvlášť pro každého:';

  @override
  String get guildCommandCounterPersonMentioned => 'Zmíněná osoba';

  @override
  String get guildCommandCounterChannel => 'Kanál';

  @override
  String get guildCommandCounterPersonas => 'Počítat persony zvlášť';

  @override
  String get guildCommandCounterRemove => 'Odebrat počítadlo';

  @override
  String get guildCommandCounterReset => 'Vynulovat počty';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Vynulovat počty pro $name? Tuto akci nelze vrátit zpět.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Použij malá písmena, číslice a _, začni písmenem a nepoužívej název, který už skripty používají.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Ve skriptu ho použij jako $variable. Každé spuštění nejdřív přičte jedničku, takže první spuštění přečte 1.';
  }

  @override
  String get notificationsAlertEveryMessageLabel =>
      'Upozornit na každou zprávu';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Když je vypnuto, rušná konverzace upozorní jen jednou a pak se tiše aktualizuje, dokud ji nepřečtete nebo nezavřete.';

  @override
  String personaGalleryTitle(int count) {
    return 'Persony ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Hledat v personách uživatele $name';
  }

  @override
  String get personaGallerySearchOwn => 'Hledat ve vašich personách';

  @override
  String get personaGallerySortBy => 'Seřadit podle';

  @override
  String get personaGallerySortName => 'Jméno (A–Z)';

  @override
  String get personaGallerySortMostUsed => 'Nejpoužívanější';

  @override
  String get personaGallerySortRecentlyUsed => 'Naposledy použité';

  @override
  String get personaGalleryViewGallery => 'Galerie';

  @override
  String get personaGalleryViewList => 'Seznam';

  @override
  String get personaGalleryViewAvatars => 'Avatary';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person',
      many: '$count persony',
      few: '$count persony',
      one: '$count persona',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return '$shown z $total person';
  }

  @override
  String get personaGalleryNoMatch => 'Hledání neodpovídá žádná persona.';

  @override
  String get personaGalleryLoadFailed => 'Persony se nepodařilo načíst.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veřejných person',
      many: '$count veřejné persony',
      few: '$count veřejné persony',
      one: '$count veřejnou personu',
    );
    return 'Ostatní vidí $_temp0.';
  }

  @override
  String get personaGalleryShowHidden => 'Zobrazit neuvedené a soukromé';

  @override
  String get personaGalleryManage => 'Spravovat persony';

  @override
  String get personaGalleryNonePublic =>
      'Žádná z vašich person zatím není veřejná. Ostatní tu personu uvidí, jakmile jí nastavíte viditelnost na „Veřejné“.';

  @override
  String get personaGalleryNoBio => 'Zatím bez popisu.';

  @override
  String personaGalleryCreated(String date) {
    return 'Vytvořeno $date';
  }

  @override
  String get personaBulkSelect => 'Vybrat';

  @override
  String get personaBulkSelectAll => 'Vybrat vše';

  @override
  String personaBulkSelectedCount(int count) {
    return 'Vybráno: $count';
  }

  @override
  String get personaFilterAll => 'Vše';

  @override
  String get personaBulkMakePublic => 'Nastavit jako veřejné';

  @override
  String get personaBulkMakeUnlisted => 'Nastavit jako neuvedené';

  @override
  String get personaBulkMakePrivate => 'Nastavit jako soukromé';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person',
      many: '$count persony',
      few: '$count persony',
      one: '$count personu',
    );
    return 'Nastavit $_temp0 jako veřejné?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person',
      many: '$count persony',
      few: '$count persony',
      one: '$count personu',
    );
    return 'Nastavit $_temp0 jako soukromé?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person',
      many: '$count persony',
      few: '$count persony',
      one: '$count personu',
    );
    return 'Smazat $_temp0?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Ostatní je uvidí ve vašem seznamu person a budou moci otevřít jejich profily. Kdykoli to můžete změnit zpět.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Jejich profily budou před ostatními skryté. Jejich jména a avatary se budou dál zobrazovat u jejich zpráv a reakcí.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Jejich zprávy budou dál ukazovat jejich jména a avatary, ale už za ně nebudete moci psát a jejich značky a podpisové emoji se uvolní. Tuto akci nelze vrátit.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person je nyní veřejných',
      many: '$count persony jsou nyní veřejné',
      few: '$count persony jsou nyní veřejné',
      one: '$count persona je nyní veřejná',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person je nyní neuvedených',
      many: '$count persony jsou nyní neuvedené',
      few: '$count persony jsou nyní neuvedené',
      one: '$count persona je nyní neuvedená',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person je nyní soukromých',
      many: '$count persony jsou nyní soukromé',
      few: '$count persony jsou nyní soukromé',
      one: '$count persona je nyní soukromá',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count person smazáno',
      many: '$count persony smazány',
      few: '$count persony smazány',
      one: '$count persona smazána',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed =>
      'Persony se nepodařilo změnit. Zkuste to znovu.';

  @override
  String get personaFilterEmpty => 'Žádné persony.';

  @override
  String get personaGalleryChooseFeatured =>
      'Vyberte persony, které chcete ukázat';

  @override
  String get personaUndo => 'Zpět';

  @override
  String get personaReactionsTitle => 'Vaše reakce';

  @override
  String get personaReactionsEveryoneElse => 'VŠICHNI OSTATNÍ';

  @override
  String get personaReactionsCurrent => 'AKTUÁLNÍ';

  @override
  String get personaReactionsAccount => 'Účet';

  @override
  String get personaReactionsSomeoneElse => 'Reagovat jako někdo jiný...';

  @override
  String get personaReactionsDone => 'Hotovo';

  @override
  String get personaSettingsReactionsHeader => 'Reakce';

  @override
  String get personaSettingsMultiReactions =>
      'Reagovat jako více person najednou';

  @override
  String get personaDuplicateButton => 'Duplikovat personu';

  @override
  String personaCopyOf(String name) {
    return 'Kopie persony $name';
  }

  @override
  String signalsEverywhereTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chatů',
      many: '$count chatu',
      few: '$count chaty',
      one: '$count chat',
    );
    return 'Tvoje signály všude · $_temp0';
  }

  @override
  String signalsEverywhereHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chatů',
      many: '$count chatu',
      few: '$count chaty',
      one: '$count chat',
    );
    return 'Nastavit všude ($_temp0)';
  }

  @override
  String signalsEverywhereSet(String label) {
    return 'Nastavit $label všude';
  }

  @override
  String get signalsEverywhereTurnAllOff => 'Vypnout vše';

  @override
  String get signalsEverywhereRestore => 'Obnovit…';

  @override
  String get signalsEverywhereNone => 'Nikde nemáš zapnutý žádný signál.';

  @override
  String get signalsRestoreTitle => 'Obnovit tvoje signály?';

  @override
  String signalsRestoreBeforeSet(String label, String time) {
    return 'Vrátí stav před nastavením signálu $label všude ($time). Co tam máš zapnuté teď, se vypne.';
  }

  @override
  String signalsRestoreBeforeOff(String time) {
    return 'Vrátí stav před vypnutím všech signálů ($time). Co tam máš zapnuté teď, se vypne.';
  }

  @override
  String signalsRestoreBeforeRestore(String time) {
    return 'Vrátí stav před tvým posledním obnovením ($time). Co tam máš zapnuté teď, se vypne.';
  }

  @override
  String get signalsRestoreNow => 'Teď';

  @override
  String get signalsRestoreAfter => 'Potom';

  @override
  String signalsRestoreMoreChats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count dalších chatů',
      many: '+ $count dalšího chatu',
      few: '+ $count další chaty',
      one: '+ $count další chat',
    );
    return '$_temp0';
  }

  @override
  String signalsRestoreLeftOut(String chats) {
    return 'Vynecháno, protože tam už nemůžeš psát: $chats';
  }

  @override
  String get signalsRestoreConfirm => 'Obnovit';

  @override
  String get signalsRestoreUnavailable =>
      'Nepodařilo se načíst, co by „Obnovit“ změnilo. Zkus to znovu.';

  @override
  String get signalsRestoreNothing => 'Není co obnovit.';

  @override
  String get signalsProfileMenu => 'Signály';
}
