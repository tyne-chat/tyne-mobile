// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class ForkLocalizationsBn extends ForkLocalizations {
  ForkLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get chatMessageChangePersona => 'পারসোনা বদলান';

  @override
  String get chatAttachmentPanelVoice => 'ভয়েস';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'কুইক সুইচার বোতাম';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'দ্রুত নেভিগেশনের জন্য মেসেজ ইনপুটের ভয়েস মেসেজ বোতামের বদলে কুইক সুইচার বোতাম দেখান';

  @override
  String get userSettingsCheckForUpdates => 'আপডেট আছে কি না দেখুন';

  @override
  String get userSettingsCheckingForUpdates => 'আপডেট খোঁজা হচ্ছে…';

  @override
  String get userSettingsAppUpToDate => 'Tyne সর্বশেষ সংস্করণে আছে';

  @override
  String get userSettingsUpdateAvailableTitle => 'আপডেট উপলব্ধ';

  @override
  String get userSettingsUpdateDownloadAction => 'ডাউনলোড ও ইনস্টল করুন';

  @override
  String get userSettingsUpdateInstallAction => 'আপডেট ইনস্টল করুন';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'আপডেট ডাউনলোড হচ্ছে ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed => 'আপডেট যাচাই বা ডাউনলোড করা যায়নি।';

  @override
  String get personaSelectTitle => 'পারসোনা বেছে নিন';

  @override
  String get personaSettingsHeader => 'পারসোনা সেটিংস';

  @override
  String get personaManageAction => 'পরিচালনা করুন';

  @override
  String get personaSearchPlaceholder => 'পারসোনা, ট্যাগ, সর্বনাম খুঁজুন…';

  @override
  String get personaModeManual => 'ম্যানুয়াল';

  @override
  String get personaModeLast => 'শেষ ব্যবহৃত';

  @override
  String get personaModeManualDescription =>
      'না বদলানো পর্যন্ত সবসময় বেছে নেওয়া পারসোনা হিসেবে পাঠায়।';

  @override
  String get personaModeLastDescription =>
      'আপনার শেষ মেসেজে ব্যবহৃত পারসোনায় নিজে থেকেই বদলে যায়।';

  @override
  String get personaRecentHeader => 'সাম্প্রতিক পারসোনা';

  @override
  String personaAllHeader(int count) {
    return 'সব পারসোনা ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'সার্চের ফলাফল ($count)';
  }

  @override
  String get personaRootAccountLabel => 'মূল অ্যাকাউন্ট (ডিফল্ট)';

  @override
  String get personaEmptyState =>
      'এখনও কোনো পারসোনা কনফিগার করা হয়নি। “পারসোনা পরিচালনা করুন” থেকে একটি তৈরি করুন।';

  @override
  String get personaEmptySearch => 'মিলে যায় এমন কোনো পারসোনা পাওয়া যায়নি।';

  @override
  String get personaEditTitle => 'পারসোনা এডিট করুন';

  @override
  String get personaCreateTitle => 'পারসোনা তৈরি করুন';

  @override
  String get personaDisplayNameLabel => 'ডিসপ্লে নাম';

  @override
  String get personaPronounsLabel => 'সর্বনাম';

  @override
  String get personaPronounsHint => 'যেমন তারা/তাদের';

  @override
  String get personaBioHint => 'অন্যদের এই পারসোনা সম্পর্কে বলুন…';

  @override
  String get personaUpdatedToast => 'পারসোনা আপডেট করা হয়েছে';

  @override
  String personaUpdateFailedToast(String error) {
    return 'পারসোনা আপডেট করা যায়নি: $error';
  }

  @override
  String get personaSectionTitle => 'পারসোনা';

  @override
  String get personaDisplayNameHint => 'পারসোনার নাম';

  @override
  String personaSendingAsTag(String name) {
    return '$name হিসেবে পাঠাচ্ছেন (ট্যাগ মিলেছে)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return '$name হিসেবে পাঠাচ্ছেন (স্থির)';
  }

  @override
  String personaSendingAs(String name) {
    return '$name হিসেবে পাঠাচ্ছেন';
  }

  @override
  String personaPostingAs(String name) {
    return '$name হিসেবে পোস্ট করছেন';
  }

  @override
  String personaSendingAsRoot(String username) {
    return '@$username হিসেবে পাঠাচ্ছেন';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'পাঠানো হয়নি: আপনার পারসোনা এখনও লোড হয়নি।';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'পাঠানো হয়নি: আপনার পারসোনা এখনও লোড হয়নি। এর বদলে @$username হিসেবে পাঠাবেন?';
  }

  @override
  String get personaSendAsAccountAction => 'তবুও পাঠান';

  @override
  String get personaMainAccount => 'প্রধান অ্যাকাউন্ট';

  @override
  String get personaEditPersona => 'পারসোনা এডিট করুন';

  @override
  String get userSettingsNavPersonas => 'পারসোনা';

  @override
  String get personaSettingsDescription =>
      'সক্রিয় পারসোনা মোড ও নিজস্ব ডিসপ্লে ট্যাগ কনফিগার করুন, এবং আলাদা আলাদা পারসোনা পরিচালনা করুন।';

  @override
  String get personaDisplayTagSection => 'ডিসপ্লে ট্যাগ';

  @override
  String get personaDisplayTagDescription =>
      'মেসেজে সব পারসোনার নামের পাশে ডিসপ্লে ট্যাগ দেখা যাবে। কোনো ডিসপ্লে ট্যাগ সেট না থাকলে আপনার অ্যাকাউন্টের প্রোফাইল ছবি দেখানো হবে।';

  @override
  String get personaDisplayTagLabel => 'ডিসপ্লে ট্যাগের টেক্সট';

  @override
  String get personaDisplayTagHint => 'যেমন SYS';

  @override
  String get personaDisplayTagIconLabel => 'ডিসপ্লে ট্যাগের আইকন';

  @override
  String get personaUploadTagIcon => 'আইকন আপলোড করুন';

  @override
  String get personaChangeTagIcon => 'আইকন বদলান';

  @override
  String get personaRemoveTagIcon => 'আইকন সরান';

  @override
  String get personaChatPreviewTitle => 'চ্যাট প্রিভিউ';

  @override
  String get personaChatPreviewSampleMessage =>
      'হ্যালো! আপনার ডিসপ্লে ট্যাগ ও সক্রিয় পারসোনা দিয়ে মেসেজ কেমন দেখায়, এটি তার প্রিভিউ।';

  @override
  String get personaListTitle => 'কনফিগার করা পারসোনা';

  @override
  String get personaAddButton => 'পারসোনা যোগ করুন';

  @override
  String get personaActiveBadge => 'সক্রিয়';

  @override
  String get personaMakeActive => 'সক্রিয় করুন';

  @override
  String get personaDeleteTitle => 'পারসোনা মুছে ফেলুন';

  @override
  String personaDeleteMessage(String name) {
    return 'আপনি কি নিশ্চিত যে “$name” মুছে ফেলতে চান? মুছে ফেলা পারসোনা পরে সেটিংস › পারসোনা-র “মুছে ফেলা পারসোনা” অংশ থেকে পুনরুদ্ধার করতে পারবেন।';
  }

  @override
  String get personaDeleteConfirm => 'মুছে ফেলুন';

  @override
  String get personaDeletedToast => 'পারসোনা মুছে ফেলা হয়েছে';

  @override
  String get personaCreatedToast => 'পারসোনা তৈরি করা হয়েছে';

  @override
  String personaCreateFailedToast(String error) {
    return 'পারসোনা তৈরি করা যায়নি: $error';
  }

  @override
  String get personaChangeAvatar => 'অ্যাভাটার বদলান';

  @override
  String get personaRemoveAvatar => 'অ্যাভাটার সরান';

  @override
  String get personaUploadAvatar => 'অ্যাভাটার আপলোড করুন';

  @override
  String get personaTagsLabel => 'পারসোনা ট্যাগ';

  @override
  String get personaAutoTagDisabledLabel => 'এই পারসোনার ট্যাগ মেলাবেন না';

  @override
  String get personaAutoTagDisabledDescription =>
      'এই ট্যাগগুলোর কোনোটি লিখলে এই পারসোনায় বদলাবে না। ট্যাগটি যেভাবে লেখা হয়েছে সেভাবেই পাঠানো হবে।';

  @override
  String get personaTagPrefixLabel => 'প্রিফিক্স';

  @override
  String get personaTagSuffixLabel => 'সাফিক্স';

  @override
  String get personaVisibilityLabel => 'দৃশ্যমানতা';

  @override
  String get personaVisibilityUnlisted => 'তালিকার বাইরে';

  @override
  String get personaVisibilityPublic => 'সর্বজনীন';

  @override
  String get personaVisibilityPrivate => 'ব্যক্তিগত';

  @override
  String get personaNameRequired => 'পারসোনার ডিসপ্লে নাম লিখুন';

  @override
  String get personaNameTooLong =>
      'পারসোনার ডিসপ্লে নাম সর্বোচ্চ 100 অক্ষরের হতে পারে';

  @override
  String get personaTagPrefixTooLong =>
      'পারসোনা ট্যাগের প্রিফিক্স সর্বোচ্চ 32 অক্ষরের হতে পারে';

  @override
  String get personaTagSuffixTooLong =>
      'পারসোনা ট্যাগের সাফিক্স সর্বোচ্চ 32 অক্ষরের হতে পারে';

  @override
  String personaTagCollisionError(String tag, String name) {
    return '“$tag” ট্যাগটি ইতিমধ্যে “$name” ব্যবহার করছে।';
  }

  @override
  String get chatInsertTimestamp => 'টাইমস্ট্যাম্প বসান';

  @override
  String get chatAttachmentSendVoiceMessage => 'ভয়েস মেসেজ পাঠান';

  @override
  String get timestampPickerTitle => 'টাইমস্ট্যাম্প বসান';

  @override
  String get timestampPickerInsert => 'বসান';

  @override
  String get timestampCopied => 'টাইমস্ট্যাম্প কপি করা হয়েছে';

  @override
  String get timestampPickerTimeLabel => 'সময়';

  @override
  String get timestampPickerDateLabel => 'তারিখ';

  @override
  String get timestampPickerTimeSectionLabel => 'সময়';

  @override
  String get timestampPickerTimezoneLabel => 'টাইম জোন';

  @override
  String get timestampPickerFormatPreviewLabel => 'ফরম্যাটের প্রিভিউ';

  @override
  String get timestampPickerNlpPlaceholder =>
      'যেমন tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'টাইম জোন খুঁজুন…';

  @override
  String get userProfileTimezoneSettingLabel => 'টাইম জোন';

  @override
  String get userProfileTimezoneSettingDescription =>
      'আপনার প্রোফাইলে স্থানীয় সময় দেখাতে ব্যবহৃত হয়।';

  @override
  String get userProfileTimezoneNone => 'কোনোটি নয়';

  @override
  String get chatReactAs => 'পারসোনা হিসেবে প্রতিক্রিয়া জানান…';

  @override
  String get emojiCopy => 'ইমোজি কপি করুন';

  @override
  String get emojiCopyLink => 'লিংক কপি করুন';

  @override
  String get emojiPin => 'ইমোজি পিন করুন';

  @override
  String get emojiUnpin => 'ইমোজি আনপিন করুন';

  @override
  String get emojiPinForPersona => 'এই পারসোনার জন্য পিন করুন';

  @override
  String get emojiUnpinForPersona => 'এই পারসোনার জন্য আনপিন করুন';

  @override
  String get personaSignatureEmojisLabel => 'সিগনেচার ইমোজি';

  @override
  String get personaSignatureEmojisDescription =>
      'সিগনেচার ইমোজি দিয়ে প্রতিক্রিয়া জানালে সক্রিয় পারসোনা যেটিই হোক, প্রতিক্রিয়া সবসময় এই পারসোনা হিসেবেই যাবে।';

  @override
  String get personaAddSignatureEmoji => 'ইমোজি যোগ করুন';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'এই ইমোজিটি ইতিমধ্যে সিগনেচার ইমোজি হিসেবে যোগ করা আছে';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'সিগনেচার ইমোজিটি ইতিমধ্যে “$name” পারসোনা ব্যবহার করছে';
  }

  @override
  String get personaRemoveSignatureEmoji => 'সিগনেচার ইমোজি সরান';

  @override
  String get signalBarLabel => 'সিগন্যাল বার';

  @override
  String get signalBarShow => 'সিগন্যাল বার দেখান';

  @override
  String get signalBarHide => 'সিগন্যাল বার লুকান';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'কেউ এই সিগন্যাল চালু করেনি';

  @override
  String get signalBarReset => 'সবার জন্য সিগন্যাল রিসেট করুন';

  @override
  String signalBarTurnOff(String name) {
    return '$name-এর জন্য বন্ধ করুন';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'ডিফল্ট ইনস্ট্যান্সের জন্য $domain ব্যবহার করুন, অথবা অন্য কোনো ইনস্ট্যান্সের সঠিক URL দিন।';
  }

  @override
  String get instanceResetToDefault => 'ডিফল্ট ইনস্ট্যান্সে ফিরে যান';

  @override
  String get personaScopeTitle => 'পারসোনা কোথায় প্রযোজ্য';

  @override
  String get personaScopeGlobal => 'সবখানে';

  @override
  String get personaScopeGlobalDescription =>
      'সব চ্যানেলের জন্য একটিই পারসোনা।';

  @override
  String get personaScopeChannel => 'প্রতিটি চ্যানেলে';

  @override
  String get personaScopeChannelDescription =>
      'প্রতিটি চ্যানেল নিজের পারসোনা মনে রাখে। নতুন চ্যানেল শুরু হয় আপনার অ্যাকাউন্ট দিয়ে।';

  @override
  String get personaPickerChannelOnly => 'শুধু এই চ্যানেলের জন্য';

  @override
  String get personaProfilePrivate => 'এই পারসোনার প্রোফাইল ব্যক্তিগত।';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'ছবির ফাইলটি অনেক বড়। $maxSize-এর চেয়ে ছোট একটি ফাইল বেছে নিন।';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'KLIPY-তে খুঁজুন';

  @override
  String get appUpdateDownloadFailed => 'আপডেট ডাউনলোড করা যায়নি';

  @override
  String get appUpdateInstallFailed => 'আপডেট ইনস্টল করা যায়নি';

  @override
  String get personaChangeMessageFailed => 'মেসেজের পারসোনা বদলানো যায়নি';

  @override
  String get personaActiveCleared => 'সক্রিয় পারসোনা সরানো হয়েছে';

  @override
  String get klipyPoweredBy => 'KLIPY দ্বারা চালিত';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'এই পারসোনায় “$pattern” ট্যাগ জোড়া একাধিকবার আছে';
  }

  @override
  String personaAddTagPair(int count) {
    return 'ট্যাগ জোড়া যোগ করুন ($count/5)';
  }

  @override
  String get personaTagExampleText => 'টেক্সট';

  @override
  String get personaPreviewNameFallback => 'ব্যবহারকারী';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne অপ্রত্যাশিতভাবে বন্ধ হয়ে গেছে। বেনামি ক্র্যাশ ও ত্রুটির তথ্য শেয়ার করলে আমরা আরও দ্রুত সমস্যা ঠিক করতে পারি।';

  @override
  String get crashReportingSectionDescription =>
      'ক্র্যাশ ও পারফরম্যান্সের তথ্য শেয়ার করে Tyne-এর বাগ ঠিক করতে সাহায্য করুন। এটি ডিফল্টভাবে বন্ধ থাকে।';

  @override
  String get crashReportingDescription =>
      'অন্য কোনো ইনস্ট্যান্সে সাইন ইন করা থাকলেও রিপোর্টগুলো Tyne-এর নিজস্ব এরর ট্র্যাকারে যায়। এগুলোতে ইনস্ট্যান্সের নাম, আইডি বা মেসেজের বিষয়বস্তু থাকে না।';

  @override
  String get instanceOfflineTitle => 'Tyne অফলাইন!';

  @override
  String get instanceOfflineBody => 'আমরা বিষয়টি খতিয়ে দেখছি।';

  @override
  String get instanceStatusSignalLink =>
      'আপডেট পেতে আমাদের Signal চ্যাটে যোগ দিন';

  @override
  String get convertEmoticonsLabel => 'টেক্সট স্মাইলিকে ইমোজিতে বদলান';

  @override
  String guildCommandFailed(String name, String detail) {
    return '/$name চালানো যায়নি: $detail';
  }

  @override
  String get guildCommandBroken => 'এর স্ক্রিপ্টে সমস্যা আছে।';

  @override
  String guildCommandOneLine(String name) {
    return '/$name-এর পরে আপনি যা লিখবেন তা এক লাইনের মধ্যে হতে হবে।';
  }

  @override
  String get permissionCreateCommands => 'কমান্ড তৈরি';

  @override
  String get permissionManageCommands => 'কমান্ড পরিচালনা';

  @override
  String get permissionUseExternalCommands => 'বাইরের কমান্ড ব্যবহার';

  @override
  String get permissionCreateCommandsDescription =>
      'এই কমিউনিটির জন্য কমান্ড তৈরি করতে এবং নিজের কমান্ড এডিট বা মুছে ফেলতে দেয়।';

  @override
  String get permissionManageCommandsDescription =>
      'এই কমিউনিটিতে যে কারও কমান্ড এডিট বা মুছে ফেলতে দেয়।';

  @override
  String get permissionUseExternalCommandsDescription =>
      'অন্য কমিউনিটির কমান্ড ব্যবহার করতে দেয়।';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'এই চ্যানেলে অন্য কমিউনিটির কমান্ড ব্যবহার করতে দেয়।';

  @override
  String get guildSettingsCategoryMessageTools => 'মেসেজ টুল';

  @override
  String get guildSettingsCommands => 'কমান্ড';

  @override
  String get guildCommandsLoadFailed => 'কমান্ডগুলো লোড করা যায়নি।';

  @override
  String get guildCommandsSubtitle =>
      'সদস্যরা /name লিখে যেসব মেসেজ পোস্ট করতে পারেন।';

  @override
  String get guildCommandsSlots => 'কমান্ড স্লট';

  @override
  String get guildCommandsNew => 'নতুন কমান্ড';

  @override
  String get guildCommandsSearch => 'কমান্ড খুঁজুন';

  @override
  String get guildCommandsEmptyTitle => 'কোনো কমান্ড নেই';

  @override
  String get guildCommandsEmptyBody => 'এই কমিউনিটিতে এখনও কোনো কমান্ড নেই।';

  @override
  String get guildCommandsSaved => 'কমান্ড সেভ করা হয়েছে';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return '/$name সেভ করা যায়নি: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return '/$name এডিট করুন';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return '/$name মুছে ফেলবেন?';
  }

  @override
  String get guildCommandDeleteBody =>
      'এটি পূর্বাবস্থায় ফেরানো যাবে না। এটি দিয়ে তৈরি মেসেজে তবুও দেখা যাবে কোন কমান্ড সেগুলো তৈরি করেছে।';

  @override
  String get guildCommandDelete => 'মুছে ফেলুন';

  @override
  String get guildCommandDeleteCommand => 'কমান্ড মুছে ফেলুন';

  @override
  String get guildCommandSectionCommand => 'কমান্ড';

  @override
  String get guildCommandName => 'নাম';

  @override
  String get guildCommandNameInvalid =>
      'ছোট হাতের ইংরেজি অক্ষর, সংখ্যা, - ও _ ব্যবহার করুন, সর্বোচ্চ 32 অক্ষর।';

  @override
  String get guildCommandNameTaken =>
      'অন্য কোনো কমান্ড বা বিল্ট-ইন কমান্ড ইতিমধ্যে এই নাম ব্যবহার করছে।';

  @override
  String get guildCommandDescription => 'বিবরণ';

  @override
  String get guildCommandSectionInput => 'ইনপুট';

  @override
  String get guildCommandInputNone => 'নেই';

  @override
  String get guildCommandInputOptional => 'ঐচ্ছিক';

  @override
  String get guildCommandInputRequired => 'আবশ্যক';

  @override
  String get guildCommandHint => 'ইঙ্গিত';

  @override
  String get guildCommandMessage => 'মেসেজ';

  @override
  String get guildCommandInsert => 'বসান:';

  @override
  String get guildCommandInsertPerson => 'যিনি চালাচ্ছেন';

  @override
  String get guildCommandInsertInput => 'তারা যা লেখে';

  @override
  String get guildCommandPreview => 'প্রিভিউ';

  @override
  String get guildCommandSampleInput => 'নমুনা ইনপুট';

  @override
  String guildCommandMadeWith(String name) {
    return '/$name দিয়ে তৈরি';
  }

  @override
  String guildCommandClearBox(String name) {
    return '/$name ব্যবহার করতে মেসেজ বক্স খালি করুন';
  }

  @override
  String get guildCommandEmptyMessage =>
      'এতে কিছুই পোস্ট হবে না, তাই কমান্ডটি ব্যর্থ হবে।';

  @override
  String get guildCommandUseScriptEditor => 'স্ক্রিপ্ট এডিটর ব্যবহার করুন';

  @override
  String get guildCommandUseBasicEditor => 'সাধারণ এডিটর ব্যবহার করুন';

  @override
  String get guildCommandScript => 'স্ক্রিপ্ট';

  @override
  String get guildCommandRunAgain => 'আবার চালান';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return '$name নামে কোনো ট্যাগ নেই।';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return '$name নামে কোনো ফিল্টার নেই।';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name কখনো বন্ধ করা হয়নি।';
  }

  @override
  String get guildCommandIssueTooLong => 'স্ক্রিপ্টটি অনেক লম্বা।';

  @override
  String get guildCommandIssueTooLarge =>
      'স্ক্রিপ্টটি অনেক বেশি টেক্সট তৈরি করছে।';

  @override
  String get guildCommandIssueTooSlow =>
      'স্ক্রিপ্টটি চলতে অনেক বেশি সময় নিয়েছে।';

  @override
  String get guildCommandIssueInvalid => 'এই অংশটি পড়া যাচ্ছে না।';

  @override
  String get guildCommandIssueFailed => 'এই অংশে ত্রুটি হয়ে থেমে গেছে।';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'লাইন $line, কলাম $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'স্ক্রিপ্ট রেফারেন্স';

  @override
  String get guildCommandReferencePerson => 'যিনি চালাচ্ছেন, মেনশন হিসেবে';

  @override
  String get guildCommandReferencePersonName => 'তার নাম';

  @override
  String get guildCommandReferenceTarget =>
      'প্রথম যাকে মেনশন করা হয়েছে, যদি থাকে';

  @override
  String get guildCommandReferenceTargetName => 'সেই ব্যক্তির নাম';

  @override
  String get guildCommandReferenceChannel => 'চ্যানেলটি, মেনশন হিসেবে';

  @override
  String get guildCommandReferenceCommunity => 'এই কমিউনিটির নাম';

  @override
  String get guildCommandExampleRandom => 'এলোমেলোভাবে একটি বিকল্প বেছে নিন';

  @override
  String get guildCommandExampleDepends =>
      'তারা কী লিখেছে তার ওপর নির্ভর করে মেসেজ বদলান';

  @override
  String get guildCommandExampleOneWord => 'এলোমেলোভাবে একটি শব্দ বেছে নিন';

  @override
  String get guildCommandExampleWordForNumber =>
      'সংখ্যা অনুযায়ী শব্দ বেছে নিন';

  @override
  String get guildCommandExampleOrdinal =>
      'সংখ্যাকে 1st, 2nd, 3rd হিসেবে লিখুন';

  @override
  String get guildCommandFullGuide => 'স্ক্রিপ্টের পূর্ণ গাইড';

  @override
  String get guildCommandCounters => 'কাউন্টার';

  @override
  String get guildCommandCounterAdd => 'কাউন্টার যোগ করুন';

  @override
  String get guildCommandCounterSeparately => 'প্রতিটির জন্য আলাদা করে গুনুন:';

  @override
  String get guildCommandCounterPersonMentioned => 'যাকে মেনশন করা হয়েছে';

  @override
  String get guildCommandCounterChannel => 'চ্যানেল';

  @override
  String get guildCommandCounterPersonas => 'পারসোনা আলাদাভাবে গুনুন';

  @override
  String get guildCommandCounterRemove => 'কাউন্টার সরান';

  @override
  String get guildCommandCounterReset => 'গণনা রিসেট করুন';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return '$name-এর গণনা রিসেট করবেন? এটি পূর্বাবস্থায় ফেরানো যাবে না।';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'ছোট হাতের ইংরেজি অক্ষর, সংখ্যা ও _ ব্যবহার করুন; শুরু হবে অক্ষর দিয়ে, আর নামটি এমন হবে না যা স্ক্রিপ্ট আগে থেকেই ব্যবহার করে।';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'স্ক্রিপ্টে এটি $variable হিসেবে ব্যবহার করুন। প্রতিবার চালানোর সময় আগে এক যোগ হয়, তাই প্রথমবার এটি 1 দেখায়।';
  }

  @override
  String get notificationsAlertEveryMessageLabel =>
      'প্রতিটি মেসেজের জন্য অ্যালার্ট';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'বন্ধ থাকলে ব্যস্ত কথোপকথন একবার অ্যালার্ট দেয়, তারপর আপনি সেটি না পড়া বা সরিয়ে না দেওয়া পর্যন্ত নিঃশব্দে আপডেট হয়।';

  @override
  String personaGalleryTitle(int count) {
    return 'পারসোনা ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return '$name-এর পারসোনা খুঁজুন';
  }

  @override
  String get personaGallerySearchOwn => 'আপনার পারসোনা খুঁজুন';

  @override
  String get personaGallerySortBy => 'এই অনুযায়ী সাজান';

  @override
  String get personaGallerySortName => 'নাম (A–Z)';

  @override
  String get personaGallerySortMostUsed => 'সবচেয়ে বেশি ব্যবহৃত';

  @override
  String get personaGallerySortRecentlyUsed => 'সম্প্রতি ব্যবহৃত';

  @override
  String get personaGalleryViewGallery => 'গ্যালারি';

  @override
  String get personaGalleryViewList => 'তালিকা';

  @override
  String get personaGalleryViewAvatars => 'অ্যাভাটার';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পারসোনা',
      one: '$countটি পারসোনা',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return '$totalটি পারসোনার মধ্যে $shownটি';
  }

  @override
  String get personaGalleryNoMatch =>
      'আপনার সার্চের সঙ্গে কোনো পারসোনা মেলেনি।';

  @override
  String get personaGalleryLoadFailed => 'পারসোনা লোড করা যায়নি।';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি সর্বজনীন পারসোনা',
      one: '$countটি সর্বজনীন পারসোনা',
    );
    return 'অন্যরা $_temp0 দেখতে পায়।';
  }

  @override
  String get personaGalleryShowHidden =>
      'তালিকার বাইরের ও ব্যক্তিগতগুলোও দেখান';

  @override
  String get personaGalleryManage => 'পারসোনা পরিচালনা করুন';

  @override
  String get personaGalleryNonePublic =>
      'আপনার কোনো পারসোনা এখনও সর্বজনীন নয়। কোনো পারসোনার দৃশ্যমানতা সর্বজনীন করলে অন্যরা সেটি এখানে দেখতে পাবে।';

  @override
  String get personaGalleryNoBio => 'এখনও কোনো বায়ো নেই।';

  @override
  String personaGalleryCreated(String date) {
    return 'তৈরি: $date';
  }

  @override
  String get personaBulkSelect => 'নির্বাচন করুন';

  @override
  String get personaBulkSelectAll => 'সব নির্বাচন করুন';

  @override
  String personaBulkSelectedCount(int count) {
    return '$countটি নির্বাচিত';
  }

  @override
  String get personaFilterAll => 'সব';

  @override
  String get personaBulkMakePublic => 'সর্বজনীন করুন';

  @override
  String get personaBulkMakeUnlisted => 'তালিকার বাইরে রাখুন';

  @override
  String get personaBulkMakePrivate => 'ব্যক্তিগত করুন';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পারসোনা',
      one: '$countটি পারসোনা',
    );
    return '$_temp0 সর্বজনীন করবেন?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পারসোনা',
      one: '$countটি পারসোনা',
    );
    return '$_temp0 ব্যক্তিগত করবেন?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পারসোনা',
      one: '$countটি পারসোনা',
    );
    return '$_temp0 মুছে ফেলবেন?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'এই পারসোনাগুলো অন্যরা আপনার পারসোনা তালিকায় দেখতে পাবে এবং তাদের প্রোফাইল খুলতে পারবে। আপনি যেকোনো সময় এটি আবার বদলাতে পারবেন।';

  @override
  String get personaBulkConfirmPrivateBody =>
      'তাদের প্রোফাইল অন্যদের কাছ থেকে লুকানো থাকবে। তাদের মেসেজ ও প্রতিক্রিয়ায় নাম ও অ্যাভাটার তবুও দেখা যাবে।';

  @override
  String get personaBulkConfirmDeleteBody =>
      'মুছে ফেলা পারসোনা পরে সেটিংস › পারসোনা-র “মুছে ফেলা পারসোনা” অংশ থেকে পুনরুদ্ধার করতে পারবেন।';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পারসোনা',
      one: '$countটি পারসোনা',
    );
    return '$_temp0 এখন সর্বজনীন';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পারসোনা',
      one: '$countটি পারসোনা',
    );
    return '$_temp0 এখন তালিকার বাইরে';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পারসোনা',
      one: '$countটি পারসোনা',
    );
    return '$_temp0 এখন ব্যক্তিগত';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পারসোনা',
      one: '$countটি পারসোনা',
    );
    return '$_temp0 মুছে ফেলা হয়েছে';
  }

  @override
  String get personaBulkFailed =>
      'পারসোনাগুলো বদলানো যায়নি। আবার চেষ্টা করুন।';

  @override
  String get personaFilterEmpty => 'এখানে কোনো পারসোনা নেই।';

  @override
  String get personaGalleryChooseFeatured =>
      'কোন পারসোনাগুলো দেখাবেন, বেছে নিন';

  @override
  String get personaUndo => 'পূর্বাবস্থায় ফেরান';

  @override
  String get personaReactionsTitle => 'আপনার প্রতিক্রিয়া';

  @override
  String get personaReactionsEveryoneElse => 'অন্য সবাই';

  @override
  String get personaReactionsCurrent => 'বর্তমান';

  @override
  String get personaReactionsAccount => 'অ্যাকাউন্ট';

  @override
  String get personaReactionsSomeoneElse =>
      'অন্য কারও হিসেবে প্রতিক্রিয়া জানান…';

  @override
  String get personaReactionsDone => 'সম্পন্ন';

  @override
  String get personaSettingsReactionsHeader => 'প্রতিক্রিয়া';

  @override
  String get personaSettingsMultiReactions =>
      'একসঙ্গে একাধিক পারসোনা হিসেবে প্রতিক্রিয়া জানান';

  @override
  String get personaDuplicateButton => 'পারসোনা ডুপ্লিকেট করুন';

  @override
  String personaCopyOf(String name) {
    return '$name-এর কপি';
  }

  @override
  String signalsEverywhereTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count টি চ্যাট',
      one: '$count টি চ্যাট',
    );
    return 'সবখানে আপনার সিগন্যাল · $_temp0';
  }

  @override
  String signalsEverywhereHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count টি চ্যাট',
      one: '$count টি চ্যাট',
    );
    return 'সবখানে সেট করুন ($_temp0)';
  }

  @override
  String signalsEverywhereSet(String label) {
    return 'সবখানে $label সেট করুন';
  }

  @override
  String get signalsEverywhereTurnAllOff => 'সব বন্ধ করুন';

  @override
  String get signalsEverywhereRestore => 'পুনরুদ্ধার করুন…';

  @override
  String get signalsEverywhereNone => 'আপনার কোনো সিগন্যাল কোথাও চালু নেই।';

  @override
  String get signalsRestoreTitle => 'আপনার সিগন্যাল পুনরুদ্ধার করবেন?';

  @override
  String signalsRestoreBeforeSet(String label, String time) {
    return '$time-এ সবখানে $label সেট করার আগে আপনি যা চালু রেখেছিলেন তা ফিরিয়ে আনে। সেখানে এখন যা চালু আছে তা বন্ধ হয়ে যাবে।';
  }

  @override
  String signalsRestoreBeforeOff(String time) {
    return '$time-এ সব বন্ধ করার আগে আপনি যা চালু রেখেছিলেন তা ফিরিয়ে আনে। সেখানে এখন যা চালু আছে তা বন্ধ হয়ে যাবে।';
  }

  @override
  String signalsRestoreBeforeRestore(String time) {
    return '$time-এ আপনার শেষ পুনরুদ্ধারের আগে যা চালু ছিল তা ফিরিয়ে আনে। সেখানে এখন যা চালু আছে তা বন্ধ হয়ে যাবে।';
  }

  @override
  String get signalsRestoreNow => 'এখন';

  @override
  String get signalsRestoreAfter => 'পরে';

  @override
  String signalsRestoreLeftOut(String chats) {
    return 'বাদ দেওয়া হয়েছে, কারণ আপনি আর সেখানে পোস্ট করতে পারেন না: $chats';
  }

  @override
  String get signalsRestoreConfirm => 'পুনরুদ্ধার করুন';

  @override
  String get signalsRestoreUnavailable =>
      'পুনরুদ্ধার করলে কী বদলাবে তা লোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get signalsRestoreNothing => 'পুনরুদ্ধার করার মতো কিছু নেই।';

  @override
  String get signalsProfileMenu => 'সিগন্যাল';

  @override
  String get signalsEverywhereTurnOffChat => 'সিগন্যাল বন্ধ করুন';

  @override
  String signalsRestoreBeforeChange(String time) {
    return '$time-এ সবখানে আপনার শেষ পরিবর্তনের আগে যা চালু ছিল তা ফিরিয়ে আনে। সেখানে এখন যা চালু আছে তা বন্ধ হয়ে যাবে।';
  }

  @override
  String get personaCopyBadge => 'নতুন পারসোনা';

  @override
  String get deletedPersonasTitle => 'মুছে ফেলা পারসোনা';

  @override
  String get deletedPersonasDescription =>
      'মুছে ফেলা পারসোনা তাদের পুরোনো মেসেজে এখনও দেখা যায়, কিন্তু কেউ তাদের বেছে নিতে পারে না এবং আপনার সীমার মধ্যে তাদের গোনা হয় না। পুনরুদ্ধার করলে একই পারসোনা তার ইতিহাসসহ ফিরে আসে।';

  @override
  String get deletedPersonasShow => 'মুছে ফেলা পারসোনা দেখান';

  @override
  String get deletedPersonasLoadFailed =>
      'মুছে ফেলা পারসোনাগুলো লোড করা যায়নি।';

  @override
  String get deletedPersonasEmpty => 'মুছে ফেলা কোনো পারসোনা নেই।';

  @override
  String deletedPersonaDeletedAt(String date) {
    return 'মুছে ফেলা হয়েছে: $date';
  }

  @override
  String deletedPersonaUseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count বার ব্যবহৃত',
      one: '$count বার ব্যবহৃত',
    );
    return '$_temp0';
  }

  @override
  String get deletedPersonaRestore => 'পুনরুদ্ধার করুন';

  @override
  String personaRestored(String name) {
    return '$name ফিরে এসেছে।';
  }

  @override
  String personaRestoredWithout(String items) {
    return '$items ছাড়াই ফিরে এসেছে: এগুলো এখন অন্য একটি পারসোনার।';
  }

  @override
  String get personaRestoreFailed => 'পারসোনাটি পুনরুদ্ধার করা যায়নি।';

  @override
  String deletedPersonaRestoreLabel(String name) {
    return '$name পুনরুদ্ধার করুন';
  }
}
