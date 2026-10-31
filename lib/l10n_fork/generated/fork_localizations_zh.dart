// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class ForkLocalizationsZh extends ForkLocalizations {
  ForkLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get chatMessageChangePersona => '切换人格';

  @override
  String get chatAttachmentPanelVoice => '语音';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => '快速切换按钮';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      '将消息输入框中的语音消息按钮替换为快速切换按钮，以便快速导航';

  @override
  String get userSettingsCheckForUpdates => '检查更新';

  @override
  String get userSettingsCheckingForUpdates => '正在检查更新…';

  @override
  String get userSettingsAppUpToDate => 'Tyne 已是最新版本';

  @override
  String get userSettingsUpdateAvailableTitle => '有可用更新';

  @override
  String get userSettingsUpdateDownloadAction => '下载并安装';

  @override
  String get userSettingsUpdateInstallAction => '安装更新';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return '正在下载更新（$percent%）…';
  }

  @override
  String get userSettingsUpdateFailed => '检查或下载更新失败。';

  @override
  String get personaSelectTitle => '选择人格';

  @override
  String get personaSettingsHeader => '人格设置';

  @override
  String get personaManageAction => '管理';

  @override
  String get personaSearchPlaceholder => '搜索人格、标签、代词...';

  @override
  String get personaModeManual => '手动';

  @override
  String get personaModeLast => '最近使用';

  @override
  String get personaModeManualDescription => '在更改之前，始终以选定的人格发送。';

  @override
  String get personaModeLastDescription => '自动切换到上一条消息中使用的人格。';

  @override
  String get personaRecentHeader => '最近人格';

  @override
  String personaAllHeader(int count) {
    return '所有人格 ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return '搜索结果 ($count)';
  }

  @override
  String get personaRootAccountLabel => '根账户 (默认)';

  @override
  String get personaEmptyState => '尚未配置人格。请通过“管理人格”创建一个。';

  @override
  String get personaEmptySearch => '未找到匹配的人格。';

  @override
  String get personaEditTitle => '编辑人格';

  @override
  String get personaCreateTitle => '创建人格';

  @override
  String get personaDisplayNameLabel => '显示名称';

  @override
  String get personaPronounsLabel => '代词';

  @override
  String get personaPronounsHint => '例如：they/them';

  @override
  String get personaBioHint => '向他人介绍此人格...';

  @override
  String get personaUpdatedToast => '人格已更新';

  @override
  String personaUpdateFailedToast(String error) {
    return '更新人格失败：$error';
  }

  @override
  String get personaSectionTitle => '人格';

  @override
  String get personaDisplayNameHint => '人格名称';

  @override
  String personaSendingAsTag(String name) {
    return '以 $name 发送 (通过标签匹配)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return '以 $name 发送 (已锁定)';
  }

  @override
  String personaSendingAs(String name) {
    return '以 $name 发送';
  }

  @override
  String personaPostingAs(String name) {
    return '以 $name 发布';
  }

  @override
  String personaSendingAsRoot(String username) {
    return '以 @$username 发送';
  }

  @override
  String get personaMainAccount => '主账户';

  @override
  String get personaEditPersona => '编辑人格';

  @override
  String get userSettingsNavPersonas => '人格';

  @override
  String get personaSettingsDescription => '配置您的活跃人格模式、自定义显示标签，并管理个人人格。';

  @override
  String get personaDisplayTagSection => '显示标签';

  @override
  String get personaDisplayTagDescription =>
      '显示标签将出现在消息中所有人格名称旁边。如果未设置显示标签，将显示您的账户头像。';

  @override
  String get personaDisplayTagLabel => '显示标签文本';

  @override
  String get personaDisplayTagHint => '例如：SYS';

  @override
  String get personaDisplayTagIconLabel => '显示标签图标';

  @override
  String get personaUploadTagIcon => '上传图标';

  @override
  String get personaChangeTagIcon => '更改图标';

  @override
  String get personaRemoveTagIcon => '移除图标';

  @override
  String get personaChatPreviewTitle => '聊天预览';

  @override
  String get personaChatPreviewSampleMessage => '你好！这是带有您的显示标签和活跃人格的消息外观预览。';

  @override
  String get personaListTitle => '已配置的人格';

  @override
  String get personaAddButton => '添加人格';

  @override
  String get personaActiveBadge => '有效';

  @override
  String get personaMakeActive => '设为活跃';

  @override
  String get personaDeleteTitle => '删除人格';

  @override
  String personaDeleteMessage(String name) {
    return '确定要删除“$name”吗？此操作无法撤销。';
  }

  @override
  String get personaDeleteConfirm => '删除';

  @override
  String get personaDeletedToast => '人格已删除';

  @override
  String get personaCreatedToast => '人格已创建';

  @override
  String personaCreateFailedToast(String error) {
    return '创建人格失败：$error';
  }

  @override
  String get personaChangeAvatar => '更换头像';

  @override
  String get personaRemoveAvatar => '移除头像';

  @override
  String get personaUploadAvatar => '上传头像';

  @override
  String get personaTagsLabel => '人格标签';

  @override
  String get personaTagPrefixLabel => '前缀';

  @override
  String get personaTagSuffixLabel => '后缀';

  @override
  String get personaVisibilityLabel => '可见性';

  @override
  String get personaVisibilityUnlisted => '未列出';

  @override
  String get personaVisibilityPublic => '公开';

  @override
  String get personaVisibilityPrivate => '私密';

  @override
  String get personaNameRequired => '请输入人格显示名称';

  @override
  String get personaNameTooLong => '人格显示名称不能超过 100 个字符';

  @override
  String get personaTagPrefixTooLong => '人格标签前缀不能超过 32 个字符';

  @override
  String get personaTagSuffixTooLong => '人格标签后缀不能超过 32 个字符';

  @override
  String personaTagCollisionError(String tag, String name) {
    return '标签“$tag”已被“$name”使用。';
  }

  @override
  String get chatInsertTimestamp => '插入时间戳';

  @override
  String get chatAttachmentSendVoiceMessage => '发送语音消息';

  @override
  String get timestampPickerTitle => '插入时间戳';

  @override
  String get timestampPickerInsert => '插入';

  @override
  String get timestampCopied => '时间戳已复制';

  @override
  String get timestampPickerTimeLabel => '时间';

  @override
  String get timestampPickerDateLabel => '日期';

  @override
  String get timestampPickerTimeSectionLabel => '时间';

  @override
  String get timestampPickerTimezoneLabel => '时区';

  @override
  String get timestampPickerFormatPreviewLabel => '格式预览';

  @override
  String get timestampPickerNlpPlaceholder => '例如：明天下午3点，2小时后，现在';

  @override
  String get timestampPickerSearchTimezones => '搜索时区...';

  @override
  String get userProfileTimezoneSettingLabel => '时区';

  @override
  String get userProfileTimezoneSettingDescription => '用于在个人资料中显示您的当地时间。';

  @override
  String get userProfileTimezoneNone => '无';

  @override
  String get chatReactAs => '回应身份...';

  @override
  String get emojiCopy => '复制表情';

  @override
  String get emojiCopyLink => '复制链接';

  @override
  String get emojiPin => '置顶表情';

  @override
  String get emojiUnpin => '取消置顶表情';

  @override
  String get emojiPinForPersona => '为此人格置顶';

  @override
  String get emojiUnpinForPersona => '取消此人格的置顶';

  @override
  String get personaSignatureEmojisLabel => '专属表情符号';

  @override
  String get personaSignatureEmojisDescription =>
      '使用专属表情符号回应时，无论当前活跃角色是谁，都将始终以此角色身份回应。';

  @override
  String get personaAddSignatureEmoji => '添加表情符号';

  @override
  String get personaSignatureEmojiAlreadyAdded => '此表情符号已添加为专属表情符号';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return '专属表情符号已被角色“$name”使用';
  }

  @override
  String get personaRemoveSignatureEmoji => '移除专属表情符号';

  @override
  String get signalBarLabel => '信号栏';

  @override
  String get signalBarShow => '显示信号栏';

  @override
  String get signalBarHide => '隐藏信号栏';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label：$names';
  }

  @override
  String get signalBarNobody => '还没有人开启此信号';

  @override
  String get signalBarReset => '为所有人重置信号';

  @override
  String signalBarTurnOff(String name) {
    return '关闭 $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return '默认实例请使用 $domain，或输入其他实例的准确 URL。';
  }

  @override
  String get instanceResetToDefault => '重置为默认实例';

  @override
  String get personaScopeTitle => '人格适用范围';

  @override
  String get personaScopeGlobal => '所有地方';

  @override
  String get personaScopeGlobalDescription => '所有频道使用同一个人格。';

  @override
  String get personaScopeChannel => '每个频道';

  @override
  String get personaScopeChannelDescription => '每个频道保留各自的人格。新频道以你的账户开始。';

  @override
  String get personaPickerChannelOnly => '仅限此频道';

  @override
  String get personaProfilePrivate => '此人格的个人资料为私密。';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return '图片文件过大。请选择小于 $maxSize 的文件。';
  }

  @override
  String get gifPickerSearchKlipyBrand => '搜索 KLIPY';

  @override
  String get appUpdateDownloadFailed => '下载更新失败';

  @override
  String get appUpdateInstallFailed => '安装更新失败';

  @override
  String get personaChangeMessageFailed => '更改消息的人格失败';

  @override
  String get personaActiveCleared => '已清除活跃人格';

  @override
  String get klipyPoweredBy => '由 KLIPY 提供支持';

  @override
  String personaTagPairDuplicate(String pattern) {
    return '此人格上存在重复的标签对“$pattern”';
  }

  @override
  String personaAddTagPair(int count) {
    return '添加标签对（$count/5）';
  }

  @override
  String get personaTagExampleText => '文本';

  @override
  String get personaPreviewNameFallback => '用户';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne 意外关闭。分享匿名的崩溃和错误数据可以帮助我们更快地修复问题。';

  @override
  String get crashReportingSectionDescription =>
      '分享崩溃和性能数据，帮助修复 Tyne 中的错误。此选项默认关闭。';

  @override
  String get crashReportingDescription =>
      '即使你登录的是其他实例，报告也会发送到 Tyne 自己的错误跟踪系统。报告不包含实例名称、ID 或消息内容。';

  @override
  String get instanceOfflineTitle => 'Tyne 已离线！';

  @override
  String get instanceOfflineBody => '我们正在调查。';

  @override
  String get instanceStatusSignalLink => '加入我们的 Signal 群聊获取最新消息';

  @override
  String get convertEmoticonsLabel => '将颜文字转换为表情';

  @override
  String guildCommandFailed(String name, String detail) {
    return '无法运行 /$name：$detail';
  }

  @override
  String get guildCommandBroken => '它的脚本有问题。';

  @override
  String guildCommandOneLine(String name) {
    return '/$name 后输入的内容必须在一行之内。';
  }

  @override
  String get permissionCreateCommands => '创建命令';

  @override
  String get permissionManageCommands => '管理命令';

  @override
  String get permissionUseExternalCommands => '使用外部命令';

  @override
  String get permissionCreateCommandsDescription => '为此社区创建命令，并编辑或删除自己的命令。';

  @override
  String get permissionManageCommandsDescription => '编辑或删除此社区中任何人的命令。';

  @override
  String get permissionUseExternalCommandsDescription => '使用其他社区的命令。';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      '在此频道中使用其他社区的命令。';

  @override
  String get guildSettingsCategoryMessageTools => '消息工具';

  @override
  String get guildSettingsCommands => '命令';

  @override
  String get guildCommandsLoadFailed => '无法加载命令。';

  @override
  String get guildCommandsSubtitle => '成员输入 /name 即可发布的消息。';

  @override
  String get guildCommandsSlots => '命令槽位';

  @override
  String get guildCommandsNew => '新建命令';

  @override
  String get guildCommandsSearch => '搜索命令';

  @override
  String get guildCommandsEmptyTitle => '没有命令';

  @override
  String get guildCommandsEmptyBody => '此社区还没有命令。';

  @override
  String get guildCommandsSaved => '命令已保存';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return '无法保存 /$name：$detail';
  }

  @override
  String guildCommandEdit(String name) {
    return '编辑 /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return '删除 /$name？';
  }

  @override
  String get guildCommandDeleteBody => '此操作无法撤销。由它生成的消息仍会显示是哪个命令生成的。';

  @override
  String get guildCommandDelete => '删除';

  @override
  String get guildCommandDeleteCommand => '删除命令';

  @override
  String get guildCommandSectionCommand => '命令';

  @override
  String get guildCommandName => '名称';

  @override
  String get guildCommandNameInvalid => '请使用小写字母、数字、- 和 _，最多 32 个字符。';

  @override
  String get guildCommandNameTaken => '已有其他命令或内置命令使用此名称。';

  @override
  String get guildCommandDescription => '描述';

  @override
  String get guildCommandSectionInput => '输入';

  @override
  String get guildCommandInputNone => '无';

  @override
  String get guildCommandInputOptional => '可选';

  @override
  String get guildCommandInputRequired => '必需';

  @override
  String get guildCommandHint => '提示';

  @override
  String get guildCommandMessage => '消息';

  @override
  String get guildCommandInsert => '插入：';

  @override
  String get guildCommandInsertPerson => '使用者';

  @override
  String get guildCommandInsertInput => '输入的内容';

  @override
  String get guildCommandPreview => '预览';

  @override
  String get guildCommandSampleInput => '示例输入';

  @override
  String guildCommandMadeWith(String name) {
    return '由 /$name 生成';
  }

  @override
  String guildCommandClearBox(String name) {
    return '清空消息框后即可使用 /$name';
  }

  @override
  String get guildCommandEmptyMessage => '这不会发布任何内容，因此命令会失败。';

  @override
  String get guildCommandUseScriptEditor => '使用脚本编辑器';

  @override
  String get guildCommandUseBasicEditor => '使用基础编辑器';

  @override
  String get guildCommandScript => '脚本';

  @override
  String get guildCommandRunAgain => '再次运行';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return '没有名为 $name 的标签。';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return '没有名为 $name 的过滤器。';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name 始终未闭合。';
  }

  @override
  String get guildCommandIssueTooLong => '脚本过长。';

  @override
  String get guildCommandIssueTooLarge => '脚本生成的文本过多。';

  @override
  String get guildCommandIssueTooSlow => '脚本运行时间过长。';

  @override
  String get guildCommandIssueInvalid => '无法读取这部分内容。';

  @override
  String get guildCommandIssueFailed => '这部分因错误而停止。';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return '第 $line 行，第 $column 列：$problem';
  }

  @override
  String get guildCommandReferenceTitle => '脚本参考';

  @override
  String get guildCommandReferencePerson => '使用者（提及形式）';

  @override
  String get guildCommandReferencePersonName => '使用者的名称';

  @override
  String get guildCommandReferenceTarget => '第一个被提及的人（如有）';

  @override
  String get guildCommandReferenceTargetName => '此人的名称';

  @override
  String get guildCommandReferenceChannel => '频道（提及形式）';

  @override
  String get guildCommandReferenceCommunity => '此社区的名称';

  @override
  String get guildCommandExampleRandom => '随机选择一个选项';

  @override
  String get guildCommandExampleDepends => '根据输入的内容更改消息';

  @override
  String get guildCommandExampleOneWord => '随机选择一个词';

  @override
  String get guildCommandExampleWordForNumber => '根据数字选择对应的词';

  @override
  String get guildCommandExampleOrdinal => '将数字写成 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => '完整脚本指南';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class ForkLocalizationsZhHant extends ForkLocalizationsZh {
  ForkLocalizationsZhHant() : super('zh_Hant');

  @override
  String get chatMessageChangePersona => '切換人格';

  @override
  String get chatAttachmentPanelVoice => '語音';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => '快速切換按鈕';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      '將訊息輸入框中的語音訊息按鈕替換為快速切換按鈕，以便快速導航';

  @override
  String get userSettingsCheckForUpdates => '檢查更新';

  @override
  String get userSettingsCheckingForUpdates => '正在檢查更新…';

  @override
  String get userSettingsAppUpToDate => 'Tyne 已是最新版本';

  @override
  String get userSettingsUpdateAvailableTitle => '有可用更新';

  @override
  String get userSettingsUpdateDownloadAction => '下載並安裝';

  @override
  String get userSettingsUpdateInstallAction => '安裝更新';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return '正在下載更新（$percent%）…';
  }

  @override
  String get userSettingsUpdateFailed => '檢查或下載更新失敗。';

  @override
  String get personaSelectTitle => '選擇人格';

  @override
  String get personaSettingsHeader => '人格設定';

  @override
  String get personaManageAction => '管理';

  @override
  String get personaSearchPlaceholder => '搜尋人格、標籤、代名詞...';

  @override
  String get personaModeManual => '手動';

  @override
  String get personaModeLast => '最後使用';

  @override
  String get personaModeManualDescription => '在變更之前，一律以選定的人格傳送。';

  @override
  String get personaModeLastDescription => '自動切換至上一則訊息中使用的人格。';

  @override
  String get personaRecentHeader => '最近使用的人格';

  @override
  String personaAllHeader(int count) {
    return '所有人格 ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return '搜尋結果 ($count)';
  }

  @override
  String get personaRootAccountLabel => '根帳號 (預設)';

  @override
  String get personaEmptyState => '尚未設定任何人格。請透過「管理人格」建立一個。';

  @override
  String get personaEmptySearch => '找不到符合的人格。';

  @override
  String get personaEditTitle => '編輯人格';

  @override
  String get personaCreateTitle => '建立人格';

  @override
  String get personaDisplayNameLabel => '顯示名稱';

  @override
  String get personaPronounsLabel => '代名詞';

  @override
  String get personaPronounsHint => '例如：they/them';

  @override
  String get personaBioHint => '向其他人介紹這個人格...';

  @override
  String get personaUpdatedToast => '人格已更新';

  @override
  String personaUpdateFailedToast(String error) {
    return '更新人格失敗：$error';
  }

  @override
  String get personaSectionTitle => '人格';

  @override
  String get personaDisplayNameHint => '人格名稱';

  @override
  String personaSendingAsTag(String name) {
    return '以 $name 的身分傳送 (透過標籤比對)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return '以 $name 的身分傳送 (已鎖定)';
  }

  @override
  String personaSendingAs(String name) {
    return '以 $name 的身分傳送';
  }

  @override
  String personaPostingAs(String name) {
    return '以 $name 的身分發佈';
  }

  @override
  String personaSendingAsRoot(String username) {
    return '以 @$username 的身分傳送';
  }

  @override
  String get personaMainAccount => '主帳號';

  @override
  String get personaEditPersona => '編輯人格';

  @override
  String get userSettingsNavPersonas => '人格';

  @override
  String get personaSettingsDescription => '設定您的活躍人格模式、自訂顯示標籤，並管理個人人格。';

  @override
  String get personaDisplayTagSection => '顯示標籤';

  @override
  String get personaDisplayTagDescription =>
      '顯示標籤會出現在訊息中所有人格名稱的旁邊。如果未設定顯示標籤，則會顯示您的帳號大頭貼。';

  @override
  String get personaDisplayTagLabel => '顯示標籤文字';

  @override
  String get personaDisplayTagHint => '例如：SYS';

  @override
  String get personaDisplayTagIconLabel => '顯示標籤圖示';

  @override
  String get personaUploadTagIcon => '上傳圖示';

  @override
  String get personaChangeTagIcon => '更換圖示';

  @override
  String get personaRemoveTagIcon => '移除圖示';

  @override
  String get personaChatPreviewTitle => '聊天預覽';

  @override
  String get personaChatPreviewSampleMessage => '你好！這是帶有您的顯示標籤和活躍人格的訊息外觀預覽。';

  @override
  String get personaListTitle => '已設定的人格';

  @override
  String get personaAddButton => '新增人格';

  @override
  String get personaActiveBadge => '啟用中';

  @override
  String get personaMakeActive => '設為活躍';

  @override
  String get personaDeleteTitle => '刪除人格';

  @override
  String personaDeleteMessage(String name) {
    return '確定要刪除「$name」嗎？此動作無法復原。';
  }

  @override
  String get personaDeleteConfirm => '刪除';

  @override
  String get personaDeletedToast => '人格已刪除';

  @override
  String get personaCreatedToast => '人格已建立';

  @override
  String personaCreateFailedToast(String error) {
    return '建立人格失敗：$error';
  }

  @override
  String get personaChangeAvatar => '更換大頭貼';

  @override
  String get personaRemoveAvatar => '移除大頭貼';

  @override
  String get personaUploadAvatar => '上傳大頭貼';

  @override
  String get personaTagsLabel => '人格標籤';

  @override
  String get personaTagPrefixLabel => '前綴';

  @override
  String get personaTagSuffixLabel => '後綴';

  @override
  String get personaVisibilityLabel => '能見度';

  @override
  String get personaVisibilityUnlisted => '不公開';

  @override
  String get personaVisibilityPublic => '公開';

  @override
  String get personaVisibilityPrivate => '私人';

  @override
  String get personaNameRequired => '請輸入人格顯示名稱';

  @override
  String get personaNameTooLong => '人格顯示名稱不得超過 100 個字元';

  @override
  String get personaTagPrefixTooLong => '人格標籤前綴不得超過 32 個字元';

  @override
  String get personaTagSuffixTooLong => '人格標籤後綴不得超過 32 個字元';

  @override
  String personaTagCollisionError(String tag, String name) {
    return '標籤「$tag」已被「$name」使用。';
  }

  @override
  String get chatInsertTimestamp => '插入時間戳記';

  @override
  String get chatAttachmentSendVoiceMessage => '傳送語音訊息';

  @override
  String get timestampPickerTitle => '插入時間戳記';

  @override
  String get timestampPickerInsert => '插入';

  @override
  String get timestampCopied => '已複製時間戳記';

  @override
  String get timestampPickerTimeLabel => '時間';

  @override
  String get timestampPickerDateLabel => '日期';

  @override
  String get timestampPickerTimeSectionLabel => '時間';

  @override
  String get timestampPickerTimezoneLabel => '時區';

  @override
  String get timestampPickerFormatPreviewLabel => '格式預覽';

  @override
  String get timestampPickerNlpPlaceholder => '例如：明天下午3點，2小時後，現在';

  @override
  String get timestampPickerSearchTimezones => '搜尋時區...';

  @override
  String get userProfileTimezoneSettingLabel => '時區';

  @override
  String get userProfileTimezoneSettingDescription => '用於在個人檔案中顯示您的當地時間。';

  @override
  String get userProfileTimezoneNone => '無';

  @override
  String get chatReactAs => '回應身分...';

  @override
  String get emojiCopy => '複製表情符號';

  @override
  String get emojiCopyLink => '複製連結';

  @override
  String get emojiPin => '釘選表情符號';

  @override
  String get emojiUnpin => '取消釘選表情符號';

  @override
  String get emojiPinForPersona => '為此人格釘選';

  @override
  String get emojiUnpinForPersona => '取消此人格的釘選';

  @override
  String get personaSignatureEmojisLabel => '專屬表情符號';

  @override
  String get personaSignatureEmojisDescription =>
      '使用專屬表情符號回應時，無論目前啟用的角色是誰，都會一律以此角色身分回應。';

  @override
  String get personaAddSignatureEmoji => '新增表情符號';

  @override
  String get personaSignatureEmojiAlreadyAdded => '此表情符號已新增為專屬表情符號';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return '專屬表情符號已由角色「$name」使用';
  }

  @override
  String get personaRemoveSignatureEmoji => '移除專屬表情符號';

  @override
  String get signalBarLabel => '訊號列';

  @override
  String get signalBarShow => '顯示訊號列';

  @override
  String get signalBarHide => '隱藏訊號列';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label：$names';
  }

  @override
  String get signalBarNobody => '還沒有人開啟此訊號';

  @override
  String get signalBarReset => '為所有人重設訊號';

  @override
  String signalBarTurnOff(String name) {
    return '關閉 $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return '預設執行個體請使用 $domain，或輸入其他執行個體的確切 URL。';
  }

  @override
  String get instanceResetToDefault => '重設為預設執行個體';

  @override
  String get personaScopeTitle => '人格適用範圍';

  @override
  String get personaScopeGlobal => '所有地方';

  @override
  String get personaScopeGlobalDescription => '所有頻道使用同一個人格。';

  @override
  String get personaScopeChannel => '每個頻道';

  @override
  String get personaScopeChannelDescription => '每個頻道保留各自的人格。新頻道以你的帳號開始。';

  @override
  String get personaPickerChannelOnly => '僅限此頻道';

  @override
  String get personaProfilePrivate => '此人格的個人檔案為私人。';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return '圖片檔案過大。請選擇小於 $maxSize 的檔案。';
  }

  @override
  String get gifPickerSearchKlipyBrand => '搜尋 KLIPY';

  @override
  String get appUpdateDownloadFailed => '下載更新失敗';

  @override
  String get appUpdateInstallFailed => '安裝更新失敗';

  @override
  String get personaChangeMessageFailed => '變更訊息的人格失敗';

  @override
  String get personaActiveCleared => '已清除使用中人格';

  @override
  String get klipyPoweredBy => '由 KLIPY 提供技術支援';

  @override
  String personaTagPairDuplicate(String pattern) {
    return '此人格上有重複的標籤組「$pattern」';
  }

  @override
  String personaAddTagPair(int count) {
    return '新增標籤組（$count/5）';
  }

  @override
  String get personaTagExampleText => '文字';

  @override
  String get personaPreviewNameFallback => '使用者';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne 意外關閉。分享匿名的當機與錯誤資料，可以幫助我們更快修正問題。';

  @override
  String get crashReportingSectionDescription =>
      '分享當機與效能資料，協助修正 Tyne 中的錯誤。此選項預設為關閉。';

  @override
  String get crashReportingDescription =>
      '即使你登入的是其他伺服器，報告也會傳送到 Tyne 自己的錯誤追蹤系統。報告不包含伺服器名稱、ID 或訊息內容。';

  @override
  String get instanceOfflineTitle => 'Tyne 已離線！';

  @override
  String get instanceOfflineBody => '我們正在調查。';

  @override
  String get instanceStatusSignalLink => '加入我們的 Signal 群組取得最新消息';

  @override
  String get convertEmoticonsLabel => '將文字笑臉轉換為表情符號';

  @override
  String guildCommandFailed(String name, String detail) {
    return '無法執行 /$name：$detail';
  }

  @override
  String get guildCommandBroken => '它的腳本有問題。';

  @override
  String guildCommandOneLine(String name) {
    return '/$name 後輸入的內容必須在一行之內。';
  }

  @override
  String get permissionCreateCommands => '建立指令';

  @override
  String get permissionManageCommands => '管理指令';

  @override
  String get permissionUseExternalCommands => '使用外部指令';

  @override
  String get permissionCreateCommandsDescription => '為此社群建立指令，並編輯或刪除自己的指令。';

  @override
  String get permissionManageCommandsDescription => '編輯或刪除此社群中任何人的指令。';

  @override
  String get permissionUseExternalCommandsDescription => '使用其他社群的指令。';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      '在此頻道中使用其他社群的指令。';

  @override
  String get guildSettingsCategoryMessageTools => '訊息工具';

  @override
  String get guildSettingsCommands => '指令';

  @override
  String get guildCommandsLoadFailed => '無法載入指令。';

  @override
  String get guildCommandsSubtitle => '成員輸入 /name 即可發佈的訊息。';

  @override
  String get guildCommandsSlots => '指令欄位';

  @override
  String get guildCommandsNew => '新增指令';

  @override
  String get guildCommandsSearch => '搜尋指令';

  @override
  String get guildCommandsEmptyTitle => '沒有指令';

  @override
  String get guildCommandsEmptyBody => '此社群還沒有指令。';

  @override
  String get guildCommandsSaved => '指令已儲存';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return '無法儲存 /$name：$detail';
  }

  @override
  String guildCommandEdit(String name) {
    return '編輯 /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return '要刪除 /$name 嗎？';
  }

  @override
  String get guildCommandDeleteBody => '此操作無法復原。由它產生的訊息仍會顯示是哪個指令產生的。';

  @override
  String get guildCommandDelete => '刪除';

  @override
  String get guildCommandDeleteCommand => '刪除指令';

  @override
  String get guildCommandSectionCommand => '指令';

  @override
  String get guildCommandName => '名稱';

  @override
  String get guildCommandNameInvalid => '請使用小寫字母、數字、- 和 _，最多 32 個字元。';

  @override
  String get guildCommandNameTaken => '已有其他指令或內建指令使用此名稱。';

  @override
  String get guildCommandDescription => '說明';

  @override
  String get guildCommandSectionInput => '輸入';

  @override
  String get guildCommandInputNone => '無';

  @override
  String get guildCommandInputOptional => '選填';

  @override
  String get guildCommandInputRequired => '必要';

  @override
  String get guildCommandHint => '提示';

  @override
  String get guildCommandMessage => '訊息';

  @override
  String get guildCommandInsert => '插入：';

  @override
  String get guildCommandInsertPerson => '使用者';

  @override
  String get guildCommandInsertInput => '輸入的內容';

  @override
  String get guildCommandPreview => '預覽';

  @override
  String get guildCommandSampleInput => '範例輸入';

  @override
  String guildCommandMadeWith(String name) {
    return '由 /$name 產生';
  }

  @override
  String guildCommandClearBox(String name) {
    return '清空訊息框後即可使用 /$name';
  }

  @override
  String get guildCommandEmptyMessage => '這不會發佈任何內容，因此指令會失敗。';

  @override
  String get guildCommandUseScriptEditor => '使用腳本編輯器';

  @override
  String get guildCommandUseBasicEditor => '使用基本編輯器';

  @override
  String get guildCommandScript => '腳本';

  @override
  String get guildCommandRunAgain => '再次執行';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return '沒有名為 $name 的標籤。';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return '沒有名為 $name 的篩選器。';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name 始終未閉合。';
  }

  @override
  String get guildCommandIssueTooLong => '腳本過長。';

  @override
  String get guildCommandIssueTooLarge => '腳本產生的文字過多。';

  @override
  String get guildCommandIssueTooSlow => '腳本執行時間過長。';

  @override
  String get guildCommandIssueInvalid => '無法讀取這部分內容。';

  @override
  String get guildCommandIssueFailed => '這部分因錯誤而停止。';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return '第 $line 行，第 $column 欄：$problem';
  }

  @override
  String get guildCommandReferenceTitle => '腳本參考資料';

  @override
  String get guildCommandReferencePerson => '使用者（提及形式）';

  @override
  String get guildCommandReferencePersonName => '使用者的名稱';

  @override
  String get guildCommandReferenceTarget => '第一個被提及的人（如有）';

  @override
  String get guildCommandReferenceTargetName => '此人的名稱';

  @override
  String get guildCommandReferenceChannel => '頻道（提及形式）';

  @override
  String get guildCommandReferenceCommunity => '此社群的名稱';

  @override
  String get guildCommandExampleRandom => '隨機選擇一個選項';

  @override
  String get guildCommandExampleDepends => '根據輸入的內容變更訊息';

  @override
  String get guildCommandExampleOneWord => '隨機選擇一個字詞';

  @override
  String get guildCommandExampleWordForNumber => '根據數字選擇對應的字詞';

  @override
  String get guildCommandExampleOrdinal => '將數字寫成 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => '完整腳本指南';
}
