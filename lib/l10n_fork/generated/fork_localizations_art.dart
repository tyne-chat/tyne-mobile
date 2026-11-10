// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Artificial languages (`art`).
class ForkLocalizationsArt extends ForkLocalizations {
  ForkLocalizationsArt([String locale = 'art']) : super(locale);

  @override
  String get chatMessageChangePersona => 'o ante e jan insa';

  @override
  String get chatAttachmentPanelVoice => 'kalama';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'nena pi tawa wawa';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'lon poki toki la nena pi tawa wawa li kama lon ma pi nena pi toki kalama. ona li tawa e sina lon tenpo lili.';

  @override
  String get userSettingsCheckForUpdates => 'o alasa e sin';

  @override
  String get userSettingsCheckingForUpdates => 'ilo li alasa e sin…';

  @override
  String get userSettingsAppUpToDate => 'ilo Tyne li sin';

  @override
  String get userSettingsUpdateAvailableTitle => 'sin li lon';

  @override
  String get userSettingsUpdateDownloadAction => 'o kama jo, o pana';

  @override
  String get userSettingsUpdateInstallAction => 'o pana e sin';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'sin li kama ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'ilo li ken ala alasa e sin anu kama jo e ona.';

  @override
  String get personaSelectTitle => 'o wile e jan insa';

  @override
  String get personaSettingsHeader => 'nasin pi jan insa';

  @override
  String get personaManageAction => 'o lawa';

  @override
  String get personaSearchPlaceholder =>
      'o alasa e jan insa, e nimi lili, e nimi ona...';

  @override
  String get personaModeManual => 'wile sina';

  @override
  String get personaModeLast => 'kepeken pini';

  @override
  String get personaModeManualDescription =>
      'toki ale li tawa kepeken jan insa pi wile sina. sina ante e ona la ni li ante.';

  @override
  String get personaModeLastDescription =>
      'ilo li tawa jan insa pi toki pini sina.';

  @override
  String get personaRecentHeader => 'JAN INSA PI TENPO POKA';

  @override
  String personaAllHeader(int count) {
    return 'JAN INSA ALE ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'TAN ALASA ($count)';
  }

  @override
  String get personaRootAccountLabel => 'lipu jan sina (nasin open)';

  @override
  String get personaEmptyState =>
      'jan insa li lon ala. o pali e jan insa lon nasin pi jan insa.';

  @override
  String get personaEmptySearch => 'alasa li kama jo e jan insa ala.';

  @override
  String get personaEditTitle => 'o ante e jan insa';

  @override
  String get personaCreateTitle => 'o pali e jan insa';

  @override
  String get personaDisplayNameLabel => 'nimi';

  @override
  String get personaPronounsLabel => 'nimi ona';

  @override
  String get personaPronounsHint => 'sama ni: they/them';

  @override
  String get personaBioHint => 'o toki e jan insa ni tawa jan ante...';

  @override
  String get personaUpdatedToast => 'jan insa li ante';

  @override
  String personaUpdateFailedToast(String error) {
    return 'jan insa li ante ala tan pakala: $error';
  }

  @override
  String get personaSectionTitle => 'jan insa';

  @override
  String get personaDisplayNameHint => 'nimi pi jan insa';

  @override
  String personaSendingAsTag(String name) {
    return 'sina toki kepeken nimi $name (tan nimi lili)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'sina toki kepeken nimi $name (kepeken pini)';
  }

  @override
  String personaSendingAs(String name) {
    return 'sina toki kepeken nimi $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'sina pana e toki kepeken nimi $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'sina toki kepeken nimi @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'toki li tawa ala: jan insa sina li kama ala lon tenpo ni.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'toki li tawa ala: jan insa sina li kama ala lon tenpo ni. sina wile ala wile pana e ona kepeken nimi @$username?';
  }

  @override
  String get personaSendAsAccountAction => 'o pana kin';

  @override
  String get personaMainAccount => 'lipu jan lawa';

  @override
  String get personaEditPersona => 'o ante e jan insa';

  @override
  String get userSettingsNavPersonas => 'jan insa';

  @override
  String get personaSettingsDescription =>
      'o ante e nasin pi jan insa toki, e nimi poka sina, e jan insa ale sina.';

  @override
  String get personaDisplayTagSection => 'nimi poka';

  @override
  String get personaDisplayTagDescription =>
      'nimi poka li lon poka pi nimi ale pi jan insa lon toki. nimi poka li lon ala la sitelen jan pi lipu jan sina li lon.';

  @override
  String get personaDisplayTagLabel => 'toki pi nimi poka';

  @override
  String get personaDisplayTagHint => 'sama ni: SYS';

  @override
  String get personaDisplayTagIconLabel => 'sitelen lili pi nimi poka';

  @override
  String get personaUploadTagIcon => 'o pana e sitelen lili';

  @override
  String get personaChangeTagIcon => 'o ante e sitelen lili';

  @override
  String get personaRemoveTagIcon => 'o weka e sitelen lili';

  @override
  String get personaChatPreviewTitle => 'lukin pi toki';

  @override
  String get personaChatPreviewSampleMessage =>
      'toki! ni la sina ken lukin e toki sina: ona li jo e nimi poka sina, li tan jan insa toki sina.';

  @override
  String get personaListTitle => 'jan insa sina';

  @override
  String get personaAddButton => 'o pana e jan insa sin';

  @override
  String get personaActiveBadge => 'lon tenpo ni';

  @override
  String get personaMakeActive => 'o kepeken';

  @override
  String get personaDeleteTitle => 'o weka e jan insa';

  @override
  String personaDeleteMessage(String name) {
    return 'sina wile ala wile weka e \"$name\"? sina ken ala weka e ante ni.';
  }

  @override
  String get personaDeleteConfirm => 'o weka';

  @override
  String get personaDeletedToast => 'jan insa li weka';

  @override
  String get personaCreatedToast => 'jan insa sin li lon';

  @override
  String personaCreateFailedToast(String error) {
    return 'jan insa sin li lon ala tan pakala: $error';
  }

  @override
  String get personaChangeAvatar => 'o ante e sitelen jan';

  @override
  String get personaRemoveAvatar => 'o weka e sitelen jan';

  @override
  String get personaUploadAvatar => 'o pana e sitelen jan';

  @override
  String get personaTagsLabel => 'nimi lili pi jan insa';

  @override
  String get personaAutoTagDisabledLabel =>
      'nimi lili pi jan insa ni li lawa ala';

  @override
  String get personaAutoTagDisabledDescription =>
      'sina sitelen e nimi lili ni la sina tawa ala jan insa ni. nimi lili li tawa sama sitelen sina.';

  @override
  String get personaTagPrefixLabel => 'open';

  @override
  String get personaTagSuffixLabel => 'pini';

  @override
  String get personaVisibilityLabel => 'ken lukin';

  @override
  String get personaVisibilityUnlisted => 'lon ala lipu';

  @override
  String get personaVisibilityPublic => 'tawa jan ale';

  @override
  String get personaVisibilityPrivate => 'len';

  @override
  String get personaNameRequired => 'o pana e nimi tawa jan insa';

  @override
  String get personaNameTooLong => 'nimi pi jan insa o jo e sitelen 100 taso';

  @override
  String get personaTagPrefixTooLong =>
      'open pi nimi lili o jo e sitelen 32 taso';

  @override
  String get personaTagSuffixTooLong =>
      'pini pi nimi lili o jo e sitelen 32 taso';

  @override
  String personaTagCollisionError(String tag, String name) {
    return '\'$name\' li kepeken nimi lili \'$tag\'.';
  }

  @override
  String get chatInsertTimestamp => 'o pana e sitelen tenpo';

  @override
  String get chatAttachmentSendVoiceMessage => 'o pana e toki kalama';

  @override
  String get timestampPickerTitle => 'o pana e sitelen tenpo';

  @override
  String get timestampPickerInsert => 'o pana';

  @override
  String get timestampCopied => 'sina sama e sitelen tenpo';

  @override
  String get timestampPickerTimeLabel => 'tenpo';

  @override
  String get timestampPickerDateLabel => 'TENPO SUNO';

  @override
  String get timestampPickerTimeSectionLabel => 'TENPO';

  @override
  String get timestampPickerTimezoneLabel => 'MA TENPO';

  @override
  String get timestampPickerFormatPreviewLabel => 'LUKIN PI NASIN SITELEN';

  @override
  String get timestampPickerNlpPlaceholder =>
      'sama ni: tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'o alasa e ma tenpo...';

  @override
  String get userProfileTimezoneSettingLabel => 'ma tenpo';

  @override
  String get userProfileTimezoneSettingDescription =>
      'ni la lipu sona sina li ken pana e tenpo lon ma sina.';

  @override
  String get userProfileTimezoneNone => 'ala';

  @override
  String get chatReactAs => 'o pilin kepeken nimi...';

  @override
  String get emojiCopy => 'o sama e sitelen pilin';

  @override
  String get emojiCopyLink => 'o sama e linja';

  @override
  String get emojiPin => 'o sinpin e sitelen pilin';

  @override
  String get emojiUnpin => 'o weka e sitelen pilin tan sinpin';

  @override
  String get emojiPinForPersona => 'o sinpin tawa jan insa ni';

  @override
  String get emojiUnpinForPersona => 'o weka tan sinpin pi jan insa ni';

  @override
  String get personaSignatureEmojisLabel => 'sitelen pilin nimi';

  @override
  String get personaSignatureEmojisDescription =>
      'sina pilin kepeken sitelen pilin nimi la sina pilin kepeken nimi pi jan insa ni lon tenpo ale. jan insa toki li ante ala e ni.';

  @override
  String get personaAddSignatureEmoji => 'o pana e sitelen pilin';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'sitelen pilin ni li lon sitelen pilin nimi';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'jan insa \"$name\" li kepeken sitelen pilin nimi ni';
  }

  @override
  String get personaRemoveSignatureEmoji => 'o weka e sitelen pilin nimi';

  @override
  String get signalBarLabel => 'linja suno';

  @override
  String get signalBarShow => 'o lukin e linja suno';

  @override
  String get signalBarHide => 'o len e linja suno';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'jan ala li open e suno ni';

  @override
  String get signalBarReset => 'o pini e suno ni tawa jan ale';

  @override
  String signalBarTurnOff(String name) {
    return 'o pini e suno pi $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'o sitelen e $domain tawa ma pi ilo ni. ma ante la o sitelen e URL ona ale.';
  }

  @override
  String get instanceResetToDefault => 'o kepeken sin e ma pi ilo ni';

  @override
  String get personaScopeTitle => 'jan insa li lon seme?';

  @override
  String get personaScopeGlobal => 'lon ale';

  @override
  String get personaScopeGlobalDescription =>
      'jan insa wan tawa tomo toki ale.';

  @override
  String get personaScopeChannel => 'lon tomo toki wan wan';

  @override
  String get personaScopeChannelDescription =>
      'tomo toki ale li awen jo e jan insa ona. lon tomo toki sin la sina open kepeken lipu jan sina.';

  @override
  String get personaPickerChannelOnly => 'tawa tomo toki ni taso';

  @override
  String get personaProfilePrivate => 'lipu sona pi jan insa ni li len.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'lipu sitelen li suli ike. lipu li ken suli $maxSize taso.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'o alasa lon ilo KLIPY';

  @override
  String get appUpdateDownloadFailed => 'sin li kama ala tan pakala';

  @override
  String get appUpdateInstallFailed => 'ilo li ken ala pana e sin';

  @override
  String get personaChangeMessageFailed =>
      'jan insa pi toki ni li ante ala tan pakala';

  @override
  String get personaActiveCleared => 'jan insa toki li weka';

  @override
  String get klipyPoweredBy => 'wawa tan ilo KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'nimi lili tu \'$pattern\' li lon tenpo tu lon jan insa ni';
  }

  @override
  String personaAddTagPair(int count) {
    return 'o pana e nimi lili tu ($count/5)';
  }

  @override
  String get personaTagExampleText => 'toki';

  @override
  String get personaPreviewNameFallback => 'jan';

  @override
  String get crashReportingConsentSubtitle =>
      'ilo Tyne li pini lon nasin ike. sina pana e sona pakala (ona li jo ala e nimi sina) la mi ken pona e pakala lon tenpo lili.';

  @override
  String get crashReportingSectionDescription =>
      'sina pana e sona pakala e sona pi wawa ilo la sina pona e ilo Tyne. nasin open la ni li pini.';

  @override
  String get crashReportingDescription =>
      'sona ni li tawa ilo pakala pi ilo Tyne. sina lon ma ante la ni li sama. ona li jo ala e nimi ma, e nanpa ID, e toki.';

  @override
  String get instanceOfflineTitle => 'ilo Tyne li lon ala linluwi!';

  @override
  String get instanceOfflineBody => 'mi alasa e pakala.';

  @override
  String get instanceStatusSignalLink =>
      'o kama lon tomo toki mi lon ilo Signal tawa sona sin';

  @override
  String get convertEmoticonsLabel =>
      'o ante e sitelen sama :) tawa sitelen pilin';

  @override
  String guildCommandFailed(String name, String detail) {
    return '/$name li ken ala pali: $detail';
  }

  @override
  String get guildCommandBroken => 'toki ilo ona li jo e pakala.';

  @override
  String guildCommandOneLine(String name) {
    return 'sitelen sina lon monsi pi /$name o lon linja wan taso.';
  }

  @override
  String get permissionCreateCommands => 'pali e nimi lawa';

  @override
  String get permissionManageCommands => 'ante e nimi lawa ale';

  @override
  String get permissionUseExternalCommands =>
      'kepeken nimi lawa tan kulupu ante';

  @override
  String get permissionCreateCommandsDescription =>
      'sina ken pali e nimi lawa lon kulupu ni. sina ken ante anu weka e nimi lawa sina.';

  @override
  String get permissionManageCommandsDescription =>
      'sina ken ante anu weka e nimi lawa pi jan ale lon kulupu ni.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'sina ken kepeken nimi lawa tan kulupu ante.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'sina ken kepeken nimi lawa tan kulupu ante lon tomo toki ni.';

  @override
  String get guildSettingsCategoryMessageTools => 'ilo pi poki toki';

  @override
  String get guildSettingsCommands => 'nimi lawa';

  @override
  String get guildCommandsLoadFailed => 'nimi lawa li ken ala kama.';

  @override
  String get guildCommandsSubtitle =>
      'jan kulupu li sitelen e /name la ilo li pana e toki.';

  @override
  String get guildCommandsSlots => 'poki pi nimi lawa';

  @override
  String get guildCommandsNew => 'nimi lawa sin';

  @override
  String get guildCommandsSearch => 'o alasa e nimi lawa';

  @override
  String get guildCommandsEmptyTitle => 'nimi lawa ala';

  @override
  String get guildCommandsEmptyBody => 'kulupu ni li jo ala e nimi lawa.';

  @override
  String get guildCommandsSaved => 'nimi lawa li awen';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'ilo li ken ala awen e /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'o ante e /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'sina wile ala wile weka e /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'sina ken ala weka e ante ni. toki tan nimi lawa ni li awen toki e ni: ona li tan nimi lawa seme.';

  @override
  String get guildCommandDelete => 'o weka';

  @override
  String get guildCommandDeleteCommand => 'o weka e nimi lawa';

  @override
  String get guildCommandSectionCommand => 'nimi lawa';

  @override
  String get guildCommandName => 'nimi';

  @override
  String get guildCommandNameInvalid =>
      'o kepeken sitelen lili (a–z), nanpa, - en _ taso. nimi li ken jo e sitelen 32 taso.';

  @override
  String get guildCommandNameTaken =>
      'nimi lawa ante anu nimi lawa pi ilo li jo e nimi ni.';

  @override
  String get guildCommandDescription => 'toki sona';

  @override
  String get guildCommandSectionInput => 'sitelen pi jan kepeken';

  @override
  String get guildCommandInputNone => 'ala';

  @override
  String get guildCommandInputOptional => 'ken';

  @override
  String get guildCommandInputRequired => 'wile';

  @override
  String get guildCommandHint => 'sona lili';

  @override
  String get guildCommandMessage => 'toki';

  @override
  String get guildCommandInsert => 'o pana:';

  @override
  String get guildCommandInsertPerson => 'jan kepeken';

  @override
  String get guildCommandInsertInput => 'sitelen ona';

  @override
  String get guildCommandPreview => 'lukin';

  @override
  String get guildCommandSampleInput => 'sitelen lukin';

  @override
  String guildCommandMadeWith(String name) {
    return 'ona li tan /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'o weka e ale lon poki toki tawa kepeken /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'ni li pana e toki ala. tan ni la nimi lawa li pakala.';

  @override
  String get guildCommandUseScriptEditor => 'o kepeken poki pi toki ilo';

  @override
  String get guildCommandUseBasicEditor => 'o kepeken poki toki taso';

  @override
  String get guildCommandScript => 'toki ilo';

  @override
  String get guildCommandRunAgain => 'o pali sin';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'nimi $name li lon ala lon toki ilo.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'ilo ante $name li lon ala.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name li pini ala.';
  }

  @override
  String get guildCommandIssueTooLong => 'toki ilo li suli ike.';

  @override
  String get guildCommandIssueTooLarge =>
      'toki ilo li pali e toki pi mute ike.';

  @override
  String get guildCommandIssueTooSlow =>
      'toki ilo li pali lon tenpo pi suli ike.';

  @override
  String get guildCommandIssueInvalid => 'ilo li ken ala sona e ni.';

  @override
  String get guildCommandIssueFailed => 'ni li pini tan pakala.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'linja nanpa $line, sitelen nanpa $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'sona pi toki ilo';

  @override
  String get guildCommandReferencePerson => 'nimi @ pi jan kepeken';

  @override
  String get guildCommandReferencePersonName => 'nimi ona';

  @override
  String get guildCommandReferenceTarget =>
      'jan nanpa wan pi nimi @ lon toki ona (ona li lon la)';

  @override
  String get guildCommandReferenceTargetName => 'nimi pi jan ni';

  @override
  String get guildCommandReferenceChannel => 'nimi # pi tomo toki ni';

  @override
  String get guildCommandReferenceCommunity => 'nimi pi kulupu ni';

  @override
  String get guildCommandExampleRandom => 'o wile e ijo wan lon nasin nasa';

  @override
  String get guildCommandExampleDepends => 'o ante e toki tan sitelen ona';

  @override
  String get guildCommandExampleOneWord => 'o wile e nimi wan lon nasin nasa';

  @override
  String get guildCommandExampleWordForNumber => 'o ante e nanpa tawa nimi';

  @override
  String get guildCommandExampleOrdinal =>
      'o sitelen e nanpa sama 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'lipu sona ale pi toki ilo';

  @override
  String get guildCommandCounters => 'ilo nanpa';

  @override
  String get guildCommandCounterAdd => 'o pana e ilo nanpa';

  @override
  String get guildCommandCounterSeparately => 'o nanpa ante tawa:';

  @override
  String get guildCommandCounterPersonMentioned => 'jan pi nimi @';

  @override
  String get guildCommandCounterChannel => 'tomo toki';

  @override
  String get guildCommandCounterPersonas => 'jan insa li jo e nanpa ona';

  @override
  String get guildCommandCounterRemove => 'o weka e ilo nanpa';

  @override
  String get guildCommandCounterReset => 'o open sin e nanpa';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'sina wile ala wile open sin e nanpa pi $name? sina ken ala weka e ante ni.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'o kepeken sitelen lili (a–z), nanpa, _ taso. nimi o open kepeken sitelen (a–z). nimi o sama ala nimi pi toki ilo.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'o kepeken ona lon toki ilo sama $variable. pali ale li pana e 1 tawa ona lon open. tan ni la ona li 1 lon pali nanpa wan.';
  }

  @override
  String get notificationsAlertEveryMessageLabel => 'toki ale li kalama';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'ni li pini la toki mute li kalama lon tenpo wan taso. ni la ona li sin lon kalama ala. sina lukin e ona anu weka e ona la ona li ken kalama sin.';

  @override
  String personaGalleryTitle(int count) {
    return 'jan insa ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'o alasa e jan insa pi $name';
  }

  @override
  String get personaGallerySearchOwn => 'o alasa e jan insa sina';

  @override
  String get personaGallerySortBy => 'o nasin kepeken';

  @override
  String get personaGallerySortName => 'nimi (A–Z)';

  @override
  String get personaGallerySortMostUsed => 'kepeken mute';

  @override
  String get personaGallerySortRecentlyUsed => 'kepeken lon tenpo poka';

  @override
  String get personaGalleryViewGallery => 'lipu lili';

  @override
  String get personaGalleryViewList => 'linja';

  @override
  String get personaGalleryViewAvatars => 'sitelen jan';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jan insa $count',
      one: 'jan insa $count',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return 'jan insa $shown/$total';
  }

  @override
  String get personaGalleryNoMatch => 'alasa sina li kama jo e jan insa ala.';

  @override
  String get personaGalleryLoadFailed => 'jan insa li ken ala kama.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jan insa sina $count',
      one: 'jan insa sina $count',
    );
    return 'jan ante li ken lukin e $_temp0.';
  }

  @override
  String get personaGalleryShowHidden =>
      'o lukin kin e jan insa pi lon ala lipu e jan insa len';

  @override
  String get personaGalleryManage => 'o lawa e jan insa';

  @override
  String get personaGalleryNonePublic =>
      'jan insa sina li tawa ala jan ale. sina pana e ken lukin \"tawa jan ale\" tawa jan insa la jan ante li lukin e ona lon ni.';

  @override
  String get personaGalleryNoBio => 'toki sona li lon ala.';

  @override
  String personaGalleryCreated(String date) {
    return 'open lon $date';
  }

  @override
  String get personaBulkSelect => 'o wile';

  @override
  String get personaBulkSelectAll => 'o wile e ale';

  @override
  String personaBulkSelectedCount(int count) {
    return 'sina wile e $count';
  }

  @override
  String get personaFilterAll => 'ale';

  @override
  String get personaBulkMakePublic => 'o pana tawa jan ale';

  @override
  String get personaBulkMakeUnlisted => 'o weka tan lipu';

  @override
  String get personaBulkMakePrivate => 'o len';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jan insa $count',
      one: 'jan insa $count',
    );
    return 'sina wile ala wile pana e $_temp0 tawa jan ale?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jan insa $count',
      one: 'jan insa $count',
    );
    return 'sina wile ala wile len e $_temp0?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jan insa $count',
      one: 'jan insa $count',
    );
    return 'sina wile ala wile weka e $_temp0?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'jan ante li ken lukin e ona lon lipu pi jan insa sina, li ken open e lipu sona ona. sina ken ante sin e ni lon tenpo ale.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'lipu sona ona li kama len tawa jan ante. nimi ona en sitelen jan ona li awen lon toki ona, lon pilin ona kin.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'toki ona li awen jo e nimi ona e sitelen jan ona. taso sina ken ala toki kepeken nimi ona. nimi lili ona en sitelen pilin nimi ona li kama ken tawa jan insa ante. sina ken ala weka e ante ni.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jan insa $count li tawa jan ale',
      one: 'jan insa $count li tawa jan ale',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jan insa $count li lon ala lipu',
      one: 'jan insa $count li lon ala lipu',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jan insa $count li len',
      one: 'jan insa $count li len',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jan insa $count li weka',
      one: 'jan insa $count li weka',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed =>
      'ilo li ken ala ante e jan insa. o lukin sin.';

  @override
  String get personaFilterEmpty => 'jan insa li lon ala.';

  @override
  String get personaGalleryChooseFeatured => 'o wile e jan insa tawa jan ale';

  @override
  String get personaUndo => 'o weka e ante';

  @override
  String get personaReactionsTitle => 'pilin sina';

  @override
  String get personaReactionsEveryoneElse => 'ANTE ALE';

  @override
  String get personaReactionsCurrent => 'TENPO NI';

  @override
  String get personaReactionsAccount => 'lipu jan';

  @override
  String get personaReactionsSomeoneElse => 'o pilin kepeken nimi ante...';

  @override
  String get personaReactionsDone => 'pini';

  @override
  String get personaSettingsReactionsHeader => 'pilin';

  @override
  String get personaSettingsMultiReactions =>
      'jan insa mute li ken pilin lon tenpo sama';
}
