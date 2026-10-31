// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class ForkLocalizationsHe extends ForkLocalizations {
  ForkLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get chatMessageChangePersona => 'החלפת פרסונה';

  @override
  String get chatAttachmentPanelVoice => 'קולי';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'כפתור מחליף מהיר';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'החלפת כפתור ההודעה הקולית בשדה הקלט בכפתור מחליף מהיר לניווט קל';

  @override
  String get userSettingsCheckForUpdates => 'בדוק עדכונים';

  @override
  String get userSettingsCheckingForUpdates => 'בודק עדכונים…';

  @override
  String get userSettingsAppUpToDate => 'Tyne מעודכנת';

  @override
  String get userSettingsUpdateAvailableTitle => 'עדכון זמין';

  @override
  String get userSettingsUpdateDownloadAction => 'הורד והתקן';

  @override
  String get userSettingsUpdateInstallAction => 'התקן עדכון';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'מוריד עדכון ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed => 'בדיקת העדכון או הורדתו נכשלה.';

  @override
  String get personaSelectTitle => 'בחר פרסונה';

  @override
  String get personaSettingsHeader => 'הגדרות פרסונה';

  @override
  String get personaManageAction => 'ניהול';

  @override
  String get personaSearchPlaceholder => 'חפש פרסונות, תגיות, כינויי גוף...';

  @override
  String get personaModeManual => 'ידני';

  @override
  String get personaModeLast => 'שימוש אחרון';

  @override
  String get personaModeManualDescription =>
      'שולח תמיד בתור הפרסונה שנבחרה עד לשינוי.';

  @override
  String get personaModeLastDescription =>
      'עובר אוטומטית לפרסונה ששימשה בהודעה האחרונה שלך.';

  @override
  String get personaRecentHeader => 'פרסונות אחרונות';

  @override
  String personaAllHeader(int count) {
    return 'כל הפרסונות ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'תוצאות חיפוש ($count)';
  }

  @override
  String get personaRootAccountLabel => 'חשבון ראשי (ברירת מחדל)';

  @override
  String get personaEmptyState =>
      'עדיין לא הוגדרו פרסונות. צור אחת דרך נהל פרסונות.';

  @override
  String get personaEmptySearch => 'לא נמצאו פרסונות תואמות.';

  @override
  String get personaEditTitle => 'ערוך פרסונה';

  @override
  String get personaCreateTitle => 'צור פרסונה';

  @override
  String get personaDisplayNameLabel => 'שם לתצוגה';

  @override
  String get personaPronounsLabel => 'כינויי גוף';

  @override
  String get personaPronounsHint => 'לדוגמה: הוא/היא';

  @override
  String get personaBioHint => 'ספר לאחרים על פרסונה זו...';

  @override
  String get personaUpdatedToast => 'הפרסונה עודכנה';

  @override
  String personaUpdateFailedToast(String error) {
    return 'עדכון הפרסונה נכשל: $error';
  }

  @override
  String get personaSectionTitle => 'פרסונות';

  @override
  String get personaDisplayNameHint => 'שם הפרסונה';

  @override
  String personaSendingAsTag(String name) {
    return 'שולח בתור $name (הותאם לפי תגית)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'שולח בתור $name (נעול)';
  }

  @override
  String personaSendingAs(String name) {
    return 'שולח בתור $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'מפרסם בתור $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'שולח בתור @$username';
  }

  @override
  String get personaMainAccount => 'חשבון ראשי';

  @override
  String get personaEditPersona => 'ערוך פרסונה';

  @override
  String get userSettingsNavPersonas => 'פרסונות';

  @override
  String get personaSettingsDescription =>
      'הגדר את מצב הפרסונה הפעילה, תגית תצוגה מותאמת אישית ונהל פרסונות בודדות.';

  @override
  String get personaDisplayTagSection => 'תגית תצוגה';

  @override
  String get personaDisplayTagDescription =>
      'תגית התצוגה תופיע לצד כל שמות הפרסונות בהודעות. אם לא הוגדרה תגית תצוגה, תוצג תמונת הפרופיל של החשבון שלך.';

  @override
  String get personaDisplayTagLabel => 'טקסט תגית תצוגה';

  @override
  String get personaDisplayTagHint => 'לדוגמה: SYS';

  @override
  String get personaDisplayTagIconLabel => 'אייקון תגית תצוגה';

  @override
  String get personaUploadTagIcon => 'העלאת אייקון';

  @override
  String get personaChangeTagIcon => 'שינוי אייקון';

  @override
  String get personaRemoveTagIcon => 'הסר אייקון';

  @override
  String get personaChatPreviewTitle => 'תצוגה מקדימה של הצ\'אט';

  @override
  String get personaChatPreviewSampleMessage =>
      'שלום! זוהי תצוגה מקדימה של איך הודעות ייראו עם תגית התצוגה והפרסונה הפעילה שלך.';

  @override
  String get personaListTitle => 'פרסונות מוגדרות';

  @override
  String get personaAddButton => 'הוסף פרסונה';

  @override
  String get personaActiveBadge => 'פעיל';

  @override
  String get personaMakeActive => 'הגדר כפעיל';

  @override
  String get personaDeleteTitle => 'מחק פרסונה';

  @override
  String personaDeleteMessage(String name) {
    return 'האם אתה בטוח שברצונך למחוק את \"$name\"? לא ניתן לבטל פעולה זו.';
  }

  @override
  String get personaDeleteConfirm => 'מחק';

  @override
  String get personaDeletedToast => 'הפרסונה נמחקה';

  @override
  String get personaCreatedToast => 'הפרסונה נוצרה';

  @override
  String personaCreateFailedToast(String error) {
    return 'יצירת הפרסונה נכשלה: $error';
  }

  @override
  String get personaChangeAvatar => 'שנה תמונת פרופיל';

  @override
  String get personaRemoveAvatar => 'הסר תמונת פרופיל';

  @override
  String get personaUploadAvatar => 'העלה תמונת פרופיל';

  @override
  String get personaTagsLabel => 'תגיות פרסונה';

  @override
  String get personaTagPrefixLabel => 'קידומת';

  @override
  String get personaTagSuffixLabel => 'סיומת';

  @override
  String get personaVisibilityLabel => 'נראות';

  @override
  String get personaVisibilityUnlisted => 'לא רשום';

  @override
  String get personaVisibilityPublic => 'ציבורי';

  @override
  String get personaVisibilityPrivate => 'פרטי';

  @override
  String get personaNameRequired => 'נא להזין שם תצוגה לפרסונה';

  @override
  String get personaNameTooLong =>
      'שם התצוגה של הפרסונה חייב להכיל עד 100 תווים';

  @override
  String get personaTagPrefixTooLong =>
      'קידומת התגית של הפרסונה חייבת להכיל עד 32 תווים';

  @override
  String get personaTagSuffixTooLong =>
      'סיומת התגית של הפרסונה חייבת להכיל עד 32 תווים';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'התגית \'$tag\' כבר בשימוש על ידי \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'הוספת חותמת זמן';

  @override
  String get chatAttachmentSendVoiceMessage => 'שלח הודעה קולית';

  @override
  String get timestampPickerTitle => 'הוספת חותמת זמן';

  @override
  String get timestampPickerInsert => 'הוספה';

  @override
  String get timestampCopied => 'חותמת הזמן הועתקה';

  @override
  String get timestampPickerTimeLabel => 'שעה';

  @override
  String get timestampPickerDateLabel => 'תאריך';

  @override
  String get timestampPickerTimeSectionLabel => 'שעה';

  @override
  String get timestampPickerTimezoneLabel => 'אזור זמן';

  @override
  String get timestampPickerFormatPreviewLabel => 'תצוגה מקדימה של הפורמט';

  @override
  String get timestampPickerNlpPlaceholder =>
      'לדוגמה: מחר ב-15:00, בעוד שעתיים, עכשיו';

  @override
  String get timestampPickerSearchTimezones => 'חיפוש אזורי זמן...';

  @override
  String get userProfileTimezoneSettingLabel => 'אזור זמן';

  @override
  String get userProfileTimezoneSettingDescription =>
      'משמש להצגת השעה המקומית שלך בפרופיל.';

  @override
  String get userProfileTimezoneNone => 'ללא';

  @override
  String get chatReactAs => 'הגב בתור...';

  @override
  String get emojiCopy => 'העתקת אימוג\'י';

  @override
  String get emojiCopyLink => 'העתקת קישור';

  @override
  String get emojiPin => 'הצמד אימוג\'י';

  @override
  String get emojiUnpin => 'בטל הצמדת אימוג\'י';

  @override
  String get emojiPinForPersona => 'הצמד לפרסונה זו';

  @override
  String get emojiUnpinForPersona => 'בטל הצמדה לפרסונה זו';

  @override
  String get personaSignatureEmojisLabel => 'אימוג\'י חתימה';

  @override
  String get personaSignatureEmojisDescription =>
      'תגובה עם אימוג\'י חתימה תגיב תמיד בתור פרסונה זו, ללא קשר לפרסונה הפעילה.';

  @override
  String get personaAddSignatureEmoji => 'הוסף אימוג\'י';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'אימוג\'י זה כבר נוסף כאימוג\'י חתימה';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'אימוג\'י החתימה כבר נמצא בשימוש על ידי הפרסונה \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'הסר אימוג\'י חתימה';

  @override
  String get signalBarLabel => 'סרגל אותות';

  @override
  String get signalBarShow => 'הצגת סרגל האותות';

  @override
  String get signalBarHide => 'הסתרת סרגל האותות';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'אף אחד לא הפעיל את האות הזה';

  @override
  String get signalBarReset => 'איפוס האות לכולם';

  @override
  String signalBarTurnOff(String name) {
    return 'כיבוי $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'השתמשו ב-$domain עבור המופע שמוגדר כברירת מחדל, או בכתובת ה-URL המדויקת של מופע אחר.';
  }

  @override
  String get instanceResetToDefault => 'איפוס למופע ברירת המחדל';

  @override
  String get personaScopeTitle => 'הפרסונה חלה על';

  @override
  String get personaScopeGlobal => 'בכל מקום';

  @override
  String get personaScopeGlobalDescription => 'פרסונה אחת לכל הערוצים.';

  @override
  String get personaScopeChannel => 'בכל ערוץ';

  @override
  String get personaScopeChannelDescription =>
      'כל ערוץ שומר על הפרסונה שלו. ערוצים חדשים מתחילים כחשבון שלכם.';

  @override
  String get personaPickerChannelOnly => 'רק לערוץ הזה';

  @override
  String get personaProfilePrivate => 'הפרופיל של הפרסונה הזו פרטי.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'קובץ התמונה גדול מדי. בחר קובץ שגודלו קטן מ-$maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'חפש ב-KLIPY';

  @override
  String get appUpdateDownloadFailed => 'הורדת העדכון נכשלה';

  @override
  String get appUpdateInstallFailed => 'התקנת העדכון נכשלה';

  @override
  String get personaChangeMessageFailed => 'שינוי הפרסונה של ההודעה נכשל';

  @override
  String get personaActiveCleared => 'הפרסונה הפעילה נוקתה';

  @override
  String get klipyPoweredBy => 'מופעל על ידי KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'זוג התגיות \'$pattern\' כפול בפרסונה זו';
  }

  @override
  String personaAddTagPair(int count) {
    return 'הוספת זוג תגיות ($count/5)';
  }

  @override
  String get personaTagExampleText => 'טקסט';

  @override
  String get personaPreviewNameFallback => 'משתמש';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne נסגרה באופן בלתי צפוי. שיתוף נתוני קריסות ושגיאות אנונימיים עוזר לנו לתקן בעיות מהר יותר.';

  @override
  String get crashReportingSectionDescription =>
      'עזור לתקן באגים ב-Tyne באמצעות שיתוף נתוני קריסות וביצועים. האפשרות כבויה כברירת מחדל.';

  @override
  String get crashReportingDescription =>
      'הדיווחים נשלחים למערכת מעקב השגיאות של Tyne עצמה, גם כשאתה מחובר למופע אחר. הם לא כוללים שמות מופעים, מזהים או תוכן הודעות.';

  @override
  String get instanceOfflineTitle => 'Tyne לא זמינה!';

  @override
  String get instanceOfflineBody => 'אנחנו בודקים את זה.';

  @override
  String get instanceStatusSignalLink => 'הצטרפו לצ׳אט שלנו ב-Signal לעדכונים';

  @override
  String get convertEmoticonsLabel => 'המר סמיילים טקסטואליים לאימוג\'י';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'לא ניתן היה להריץ את /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'יש בעיה בסקריפט שלה.';

  @override
  String guildCommandOneLine(String name) {
    return 'מה שמקלידים אחרי /$name חייב להיכנס בשורה אחת.';
  }

  @override
  String get permissionCreateCommands => 'יצירת פקודות';

  @override
  String get permissionManageCommands => 'ניהול פקודות';

  @override
  String get permissionUseExternalCommands => 'שימוש בפקודות חיצוניות';

  @override
  String get permissionCreateCommandsDescription =>
      'יצירת פקודות לקהילה הזו, ועריכה או מחיקה של הפקודות שלך.';

  @override
  String get permissionManageCommandsDescription =>
      'עריכה או מחיקה של הפקודות של כל אחד בקהילה הזו.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'שימוש בפקודות מקהילות אחרות.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'שימוש בפקודות מקהילות אחרות בערוץ הזה.';

  @override
  String get guildSettingsCategoryMessageTools => 'כלי הודעות';

  @override
  String get guildSettingsCommands => 'פקודות';

  @override
  String get guildCommandsLoadFailed => 'לא ניתן היה לטעון את הפקודות.';

  @override
  String get guildCommandsSubtitle =>
      'הודעות שחברים יכולים לפרסם על ידי הקלדת /name.';

  @override
  String get guildCommandsSlots => 'מקומות לפקודות';

  @override
  String get guildCommandsNew => 'פקודה חדשה';

  @override
  String get guildCommandsSearch => 'חיפוש פקודות';

  @override
  String get guildCommandsEmptyTitle => 'אין פקודות';

  @override
  String get guildCommandsEmptyBody => 'לקהילה הזו אין עדיין פקודות.';

  @override
  String get guildCommandsSaved => 'הפקודות נשמרו';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'לא ניתן היה לשמור את /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'עריכת /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'למחוק את /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'אי אפשר לבטל את הפעולה. הודעות שנוצרו איתה עדיין מראות איזו פקודה יצרה אותן.';

  @override
  String get guildCommandDelete => 'מחק';

  @override
  String get guildCommandDeleteCommand => 'מחיקת הפקודה';

  @override
  String get guildCommandSectionCommand => 'פקודה';

  @override
  String get guildCommandName => 'שם';

  @override
  String get guildCommandNameInvalid =>
      'השתמשו באותיות קטנות, ספרות, - ו-_, עד 32 תווים.';

  @override
  String get guildCommandNameTaken =>
      'לפקודה אחרת או לפקודה מובנית כבר יש את השם הזה.';

  @override
  String get guildCommandDescription => 'תיאור';

  @override
  String get guildCommandSectionInput => 'קלט';

  @override
  String get guildCommandInputNone => 'ללא';

  @override
  String get guildCommandInputOptional => 'אופציונלי';

  @override
  String get guildCommandInputRequired => 'נדרש';

  @override
  String get guildCommandHint => 'רמז';

  @override
  String get guildCommandMessage => 'הודעה';

  @override
  String get guildCommandInsert => 'הוספה:';

  @override
  String get guildCommandInsertPerson => 'מי שמשתמש בה';

  @override
  String get guildCommandInsertInput => 'מה שהם מקלידים';

  @override
  String get guildCommandPreview => 'תצוגה מקדימה';

  @override
  String get guildCommandSampleInput => 'קלט לדוגמה';

  @override
  String guildCommandMadeWith(String name) {
    return 'נוצרה עם /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'רוקנו את תיבת ההודעה כדי להשתמש ב-/$name';
  }

  @override
  String get guildCommandEmptyMessage => 'זה לא יפרסם כלום, ולכן הפקודה תיכשל.';

  @override
  String get guildCommandUseScriptEditor => 'שימוש בעורך הסקריפטים';

  @override
  String get guildCommandUseBasicEditor => 'שימוש בעורך הבסיסי';

  @override
  String get guildCommandScript => 'סקריפט';

  @override
  String get guildCommandRunAgain => 'הרצה חוזרת';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'אין תגית בשם $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'אין מסנן בשם $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return 'הקטע $name אף פעם לא נסגר.';
  }

  @override
  String get guildCommandIssueTooLong => 'הסקריפט ארוך מדי.';

  @override
  String get guildCommandIssueTooLarge => 'הסקריפט יוצר יותר מדי טקסט.';

  @override
  String get guildCommandIssueTooSlow => 'הרצת הסקריפט ארכה יותר מדי זמן.';

  @override
  String get guildCommandIssueInvalid => 'אי אפשר לקרוא את החלק הזה.';

  @override
  String get guildCommandIssueFailed => 'החלק הזה נעצר עם שגיאה.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'שורה $line, עמודה $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'מדריך סקריפטים';

  @override
  String get guildCommandReferencePerson => 'מי שמשתמש בה, כאזכור';

  @override
  String get guildCommandReferencePersonName => 'השם של מי שמשתמש בה';

  @override
  String get guildCommandReferenceTarget => 'האדם הראשון שמוזכר, אם יש';

  @override
  String get guildCommandReferenceTargetName => 'השם של אותו אדם';

  @override
  String get guildCommandReferenceChannel => 'הערוץ, כאזכור';

  @override
  String get guildCommandReferenceCommunity => 'השם של הקהילה הזו';

  @override
  String get guildCommandExampleRandom => 'בחירת אפשרות אחת באקראי';

  @override
  String get guildCommandExampleDepends => 'שינוי ההודעה לפי מה שהקלידו';

  @override
  String get guildCommandExampleOneWord => 'בחירת מילה אחת באקראי';

  @override
  String get guildCommandExampleWordForNumber => 'בחירת המילה לפי מספר';

  @override
  String get guildCommandExampleOrdinal => 'כתיבת מספר כמו 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'המדריך המלא לסקריפטים';

  @override
  String get guildCommandCounters => 'מונים';

  @override
  String get guildCommandCounterAdd => 'הוספת מונה';

  @override
  String get guildCommandCounterSeparately => 'ספירה נפרדת לכל:';

  @override
  String get guildCommandCounterPersonMentioned => 'האדם שאוזכר';

  @override
  String get guildCommandCounterChannel => 'ערוץ';

  @override
  String get guildCommandCounterPersonas => 'ספירה נפרדת של פרסונות';

  @override
  String get guildCommandCounterRemove => 'הסרת מונה';

  @override
  String get guildCommandCounterReset => 'איפוס ספירות';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'לאפס את הספירות של $name? אי אפשר לבטל פעולה זו.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'יש להשתמש באותיות לטיניות קטנות, ספרות ו־_, להתחיל באות ולבחור שם שסקריפטים לא משתמשים בו.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'אפשר להשתמש בו בסקריפט בתור $variable. כל הרצה מוסיפה אחד קודם, כך שההרצה הראשונה קוראת 1.';
  }
}
