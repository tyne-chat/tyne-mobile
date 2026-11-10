// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class ForkLocalizationsFil extends ForkLocalizations {
  ForkLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Palitan ang Persona';

  @override
  String get chatAttachmentPanelVoice => 'Boses';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Button ng Quick Switcher';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Palitan ang button ng voice message sa kahon ng mensahe ng button ng Quick Switcher para sa mabilis na paglipat';

  @override
  String get userSettingsCheckForUpdates => 'Tingnan kung may update';

  @override
  String get userSettingsCheckingForUpdates => 'Tinitingnan kung may update…';

  @override
  String get userSettingsAppUpToDate => 'Napapanahon ang Tyne';

  @override
  String get userSettingsUpdateAvailableTitle => 'May Bagong Update';

  @override
  String get userSettingsUpdateDownloadAction => 'I-download at I-install';

  @override
  String get userSettingsUpdateInstallAction => 'I-install ang Update';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Dina-download ang update ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Hindi natingnan o na-download ang update.';

  @override
  String get personaSelectTitle => 'Pumili ng Persona';

  @override
  String get personaSettingsHeader => 'Mga Setting ng Persona';

  @override
  String get personaManageAction => 'Pamahalaan';

  @override
  String get personaSearchPlaceholder => 'Maghanap ng persona, tag, panghalip…';

  @override
  String get personaModeManual => 'Mano-mano';

  @override
  String get personaModeLast => 'Huling Ginamit';

  @override
  String get personaModeManualDescription =>
      'Laging nagpapadala bilang napiling persona hangga’t hindi pinapalitan.';

  @override
  String get personaModeLastDescription =>
      'Kusang lumilipat sa personang ginamit sa huli mong mensahe.';

  @override
  String get personaRecentHeader => 'MGA KAMAKAILANG PERSONA';

  @override
  String personaAllHeader(int count) {
    return 'LAHAT NG PERSONA ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'MGA RESULTA NG PAGHAHANAP ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Pangunahing Account (Default)';

  @override
  String get personaEmptyState =>
      'Wala ka pang persona. Gumawa ng isa sa “Pamahalaan ang mga Persona”.';

  @override
  String get personaEmptySearch => 'Walang nakitang tugmang persona.';

  @override
  String get personaEditTitle => 'I-edit ang Persona';

  @override
  String get personaCreateTitle => 'Gumawa ng Persona';

  @override
  String get personaDisplayNameLabel => 'Ipinapakitang Pangalan';

  @override
  String get personaPronounsLabel => 'Mga Panghalip';

  @override
  String get personaPronounsHint => 'hal. they/them';

  @override
  String get personaBioHint => 'Ikuwento sa iba ang tungkol sa personang ito…';

  @override
  String get personaUpdatedToast => 'Na-update ang persona';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Hindi na-update ang persona: $error';
  }

  @override
  String get personaSectionTitle => 'Mga Persona';

  @override
  String get personaDisplayNameHint => 'Pangalan ng persona';

  @override
  String personaSendingAsTag(String name) {
    return 'Nagpapadala bilang $name (tugma sa tag)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Nagpapadala bilang $name (huling ginamit)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Nagpapadala bilang $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Nagpo-post bilang $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Nagpapadala bilang @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'Hindi naipadala: hindi pa naglo-load ang iyong mga persona.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Hindi naipadala: hindi pa naglo-load ang iyong mga persona. Ipadala na lang bilang @$username?';
  }

  @override
  String get personaSendAsAccountAction => 'Ipadala pa rin';

  @override
  String get personaMainAccount => 'Pangunahing account';

  @override
  String get personaEditPersona => 'I-edit ang persona';

  @override
  String get userSettingsNavPersonas => 'Mga Persona';

  @override
  String get personaSettingsDescription =>
      'Itakda ang mode ng aktibong persona at ang sarili mong ipinapakitang tag, at pamahalaan ang bawat persona.';

  @override
  String get personaDisplayTagSection => 'Ipinapakitang Tag';

  @override
  String get personaDisplayTagDescription =>
      'Lalabas ang ipinapakitang tag sa tabi ng pangalan ng bawat persona sa mga mensahe. Kung walang nakatakdang ipinapakitang tag, ipapakita ang larawan sa profile ng iyong account.';

  @override
  String get personaDisplayTagLabel => 'Teksto ng Ipinapakitang Tag';

  @override
  String get personaDisplayTagHint => 'hal. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Icon ng Ipinapakitang Tag';

  @override
  String get personaUploadTagIcon => 'I-upload ang Icon';

  @override
  String get personaChangeTagIcon => 'Palitan ang Icon';

  @override
  String get personaRemoveTagIcon => 'Alisin ang Icon';

  @override
  String get personaChatPreviewTitle => 'Preview ng Chat';

  @override
  String get personaChatPreviewSampleMessage =>
      'Kumusta! Ganito ang hitsura ng mga mensahe kasama ang iyong ipinapakitang tag at aktibong persona.';

  @override
  String get personaListTitle => 'Iyong Mga Persona';

  @override
  String get personaAddButton => 'Magdagdag ng Persona';

  @override
  String get personaActiveBadge => 'Aktibo';

  @override
  String get personaMakeActive => 'Gawing Aktibo';

  @override
  String get personaDeleteTitle => 'I-delete ang Persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Sigurado ka bang gusto mong i-delete ang “$name”? Hindi na ito mababawi.';
  }

  @override
  String get personaDeleteConfirm => 'I-delete';

  @override
  String get personaDeletedToast => 'Na-delete ang persona';

  @override
  String get personaCreatedToast => 'Nagawa ang persona';

  @override
  String personaCreateFailedToast(String error) {
    return 'Hindi nagawa ang persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Palitan ang Avatar';

  @override
  String get personaRemoveAvatar => 'Alisin ang Avatar';

  @override
  String get personaUploadAvatar => 'I-upload ang Avatar';

  @override
  String get personaTagsLabel => 'Mga Tag ng Persona';

  @override
  String get personaAutoTagDisabledLabel =>
      'Huwag itugma ang mga tag ng personang ito';

  @override
  String get personaAutoTagDisabledDescription =>
      'Hindi lilipat sa personang ito kapag nag-type ka ng isa sa mga tag na ito. Ipapadala ang tag gaya ng pagkakasulat.';

  @override
  String get personaTagPrefixLabel => 'Unlapi';

  @override
  String get personaTagSuffixLabel => 'Hulapi';

  @override
  String get personaVisibilityLabel => 'Visibility ng Persona';

  @override
  String get personaVisibilityUnlisted => 'Hindi Nakalista';

  @override
  String get personaVisibilityPublic => 'Pampubliko';

  @override
  String get personaVisibilityPrivate => 'Pribado';

  @override
  String get personaNameRequired =>
      'Maglagay ng ipinapakitang pangalan ng persona';

  @override
  String get personaNameTooLong =>
      'Dapat 100 karakter o mas maikli ang ipinapakitang pangalan ng persona';

  @override
  String get personaTagPrefixTooLong =>
      'Dapat 32 karakter o mas maikli ang unlapi ng tag ng persona';

  @override
  String get personaTagSuffixTooLong =>
      'Dapat 32 karakter o mas maikli ang hulapi ng tag ng persona';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Ginagamit na ni “$name” ang tag na “$tag”.';
  }

  @override
  String get chatInsertTimestamp => 'Maglagay ng timestamp';

  @override
  String get chatAttachmentSendVoiceMessage => 'Magpadala ng voice message';

  @override
  String get timestampPickerTitle => 'Maglagay ng Timestamp';

  @override
  String get timestampPickerInsert => 'Ilagay';

  @override
  String get timestampCopied => 'Nakopya ang timestamp';

  @override
  String get timestampPickerTimeLabel => 'Oras';

  @override
  String get timestampPickerDateLabel => 'PETSA';

  @override
  String get timestampPickerTimeSectionLabel => 'ORAS';

  @override
  String get timestampPickerTimezoneLabel => 'TIME ZONE';

  @override
  String get timestampPickerFormatPreviewLabel => 'PREVIEW NG FORMAT';

  @override
  String get timestampPickerNlpPlaceholder =>
      'hal. tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'Maghanap ng time zone…';

  @override
  String get userProfileTimezoneSettingLabel => 'Time zone';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Ginagamit para ipakita ang lokal mong oras sa iyong profile.';

  @override
  String get userProfileTimezoneNone => 'Wala';

  @override
  String get chatReactAs => 'Mag-react bilang…';

  @override
  String get emojiCopy => 'Kopyahin ang emoji';

  @override
  String get emojiCopyLink => 'Kopyahin ang link';

  @override
  String get emojiPin => 'I-pin ang emoji';

  @override
  String get emojiUnpin => 'I-unpin ang emoji';

  @override
  String get emojiPinForPersona => 'I-pin para sa personang ito';

  @override
  String get emojiUnpinForPersona => 'I-unpin para sa personang ito';

  @override
  String get personaSignatureEmojisLabel => 'Mga Natatanging Emoji';

  @override
  String get personaSignatureEmojisDescription =>
      'Kapag nag-react gamit ang natatanging emoji, laging bilang personang ito ang reaksyon, anuman ang aktibong persona.';

  @override
  String get personaAddSignatureEmoji => 'Magdagdag ng Emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Naidagdag na ang emoji na ito bilang natatanging emoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Ginagamit na ng personang “$name” ang natatanging emoji na ito';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Alisin ang natatanging emoji';

  @override
  String get signalBarLabel => 'Hanay ng signal';

  @override
  String get signalBarShow => 'Ipakita ang hanay ng signal';

  @override
  String get signalBarHide => 'Itago ang hanay ng signal';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Walang naka-on ng signal na ito';

  @override
  String get signalBarReset => 'I-reset ang signal para sa lahat';

  @override
  String signalBarTurnOff(String name) {
    return 'I-off para kay $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Gamitin ang $domain para sa default na instance, o ang eksaktong URL ng ibang instance.';
  }

  @override
  String get instanceResetToDefault => 'Bumalik sa default na instance';

  @override
  String get personaScopeTitle => 'Saklaw ng Persona';

  @override
  String get personaScopeGlobal => 'Kahit saan';

  @override
  String get personaScopeGlobalDescription =>
      'Iisang persona para sa lahat ng channel.';

  @override
  String get personaScopeChannel => 'Sa bawat channel';

  @override
  String get personaScopeChannelDescription =>
      'May sariling persona ang bawat channel. Nagsisimula ang mga bagong channel bilang iyong account.';

  @override
  String get personaPickerChannelOnly => 'Para sa channel na ito lang';

  @override
  String get personaProfilePrivate => 'Pribado ang profile ng personang ito.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Masyadong malaki ang file ng larawan. Pumili ng file na mas maliit sa $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Maghanap sa KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Hindi na-download ang update';

  @override
  String get appUpdateInstallFailed => 'Hindi na-install ang update';

  @override
  String get personaChangeMessageFailed =>
      'Hindi napalitan ang persona ng mensahe';

  @override
  String get personaActiveCleared => 'Inalis ang aktibong persona';

  @override
  String get klipyPoweredBy => 'Pinapagana ng KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Dobleng pares ng tag na “$pattern” sa personang ito';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Magdagdag ng Pares ng Tag ($count/5)';
  }

  @override
  String get personaTagExampleText => 'teksto';

  @override
  String get personaPreviewNameFallback => 'Gumagamit';

  @override
  String get crashReportingConsentSubtitle =>
      'Biglang nagsara ang Tyne. Matutulungan mo kaming ayusin nang mas mabilis ang mga problema kung ibabahagi mo ang anonymous na data tungkol sa mga crash at error.';

  @override
  String get crashReportingSectionDescription =>
      'Tumulong sa pag-ayos ng mga bug sa Tyne sa pamamagitan ng pagbabahagi ng data tungkol sa mga crash at performance. Naka-off ito bilang default.';

  @override
  String get crashReportingDescription =>
      'Napupunta ang mga ulat sa sariling error tracker ng Tyne, kahit naka-sign in ka sa ibang instance. Hindi kasama rito ang mga pangalan ng instance, mga ID, o ang nilalaman ng mga mensahe.';

  @override
  String get instanceOfflineTitle => 'Offline ang Tyne!';

  @override
  String get instanceOfflineBody => 'Iniimbestigahan namin ito.';

  @override
  String get instanceStatusSignalLink =>
      'Sumali sa aming Signal chat para sa mga update';

  @override
  String get convertEmoticonsLabel => 'Gawing emoji ang mga smiley na teksto';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Hindi napatakbo ang /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'May problema ang script nito.';

  @override
  String guildCommandOneLine(String name) {
    return 'Dapat magkasya sa isang linya ang tina-type mo pagkatapos ng /$name.';
  }

  @override
  String get permissionCreateCommands => 'Gumawa ng mga command';

  @override
  String get permissionManageCommands => 'Pamahalaan ang mga command';

  @override
  String get permissionUseExternalCommands =>
      'Gumamit ng mga panlabas na command';

  @override
  String get permissionCreateCommandsDescription =>
      'Gumawa ng mga command para sa komunidad na ito, at i-edit o i-delete ang sarili mong mga command.';

  @override
  String get permissionManageCommandsDescription =>
      'I-edit o i-delete ang mga command ng sinuman sa komunidad na ito.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Gumamit ng mga command mula sa ibang komunidad.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Gumamit ng mga command mula sa ibang komunidad sa channel na ito.';

  @override
  String get guildSettingsCategoryMessageTools => 'Mga Tool sa Mensahe';

  @override
  String get guildSettingsCommands => 'Mga Command';

  @override
  String get guildCommandsLoadFailed => 'Hindi ma-load ang mga command.';

  @override
  String get guildCommandsSubtitle =>
      'Mga mensaheng maipo-post ng mga miyembro sa pag-type ng /name.';

  @override
  String get guildCommandsSlots => 'Mga slot ng command';

  @override
  String get guildCommandsNew => 'Bagong command';

  @override
  String get guildCommandsSearch => 'Maghanap ng command';

  @override
  String get guildCommandsEmptyTitle => 'Walang command';

  @override
  String get guildCommandsEmptyBody =>
      'Wala pang command ang komunidad na ito.';

  @override
  String get guildCommandsSaved => 'Na-save ang mga command';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Hindi na-save ang /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'I-edit ang /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'I-delete ang /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Hindi na ito mababawi. Makikita pa rin sa mga mensaheng ginawa nito kung aling command ang gumawa sa kanila.';

  @override
  String get guildCommandDelete => 'I-delete';

  @override
  String get guildCommandDeleteCommand => 'I-delete ang command';

  @override
  String get guildCommandSectionCommand => 'Command';

  @override
  String get guildCommandName => 'Pangalan';

  @override
  String get guildCommandNameInvalid =>
      'Gumamit ng maliliit na titik, numero, - at _, hanggang 32 karakter.';

  @override
  String get guildCommandNameTaken =>
      'Ginagamit na ng ibang command o ng isang built-in na command ang pangalang ito.';

  @override
  String get guildCommandDescription => 'Paglalarawan';

  @override
  String get guildCommandSectionInput => 'Input';

  @override
  String get guildCommandInputNone => 'Wala';

  @override
  String get guildCommandInputOptional => 'Opsyonal';

  @override
  String get guildCommandInputRequired => 'Kailangan';

  @override
  String get guildCommandHint => 'Pahiwatig';

  @override
  String get guildCommandMessage => 'Mensahe';

  @override
  String get guildCommandInsert => 'Ilagay:';

  @override
  String get guildCommandInsertPerson => 'Taong nagpapatakbo nito';

  @override
  String get guildCommandInsertInput => 'Ang tina-type nila';

  @override
  String get guildCommandPreview => 'Preview';

  @override
  String get guildCommandSampleInput => 'Halimbawang input';

  @override
  String guildCommandMadeWith(String name) {
    return 'Ginawa gamit ang /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Burahin ang laman ng kahon ng mensahe para magamit ang /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Walang maipo-post dito, kaya mabibigo ang command.';

  @override
  String get guildCommandUseScriptEditor => 'Gamitin ang script editor';

  @override
  String get guildCommandUseBasicEditor => 'Gamitin ang simpleng editor';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Patakbuhin ulit';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Walang tag na tinatawag na $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Walang filter na tinatawag na $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return 'Hindi isinara ang $name.';
  }

  @override
  String get guildCommandIssueTooLong => 'Masyadong mahaba ang script.';

  @override
  String get guildCommandIssueTooLarge =>
      'Masyadong maraming teksto ang binubuo ng script.';

  @override
  String get guildCommandIssueTooSlow =>
      'Masyadong natagalan ang pagtakbo ng script.';

  @override
  String get guildCommandIssueInvalid => 'Hindi mabasa ang bahaging ito.';

  @override
  String get guildCommandIssueFailed =>
      'Huminto nang may error ang bahaging ito.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Linya $line, kolum $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Sanggunian sa script';

  @override
  String get guildCommandReferencePerson =>
      'Ang taong nagpapatakbo nito, bilang mention';

  @override
  String get guildCommandReferencePersonName => 'Ang pangalan nila';

  @override
  String get guildCommandReferenceTarget =>
      'Ang unang taong binanggit nila, kung mayroon';

  @override
  String get guildCommandReferenceTargetName => 'Ang pangalan ng taong iyon';

  @override
  String get guildCommandReferenceChannel => 'Ang channel, bilang mention';

  @override
  String get guildCommandReferenceCommunity =>
      'Ang pangalan ng komunidad na ito';

  @override
  String get guildCommandExampleRandom => 'Pumili ng isang opsyon nang random';

  @override
  String get guildCommandExampleDepends =>
      'Baguhin ang mensahe depende sa na-type nila';

  @override
  String get guildCommandExampleOneWord => 'Pumili ng isang salita nang random';

  @override
  String get guildCommandExampleWordForNumber =>
      'Piliin ang salita para sa isang numero';

  @override
  String get guildCommandExampleOrdinal =>
      'Isulat ang numero bilang 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Buong gabay sa script';

  @override
  String get guildCommandCounters => 'Mga counter';

  @override
  String get guildCommandCounterAdd => 'Magdagdag ng counter';

  @override
  String get guildCommandCounterSeparately =>
      'Hiwalay na bilang para sa bawat:';

  @override
  String get guildCommandCounterPersonMentioned => 'Taong binanggit';

  @override
  String get guildCommandCounterChannel => 'Channel';

  @override
  String get guildCommandCounterPersonas =>
      'Bilangin nang hiwalay ang mga persona';

  @override
  String get guildCommandCounterRemove => 'Alisin ang counter';

  @override
  String get guildCommandCounterReset => 'I-reset ang mga bilang';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'I-reset ang mga bilang ng $name? Hindi na ito mababawi.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Gumamit ng maliliit na titik, numero at _, nagsisimula sa titik, at hindi pangalang ginagamit na ng mga script.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Gamitin ito sa script bilang $variable. Nagdadagdag muna ng isa ang bawat pagtakbo, kaya 1 ang mababasa sa unang pagtakbo.';
  }

  @override
  String get notificationsAlertEveryMessageLabel =>
      'Mag-alerto sa bawat mensahe';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Kapag naka-off, isang beses lang mag-aalerto ang abalang usapan, saka tahimik na mag-a-update hanggang basahin mo ito o isara.';

  @override
  String personaGalleryTitle(int count) {
    return 'Mga Persona ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Hanapin sa mga persona ni $name';
  }

  @override
  String get personaGallerySearchOwn => 'Hanapin sa iyong mga persona';

  @override
  String get personaGallerySortBy => 'Ayusin ayon sa';

  @override
  String get personaGallerySortName => 'Pangalan (A–Z)';

  @override
  String get personaGallerySortMostUsed => 'Pinakaginagamit';

  @override
  String get personaGallerySortRecentlyUsed => 'Kamakailang ginamit';

  @override
  String get personaGalleryViewGallery => 'Galeriya';

  @override
  String get personaGalleryViewList => 'Listahan';

  @override
  String get personaGalleryViewAvatars => 'Mga avatar';

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
    return '$shown sa $total persona';
  }

  @override
  String get personaGalleryNoMatch =>
      'Walang personang tumutugma sa paghahanap mo.';

  @override
  String get personaGalleryLoadFailed => 'Hindi ma-load ang mga persona.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pampublikong persona',
      one: '$count pampublikong persona',
    );
    return 'Nakikita ng iba ang $_temp0.';
  }

  @override
  String get personaGalleryShowHidden =>
      'Ipakita ang hindi nakalista at pribado';

  @override
  String get personaGalleryManage => 'Pamahalaan ang mga persona';

  @override
  String get personaGalleryNonePublic =>
      'Wala pa sa iyong mga persona ang pampubliko. Makikita ng iba ang isang persona dito kapag itinakda mo ang visibility nito sa Pampubliko.';

  @override
  String get personaGalleryNoBio => 'Wala pang bio.';

  @override
  String personaGalleryCreated(String date) {
    return 'Ginawa noong $date';
  }

  @override
  String get personaBulkSelect => 'Pumili';

  @override
  String get personaBulkSelectAll => 'Piliin lahat';

  @override
  String personaBulkSelectedCount(int count) {
    return '$count ang napili';
  }

  @override
  String get personaFilterAll => 'Lahat';

  @override
  String get personaBulkMakePublic => 'Gawing pampubliko';

  @override
  String get personaBulkMakeUnlisted => 'Gawing hindi nakalista';

  @override
  String get personaBulkMakePrivate => 'Gawing pribado';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return 'Gawing pampubliko ang $_temp0?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return 'Gawing pribado ang $_temp0?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return 'I-delete ang $_temp0?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Makikita sila ng iba sa iyong listahan ng mga persona at mabubuksan nila ang kanilang mga profile. Puwede mo itong ibalik anumang oras.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Itatago sa iba ang kanilang mga profile. Makikita pa rin ang kanilang pangalan at avatar sa kanilang mga mensahe at reaksyon.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Patuloy na ipapakita ng kanilang mga mensahe ang kanilang pangalan at avatar, pero hindi ka na makakapagpadala bilang sila, at magagamit na ng iba ang kanilang mga tag at natatanging emoji. Hindi na ito mababawi.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return 'Pampubliko na ang $_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return 'Hindi na nakalista ang $_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return 'Pribado na ang $_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return 'Na-delete ang $_temp0';
  }

  @override
  String get personaBulkFailed => 'Hindi mabago ang mga persona. Subukan ulit.';

  @override
  String get personaFilterEmpty => 'Walang persona dito.';

  @override
  String get personaGalleryChooseFeatured =>
      'Pumili ng mga personang itatampok';

  @override
  String get personaUndo => 'I-undo';

  @override
  String get personaReactionsTitle => 'Ang iyong mga reaksyon';

  @override
  String get personaReactionsEveryoneElse => 'ANG IBA PA';

  @override
  String get personaReactionsCurrent => 'KASALUKUYAN';

  @override
  String get personaReactionsAccount => 'Account';

  @override
  String get personaReactionsSomeoneElse => 'Mag-react bilang ibang tao…';

  @override
  String get personaReactionsDone => 'Tapos na';

  @override
  String get personaSettingsReactionsHeader => 'Mga reaksyon';

  @override
  String get personaSettingsMultiReactions =>
      'Mag-react bilang ilang persona nang sabay-sabay';

  @override
  String get personaDuplicateButton => 'I-duplicate ang Persona';

  @override
  String personaCopyOf(String name) {
    return 'Kopya ng $name';
  }
}
