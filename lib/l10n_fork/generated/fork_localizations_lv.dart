// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class ForkLocalizationsLv extends ForkLocalizations {
  ForkLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Mainīt personu';

  @override
  String get chatAttachmentPanelVoice => 'Balss';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'Ātrā pārslēdzēja poga';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Aizstāt balss ziņas pogu ziņas ievades laukā ar ātrā pārslēdzēja pogu ērtākai pārvietošanās iespējai';

  @override
  String get userSettingsCheckForUpdates => 'Pārbaudīt atjauninājumus';

  @override
  String get userSettingsCheckingForUpdates => 'Notiek atjauninājumu pārbaude…';

  @override
  String get userSettingsAppUpToDate => 'Jums ir jaunākā Tyne versija';

  @override
  String get userSettingsUpdateAvailableTitle => 'Pieejams atjauninājums';

  @override
  String get userSettingsUpdateDownloadAction => 'Lejupielādēt un instalēt';

  @override
  String get userSettingsUpdateInstallAction => 'Instalēt atjauninājumu';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Lejupielādē atjauninājumu ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Neizdevās pārbaudīt vai lejupielādēt atjauninājumu.';

  @override
  String get personaSelectTitle => 'Izvēlēties personu';

  @override
  String get personaSettingsHeader => 'Personu iestatījumi';

  @override
  String get personaManageAction => 'Pārvaldīt';

  @override
  String get personaSearchPlaceholder =>
      'Meklēt personas, birkas, vietniekvārdus...';

  @override
  String get personaModeManual => 'Manuāli';

  @override
  String get personaModeLast => 'Pēdējā izmantotā';

  @override
  String get personaModeManualDescription =>
      'Ziņas vienmēr tiek sūtītas kā izvēlētā persona, līdz to nomaināt.';

  @override
  String get personaModeLastDescription =>
      'Automātiski pārslēdzas uz personu, kas izmantota jūsu pēdējā ziņā.';

  @override
  String get personaRecentHeader => 'NESEN LIETOTĀS PERSONAS';

  @override
  String personaAllHeader(int count) {
    return 'VISAS PERSONAS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'MEKLĒŠANAS REZULTĀTI ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Galvenais konts (noklusējums)';

  @override
  String get personaEmptyState =>
      'Vēl nav nevienas personas. Izveidojiet to sadaļā „Pārvaldīt personas”.';

  @override
  String get personaEmptySearch => 'Atbilstošas personas netika atrastas.';

  @override
  String get personaEditTitle => 'Rediģēt personu';

  @override
  String get personaCreateTitle => 'Izveidot personu';

  @override
  String get personaDisplayNameLabel => 'Rādāmais vārds';

  @override
  String get personaPronounsLabel => 'Vietniekvārdi';

  @override
  String get personaPronounsHint => 'piem., viņa/viņas';

  @override
  String get personaBioHint => 'Pastāstiet citiem par šo personu...';

  @override
  String get personaUpdatedToast => 'Persona atjaunināta';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Neizdevās atjaunināt personu: $error';
  }

  @override
  String get personaSectionTitle => 'Personas';

  @override
  String get personaDisplayNameHint => 'Personas vārds';

  @override
  String personaSendingAsTag(String name) {
    return 'Sūtāt kā $name (atpazīta pēc birkas)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Sūtāt kā $name (fiksēta)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Sūtāt kā $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Publicējat kā $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Sūtāt kā @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'Ziņa nav nosūtīta: jūsu personas vēl nav ielādētas.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Ziņa nav nosūtīta: jūsu personas vēl nav ielādētas. Sūtīt to kā @$username?';
  }

  @override
  String get personaSendAsAccountAction => 'Tomēr sūtīt';

  @override
  String get personaMainAccount => 'Galvenais konts';

  @override
  String get personaEditPersona => 'Rediģēt personu';

  @override
  String get userSettingsNavPersonas => 'Personas';

  @override
  String get personaSettingsDescription =>
      'Iestatiet aktīvās personas režīmu un savu rādāmo birku, kā arī pārvaldiet atsevišķas personas.';

  @override
  String get personaDisplayTagSection => 'Rādāmā birka';

  @override
  String get personaDisplayTagDescription =>
      'Rādāmā birka būs redzama ziņās blakus visu personu vārdiem. Ja rādāmā birka nav iestatīta, tiks rādīts jūsu konta profila attēls.';

  @override
  String get personaDisplayTagLabel => 'Rādāmās birkas teksts';

  @override
  String get personaDisplayTagHint => 'piem., SYS';

  @override
  String get personaDisplayTagIconLabel => 'Rādāmās birkas ikona';

  @override
  String get personaUploadTagIcon => 'Augšupielādēt ikonu';

  @override
  String get personaChangeTagIcon => 'Mainīt ikonu';

  @override
  String get personaRemoveTagIcon => 'Noņemt ikonu';

  @override
  String get personaChatPreviewTitle => 'Tērzēšanas priekšskatījums';

  @override
  String get personaChatPreviewSampleMessage =>
      'Sveiki! Šis ir priekšskatījums, kā ziņas izskatās ar jūsu rādāmo birku un aktīvo personu.';

  @override
  String get personaListTitle => 'Iestatītās personas';

  @override
  String get personaAddButton => 'Pievienot personu';

  @override
  String get personaActiveBadge => 'Aktīva';

  @override
  String get personaMakeActive => 'Padarīt aktīvu';

  @override
  String get personaDeleteTitle => 'Dzēst personu';

  @override
  String personaDeleteMessage(String name) {
    return 'Vai tiešām vēlaties dzēst „$name”? To nevar atsaukt.';
  }

  @override
  String get personaDeleteConfirm => 'Dzēst';

  @override
  String get personaDeletedToast => 'Persona dzēsta';

  @override
  String get personaCreatedToast => 'Persona izveidota';

  @override
  String personaCreateFailedToast(String error) {
    return 'Neizdevās izveidot personu: $error';
  }

  @override
  String get personaChangeAvatar => 'Mainīt avatāru';

  @override
  String get personaRemoveAvatar => 'Noņemt avatāru';

  @override
  String get personaUploadAvatar => 'Augšupielādēt avatāru';

  @override
  String get personaTagsLabel => 'Personas birkas';

  @override
  String get personaAutoTagDisabledLabel => 'Neatpazīt šīs personas birkas';

  @override
  String get personaAutoTagDisabledDescription =>
      'Ierakstot kādu no šīm birkām, netiks pārslēgts uz šo personu. Birka tiks nosūtīta tieši tā, kā uzrakstīta.';

  @override
  String get personaTagPrefixLabel => 'Prefikss';

  @override
  String get personaTagSuffixLabel => 'Sufikss';

  @override
  String get personaVisibilityLabel => 'Redzamība';

  @override
  String get personaVisibilityUnlisted => 'Ārpus saraksta';

  @override
  String get personaVisibilityPublic => 'Publiska';

  @override
  String get personaVisibilityPrivate => 'Privāta';

  @override
  String get personaNameRequired => 'Ievadiet personas rādāmo vārdu';

  @override
  String get personaNameTooLong =>
      'Personas rādāmais vārds nedrīkst būt garāks par 100 rakstzīmēm';

  @override
  String get personaTagPrefixTooLong =>
      'Personas birkas prefikss nedrīkst būt garāks par 32 rakstzīmēm';

  @override
  String get personaTagSuffixTooLong =>
      'Personas birkas sufikss nedrīkst būt garāks par 32 rakstzīmēm';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Birku „$tag” jau izmanto „$name”.';
  }

  @override
  String get chatInsertTimestamp => 'Ievietot laikspiedolu';

  @override
  String get chatAttachmentSendVoiceMessage => 'Sūtīt balss ziņu';

  @override
  String get timestampPickerTitle => 'Ievietot laikspiedolu';

  @override
  String get timestampPickerInsert => 'Ievietot';

  @override
  String get timestampCopied => 'Laikspiedols nokopēts';

  @override
  String get timestampPickerTimeLabel => 'Laiks';

  @override
  String get timestampPickerDateLabel => 'DATUMS';

  @override
  String get timestampPickerTimeSectionLabel => 'LAIKS';

  @override
  String get timestampPickerTimezoneLabel => 'LAIKA JOSLA';

  @override
  String get timestampPickerFormatPreviewLabel => 'FORMĀTA PRIEKŠSKATĪJUMS';

  @override
  String get timestampPickerNlpPlaceholder =>
      'piem., tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'Meklēt laika joslas...';

  @override
  String get userProfileTimezoneSettingLabel => 'Laika josla';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Tiek izmantota, lai jūsu profilā rādītu jūsu vietējo laiku.';

  @override
  String get userProfileTimezoneNone => 'Nav';

  @override
  String get chatReactAs => 'Reaģēt kā...';

  @override
  String get emojiCopy => 'Kopēt emocijzīmi';

  @override
  String get emojiCopyLink => 'Kopēt saiti';

  @override
  String get emojiPin => 'Piespraust emocijzīmi';

  @override
  String get emojiUnpin => 'Atspraust emocijzīmi';

  @override
  String get emojiPinForPersona => 'Piespraust šai personai';

  @override
  String get emojiUnpinForPersona => 'Atspraust šai personai';

  @override
  String get personaSignatureEmojisLabel => 'Raksturīgās emocijzīmes';

  @override
  String get personaSignatureEmojisDescription =>
      'Reaģējot ar raksturīgo emocijzīmi, jūs vienmēr reaģēsiet kā šī persona neatkarīgi no aktīvās personas.';

  @override
  String get personaAddSignatureEmoji => 'Pievienot emocijzīmi';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Šī emocijzīme jau ir pievienota kā raksturīgā emocijzīme';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Raksturīgo emocijzīmi jau izmanto persona „$name”';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Noņemt raksturīgo emocijzīmi';

  @override
  String get signalBarLabel => 'Signālu josla';

  @override
  String get signalBarShow => 'Rādīt signālu joslu';

  @override
  String get signalBarHide => 'Paslēpt signālu joslu';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Neviens nav ieslēdzis šo signālu';

  @override
  String get signalBarReset => 'Atiestatīt signālu visiem';

  @override
  String signalBarTurnOff(String name) {
    return 'Izslēgt signālu: $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Noklusējuma serverim izmantojiet $domain vai ievadiet precīzu cita servera URL.';
  }

  @override
  String get instanceResetToDefault => 'Atjaunot noklusējuma serveri';

  @override
  String get personaScopeTitle => 'Izvēlētā persona darbojas';

  @override
  String get personaScopeGlobal => 'Visur';

  @override
  String get personaScopeGlobalDescription => 'Viena persona visiem kanāliem.';

  @override
  String get personaScopeChannel => 'Katrā kanālā';

  @override
  String get personaScopeChannelDescription =>
      'Katrā kanālā tiek paturēta sava persona. Jaunos kanālos sākumā tiek izmantots jūsu konts.';

  @override
  String get personaPickerChannelOnly => 'Tikai šim kanālam';

  @override
  String get personaProfilePrivate => 'Šīs personas profils ir privāts.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Attēla fails ir pārāk liels. Izvēlieties failu, kas mazāks par $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Meklēt KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Neizdevās lejupielādēt atjauninājumu';

  @override
  String get appUpdateInstallFailed => 'Neizdevās instalēt atjauninājumu';

  @override
  String get personaChangeMessageFailed => 'Neizdevās mainīt ziņas personu';

  @override
  String get personaActiveCleared => 'Aktīvā persona noņemta';

  @override
  String get klipyPoweredBy => 'Nodrošina KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Šai personai birku pāris „$pattern” norādīts divreiz';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Pievienot birku pāri ($count/5)';
  }

  @override
  String get personaTagExampleText => 'teksts';

  @override
  String get personaPreviewNameFallback => 'Lietotājs';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne negaidīti aizvērās. Kopīgojot anonīmus avāriju un kļūdu datus, jūs palīdzat mums ātrāk novērst problēmas.';

  @override
  String get crashReportingSectionDescription =>
      'Palīdziet labot kļūdas lietotnē Tyne, kopīgojot avāriju un veiktspējas datus. Pēc noklusējuma šī funkcija ir izslēgta.';

  @override
  String get crashReportingDescription =>
      'Pārskati tiek sūtīti uz paša Tyne kļūdu izsekošanas sistēmu, pat ja izmantojat citu serveri. Tajos nav serveru nosaukumu, ID vai ziņu satura.';

  @override
  String get instanceOfflineTitle => 'Tyne ir bezsaistē!';

  @override
  String get instanceOfflineBody => 'Mēs jau noskaidrojam, kas noticis.';

  @override
  String get instanceStatusSignalLink =>
      'Pievienojieties mūsu Signal tērzēšanai, lai saņemtu jaunumus';

  @override
  String get convertEmoticonsLabel => 'Pārvērst teksta smaidiņus emocijzīmēs';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Neizdevās izpildīt /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Tās skriptā ir kļūda.';

  @override
  String guildCommandOneLine(String name) {
    return 'Tam, ko ierakstāt pēc /$name, jāietilpst vienā rindā.';
  }

  @override
  String get permissionCreateCommands => 'Veidot komandas';

  @override
  String get permissionManageCommands => 'Pārvaldīt komandas';

  @override
  String get permissionUseExternalCommands => 'Izmantot ārējās komandas';

  @override
  String get permissionCreateCommandsDescription =>
      'Veidot komandas šajā kopienā un rediģēt vai dzēst savējās.';

  @override
  String get permissionManageCommandsDescription =>
      'Rediģēt vai dzēst jebkura dalībnieka komandas šajā kopienā.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Izmantot citu kopienu komandas.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Izmantot citu kopienu komandas šajā kanālā.';

  @override
  String get guildSettingsCategoryMessageTools => 'Ziņu rīki';

  @override
  String get guildSettingsCommands => 'Komandas';

  @override
  String get guildCommandsLoadFailed => 'Neizdevās ielādēt komandas.';

  @override
  String get guildCommandsSubtitle =>
      'Ziņas, ko dalībnieki var publicēt, ierakstot /name.';

  @override
  String get guildCommandsSlots => 'Komandu vietas';

  @override
  String get guildCommandsNew => 'Jauna komanda';

  @override
  String get guildCommandsSearch => 'Meklēt komandas';

  @override
  String get guildCommandsEmptyTitle => 'Nav komandu';

  @override
  String get guildCommandsEmptyBody =>
      'Šai kopienai vēl nav nevienas komandas.';

  @override
  String get guildCommandsSaved => 'Komandas saglabātas';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Neizdevās saglabāt /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Rediģēt /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Dzēst /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'To nevar atsaukt. Ziņās, kas izveidotas ar šo komandu, joprojām būs redzams, kura komanda tās izveidoja.';

  @override
  String get guildCommandDelete => 'Dzēst';

  @override
  String get guildCommandDeleteCommand => 'Dzēst komandu';

  @override
  String get guildCommandSectionCommand => 'Komanda';

  @override
  String get guildCommandName => 'Nosaukums';

  @override
  String get guildCommandNameInvalid =>
      'Izmantojiet mazos burtus, ciparus, - un _, ne vairāk kā 32 rakstzīmes.';

  @override
  String get guildCommandNameTaken =>
      'Šāds nosaukums jau ir citai komandai vai iebūvētai komandai.';

  @override
  String get guildCommandDescription => 'Apraksts';

  @override
  String get guildCommandSectionInput => 'Ievade';

  @override
  String get guildCommandInputNone => 'Nav';

  @override
  String get guildCommandInputOptional => 'Neobligāti';

  @override
  String get guildCommandInputRequired => 'Obligāti';

  @override
  String get guildCommandHint => 'Mājiens';

  @override
  String get guildCommandMessage => 'Ziņa';

  @override
  String get guildCommandInsert => 'Ievietot:';

  @override
  String get guildCommandInsertPerson => 'Lietotājs, kas to palaiž';

  @override
  String get guildCommandInsertInput => 'Ko lietotājs ieraksta';

  @override
  String get guildCommandPreview => 'Priekšskatījums';

  @override
  String get guildCommandSampleInput => 'Ievades piemērs';

  @override
  String guildCommandMadeWith(String name) {
    return 'Izveidota ar /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Notīriet ziņas lauku, lai izmantotu /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Šī komanda neko nepublicētu, tāpēc tā neizdotos.';

  @override
  String get guildCommandUseScriptEditor => 'Izmantot skriptu redaktoru';

  @override
  String get guildCommandUseBasicEditor => 'Izmantot pamata redaktoru';

  @override
  String get guildCommandScript => 'Skripts';

  @override
  String get guildCommandRunAgain => 'Palaist vēlreiz';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Nav taga ar nosaukumu $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Nav filtra ar nosaukumu $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name nav aizvērts.';
  }

  @override
  String get guildCommandIssueTooLong => 'Skripts ir pārāk garš.';

  @override
  String get guildCommandIssueTooLarge => 'Skripts izveido pārāk daudz teksta.';

  @override
  String get guildCommandIssueTooSlow =>
      'Skripta izpilde aizņēma pārāk ilgu laiku.';

  @override
  String get guildCommandIssueInvalid => 'Šo daļu nevar nolasīt.';

  @override
  String get guildCommandIssueFailed => 'Šajā daļā radās kļūda.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return '$line. rinda, $column. kolonna: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Skriptu uzziņas';

  @override
  String get guildCommandReferencePerson =>
      'Lietotājs, kas to palaiž, kā pieminējums';

  @override
  String get guildCommandReferencePersonName =>
      'Tā lietotāja vārds, kas to palaiž';

  @override
  String get guildCommandReferenceTarget =>
      'Pirmais pieminētais lietotājs, ja tāds ir';

  @override
  String get guildCommandReferenceTargetName => 'Šī lietotāja vārds';

  @override
  String get guildCommandReferenceChannel => 'Kanāls kā pieminējums';

  @override
  String get guildCommandReferenceCommunity => 'Šīs kopienas nosaukums';

  @override
  String get guildCommandExampleRandom => 'Nejauši izvēlēties vienu variantu';

  @override
  String get guildCommandExampleDepends =>
      'Mainīt ziņu atkarībā no tā, ko lietotājs ierakstīja';

  @override
  String get guildCommandExampleOneWord => 'Nejauši izvēlēties vienu vārdu';

  @override
  String get guildCommandExampleWordForNumber =>
      'Izvēlēties vārdu atkarībā no skaitļa';

  @override
  String get guildCommandExampleOrdinal => 'Rakstīt skaitli kā 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Pilna skriptu rokasgrāmata';

  @override
  String get guildCommandCounters => 'Skaitītāji';

  @override
  String get guildCommandCounterAdd => 'Pievienot skaitītāju';

  @override
  String get guildCommandCounterSeparately => 'Skaitīt atsevišķi katram:';

  @override
  String get guildCommandCounterPersonMentioned => 'Pieminētais lietotājs';

  @override
  String get guildCommandCounterChannel => 'Kanāls';

  @override
  String get guildCommandCounterPersonas => 'Skaitīt personas atsevišķi';

  @override
  String get guildCommandCounterRemove => 'Noņemt skaitītāju';

  @override
  String get guildCommandCounterReset => 'Atiestatīt skaitītājus';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Atiestatīt $name skaitītājus? To nevar atsaukt.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Izmantojiet mazos burtus, ciparus un _; nosaukumam jāsākas ar burtu, un tas nedrīkst sakrist ar skriptos jau izmantotu nosaukumu.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Izmantojiet to skriptā kā $variable. Katra palaišana vispirms pieskaita vienu, tāpēc pirmajā palaišanā vērtība ir 1.';
  }

  @override
  String get notificationsAlertEveryMessageLabel => 'Paziņot par katru ziņu';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Ja izslēgts, par aktīvu sarunu tiek paziņots vienreiz, pēc tam paziņojums tiek klusi atjaunināts, līdz to izlasāt vai noraidāt.';

  @override
  String personaGalleryTitle(int count) {
    return 'Personas ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Meklēt lietotāja $name personas';
  }

  @override
  String get personaGallerySearchOwn => 'Meklēt savas personas';

  @override
  String get personaGallerySortBy => 'Kārtot pēc';

  @override
  String get personaGallerySortName => 'Vārds (A–Ž)';

  @override
  String get personaGallerySortMostUsed => 'Visbiežāk lietotās';

  @override
  String get personaGallerySortRecentlyUsed => 'Nesen lietotās';

  @override
  String get personaGalleryViewGallery => 'Galerija';

  @override
  String get personaGalleryViewList => 'Saraksts';

  @override
  String get personaGalleryViewAvatars => 'Avatāri';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '$count persona',
      zero: '$count personas',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return '$shown no $total personām';
  }

  @override
  String get personaGalleryNoMatch =>
      'Neviena persona neatbilst meklēšanas vaicājumam.';

  @override
  String get personaGalleryLoadFailed => 'Neizdevās ielādēt personas.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count publiskas personas',
      one: '$count publisku personu',
      zero: '$count publiskas personas',
    );
    return 'Citi redz $_temp0.';
  }

  @override
  String get personaGalleryShowHidden =>
      'Rādīt arī personas ārpus saraksta un privātās';

  @override
  String get personaGalleryManage => 'Pārvaldīt personas';

  @override
  String get personaGalleryNonePublic =>
      'Neviena no jūsu personām vēl nav publiska. Citi šeit redz personu, kad iestatāt tās redzamību uz „Publiska”.';

  @override
  String get personaGalleryNoBio => 'Apraksta vēl nav.';

  @override
  String personaGalleryCreated(String date) {
    return 'Izveidota $date';
  }

  @override
  String get personaBulkSelect => 'Atlasīt';

  @override
  String get personaBulkSelectAll => 'Atlasīt visas';

  @override
  String personaBulkSelectedCount(int count) {
    return 'Atlasītas: $count';
  }

  @override
  String get personaFilterAll => 'Visas';

  @override
  String get personaBulkMakePublic => 'Padarīt publiskas';

  @override
  String get personaBulkMakeUnlisted => 'Izņemt no saraksta';

  @override
  String get personaBulkMakePrivate => 'Padarīt privātas';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas publiskas',
      one: '$count personu publisku',
      zero: '$count personas publiskas',
    );
    return 'Padarīt $_temp0?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas privātas',
      one: '$count personu privātu',
      zero: '$count personas privātas',
    );
    return 'Padarīt $_temp0?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '$count personu',
      zero: '$count personas',
    );
    return 'Dzēst $_temp0?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Citi tās redzēs jūsu personu sarakstā un varēs atvērt to profilus. To jebkurā laikā var mainīt atpakaļ.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Šo personu profili tiks paslēpti no citiem. Vārdi un avatāri joprojām būs redzami pie to ziņām un reakcijām.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Ziņās joprojām būs redzami to vārdi un avatāri, taču jūs vairs nevarēsiet rakstīt to vārdā, un to birkas un raksturīgās emocijzīmes kļūs brīvas. To nevar atsaukt.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas tagad ir publiskas',
      one: '$count persona tagad ir publiska',
      zero: '$count personas tagad ir publiskas',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas tagad ir ārpus saraksta',
      one: '$count persona tagad ir ārpus saraksta',
      zero: '$count personas tagad ir ārpus saraksta',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas tagad ir privātas',
      one: '$count persona tagad ir privāta',
      zero: '$count personas tagad ir privātas',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dzēstas $count personas',
      one: 'Dzēsta $count persona',
      zero: 'Dzēstas $count personas',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed =>
      'Neizdevās mainīt personas. Mēģiniet vēlreiz.';

  @override
  String get personaFilterEmpty => 'Šeit nav personu.';

  @override
  String get personaGalleryChooseFeatured => 'Izvēlēties, kuras personas rādīt';

  @override
  String get personaUndo => 'Atsaukt';

  @override
  String get personaReactionsTitle => 'Jūsu reakcijas';

  @override
  String get personaReactionsEveryoneElse => 'VISI PĀRĒJIE';

  @override
  String get personaReactionsCurrent => 'PAŠREIZĒJĀ';

  @override
  String get personaReactionsAccount => 'Konts';

  @override
  String get personaReactionsSomeoneElse => 'Reaģēt kā kādam citam...';

  @override
  String get personaReactionsDone => 'Gatavs';

  @override
  String get personaSettingsReactionsHeader => 'Reakcijas';

  @override
  String get personaSettingsMultiReactions =>
      'Reaģēt kā vairākas personas vienlaikus';

  @override
  String get personaDuplicateButton => 'Dublēt personu';

  @override
  String personaCopyOf(String name) {
    return 'Personas $name kopija';
  }
}
