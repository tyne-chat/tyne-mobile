// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class ForkLocalizationsAr extends ForkLocalizations {
  ForkLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get chatMessageChangePersona => 'تغيير الشخصية';

  @override
  String get chatAttachmentPanelVoice => 'صوتي';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'زر التبديل السريع';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'استبدال زر الرسالة الصوتية في حقل الإدخال بزر التبديل السريع للتنقل السهل';

  @override
  String get userSettingsCheckForUpdates => 'التحقق من وجود تحديثات';

  @override
  String get userSettingsCheckingForUpdates => 'جارٍ التحقق من وجود تحديثات…';

  @override
  String get userSettingsAppUpToDate => 'Tyne محدّث لأحدث إصدار';

  @override
  String get userSettingsUpdateAvailableTitle => 'تحديث متوفر';

  @override
  String get userSettingsUpdateDownloadAction => 'تنزيل وتثبيت';

  @override
  String get userSettingsUpdateInstallAction => 'تثبيت التحديث';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'جارٍ تنزيل التحديث ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed => 'فشل التحقق من التحديث أو تنزيله.';

  @override
  String get personaSelectTitle => 'اختيار الشخصية';

  @override
  String get personaSettingsHeader => 'إعدادات الشخصية';

  @override
  String get personaManageAction => 'إدارة';

  @override
  String get personaSearchPlaceholder => 'ابحث عن شخصيات، علامات، ضمائر...';

  @override
  String get personaModeManual => 'يدوي';

  @override
  String get personaModeLast => 'آخر استخدام';

  @override
  String get personaModeManualDescription =>
      'يرسل دائمًا بالشخصية المحددة حتى يتم تغييرها.';

  @override
  String get personaModeLastDescription =>
      'التبديل تلقائيًا إلى الشخصية المستخدمة في رسالتك الأخيرة.';

  @override
  String get personaRecentHeader => 'الشخصيات الأخيرة';

  @override
  String personaAllHeader(int count) {
    return 'كل الشخصيات ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'نتائج البحث ($count)';
  }

  @override
  String get personaRootAccountLabel => 'الحساب الأساسي (افتراضي)';

  @override
  String get personaEmptyState =>
      'لم يتم تكوين شخصيات بعد. أنشئ واحدة عبر إدارة الشخصيات.';

  @override
  String get personaEmptySearch => 'لم يتم العثور على شخصيات مطابقة.';

  @override
  String get personaEditTitle => 'تعديل الشخصية';

  @override
  String get personaCreateTitle => 'إنشاء شخصية';

  @override
  String get personaDisplayNameLabel => 'اسم العرض';

  @override
  String get personaPronounsLabel => 'الضمائر';

  @override
  String get personaPronounsHint => 'مثال: هو/هي';

  @override
  String get personaBioHint => 'أخبر الآخرين عن هذه الشخصية...';

  @override
  String get personaUpdatedToast => 'تم تحديث الشخصية';

  @override
  String personaUpdateFailedToast(String error) {
    return 'فشل تحديث الشخصية: $error';
  }

  @override
  String get personaSectionTitle => 'الشخصيات';

  @override
  String get personaDisplayNameHint => 'اسم الشخصية';

  @override
  String personaSendingAsTag(String name) {
    return 'إرسال باسم $name (تمت المطابقة بواسطة العلامة)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'إرسال باسم $name (مثبّت)';
  }

  @override
  String personaSendingAs(String name) {
    return 'إرسال باسم $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'النشر باسم $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'إرسال باسم @$username';
  }

  @override
  String get personaMainAccount => 'الحساب الرئيسي';

  @override
  String get personaEditPersona => 'تعديل الشخصية';

  @override
  String get userSettingsNavPersonas => 'الشخصيات';

  @override
  String get personaSettingsDescription =>
      'تكوين وضع الشخصية النشطة، وعلامة العرض المخصصة، وإدارة الشخصيات الفردية.';

  @override
  String get personaDisplayTagSection => 'علامة العرض';

  @override
  String get personaDisplayTagDescription =>
      'ستظهر علامة العرض بجوار جميع أسماء الشخصيات في الرسائل. إذا لم يتم تعيين علامة عرض، فستظهر صورة ملف تعريف حسابك.';

  @override
  String get personaDisplayTagLabel => 'نص علامة العرض';

  @override
  String get personaDisplayTagHint => 'مثل: SYS';

  @override
  String get personaDisplayTagIconLabel => 'أيقونة علامة العرض';

  @override
  String get personaUploadTagIcon => 'تحميل أيقونة';

  @override
  String get personaChangeTagIcon => 'تغيير الأيقونة';

  @override
  String get personaRemoveTagIcon => 'إزالة الأيقونة';

  @override
  String get personaChatPreviewTitle => 'معاينة الدردشة';

  @override
  String get personaChatPreviewSampleMessage =>
      'مرحبًا! هذه معاينة لكيفية ظهور الرسائل مع علامة العرض والشخصية النشطة.';

  @override
  String get personaListTitle => 'الشخصيات المكونة';

  @override
  String get personaAddButton => 'إضافة شخصية';

  @override
  String get personaActiveBadge => 'نشط';

  @override
  String get personaMakeActive => 'تعيين كنشط';

  @override
  String get personaDeleteTitle => 'حذف الشخصية';

  @override
  String personaDeleteMessage(String name) {
    return 'هل أنت متأكد أنك تريد حذف \"$name\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get personaDeleteConfirm => 'حذف';

  @override
  String get personaDeletedToast => 'تم حذف الشخصية';

  @override
  String get personaCreatedToast => 'تم إنشاء الشخصية';

  @override
  String personaCreateFailedToast(String error) {
    return 'فشل إنشاء الشخصية: $error';
  }

  @override
  String get personaChangeAvatar => 'تغيير الصورة الرمزية';

  @override
  String get personaRemoveAvatar => 'إزالة الصورة الرمزية';

  @override
  String get personaUploadAvatar => 'تحميل الصورة الرمزية';

  @override
  String get personaTagsLabel => 'علامات الشخصية';

  @override
  String get personaTagPrefixLabel => 'البادئة';

  @override
  String get personaTagSuffixLabel => 'اللاحقة';

  @override
  String get personaVisibilityLabel => 'الرؤية';

  @override
  String get personaVisibilityUnlisted => 'غير مدرج';

  @override
  String get personaVisibilityPublic => 'عام';

  @override
  String get personaVisibilityPrivate => 'خاص';

  @override
  String get personaNameRequired => 'يرجى إدخال اسم عرض الشخصية';

  @override
  String get personaNameTooLong => 'يجب أن يكون اسم عرض الشخصية 100 حرف أو أقل';

  @override
  String get personaTagPrefixTooLong =>
      'يجب أن تكون بادئة علامة الشخصية 32 حرفًا أو أقل';

  @override
  String get personaTagSuffixTooLong =>
      'يجب أن تكون لاحقة علامة الشخصية 32 حرفًا أو أقل';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'العلامة \'$tag\' مستخدمة بالفعل بواسطة \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'إدراج طابع زمني';

  @override
  String get chatAttachmentSendVoiceMessage => 'إرسال رسالة صوتية';

  @override
  String get timestampPickerTitle => 'إدراج طابع زمني';

  @override
  String get timestampPickerInsert => 'إدراج';

  @override
  String get timestampCopied => 'تم نسخ الطابع الزمني';

  @override
  String get timestampPickerTimeLabel => 'الوقت';

  @override
  String get timestampPickerDateLabel => 'التاريخ';

  @override
  String get timestampPickerTimeSectionLabel => 'الوقت';

  @override
  String get timestampPickerTimezoneLabel => 'المنطقة الزمنية';

  @override
  String get timestampPickerFormatPreviewLabel => 'معاينة التنسيق';

  @override
  String get timestampPickerNlpPlaceholder =>
      'مثال: غدًا في 3 مساءً، خلال ساعتين، الآن';

  @override
  String get timestampPickerSearchTimezones => 'البحث في المناطق الزمنية...';

  @override
  String get userProfileTimezoneSettingLabel => 'المنطقة الزمنية';

  @override
  String get userProfileTimezoneSettingDescription =>
      'تُستخدم لعرض وقتك المحلي في ملفك الشخصي.';

  @override
  String get userProfileTimezoneNone => 'بلا';

  @override
  String get chatReactAs => 'تفاعل باسم...';

  @override
  String get emojiCopy => 'نسخ الرمز التعبيري';

  @override
  String get emojiCopyLink => 'نسخ الرابط';

  @override
  String get emojiPin => 'تثبيت الرمز التعبيري';

  @override
  String get emojiUnpin => 'إلغاء تثبيت الرمز التعبيري';

  @override
  String get emojiPinForPersona => 'تثبيت لهذه الشخصية';

  @override
  String get emojiUnpinForPersona => 'إلغاء التثبيت لهذه الشخصية';

  @override
  String get personaSignatureEmojisLabel => 'الرموز التعبيرية المميزة';

  @override
  String get personaSignatureEmojisDescription =>
      'التفاعل برمز تعبيري مميز سيتفاعل دائمًا بهذه الشخصية، بغض النظر عن الشخصية النشطة.';

  @override
  String get personaAddSignatureEmoji => 'إضافة إيموجي';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'تمت إضافة هذا الرمز التعبيري بالفعل كرمز مميز';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'الرمز التعبيري المميز مستخدم بالفعل من قبل الشخصية \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'إزالة الرمز التعبيري المميز';

  @override
  String get signalBarLabel => 'شريط الإشارات';

  @override
  String get signalBarShow => 'إظهار شريط الإشارات';

  @override
  String get signalBarHide => 'إخفاء شريط الإشارات';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'لم يُفعّل أحد هذه الإشارة';

  @override
  String get signalBarReset => 'إعادة تعيين الإشارة للجميع';

  @override
  String signalBarTurnOff(String name) {
    return 'إيقاف $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'استخدم $domain للمثيل الافتراضي، أو عنوان URL الدقيق لمثيل آخر.';
  }

  @override
  String get instanceResetToDefault => 'إعادة الضبط إلى المثيل الافتراضي';

  @override
  String get personaScopeTitle => 'الشخصية تنطبق على';

  @override
  String get personaScopeGlobal => 'في كل مكان';

  @override
  String get personaScopeGlobalDescription => 'شخصية واحدة لكل القنوات.';

  @override
  String get personaScopeChannel => 'في كل قناة';

  @override
  String get personaScopeChannelDescription =>
      'كل قناة تحتفظ بشخصيتها الخاصة. القنوات الجديدة تبدأ بحسابك.';

  @override
  String get personaPickerChannelOnly => 'لهذه القناة فقط';

  @override
  String get personaProfilePrivate => 'الملف الشخصي لهذه الشخصية خاص.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'ملف الصورة كبير جدًا. يرجى اختيار ملف أصغر من $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'ابحث في KLIPY';

  @override
  String get appUpdateDownloadFailed => 'تعذّر تنزيل التحديث';

  @override
  String get appUpdateInstallFailed => 'تعذّر تثبيت التحديث';

  @override
  String get personaChangeMessageFailed => 'تعذّر تغيير شخصية الرسالة';

  @override
  String get personaActiveCleared => 'تمت إزالة الشخصية النشطة';

  @override
  String get klipyPoweredBy => 'بدعم من KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'زوج العلامات \'$pattern\' مكرر في هذه الشخصية';
  }

  @override
  String personaAddTagPair(int count) {
    return 'إضافة زوج علامات ($count/5)';
  }

  @override
  String get personaTagExampleText => 'نص';

  @override
  String get personaPreviewNameFallback => 'مستخدم';

  @override
  String get crashReportingConsentSubtitle =>
      'أُغلق Tyne بشكل غير متوقع. تساعدنا مشاركة بيانات الأعطال والأخطاء المجهولة على إصلاح المشكلات بشكل أسرع.';

  @override
  String get crashReportingSectionDescription =>
      'ساعد في إصلاح أخطاء Tyne بمشاركة بيانات الأعطال والأداء. هذا الخيار معطّل افتراضيًا.';

  @override
  String get crashReportingDescription =>
      'تُرسَل التقارير إلى متتبّع الأخطاء الخاص بـ Tyne، حتى عند تسجيل الدخول إلى خادم آخر. ولا تتضمن أسماء الخوادم أو المعرّفات أو محتوى الرسائل.';

  @override
  String get instanceOfflineTitle => 'Tyne غير متصل!';

  @override
  String get instanceOfflineBody => 'نحن نتحقق من الأمر.';

  @override
  String get instanceStatusSignalLink =>
      'انضم إلى دردشتنا على Signal لمتابعة آخر الأخبار';

  @override
  String get convertEmoticonsLabel => 'تحويل الوجوه النصية إلى رموز تعبيرية';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'تعذر تنفيذ /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'هناك مشكلة في نصه البرمجي.';

  @override
  String guildCommandOneLine(String name) {
    return 'يجب أن يتسع ما تكتبه بعد /$name في سطر واحد.';
  }

  @override
  String get permissionCreateCommands => 'إنشاء أوامر';

  @override
  String get permissionManageCommands => 'إدارة الأوامر';

  @override
  String get permissionUseExternalCommands => 'استخدام الأوامر الخارجية';

  @override
  String get permissionCreateCommandsDescription =>
      'إنشاء أوامر لهذا المجتمع وتعديل أوامرك أو حذفها.';

  @override
  String get permissionManageCommandsDescription =>
      'تعديل أوامر أي شخص في هذا المجتمع أو حذفها.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'استخدام أوامر من مجتمعات أخرى.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'استخدام أوامر من مجتمعات أخرى في هذه القناة.';

  @override
  String get guildSettingsCategoryMessageTools => 'أدوات الرسائل';

  @override
  String get guildSettingsCommands => 'الأوامر';

  @override
  String get guildCommandsLoadFailed => 'تعذر تحميل الأوامر.';

  @override
  String get guildCommandsSubtitle => 'رسائل يمكن للأعضاء نشرها بكتابة /name.';

  @override
  String get guildCommandsSlots => 'خانات الأوامر';

  @override
  String get guildCommandsNew => 'أمر جديد';

  @override
  String get guildCommandsSearch => 'البحث عن الأوامر';

  @override
  String get guildCommandsEmptyTitle => 'لا توجد أوامر';

  @override
  String get guildCommandsEmptyBody => 'لا توجد أوامر في هذا المجتمع بعد.';

  @override
  String get guildCommandsSaved => 'تم حفظ الأوامر';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'تعذر حفظ /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'تعديل /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'حذف /$name؟';
  }

  @override
  String get guildCommandDeleteBody =>
      'لا يمكن التراجع عن هذا. ستظل الرسائل التي صُنعت به تُظهر الأمر الذي صنعها.';

  @override
  String get guildCommandDelete => 'حذف';

  @override
  String get guildCommandDeleteCommand => 'حذف الأمر';

  @override
  String get guildCommandSectionCommand => 'الأمر';

  @override
  String get guildCommandName => 'الاسم';

  @override
  String get guildCommandNameInvalid =>
      'استخدم أحرفًا صغيرة وأرقامًا و- و_، بحد أقصى 32 حرفًا.';

  @override
  String get guildCommandNameTaken =>
      'هناك أمر آخر أو أمر مدمج يحمل هذا الاسم بالفعل.';

  @override
  String get guildCommandDescription => 'الوصف';

  @override
  String get guildCommandSectionInput => 'الإدخال';

  @override
  String get guildCommandInputNone => 'لا شيء';

  @override
  String get guildCommandInputOptional => 'اختياري';

  @override
  String get guildCommandInputRequired => 'مطلوب';

  @override
  String get guildCommandHint => 'تلميح';

  @override
  String get guildCommandMessage => 'رسالة';

  @override
  String get guildCommandInsert => 'إدراج:';

  @override
  String get guildCommandInsertPerson => 'من يستخدمه';

  @override
  String get guildCommandInsertInput => 'ما يكتبونه';

  @override
  String get guildCommandPreview => 'معاينة';

  @override
  String get guildCommandSampleInput => 'إدخال تجريبي';

  @override
  String guildCommandMadeWith(String name) {
    return 'صُنعت باستخدام /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'أفرغ مربع الرسالة لاستخدام /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'لن يؤدي هذا إلى نشر أي شيء، لذا سيفشل الأمر.';

  @override
  String get guildCommandUseScriptEditor => 'استخدام محرر النصوص البرمجية';

  @override
  String get guildCommandUseBasicEditor => 'استخدام المحرر الأساسي';

  @override
  String get guildCommandScript => 'النص البرمجي';

  @override
  String get guildCommandRunAgain => 'تنفيذ مرة أخرى';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'لا توجد علامة باسم $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'لا يوجد فلتر باسم $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return 'لم يُغلق $name أبدًا.';
  }

  @override
  String get guildCommandIssueTooLong => 'النص البرمجي طويل جدًا.';

  @override
  String get guildCommandIssueTooLarge =>
      'ينتج النص البرمجي نصًا أكثر من المسموح به.';

  @override
  String get guildCommandIssueTooSlow =>
      'استغرق تنفيذ النص البرمجي وقتًا طويلًا جدًا.';

  @override
  String get guildCommandIssueInvalid => 'تعذرت قراءة هذا الجزء.';

  @override
  String get guildCommandIssueFailed => 'توقف هذا الجزء بسبب خطأ.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'السطر $line، العمود $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'مرجع النص البرمجي';

  @override
  String get guildCommandReferencePerson => 'من يستخدمه، كإشارة';

  @override
  String get guildCommandReferencePersonName => 'اسم من يستخدمه';

  @override
  String get guildCommandReferenceTarget => 'أول شخص يشيرون إليه، إن وُجد';

  @override
  String get guildCommandReferenceTargetName => 'اسم ذلك الشخص';

  @override
  String get guildCommandReferenceChannel => 'القناة، كإشارة';

  @override
  String get guildCommandReferenceCommunity => 'اسم هذا المجتمع';

  @override
  String get guildCommandExampleRandom => 'اختيار خيار واحد عشوائيًا';

  @override
  String get guildCommandExampleDepends => 'تغيير الرسالة حسب ما كتبوه';

  @override
  String get guildCommandExampleOneWord => 'اختيار كلمة واحدة عشوائيًا';

  @override
  String get guildCommandExampleWordForNumber => 'اختيار الكلمة المناسبة للعدد';

  @override
  String get guildCommandExampleOrdinal => 'كتابة الرقم بالشكل 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'الدليل الكامل للنصوص البرمجية';
}
