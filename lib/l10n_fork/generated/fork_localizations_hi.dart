// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class ForkLocalizationsHi extends ForkLocalizations {
  ForkLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get chatMessageChangePersona => 'परसोना बदलें';

  @override
  String get chatAttachmentPanelVoice => 'वॉइस';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'क्विक स्विचर बटन';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'तेज़ नेविगेशन के लिए इनपुट बॉक्स में वॉइस मैसेज बटन को क्विक स्विचर बटन से बदलें';

  @override
  String get userSettingsCheckForUpdates => 'अपडेट देखें';

  @override
  String get userSettingsCheckingForUpdates => 'अपडेट की जाँच की जा रही है…';

  @override
  String get userSettingsAppUpToDate => 'Tyne अप-टू-डेट है';

  @override
  String get userSettingsUpdateAvailableTitle => 'अपडेट उपलब्ध है';

  @override
  String get userSettingsUpdateDownloadAction => 'डाउनलोड और इंस्टॉल करें';

  @override
  String get userSettingsUpdateInstallAction => 'अपडेट इंस्टॉल करें';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'अपडेट डाउनलोड हो रहा है ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'अपडेट की जाँच करने या डाउनलोड करने में विफल।';

  @override
  String get personaSelectTitle => 'परसोना चुनें';

  @override
  String get personaSettingsHeader => 'परसोना सेटिंग्स';

  @override
  String get personaManageAction => 'मैनेज करें';

  @override
  String get personaSearchPlaceholder => 'परसोना, टैग, प्रोनाउन खोजें...';

  @override
  String get personaModeManual => 'मैनुअल';

  @override
  String get personaModeLast => 'पिछली बार इस्तेमाल किया गया';

  @override
  String get personaModeManualDescription =>
      'बदले जाने तक हमेशा चुने गए परसोना के रूप में भेजता है।';

  @override
  String get personaModeLastDescription =>
      'आपके पिछले मैसेज में इस्तेमाल किए गए परसोना पर अपने आप स्विच हो जाता है।';

  @override
  String get personaRecentHeader => 'हालिया परसोना';

  @override
  String personaAllHeader(int count) {
    return 'सभी परसोना ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'खोज के नतीजे ($count)';
  }

  @override
  String get personaRootAccountLabel => 'रूट अकाउंट (डिफ़ॉल्ट)';

  @override
  String get personaEmptyState =>
      'अभी तक कोई परसोना कॉन्फ़िगर नहीं किया गया है। \'परसोना मैनेज करें\' के ज़रिए एक बनाएं।';

  @override
  String get personaEmptySearch => 'कोई मेल खाने वाला परसोना नहीं मिला।';

  @override
  String get personaEditTitle => 'परसोना एडिट करें';

  @override
  String get personaCreateTitle => 'परसोना बनाएँ';

  @override
  String get personaDisplayNameLabel => 'डिस्प्ले नाम';

  @override
  String get personaPronounsLabel => 'सर्वनाम';

  @override
  String get personaPronounsHint => 'जैसे वह/वे';

  @override
  String get personaBioHint => 'दूसरों को इस परसोना के बारे में बताएं...';

  @override
  String get personaUpdatedToast => 'परसोना अपडेट हो गया';

  @override
  String personaUpdateFailedToast(String error) {
    return 'परसोना अपडेट नहीं हो सका: $error';
  }

  @override
  String get personaSectionTitle => 'परसोना';

  @override
  String get personaDisplayNameHint => 'परसोना का नाम';

  @override
  String personaSendingAsTag(String name) {
    return '$name के तौर पर भेज रहे हैं (टैग द्वारा मैच किया गया)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return '$name के तौर पर भेज रहे हैं (लॉक किया गया)';
  }

  @override
  String personaSendingAs(String name) {
    return '$name के तौर पर भेज रहे हैं';
  }

  @override
  String personaPostingAs(String name) {
    return '$name के तौर पर पोस्ट कर रहे हैं';
  }

  @override
  String personaSendingAsRoot(String username) {
    return '@$username के तौर पर भेज रहे हैं';
  }

  @override
  String get personaMainAccount => 'मेन अकाउंट';

  @override
  String get personaEditPersona => 'परसोना एडिट करें';

  @override
  String get userSettingsNavPersonas => 'परसोना';

  @override
  String get personaSettingsDescription =>
      'अपना एक्टिव परसोना मोड, कस्टम डिस्प्ले टैग कॉन्फ़िगर करें और अलग-अलग परसोना मैनेज करें।';

  @override
  String get personaDisplayTagSection => 'डिस्प्ले टैग';

  @override
  String get personaDisplayTagDescription =>
      'डिस्प्ले टैग मैसेज में सभी परसोना नाम के आगे दिखाई देगा। यदि कोई डिस्प्ले टैग सेट नहीं है, तो आपकी अकाउंट प्रोफ़ाइल पिक्चर दिखाई जाएगी।';

  @override
  String get personaDisplayTagLabel => 'डिस्प्ले टैग टेक्स्ट';

  @override
  String get personaDisplayTagHint => 'जैसे SYS';

  @override
  String get personaDisplayTagIconLabel => 'डिस्प्ले टैग आइकॉन';

  @override
  String get personaUploadTagIcon => 'आइकॉन अपलोड करें';

  @override
  String get personaChangeTagIcon => 'आइकॉन बदलें';

  @override
  String get personaRemoveTagIcon => 'आइकॉन हटाएँ';

  @override
  String get personaChatPreviewTitle => 'चैट प्रीव्यू';

  @override
  String get personaChatPreviewSampleMessage =>
      'नमस्ते! यह एक प्रीव्यू है कि आपके डिस्प्ले टैग और एक्टिव परसोना के साथ मैसेज कैसे दिखते हैं।';

  @override
  String get personaListTitle => 'कॉन्फ़िगर किए गए परसोना';

  @override
  String get personaAddButton => 'परसोना जोड़ें';

  @override
  String get personaActiveBadge => 'सक्रिय';

  @override
  String get personaMakeActive => 'एक्टिव सेट करें';

  @override
  String get personaDeleteTitle => 'परसोना डिलीट करें';

  @override
  String personaDeleteMessage(String name) {
    return 'क्या आप वाकई \"$name\" को डिलीट करना चाहते हैं? इसे पहले जैसा नहीं किया जा सकता।';
  }

  @override
  String get personaDeleteConfirm => 'मिटाएँ';

  @override
  String get personaDeletedToast => 'परसोना डिलीट हो गया';

  @override
  String get personaCreatedToast => 'परसोना बन गया';

  @override
  String personaCreateFailedToast(String error) {
    return 'परसोना नहीं बनाया जा सका: $error';
  }

  @override
  String get personaChangeAvatar => 'अवतार बदलें';

  @override
  String get personaRemoveAvatar => 'अवतार हटाएँ';

  @override
  String get personaUploadAvatar => 'अवतार अपलोड करें';

  @override
  String get personaTagsLabel => 'परसोना टैग';

  @override
  String get personaTagPrefixLabel => 'उपसर्ग';

  @override
  String get personaTagSuffixLabel => 'प्रत्यय';

  @override
  String get personaVisibilityLabel => 'विज़िबिलिटी';

  @override
  String get personaVisibilityUnlisted => 'अनलिस्टेड';

  @override
  String get personaVisibilityPublic => 'पब्लिक';

  @override
  String get personaVisibilityPrivate => 'प्राइवेट';

  @override
  String get personaNameRequired => 'कृपया परसोना का डिस्प्ले नाम दर्ज करें';

  @override
  String get personaNameTooLong =>
      'परसोना का डिस्प्ले नाम 100 वर्ण या उससे कम होना चाहिए';

  @override
  String get personaTagPrefixTooLong =>
      'परसोना टैग उपसर्ग 32 वर्ण या उससे कम होना चाहिए';

  @override
  String get personaTagSuffixTooLong =>
      'परसोना टैग प्रत्यय 32 वर्ण या उससे कम होना चाहिए';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'टैग \'$tag\' पहले से ही \'$name\' द्वारा उपयोग में है।';
  }

  @override
  String get chatInsertTimestamp => 'समय टिकट डालें';

  @override
  String get chatAttachmentSendVoiceMessage => 'वॉइस मैसेज भेजें';

  @override
  String get timestampPickerTitle => 'समय टिकट डालें';

  @override
  String get timestampPickerInsert => 'डालें';

  @override
  String get timestampCopied => 'समय टिकट कॉपी किया गया';

  @override
  String get timestampPickerTimeLabel => 'समय';

  @override
  String get timestampPickerDateLabel => 'तारीख';

  @override
  String get timestampPickerTimeSectionLabel => 'समय';

  @override
  String get timestampPickerTimezoneLabel => 'समय क्षेत्र';

  @override
  String get timestampPickerFormatPreviewLabel => 'प्रारूप पूर्वावलोकन';

  @override
  String get timestampPickerNlpPlaceholder =>
      'उदा. कल दोपहर 3 बजे, 2 घंटे में, अभी';

  @override
  String get timestampPickerSearchTimezones => 'समय क्षेत्र खोजें...';

  @override
  String get userProfileTimezoneSettingLabel => 'समय क्षेत्र';

  @override
  String get userProfileTimezoneSettingDescription =>
      'आपकी प्रोफ़ाइल पर आपका स्थानीय समय दिखाने के लिए उपयोग किया जाता है।';

  @override
  String get userProfileTimezoneNone => 'कोई नहीं';

  @override
  String get chatReactAs => 'के रूप में प्रतिक्रिया दें...';

  @override
  String get emojiCopy => 'इमोजी कॉपी करें';

  @override
  String get emojiCopyLink => 'लिंक कॉपी करें';

  @override
  String get emojiPin => 'इमोजी पिन करें';

  @override
  String get emojiUnpin => 'इमोजी अनपिन करें';

  @override
  String get emojiPinForPersona => 'इस परसोना के लिए पिन करें';

  @override
  String get emojiUnpinForPersona => 'इस परसोना के लिए अनपिन करें';

  @override
  String get personaSignatureEmojisLabel => 'हस्ताक्षर इमोजी';

  @override
  String get personaSignatureEmojisDescription =>
      'हस्ताक्षर इमोजी के साथ प्रतिक्रिया देने पर हमेशा इस व्यक्तित्व के रूप में प्रतिक्रिया होगी, चाहे कोई भी सक्रिय व्यक्तित्व हो।';

  @override
  String get personaAddSignatureEmoji => 'इमोजी जोड़ें';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'यह इमोजी पहले से ही एक हस्ताक्षर इमोजी के रूप में जोड़ा गया है';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'हस्ताक्षर इमोजी का उपयोग पहले से ही व्यक्तित्व \"$name\" द्वारा किया जा रहा है';
  }

  @override
  String get personaRemoveSignatureEmoji => 'हस्ताक्षर इमोजी हटाएं';

  @override
  String get signalBarLabel => 'सिग्नल बार';

  @override
  String get signalBarShow => 'सिग्नल बार दिखाएँ';

  @override
  String get signalBarHide => 'सिग्नल बार छिपाएँ';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'किसी ने यह सिग्नल चालू नहीं किया है';

  @override
  String get signalBarReset => 'सभी के लिए सिग्नल रीसेट करें';

  @override
  String signalBarTurnOff(String name) {
    return '$name बंद करें';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'डिफ़ॉल्ट इंस्टेंस के लिए $domain का उपयोग करें, या किसी अन्य इंस्टेंस का सटीक URL दर्ज करें।';
  }

  @override
  String get instanceResetToDefault => 'डिफ़ॉल्ट इंस्टेंस पर रीसेट करें';

  @override
  String get personaScopeTitle => 'परसोना यहाँ लागू होता है';

  @override
  String get personaScopeGlobal => 'हर जगह';

  @override
  String get personaScopeGlobalDescription => 'सभी चैनलों के लिए एक परसोना।';

  @override
  String get personaScopeChannel => 'हर चैनल में';

  @override
  String get personaScopeChannelDescription =>
      'हर चैनल अपना परसोना रखता है। नए चैनल आपके अकाउंट से शुरू होते हैं।';

  @override
  String get personaPickerChannelOnly => 'केवल इस चैनल के लिए';

  @override
  String get personaProfilePrivate => 'इस परसोना की प्रोफ़ाइल निजी है।';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'छवि फ़ाइल बहुत बड़ी है। कृपया $maxSize से छोटी फ़ाइल चुनें।';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'KLIPY खोजें';

  @override
  String get appUpdateDownloadFailed => 'अपडेट डाउनलोड नहीं हो सका';

  @override
  String get appUpdateInstallFailed => 'अपडेट इंस्टॉल नहीं हो सका';

  @override
  String get personaChangeMessageFailed => 'संदेश का परसोना बदला नहीं जा सका';

  @override
  String get personaActiveCleared => 'सक्रिय परसोना हटा दिया गया';

  @override
  String get klipyPoweredBy => 'KLIPY द्वारा संचालित';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'इस परसोना पर टैग जोड़ी \'$pattern\' दोहराई गई है';
  }

  @override
  String personaAddTagPair(int count) {
    return 'टैग जोड़ी जोड़ें ($count/5)';
  }

  @override
  String get personaTagExampleText => 'टेक्स्ट';

  @override
  String get personaPreviewNameFallback => 'उपयोगकर्ता';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne अप्रत्याशित रूप से बंद हो गया। गुमनाम क्रैश और त्रुटि डेटा साझा करने से हमें समस्याएँ जल्दी ठीक करने में मदद मिलती है।';

  @override
  String get crashReportingSectionDescription =>
      'क्रैश और प्रदर्शन डेटा साझा करके Tyne की गड़बड़ियाँ ठीक करने में मदद करें। यह डिफ़ॉल्ट रूप से बंद है।';

  @override
  String get crashReportingDescription =>
      'रिपोर्ट Tyne के अपने एरर ट्रैकर पर जाती हैं, भले ही आप किसी दूसरे इंस्टेंस में साइन इन हों। इनमें इंस्टेंस के नाम, आईडी या संदेशों की सामग्री शामिल नहीं होती।';

  @override
  String get instanceOfflineTitle => 'Tyne ऑफ़लाइन है!';

  @override
  String get instanceOfflineBody => 'हम जाँच कर रहे हैं।';

  @override
  String get instanceStatusSignalLink =>
      'अपडेट के लिए हमारी Signal चैट से जुड़ें';

  @override
  String get convertEmoticonsLabel => 'टेक्स्ट स्माइली को इमोजी में बदलें';

  @override
  String guildCommandFailed(String name, String detail) {
    return '/$name नहीं चल सका: $detail';
  }

  @override
  String get guildCommandBroken => 'इसकी स्क्रिप्ट में कोई समस्या है।';

  @override
  String guildCommandOneLine(String name) {
    return '/$name के बाद आप जो टाइप करें, वह एक पंक्ति में आना चाहिए।';
  }

  @override
  String get permissionCreateCommands => 'कमांड बनाएँ';

  @override
  String get permissionManageCommands => 'कमांड प्रबंधित करें';

  @override
  String get permissionUseExternalCommands => 'बाहरी कमांड इस्तेमाल करें';

  @override
  String get permissionCreateCommandsDescription =>
      'इस कम्युनिटी के लिए कमांड बनाएँ, और अपने कमांड बदलें या मिटाएँ।';

  @override
  String get permissionManageCommandsDescription =>
      'इस कम्युनिटी में किसी के भी कमांड बदलें या मिटाएँ।';

  @override
  String get permissionUseExternalCommandsDescription =>
      'दूसरी कम्युनिटी के कमांड इस्तेमाल करें।';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'इस चैनल में दूसरी कम्युनिटी के कमांड इस्तेमाल करें।';

  @override
  String get guildSettingsCategoryMessageTools => 'संदेश टूल';

  @override
  String get guildSettingsCommands => 'कमांड';

  @override
  String get guildCommandsLoadFailed => 'कमांड लोड नहीं हो सके।';

  @override
  String get guildCommandsSubtitle =>
      'ऐसे मैसेज जिन्हें सदस्य /name टाइप करके पोस्ट कर सकते हैं।';

  @override
  String get guildCommandsSlots => 'कमांड स्लॉट';

  @override
  String get guildCommandsNew => 'नया कमांड';

  @override
  String get guildCommandsSearch => 'कमांड खोजें';

  @override
  String get guildCommandsEmptyTitle => 'कोई कमांड नहीं';

  @override
  String get guildCommandsEmptyBody =>
      'इस कम्युनिटी में अभी कोई कमांड नहीं है।';

  @override
  String get guildCommandsSaved => 'कमांड सेव हो गए';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return '/$name सेव नहीं हो सका: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return '/$name बदलें';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return '/$name मिटाएँ?';
  }

  @override
  String get guildCommandDeleteBody =>
      'इसे वापस नहीं किया जा सकता। इससे बने मैसेज अब भी दिखाते हैं कि उन्हें किस कमांड ने बनाया।';

  @override
  String get guildCommandDelete => 'मिटाएँ';

  @override
  String get guildCommandDeleteCommand => 'कमांड मिटाएँ';

  @override
  String get guildCommandSectionCommand => 'कमांड';

  @override
  String get guildCommandName => 'नाम';

  @override
  String get guildCommandNameInvalid =>
      'छोटे अक्षर, अंक, - और _ इस्तेमाल करें, अधिकतम 32 वर्ण।';

  @override
  String get guildCommandNameTaken =>
      'यह नाम पहले से किसी दूसरे कमांड या बिल्ट-इन कमांड का है।';

  @override
  String get guildCommandDescription => 'विवरण';

  @override
  String get guildCommandSectionInput => 'इनपुट';

  @override
  String get guildCommandInputNone => 'कोई नहीं';

  @override
  String get guildCommandInputOptional => 'वैकल्पिक';

  @override
  String get guildCommandInputRequired => 'ज़रूरी';

  @override
  String get guildCommandHint => 'संकेत';

  @override
  String get guildCommandMessage => 'मैसेज';

  @override
  String get guildCommandInsert => 'डालें:';

  @override
  String get guildCommandInsertPerson => 'इस्तेमाल करने वाला व्यक्ति';

  @override
  String get guildCommandInsertInput => 'वे जो टाइप करते हैं';

  @override
  String get guildCommandPreview => 'प्रीव्यू';

  @override
  String get guildCommandSampleInput => 'नमूना इनपुट';

  @override
  String guildCommandMadeWith(String name) {
    return '/$name से बनाया गया';
  }

  @override
  String guildCommandClearBox(String name) {
    return '/$name इस्तेमाल करने के लिए मैसेज बॉक्स खाली करें';
  }

  @override
  String get guildCommandEmptyMessage =>
      'इससे कुछ भी पोस्ट नहीं होगा, इसलिए कमांड विफल हो जाएगा।';

  @override
  String get guildCommandUseScriptEditor => 'स्क्रिप्ट एडिटर इस्तेमाल करें';

  @override
  String get guildCommandUseBasicEditor => 'बेसिक एडिटर इस्तेमाल करें';

  @override
  String get guildCommandScript => 'स्क्रिप्ट';

  @override
  String get guildCommandRunAgain => 'फिर से चलाएँ';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return '$name नाम का कोई टैग नहीं है।';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return '$name नाम का कोई फ़िल्टर नहीं है।';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name कभी बंद नहीं होता।';
  }

  @override
  String get guildCommandIssueTooLong => 'स्क्रिप्ट बहुत लंबी है।';

  @override
  String get guildCommandIssueTooLarge =>
      'स्क्रिप्ट बहुत ज़्यादा टेक्स्ट बना रही है।';

  @override
  String get guildCommandIssueTooSlow =>
      'स्क्रिप्ट चलाने में बहुत ज़्यादा समय लगा।';

  @override
  String get guildCommandIssueInvalid => 'यह हिस्सा पढ़ा नहीं जा सकता।';

  @override
  String get guildCommandIssueFailed => 'यह हिस्सा गड़बड़ी के साथ रुक गया।';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'पंक्ति $line, कॉलम $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'स्क्रिप्ट गाइड';

  @override
  String get guildCommandReferencePerson =>
      'इस्तेमाल करने वाला व्यक्ति, मेंशन के रूप में';

  @override
  String get guildCommandReferencePersonName => 'इस्तेमाल करने वाले का नाम';

  @override
  String get guildCommandReferenceTarget =>
      'पहला व्यक्ति जिसे वे मेंशन करें, अगर कोई हो';

  @override
  String get guildCommandReferenceTargetName => 'उस व्यक्ति का नाम';

  @override
  String get guildCommandReferenceChannel => 'चैनल, मेंशन के रूप में';

  @override
  String get guildCommandReferenceCommunity => 'इस कम्युनिटी का नाम';

  @override
  String get guildCommandExampleRandom => 'कोई एक विकल्प रैंडम तरीके से चुनें';

  @override
  String get guildCommandExampleDepends =>
      'उन्होंने जो टाइप किया, उसके हिसाब से मैसेज बदलें';

  @override
  String get guildCommandExampleOneWord => 'कोई एक शब्द रैंडम तरीके से चुनें';

  @override
  String get guildCommandExampleWordForNumber =>
      'संख्या के हिसाब से शब्द चुनें';

  @override
  String get guildCommandExampleOrdinal =>
      'संख्या को 1st, 2nd, 3rd की तरह लिखें';

  @override
  String get guildCommandFullGuide => 'पूरी स्क्रिप्ट गाइड';

  @override
  String get guildCommandCounters => 'काउंटर';

  @override
  String get guildCommandCounterAdd => 'काउंटर जोड़ें';

  @override
  String get guildCommandCounterSeparately => 'हर एक के लिए अलग गिनें:';

  @override
  String get guildCommandCounterPersonMentioned => 'उल्लेखित व्यक्ति';

  @override
  String get guildCommandCounterChannel => 'चैनल';

  @override
  String get guildCommandCounterPersonas => 'पर्सोना अलग गिनें';

  @override
  String get guildCommandCounterRemove => 'काउंटर हटाएं';

  @override
  String get guildCommandCounterReset => 'गिनती रीसेट करें';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return '$name की गिनती रीसेट करें? इसे पूर्ववत नहीं किया जा सकता।';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'छोटे अंग्रेज़ी अक्षर, अंक और _ इस्तेमाल करें, अक्षर से शुरू करें, और ऐसा नाम न लें जो स्क्रिप्ट पहले से इस्तेमाल करती हैं।';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'इसे स्क्रिप्ट में $variable के रूप में इस्तेमाल करें। हर रन पहले एक जोड़ता है, इसलिए पहला रन 1 पढ़ता है।';
  }
}
