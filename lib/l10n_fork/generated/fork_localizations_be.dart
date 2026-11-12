// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Belarusian (`be`).
class ForkLocalizationsBe extends ForkLocalizations {
  ForkLocalizationsBe([String locale = 'be']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Змяніць персону';

  @override
  String get chatAttachmentPanelVoice => 'Голас';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Кнопка хуткага пераключэння';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Замяняе кнопку галасавога паведамлення ў полі ўводу на кнопку хуткага пераключэння для зручнай навігацыі';

  @override
  String get userSettingsCheckForUpdates => 'Праверыць абнаўленні';

  @override
  String get userSettingsCheckingForUpdates => 'Праверка абнаўленняў…';

  @override
  String get userSettingsAppUpToDate => 'У вас апошняя версія Tyne';

  @override
  String get userSettingsUpdateAvailableTitle => 'Ёсць абнаўленне';

  @override
  String get userSettingsUpdateDownloadAction => 'Спампаваць і ўсталяваць';

  @override
  String get userSettingsUpdateInstallAction => 'Усталяваць абнаўленне';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Спампоўка абнаўлення ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Не ўдалося праверыць або спампаваць абнаўленне.';

  @override
  String get personaSelectTitle => 'Выбар персоны';

  @override
  String get personaSettingsHeader => 'Налады персон';

  @override
  String get personaManageAction => 'Кіраваць';

  @override
  String get personaSearchPlaceholder => 'Пошук персон, тэгаў, займеннікаў…';

  @override
  String get personaModeManual => 'Уручную';

  @override
  String get personaModeLast => 'Апошняя выкарыстаная';

  @override
  String get personaModeManualDescription =>
      'Заўсёды адпраўляе ад імя выбранай персоны, пакуль вы яе не зменіце.';

  @override
  String get personaModeLastDescription =>
      'Аўтаматычна пераключаецца на персону з вашага апошняга паведамлення.';

  @override
  String get personaRecentHeader => 'НЯДАЎНІЯ ПЕРСОНЫ';

  @override
  String personaAllHeader(int count) {
    return 'УСЕ ПЕРСОНЫ ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'ВЫНІКІ ПОШУКУ ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Асноўны ўліковы запіс (па змаўчанні)';

  @override
  String get personaEmptyState =>
      'Персон пакуль няма. Стварыце першую праз «Кіраваць персонамі».';

  @override
  String get personaEmptySearch => 'Адпаведных персон не знойдзена.';

  @override
  String get personaEditTitle => 'Рэдагаваць персону';

  @override
  String get personaCreateTitle => 'Стварыць персону';

  @override
  String get personaDisplayNameLabel => 'Бачнае імя';

  @override
  String get personaPronounsLabel => 'Займеннікі';

  @override
  String get personaPronounsHint => 'напр. яны/іх';

  @override
  String get personaBioHint => 'Раскажыце іншым пра гэтую персону…';

  @override
  String get personaUpdatedToast => 'Персона абноўлена';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Не ўдалося абнавіць персону: $error';
  }

  @override
  String get personaSectionTitle => 'Персоны';

  @override
  String get personaDisplayNameHint => 'Імя персоны';

  @override
  String personaSendingAsTag(String name) {
    return 'Адпраўка ад імя $name (па тэгу)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Адпраўка ад імя $name (зафіксавана)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Адпраўка ад імя $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Публікацыя ад імя $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Адпраўка ад імя @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'Не адпраўлена: вашы персоны яшчэ не загрузіліся.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Не адпраўлена: вашы персоны яшчэ не загрузіліся. Адправіць ад імя @$username?';
  }

  @override
  String get personaSendAsAccountAction => 'Усё роўна адправіць';

  @override
  String get personaMainAccount => 'Асноўны ўліковы запіс';

  @override
  String get personaEditPersona => 'Рэдагаваць персону';

  @override
  String get userSettingsNavPersonas => 'Персоны';

  @override
  String get personaSettingsDescription =>
      'Наладзьце рэжым актыўнай персоны і свой бачны тэг, а таксама кіруйце асобнымі персонамі.';

  @override
  String get personaDisplayTagSection => 'Бачны тэг';

  @override
  String get personaDisplayTagDescription =>
      'Бачны тэг будзе паказвацца побач з імёнамі ўсіх персон у паведамленнях. Калі бачны тэг не зададзены, будзе паказвацца аватар вашага ўліковага запісу.';

  @override
  String get personaDisplayTagLabel => 'Тэкст бачнага тэга';

  @override
  String get personaDisplayTagHint => 'напр. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Значок бачнага тэга';

  @override
  String get personaUploadTagIcon => 'Запампаваць значок';

  @override
  String get personaChangeTagIcon => 'Змяніць значок';

  @override
  String get personaRemoveTagIcon => 'Выдаліць значок';

  @override
  String get personaChatPreviewTitle => 'Папярэдні прагляд у чаце';

  @override
  String get personaChatPreviewSampleMessage =>
      'Прывітанне! Так будуць выглядаць паведамленні з вашым бачным тэгам і актыўнай персонай.';

  @override
  String get personaListTitle => 'Наладжаныя персоны';

  @override
  String get personaAddButton => 'Дадаць персону';

  @override
  String get personaActiveBadge => 'Актыўная';

  @override
  String get personaMakeActive => 'Зрабіць актыўнай';

  @override
  String get personaDeleteTitle => 'Выдаліць персону';

  @override
  String personaDeleteMessage(String name) {
    return 'Сапраўды выдаліць «$name»? Гэта нельга адрабіць.';
  }

  @override
  String get personaDeleteConfirm => 'Выдаліць';

  @override
  String get personaDeletedToast => 'Персона выдалена';

  @override
  String get personaCreatedToast => 'Персона створана';

  @override
  String personaCreateFailedToast(String error) {
    return 'Не ўдалося стварыць персону: $error';
  }

  @override
  String get personaChangeAvatar => 'Змяніць аватар';

  @override
  String get personaRemoveAvatar => 'Выдаліць аватар';

  @override
  String get personaUploadAvatar => 'Запампаваць аватар';

  @override
  String get personaTagsLabel => 'Тэгі персоны';

  @override
  String get personaAutoTagDisabledLabel =>
      'Не распазнаваць тэгі гэтай персоны';

  @override
  String get personaAutoTagDisabledDescription =>
      'Увод аднаго з гэтых тэгаў не пераключае на гэтую персону. Тэг адпраўляецца так, як напісаны.';

  @override
  String get personaTagPrefixLabel => 'Прэфікс';

  @override
  String get personaTagSuffixLabel => 'Суфікс';

  @override
  String get personaVisibilityLabel => 'Бачнасць';

  @override
  String get personaVisibilityUnlisted => 'Не ў спісе';

  @override
  String get personaVisibilityPublic => 'Публічная';

  @override
  String get personaVisibilityPrivate => 'Прыватная';

  @override
  String get personaNameRequired => 'Увядзіце імя персоны';

  @override
  String get personaNameTooLong =>
      'Імя персоны павінна быць не даўжэйшым за 100 сімвалаў';

  @override
  String get personaTagPrefixTooLong =>
      'Прэфікс тэга персоны павінен быць не даўжэйшым за 32 сімвалы';

  @override
  String get personaTagSuffixTooLong =>
      'Суфікс тэга персоны павінен быць не даўжэйшым за 32 сімвалы';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Тэг «$tag» ужо выкарыстоўвае персона «$name».';
  }

  @override
  String get chatInsertTimestamp => 'Уставіць пазнаку часу';

  @override
  String get chatAttachmentSendVoiceMessage =>
      'Адправіць галасавое паведамленне';

  @override
  String get timestampPickerTitle => 'Уставіць пазнаку часу';

  @override
  String get timestampPickerInsert => 'Уставіць';

  @override
  String get timestampCopied => 'Пазнака часу скапіявана';

  @override
  String get timestampPickerTimeLabel => 'Час';

  @override
  String get timestampPickerDateLabel => 'ДАТА';

  @override
  String get timestampPickerTimeSectionLabel => 'ЧАС';

  @override
  String get timestampPickerTimezoneLabel => 'ЧАСАВЫ ПОЯС';

  @override
  String get timestampPickerFormatPreviewLabel => 'ПАПЯРЭДНІ ПРАГЛЯД ФАРМАТУ';

  @override
  String get timestampPickerNlpPlaceholder =>
      'напр. tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'Пошук часавых паясоў…';

  @override
  String get userProfileTimezoneSettingLabel => 'Часавы пояс';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Патрэбны, каб паказваць ваш мясцовы час у профілі.';

  @override
  String get userProfileTimezoneNone => 'Няма';

  @override
  String get chatReactAs => 'Адрэагаваць ад імя…';

  @override
  String get emojiCopy => 'Скапіяваць эмодзі';

  @override
  String get emojiCopyLink => 'Скапіяваць спасылку';

  @override
  String get emojiPin => 'Замацаваць эмодзі';

  @override
  String get emojiUnpin => 'Адмацаваць эмодзі';

  @override
  String get emojiPinForPersona => 'Замацаваць для гэтай персоны';

  @override
  String get emojiUnpinForPersona => 'Адмацаваць для гэтай персоны';

  @override
  String get personaSignatureEmojisLabel => 'Адметныя эмодзі';

  @override
  String get personaSignatureEmojisDescription =>
      'Рэакцыя адметным эмодзі заўсёды ставіцца ад імя гэтай персоны, незалежна ад актыўнай персоны.';

  @override
  String get personaAddSignatureEmoji => 'Дадаць эмодзі';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Гэтае эмодзі ўжо дададзена як адметнае';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Гэтае адметнае эмодзі ўжо выкарыстоўвае персона «$name»';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Выдаліць адметнае эмодзі';

  @override
  String get signalBarLabel => 'Панэль сігналаў';

  @override
  String get signalBarShow => 'Паказаць панэль сігналаў';

  @override
  String get signalBarHide => 'Схаваць панэль сігналаў';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Гэты сігнал ні ў кога не ўключаны';

  @override
  String get signalBarReset => 'Скінуць сігнал для ўсіх';

  @override
  String signalBarTurnOff(String name) {
    return 'Выключыць для $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Увядзіце $domain для сервера па змаўчанні або дакладны URL іншага сервера.';
  }

  @override
  String get instanceResetToDefault => 'Вярнуцца да сервера па змаўчанні';

  @override
  String get personaScopeTitle => 'Дзе дзейнічае персона';

  @override
  String get personaScopeGlobal => 'Усюды';

  @override
  String get personaScopeGlobalDescription => 'Адна персона для ўсіх каналаў.';

  @override
  String get personaScopeChannel => 'У кожным канале';

  @override
  String get personaScopeChannelDescription =>
      'Кожны канал захоўвае сваю персону. У новых каналах вы спачатку пішаце ад імя ўліковага запісу.';

  @override
  String get personaPickerChannelOnly => 'Толькі для гэтага канала';

  @override
  String get personaProfilePrivate => 'Профіль гэтай персоны прыватны.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Файл выявы завялікі. Выберыце файл, меншы за $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Пошук у KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Не ўдалося спампаваць абнаўленне';

  @override
  String get appUpdateInstallFailed => 'Не ўдалося ўсталяваць абнаўленне';

  @override
  String get personaChangeMessageFailed =>
      'Не ўдалося змяніць персону паведамлення';

  @override
  String get personaActiveCleared => 'Актыўная персона скінута';

  @override
  String get klipyPoweredBy => 'Пры падтрымцы KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Пара тэгаў «$pattern» паўтараецца ў гэтай персоны';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Дадаць пару тэгаў ($count/5)';
  }

  @override
  String get personaTagExampleText => 'тэкст';

  @override
  String get personaPreviewNameFallback => 'Карыстальнік';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne нечакана закрыўся. Калі вы адправіце ананімныя даныя пра збоі і памылкі, мы зможам хутчэй выправіць праблемы.';

  @override
  String get crashReportingSectionDescription =>
      'Дапамажыце выпраўляць памылкі ў Tyne, адпраўляючы даныя пра збоі і хуткадзейнасць. Па змаўчанні выключана.';

  @override
  String get crashReportingDescription =>
      'Справаздачы трапляюць ва ўласны трэкер памылак Tyne, нават калі вы ўвайшлі на іншы сервер. У іх няма назваў сервераў, ідэнтыфікатараў і зместу паведамленняў.';

  @override
  String get instanceOfflineTitle => 'Tyne недаступны!';

  @override
  String get instanceOfflineBody => 'Мы высвятляем прычыну.';

  @override
  String get instanceStatusSignalLink =>
      'Далучайцеся да нашага чата ў Signal, каб сачыць за навінамі';

  @override
  String get convertEmoticonsLabel => 'Ператвараць тэкставыя смайлікі ў эмодзі';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Не ўдалося выканаць /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'У яе скрыпце ёсць памылка.';

  @override
  String guildCommandOneLine(String name) {
    return 'Тэкст пасля /$name павінен змяшчацца ў адзін радок.';
  }

  @override
  String get permissionCreateCommands => 'Ствараць каманды';

  @override
  String get permissionManageCommands => 'Кіраваць камандамі';

  @override
  String get permissionUseExternalCommands => 'Выкарыстоўваць знешнія каманды';

  @override
  String get permissionCreateCommandsDescription =>
      'Ствараць каманды для гэтай супольнасці, а таксама змяняць і выдаляць свае.';

  @override
  String get permissionManageCommandsDescription =>
      'Змяняць і выдаляць каманды любых удзельнікаў гэтай супольнасці.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Выкарыстоўваць каманды з іншых супольнасцей.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Выкарыстоўваць каманды з іншых супольнасцей у гэтым канале.';

  @override
  String get guildSettingsCategoryMessageTools => 'Інструменты паведамленняў';

  @override
  String get guildSettingsCommands => 'Каманды';

  @override
  String get guildCommandsLoadFailed => 'Не ўдалося загрузіць каманды.';

  @override
  String get guildCommandsSubtitle =>
      'Паведамленні, якія ўдзельнікі могуць адправіць, увёўшы /name.';

  @override
  String get guildCommandsSlots => 'Слоты для каманд';

  @override
  String get guildCommandsNew => 'Новая каманда';

  @override
  String get guildCommandsSearch => 'Пошук каманд';

  @override
  String get guildCommandsEmptyTitle => 'Няма каманд';

  @override
  String get guildCommandsEmptyBody =>
      'У гэтай супольнасці пакуль няма каманд.';

  @override
  String get guildCommandsSaved => 'Каманды захаваны';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Не ўдалося захаваць /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Змяніць /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Выдаліць /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Гэта нельга адрабіць. Паведамленні, створаныя гэтай камандай, па-ранейшаму будуць паказваць, якая каманда іх стварыла.';

  @override
  String get guildCommandDelete => 'Выдаліць';

  @override
  String get guildCommandDeleteCommand => 'Выдаліць каманду';

  @override
  String get guildCommandSectionCommand => 'Каманда';

  @override
  String get guildCommandName => 'Назва';

  @override
  String get guildCommandNameInvalid =>
      'Выкарыстоўвайце малыя літары, лічбы, - і _, не больш за 32 сімвалы.';

  @override
  String get guildCommandNameTaken =>
      'Гэтая назва ўжо занятая іншай або ўбудаванай камандай.';

  @override
  String get guildCommandDescription => 'Апісанне';

  @override
  String get guildCommandSectionInput => 'Увод';

  @override
  String get guildCommandInputNone => 'Няма';

  @override
  String get guildCommandInputOptional => 'Неабавязкова';

  @override
  String get guildCommandInputRequired => 'Абавязкова';

  @override
  String get guildCommandHint => 'Падказка';

  @override
  String get guildCommandMessage => 'Паведамленне';

  @override
  String get guildCommandInsert => 'Уставіць:';

  @override
  String get guildCommandInsertPerson => 'Чалавек, які запускае';

  @override
  String get guildCommandInsertInput => 'Уведзены тэкст';

  @override
  String get guildCommandPreview => 'Папярэдні прагляд';

  @override
  String get guildCommandSampleInput => 'Прыклад уводу';

  @override
  String guildCommandMadeWith(String name) {
    return 'Зроблена з дапамогай /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Ачысціце поле паведамлення, каб выкарыстаць /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Гэта нічога не адправіць, таму каманда не спрацуе.';

  @override
  String get guildCommandUseScriptEditor => 'Выкарыстаць рэдактар скрыптоў';

  @override
  String get guildCommandUseBasicEditor => 'Выкарыстаць просты рэдактар';

  @override
  String get guildCommandScript => 'Скрыпт';

  @override
  String get guildCommandRunAgain => 'Запусціць яшчэ раз';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Няма тэга з назвай $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Няма фільтра з назвай $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name нідзе не закрываецца.';
  }

  @override
  String get guildCommandIssueTooLong => 'Скрыпт занадта доўгі.';

  @override
  String get guildCommandIssueTooLarge => 'Скрыпт стварае занадта шмат тэксту.';

  @override
  String get guildCommandIssueTooSlow => 'Скрыпт выконваўся занадта доўга.';

  @override
  String get guildCommandIssueInvalid => 'Гэтую частку немагчыма прачытаць.';

  @override
  String get guildCommandIssueFailed =>
      'Выкананне гэтай часткі спынілася з памылкай.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Радок $line, слупок $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Даведка па скрыптах';

  @override
  String get guildCommandReferencePerson =>
      'Чалавек, які запускае каманду, у выглядзе згадкі';

  @override
  String get guildCommandReferencePersonName => 'Імя чалавека, які запускае';

  @override
  String get guildCommandReferenceTarget => 'Першы згаданы чалавек, калі ёсць';

  @override
  String get guildCommandReferenceTargetName => 'Імя гэтага чалавека';

  @override
  String get guildCommandReferenceChannel => 'Канал у выглядзе згадкі';

  @override
  String get guildCommandReferenceCommunity => 'Назва гэтай супольнасці';

  @override
  String get guildCommandExampleRandom => 'Выбраць выпадковы варыянт';

  @override
  String get guildCommandExampleDepends =>
      'Змяняць паведамленне ў залежнасці ад таго, што ўвялі';

  @override
  String get guildCommandExampleOneWord => 'Выбраць выпадковае слова';

  @override
  String get guildCommandExampleWordForNumber =>
      'Падабраць форму слова да ліку';

  @override
  String get guildCommandExampleOrdinal => 'Запісаць лік як 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Поўны даведнік па скрыптах';

  @override
  String get guildCommandCounters => 'Лічыльнікі';

  @override
  String get guildCommandCounterAdd => 'Дадаць лічыльнік';

  @override
  String get guildCommandCounterSeparately => 'Лічыць асобна для кожнага:';

  @override
  String get guildCommandCounterPersonMentioned => 'Згаданы чалавек';

  @override
  String get guildCommandCounterChannel => 'Канал';

  @override
  String get guildCommandCounterPersonas => 'Лічыць персоны асобна';

  @override
  String get guildCommandCounterRemove => 'Выдаліць лічыльнік';

  @override
  String get guildCommandCounterReset => 'Абнуліць лічыльнік';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Абнуліць лічыльнік $name? Гэта нельга адрабіць.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Выкарыстоўвайце малыя літары, лічбы і _; назва павінна пачынацца з літары і не супадаць з назвай, якую ўжо выкарыстоўваюць скрыпты.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Выкарыстоўвайце яго ў скрыпце як $variable. Кожны запуск спачатку дадае адзінку, таму пры першым запуску значэнне роўнае 1.';
  }

  @override
  String get notificationsAlertEveryMessageLabel =>
      'Апавяшчаць пра кожнае паведамленне';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Калі выключана, актыўная размова апавясціць адзін раз, а потым будзе абнаўляцца бязгучна, пакуль вы яе не прачытаеце або не закрыеце апавяшчэнне.';

  @override
  String personaGalleryTitle(int count) {
    return 'Персоны ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Пошук сярод персон $name';
  }

  @override
  String get personaGallerySearchOwn => 'Пошук сярод вашых персон';

  @override
  String get personaGallerySortBy => 'Сартаванне';

  @override
  String get personaGallerySortName => 'Імя (А–Я)';

  @override
  String get personaGallerySortMostUsed => 'Найчасцей выкарыстоўваныя';

  @override
  String get personaGallerySortRecentlyUsed => 'Нядаўна выкарыстаныя';

  @override
  String get personaGalleryViewGallery => 'Галерэя';

  @override
  String get personaGalleryViewList => 'Спіс';

  @override
  String get personaGalleryViewAvatars => 'Аватары';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count персоны',
      many: '$count персон',
      few: '$count персоны',
      one: '$count персона',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return 'Персоны: $shown з $total';
  }

  @override
  String get personaGalleryNoMatch => 'Па вашым запыце персон не знойдзена.';

  @override
  String get personaGalleryLoadFailed => 'Не ўдалося загрузіць персоны.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count публічнай персоны',
      many: '$count публічных персон',
      few: '$count публічныя персоны',
      one: '$count публічную персону',
    );
    return 'Іншыя бачаць $_temp0.';
  }

  @override
  String get personaGalleryShowHidden =>
      'Паказваць персоны не ў спісе і прыватныя';

  @override
  String get personaGalleryManage => 'Кіраваць персонамі';

  @override
  String get personaGalleryNonePublic =>
      'Ніводная з вашых персон пакуль не публічная. Іншыя ўбачаць персону тут, калі вы выберыце для яе бачнасць «Публічная».';

  @override
  String get personaGalleryNoBio => 'Апісання пакуль няма.';

  @override
  String personaGalleryCreated(String date) {
    return 'Створана $date';
  }

  @override
  String get personaBulkSelect => 'Выбраць';

  @override
  String get personaBulkSelectAll => 'Выбраць усе';

  @override
  String personaBulkSelectedCount(int count) {
    return 'Выбрана: $count';
  }

  @override
  String get personaFilterAll => 'Усе';

  @override
  String get personaBulkMakePublic => 'Зрабіць публічнымі';

  @override
  String get personaBulkMakeUnlisted => 'Прыбраць са спісу';

  @override
  String get personaBulkMakePrivate => 'Зрабіць прыватнымі';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count персоны публічнымі',
      many: '$count персон публічнымі',
      few: '$count персоны публічнымі',
      one: '$count персону публічнай',
    );
    return 'Зрабіць $_temp0?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count персоны прыватнымі',
      many: '$count персон прыватнымі',
      few: '$count персоны прыватнымі',
      one: '$count персону прыватнай',
    );
    return 'Зрабіць $_temp0?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count персоны',
      many: '$count персон',
      few: '$count персоны',
      one: '$count персону',
    );
    return 'Выдаліць $_temp0?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Іншыя ўбачаць іх у вашым спісе персон і змогуць адкрываць іх профілі. Вы можаце вярнуць усё назад у любы момант.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Іх профілі будуць схаваныя ад іншых. Іх імёны і аватары па-ранейшаму будуць бачныя ў іх паведамленнях і рэакцыях.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Іх паведамленні па-ранейшаму будуць паказваць іх імёны і аватары, але вы больш не зможаце пісаць ад іх імя, а іх тэгі і адметныя эмодзі вызваляцца. Гэта нельга адрабіць.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count персоны цяпер публічныя',
      many: '$count персон цяпер публічныя',
      few: '$count персоны цяпер публічныя',
      one: '$count персона цяпер публічная',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count персоны цяпер не ў спісе',
      many: '$count персон цяпер не ў спісе',
      few: '$count персоны цяпер не ў спісе',
      one: '$count персона цяпер не ў спісе',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count персоны цяпер прыватныя',
      many: '$count персон цяпер прыватныя',
      few: '$count персоны цяпер прыватныя',
      one: '$count персона цяпер прыватная',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выдалена $count персоны',
      many: 'Выдалена $count персон',
      few: 'Выдалены $count персоны',
      one: 'Выдалена $count персона',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed =>
      'Не ўдалося змяніць персоны. Паспрабуйце яшчэ раз.';

  @override
  String get personaFilterEmpty => 'Тут няма персон.';

  @override
  String get personaGalleryChooseFeatured => 'Выбраць персоны для паказу';

  @override
  String get personaUndo => 'Адрабіць';

  @override
  String get personaReactionsTitle => 'Вашы рэакцыі';

  @override
  String get personaReactionsEveryoneElse => 'УСЕ АСТАТНІЯ';

  @override
  String get personaReactionsCurrent => 'БЯГУЧАЯ';

  @override
  String get personaReactionsAccount => 'Уліковы запіс';

  @override
  String get personaReactionsSomeoneElse =>
      'Адрэагаваць ад імя кагосьці іншага…';

  @override
  String get personaReactionsDone => 'Гатова';

  @override
  String get personaSettingsReactionsHeader => 'Рэакцыі';

  @override
  String get personaSettingsMultiReactions =>
      'Рэагаваць ад імя некалькіх персон адначасова';

  @override
  String get personaDuplicateButton => 'Дубляваць персону';

  @override
  String personaCopyOf(String name) {
    return 'Копія персоны $name';
  }

  @override
  String signalsEverywhereTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count чата',
      many: '$count чатаў',
      few: '$count чаты',
      one: '$count чат',
    );
    return 'Вашы сігналы ўсюды · $_temp0';
  }

  @override
  String signalsEverywhereHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count чата',
      many: '$count чатаў',
      few: '$count чаты',
      one: '$count чат',
    );
    return 'Уключыць усюды ($_temp0)';
  }

  @override
  String signalsEverywhereSet(String label) {
    return 'Уключыць $label усюды';
  }

  @override
  String get signalsEverywhereTurnAllOff => 'Выключыць усе';

  @override
  String get signalsEverywhereRestore => 'Аднавіць…';

  @override
  String get signalsEverywhereNone =>
      'Ні адзін з вашых сігналаў нідзе не ўключаны.';

  @override
  String get signalsRestoreTitle => 'Аднавіць вашы сігналы?';

  @override
  String signalsRestoreBeforeSet(String label, String time) {
    return 'Вяртае тое, што было ўключана да ўключэння сігналу $label усюды ($time). Тое, што ўключана там цяпер, выключыцца.';
  }

  @override
  String signalsRestoreBeforeOff(String time) {
    return 'Вяртае тое, што было ўключана да выключэння ўсіх сігналаў ($time). Тое, што ўключана там цяпер, выключыцца.';
  }

  @override
  String signalsRestoreBeforeRestore(String time) {
    return 'Вяртае тое, што было ўключана да вашага апошняга аднаўлення ($time). Тое, што ўключана там цяпер, выключыцца.';
  }

  @override
  String get signalsRestoreNow => 'Цяпер';

  @override
  String get signalsRestoreAfter => 'Пасля';

  @override
  String signalsRestoreLeftOut(String chats) {
    return 'Прапушчаны, бо вы больш не можаце там пісаць: $chats';
  }

  @override
  String get signalsRestoreConfirm => 'Аднавіць';

  @override
  String get signalsRestoreUnavailable =>
      'Не ўдалося загрузіць, што зменіць «Аднавіць». Паспрабуйце яшчэ раз.';

  @override
  String get signalsRestoreNothing => 'Няма чаго аднаўляць.';

  @override
  String get signalsProfileMenu => 'Сігналы';

  @override
  String get signalsEverywhereTurnOffChat => 'Выключыць сігналы';

  @override
  String signalsRestoreBeforeChange(String time) {
    return 'Вяртае тое, што было ўключана да вашай апошняй змены ўсюды ($time). Тое, што ўключана там цяпер, выключыцца.';
  }

  @override
  String get personaCopyBadge => 'Новая персона';
}
