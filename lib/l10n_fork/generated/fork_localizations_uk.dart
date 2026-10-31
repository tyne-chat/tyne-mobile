// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class ForkLocalizationsUk extends ForkLocalizations {
  ForkLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Змінити персону';

  @override
  String get chatAttachmentPanelVoice => 'Голос';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Кнопка швидкого перемикання';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Замінити кнопку голосового повідомлення в полі введення на кнопку швидкого перемикання';

  @override
  String get userSettingsCheckForUpdates => 'Перевірити наявність оновлень';

  @override
  String get userSettingsCheckingForUpdates => 'Перевірка оновлень…';

  @override
  String get userSettingsAppUpToDate => 'Tyne оновлено до найновішої версії';

  @override
  String get userSettingsUpdateAvailableTitle => 'Доступне оновлення';

  @override
  String get userSettingsUpdateDownloadAction => 'Завантажити та встановити';

  @override
  String get userSettingsUpdateInstallAction => 'Встановити оновлення';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Завантаження оновлення ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Не вдалося перевірити або завантажити оновлення.';

  @override
  String get personaSelectTitle => 'Виберіть персону';

  @override
  String get personaSettingsHeader => 'Налаштування персон';

  @override
  String get personaManageAction => 'Керувати';

  @override
  String get personaSearchPlaceholder => 'Пошук персон, тегів, займенників...';

  @override
  String get personaModeManual => 'Вручну';

  @override
  String get personaModeLast => 'Останнє використання';

  @override
  String get personaModeManualDescription =>
      'Завжди надсилати від імені вибраної персони до зміни.';

  @override
  String get personaModeLastDescription =>
      'Автоматично перемикається на персону, використану в останньому повідомленні.';

  @override
  String get personaRecentHeader => 'НЕДАВНІ ПЕРСОНИ';

  @override
  String personaAllHeader(int count) {
    return 'УСІ ПЕРСОНИ ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'РЕЗУЛЬТАТИ ПОШУКУ ($count)';
  }

  @override
  String get personaRootAccountLabel =>
      'Основний обліковий запис (за замовчуванням)';

  @override
  String get personaEmptyState =>
      'Ще немає налаштованих персон. Створіть їх у меню «Керування персонами».';

  @override
  String get personaEmptySearch => 'Не знайдено відповідних персон.';

  @override
  String get personaEditTitle => 'Редагувати персону';

  @override
  String get personaCreateTitle => 'Створити персону';

  @override
  String get personaDisplayNameLabel => 'Ім\'я для відображення';

  @override
  String get personaPronounsLabel => 'Займенники';

  @override
  String get personaPronounsHint => 'напр. вони/їх';

  @override
  String get personaBioHint => 'Розкажіть іншим про цю персону...';

  @override
  String get personaUpdatedToast => 'Персону оновлено';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Не вдалося оновити персону: $error';
  }

  @override
  String get personaSectionTitle => 'Персони';

  @override
  String get personaDisplayNameHint => 'Ім\'я персони';

  @override
  String personaSendingAsTag(String name) {
    return 'Надсилання як $name (за тегом)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Надсилання як $name (закріплено)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Надсилання як $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Публікація як $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Надсилання як @$username';
  }

  @override
  String get personaMainAccount => 'Основний обліковий запис';

  @override
  String get personaEditPersona => 'Редагувати персону';

  @override
  String get userSettingsNavPersonas => 'Персони';

  @override
  String get personaSettingsDescription =>
      'Налаштуйте режим активної персони, значок відображення та керуйте окремими персонами.';

  @override
  String get personaDisplayTagSection => 'Значок відображення';

  @override
  String get personaDisplayTagDescription =>
      'Значок відображення з\'явиться поруч з іменами всіх персон у повідомленнях. Якщо значок не встановлено, відображатиметься зображення профілю вашого облікового запису.';

  @override
  String get personaDisplayTagLabel => 'Текст значка відображення';

  @override
  String get personaDisplayTagHint => 'напр. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Піктограма значка відображення';

  @override
  String get personaUploadTagIcon => 'Завантажити іконку';

  @override
  String get personaChangeTagIcon => 'Змінити іконку';

  @override
  String get personaRemoveTagIcon => 'Видалити іконку';

  @override
  String get personaChatPreviewTitle => 'Попередній перегляд чату';

  @override
  String get personaChatPreviewSampleMessage =>
      'Привіт! Це попередній перегляд того, як виглядають повідомлення з вашим значком відображення та активною персоною.';

  @override
  String get personaListTitle => 'Налаштовані персони';

  @override
  String get personaAddButton => 'Додати персону';

  @override
  String get personaActiveBadge => 'Активна';

  @override
  String get personaMakeActive => 'Зробити активною';

  @override
  String get personaDeleteTitle => 'Видалити персону';

  @override
  String personaDeleteMessage(String name) {
    return 'Ви впевнені, що хочете видалити «$name»? Цю дію не можна скасувати.';
  }

  @override
  String get personaDeleteConfirm => 'Видалити';

  @override
  String get personaDeletedToast => 'Персону видалено';

  @override
  String get personaCreatedToast => 'Персону створено';

  @override
  String personaCreateFailedToast(String error) {
    return 'Не вдалося створити персону: $error';
  }

  @override
  String get personaChangeAvatar => 'Змінити аватар';

  @override
  String get personaRemoveAvatar => 'Видалити аватар';

  @override
  String get personaUploadAvatar => 'Завантажити аватар';

  @override
  String get personaTagsLabel => 'Теги персони';

  @override
  String get personaTagPrefixLabel => 'Префікс';

  @override
  String get personaTagSuffixLabel => 'Суфікс';

  @override
  String get personaVisibilityLabel => 'Видимість';

  @override
  String get personaVisibilityUnlisted => 'Прихована';

  @override
  String get personaVisibilityPublic => 'Публічна';

  @override
  String get personaVisibilityPrivate => 'Приватна';

  @override
  String get personaNameRequired =>
      'Будь ласка, введіть відображуване ім\'я персони';

  @override
  String get personaNameTooLong =>
      'Відображуване ім\'я персони має містити не більше 100 символів';

  @override
  String get personaTagPrefixTooLong =>
      'Префікс тегу персони має містити не більше 32 символів';

  @override
  String get personaTagSuffixTooLong =>
      'Суфікс тегу персони має містити не більше 32 символів';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Тег \'$tag\' уже використовується персоною \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Вставити мітку часу';

  @override
  String get chatAttachmentSendVoiceMessage =>
      'Надіслати голосове повідомлення';

  @override
  String get timestampPickerTitle => 'Вставити мітку часу';

  @override
  String get timestampPickerInsert => 'Вставити';

  @override
  String get timestampCopied => 'Мітку часу скопійовано';

  @override
  String get timestampPickerTimeLabel => 'Час';

  @override
  String get timestampPickerDateLabel => 'ДАТА';

  @override
  String get timestampPickerTimeSectionLabel => 'ЧАС';

  @override
  String get timestampPickerTimezoneLabel => 'ЧАСОВИЙ ПОЯС';

  @override
  String get timestampPickerFormatPreviewLabel => 'ПОПЕРЕДНІЙ ПЕРЕГЛЯД ФОРМАТУ';

  @override
  String get timestampPickerNlpPlaceholder =>
      'напр., завтра о 15:00, через 2 години, зараз';

  @override
  String get timestampPickerSearchTimezones => 'Шукати часові пояси...';

  @override
  String get userProfileTimezoneSettingLabel => 'Часовий пояс';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Використовується для відображення вашого місцевого часу у профілі.';

  @override
  String get userProfileTimezoneNone => 'Немає';

  @override
  String get chatReactAs => 'Відреагувати як...';

  @override
  String get emojiCopy => 'Копіювати емодзі';

  @override
  String get emojiCopyLink => 'Копіювати посилання';

  @override
  String get emojiPin => 'Закріпити емодзі';

  @override
  String get emojiUnpin => 'Відкріпити емодзі';

  @override
  String get emojiPinForPersona => 'Закріпити для цієї персони';

  @override
  String get emojiUnpinForPersona => 'Відкріпити для цієї персони';

  @override
  String get personaSignatureEmojisLabel => 'Фірмові емодзі';

  @override
  String get personaSignatureEmojisDescription =>
      'Реакція фірмовим емодзі завжди залишається від імені цієї персони, незалежно від активної.';

  @override
  String get personaAddSignatureEmoji => 'Додати емодзі';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Цей емодзі вже додано як фірмовий емодзі';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Фірмовий емодзі вже використовується персоною «$name»';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Видалити фірмовий емодзі';

  @override
  String get signalBarLabel => 'Панель сигналів';

  @override
  String get signalBarShow => 'Показати панель сигналів';

  @override
  String get signalBarHide => 'Сховати панель сигналів';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Ніхто не ввімкнув цей сигнал';

  @override
  String get signalBarReset => 'Скинути сигнал для всіх';

  @override
  String signalBarTurnOff(String name) {
    return 'Вимкнути $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Використовуйте $domain для інстансу за замовчуванням або точну URL-адресу іншого інстансу.';
  }

  @override
  String get instanceResetToDefault => 'Скинути до інстансу за замовчуванням';

  @override
  String get personaScopeTitle => 'Персона діє';

  @override
  String get personaScopeGlobal => 'Усюди';

  @override
  String get personaScopeGlobalDescription => 'Одна персона для всіх каналів.';

  @override
  String get personaScopeChannel => 'У кожному каналі';

  @override
  String get personaScopeChannelDescription =>
      'Кожен канал зберігає свою персону. Нові канали починаються з вашого облікового запису.';

  @override
  String get personaPickerChannelOnly => 'Лише для цього каналу';

  @override
  String get personaProfilePrivate => 'Профіль цієї персони приватний.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Файл зображення занадто великий. Будь ласка, виберіть файл розміром менше $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Пошук KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Не вдалося завантажити оновлення';

  @override
  String get appUpdateInstallFailed => 'Не вдалося встановити оновлення';

  @override
  String get personaChangeMessageFailed =>
      'Не вдалося змінити персону повідомлення';

  @override
  String get personaActiveCleared => 'Активну персону скинуто';

  @override
  String get klipyPoweredBy => 'На основі KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Пара тегів \'$pattern\' уже є в цієї персони';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Додати пару тегів ($count/5)';
  }

  @override
  String get personaTagExampleText => 'текст';

  @override
  String get personaPreviewNameFallback => 'Користувач';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne неочікувано закрився. Надсилання анонімних даних про збої та помилки допомагає нам швидше виправляти проблеми.';

  @override
  String get crashReportingSectionDescription =>
      'Допоможіть виправляти помилки в Tyne, надсилаючи дані про збої та продуктивність. Типово вимкнено.';

  @override
  String get crashReportingDescription =>
      'Звіти надходять до власної системи відстеження помилок Tyne, навіть якщо ви ввійшли в інший інстанс. Вони не містять назв інстансів, ідентифікаторів чи вмісту повідомлень.';

  @override
  String get instanceOfflineTitle => 'Tyne недоступний!';

  @override
  String get instanceOfflineBody => 'Ми з\'ясовуємо, що сталося.';

  @override
  String get instanceStatusSignalLink =>
      'Приєднуйтеся до нашого чату в Signal, щоб стежити за новинами';

  @override
  String get convertEmoticonsLabel =>
      'Увімкнути перетворення текстових смайликів на емоджі';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Не вдалося виконати /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'У її скрипті є проблема.';

  @override
  String guildCommandOneLine(String name) {
    return 'Текст після /$name має вміщатися в один рядок.';
  }

  @override
  String get permissionCreateCommands => 'Створювати команди';

  @override
  String get permissionManageCommands => 'Керувати командами';

  @override
  String get permissionUseExternalCommands =>
      'Використовувати зовнішні команди';

  @override
  String get permissionCreateCommandsDescription =>
      'Створювати команди для цієї спільноти, а також редагувати й видаляти власні.';

  @override
  String get permissionManageCommandsDescription =>
      'Редагувати й видаляти команди будь-кого в цій спільноті.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Використовувати команди з інших спільнот.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Використовувати команди з інших спільнот у цьому каналі.';

  @override
  String get guildSettingsCategoryMessageTools => 'Інструменти повідомлень';

  @override
  String get guildSettingsCommands => 'Команди';

  @override
  String get guildCommandsLoadFailed => 'Не вдалося завантажити команди.';

  @override
  String get guildCommandsSubtitle =>
      'Повідомлення, які учасники можуть надіслати, ввівши /name.';

  @override
  String get guildCommandsSlots => 'Слоти для команд';

  @override
  String get guildCommandsNew => 'Нова команда';

  @override
  String get guildCommandsSearch => 'Пошук команд';

  @override
  String get guildCommandsEmptyTitle => 'Немає команд';

  @override
  String get guildCommandsEmptyBody => 'Ця спільнота ще не має команд.';

  @override
  String get guildCommandsSaved => 'Команди збережено';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Не вдалося зберегти /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Редагувати /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Видалити /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Цю дію не можна скасувати. Повідомлення, створені цією командою, і далі показують, яка команда їх створила.';

  @override
  String get guildCommandDelete => 'Видалити';

  @override
  String get guildCommandDeleteCommand => 'Видалити команду';

  @override
  String get guildCommandSectionCommand => 'Команда';

  @override
  String get guildCommandName => 'Назва';

  @override
  String get guildCommandNameInvalid =>
      'Використовуйте малі літери, цифри, - і _, не більше 32 символів.';

  @override
  String get guildCommandNameTaken =>
      'Ця назва вже зайнята іншою командою або вбудованою командою.';

  @override
  String get guildCommandDescription => 'Опис';

  @override
  String get guildCommandSectionInput => 'Введення';

  @override
  String get guildCommandInputNone => 'Немає';

  @override
  String get guildCommandInputOptional => 'Необов\'язково';

  @override
  String get guildCommandInputRequired => 'Обов\'язково';

  @override
  String get guildCommandHint => 'Підказка';

  @override
  String get guildCommandMessage => 'Повідомлення';

  @override
  String get guildCommandInsert => 'Вставити:';

  @override
  String get guildCommandInsertPerson => 'Хто її використовує';

  @override
  String get guildCommandInsertInput => 'Що вводять';

  @override
  String get guildCommandPreview => 'Попередній перегляд';

  @override
  String get guildCommandSampleInput => 'Приклад введення';

  @override
  String guildCommandMadeWith(String name) {
    return 'Створено за допомогою /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Очистьте поле повідомлення, щоб використати /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Це нічого не надішле, тому команда не спрацює.';

  @override
  String get guildCommandUseScriptEditor => 'Використати редактор скриптів';

  @override
  String get guildCommandUseBasicEditor => 'Використати простий редактор';

  @override
  String get guildCommandScript => 'Скрипт';

  @override
  String get guildCommandRunAgain => 'Виконати ще раз';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Немає тега з назвою $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Немає фільтра з назвою $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name ніде не закривається.';
  }

  @override
  String get guildCommandIssueTooLong => 'Скрипт задовгий.';

  @override
  String get guildCommandIssueTooLarge => 'Скрипт створює забагато тексту.';

  @override
  String get guildCommandIssueTooSlow => 'Скрипт виконувався задовго.';

  @override
  String get guildCommandIssueInvalid => 'Цю частину не вдається прочитати.';

  @override
  String get guildCommandIssueFailed =>
      'Виконання цієї частини перервалося з помилкою.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Рядок $line, стовпець $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Довідка зі скриптів';

  @override
  String get guildCommandReferencePerson =>
      'Хто її використовує, у вигляді згадки';

  @override
  String get guildCommandReferencePersonName =>
      'Ім’я того, хто її використовує';

  @override
  String get guildCommandReferenceTarget => 'Перша згадана людина, якщо є';

  @override
  String get guildCommandReferenceTargetName => 'Ім’я цієї людини';

  @override
  String get guildCommandReferenceChannel => 'Канал у вигляді згадки';

  @override
  String get guildCommandReferenceCommunity => 'Назва цієї спільноти';

  @override
  String get guildCommandExampleRandom => 'Вибрати випадковий варіант';

  @override
  String get guildCommandExampleDepends =>
      'Змінити повідомлення залежно від введеного';

  @override
  String get guildCommandExampleOneWord => 'Вибрати випадкове слово';

  @override
  String get guildCommandExampleWordForNumber => 'Підібрати слово до числа';

  @override
  String get guildCommandExampleOrdinal => 'Записати число як 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Повний посібник зі скриптів';
}
