// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class ForkLocalizationsJa extends ForkLocalizations {
  ForkLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get chatMessageChangePersona => 'ペルソナを変更';

  @override
  String get chatAttachmentPanelVoice => 'ボイス';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'クイックスイッチャーボタン';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'メッセージ入力欄のボイスメッセージボタンをクイックスイッチャーに置き換えて素早く移動する';

  @override
  String get userSettingsCheckForUpdates => 'アップデートを確認';

  @override
  String get userSettingsCheckingForUpdates => 'アップデートを確認中…';

  @override
  String get userSettingsAppUpToDate => 'Tyne は最新です';

  @override
  String get userSettingsUpdateAvailableTitle => 'アップデートが利用可能です';

  @override
  String get userSettingsUpdateDownloadAction => 'ダウンロードしてインストール';

  @override
  String get userSettingsUpdateInstallAction => 'アップデートをインストール';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'アップデートをダウンロード中（$percent%）…';
  }

  @override
  String get userSettingsUpdateFailed => 'アップデートの確認またはダウンロードに失敗しました。';

  @override
  String get personaSelectTitle => 'ペルソナを選択';

  @override
  String get personaSettingsHeader => 'ペルソナ設定';

  @override
  String get personaManageAction => '管理';

  @override
  String get personaSearchPlaceholder => 'ペルソナ、タグ、代名詞を検索...';

  @override
  String get personaModeManual => '手動';

  @override
  String get personaModeLast => '最終使用';

  @override
  String get personaModeManualDescription => '変更されるまで、常に選択したペルソナとして送信されます。';

  @override
  String get personaModeLastDescription => '前回のメッセージで使用したペルソナに自動的に切り替えます。';

  @override
  String get personaRecentHeader => '最近のペルソナ';

  @override
  String personaAllHeader(int count) {
    return 'すべてのペルソナ ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return '検索結果 ($count)';
  }

  @override
  String get personaRootAccountLabel => 'ルートアカウント (デフォルト)';

  @override
  String get personaEmptyState => 'ペルソナがまだ設定されていません。「ペルソナを管理」で作成してください。';

  @override
  String get personaEmptySearch => '一致するペルソナが見つかりません。';

  @override
  String get personaEditTitle => 'ペルソナを編集';

  @override
  String get personaCreateTitle => 'ペルソナを作成';

  @override
  String get personaDisplayNameLabel => '表示名';

  @override
  String get personaPronounsLabel => '代名詞';

  @override
  String get personaPronounsHint => '例: they/them';

  @override
  String get personaBioHint => 'このペルソナについて紹介...';

  @override
  String get personaUpdatedToast => 'ペルソナを更新しました';

  @override
  String personaUpdateFailedToast(String error) {
    return 'ペルソナの更新に失敗しました: $error';
  }

  @override
  String get personaSectionTitle => 'ペルソナ';

  @override
  String get personaDisplayNameHint => 'ペルソナ名';

  @override
  String personaSendingAsTag(String name) {
    return '$name として送信中 (タグで一致)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return '$name として送信中 (固定)';
  }

  @override
  String personaSendingAs(String name) {
    return '$name として送信中';
  }

  @override
  String personaPostingAs(String name) {
    return '$name として投稿中';
  }

  @override
  String personaSendingAsRoot(String username) {
    return '@$username として送信中';
  }

  @override
  String get personaMainAccount => 'メインアカウント';

  @override
  String get personaEditPersona => 'ペルソナを編集';

  @override
  String get userSettingsNavPersonas => 'ペルソナ';

  @override
  String get personaSettingsDescription =>
      'アクティブペルソナモードやカスタム表示タグを設定し、個別のペルソナを管理します。';

  @override
  String get personaDisplayTagSection => '表示タグ';

  @override
  String get personaDisplayTagDescription =>
      '表示タグはメッセージ内のすべてのペルソナ名の横に表示されます。表示タグが設定されていない場合は、アカウントのプロフィール画像が表示されます。';

  @override
  String get personaDisplayTagLabel => '表示タグのテキスト';

  @override
  String get personaDisplayTagHint => '例: SYS';

  @override
  String get personaDisplayTagIconLabel => '表示タグのアイコン';

  @override
  String get personaUploadTagIcon => 'アイコンをアップロード';

  @override
  String get personaChangeTagIcon => 'アイコンを変更';

  @override
  String get personaRemoveTagIcon => 'アイコンを削除';

  @override
  String get personaChatPreviewTitle => 'チャットプレビュー';

  @override
  String get personaChatPreviewSampleMessage =>
      'こんにちは！これは表示タグとアクティブなペルソナを使用したメッセージのプレビューです。';

  @override
  String get personaListTitle => '設定済みのペルソナ';

  @override
  String get personaAddButton => 'ペルソナを追加';

  @override
  String get personaActiveBadge => '有効';

  @override
  String get personaMakeActive => 'アクティブに設定';

  @override
  String get personaDeleteTitle => 'ペルソナを削除';

  @override
  String personaDeleteMessage(String name) {
    return '「$name」を削除してもよろしいですか？この操作は元に戻せません。';
  }

  @override
  String get personaDeleteConfirm => '削除';

  @override
  String get personaDeletedToast => 'ペルソナを削除しました';

  @override
  String get personaCreatedToast => 'ペルソナを作成しました';

  @override
  String personaCreateFailedToast(String error) {
    return 'ペルソナの作成に失敗しました: $error';
  }

  @override
  String get personaChangeAvatar => 'アバターを変更';

  @override
  String get personaRemoveAvatar => 'アバターを削除';

  @override
  String get personaUploadAvatar => 'アバターをアップロード';

  @override
  String get personaTagsLabel => 'ペルソナタグ';

  @override
  String get personaTagPrefixLabel => 'プレフィックス';

  @override
  String get personaTagSuffixLabel => 'サフィックス';

  @override
  String get personaVisibilityLabel => '公開設定';

  @override
  String get personaVisibilityUnlisted => '限定公開';

  @override
  String get personaVisibilityPublic => '公開';

  @override
  String get personaVisibilityPrivate => '非公開';

  @override
  String get personaNameRequired => 'ペルソナの表示名を入力してください';

  @override
  String get personaNameTooLong => 'ペルソナの表示名は100文字以内で入力してください';

  @override
  String get personaTagPrefixTooLong => 'ペルソナタグの接頭辞は32文字以内で入力してください';

  @override
  String get personaTagSuffixTooLong => 'ペルソナタグの接尾辞は32文字以内で入力してください';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'タグ「$tag」は既に「$name」によって使用されています。';
  }

  @override
  String get chatInsertTimestamp => 'タイムスタンプを挿入';

  @override
  String get chatAttachmentSendVoiceMessage => 'ボイスメッセージを送信';

  @override
  String get timestampPickerTitle => 'タイムスタンプを挿入';

  @override
  String get timestampPickerInsert => '挿入';

  @override
  String get timestampCopied => 'タイムスタンプをコピーしました';

  @override
  String get timestampPickerTimeLabel => '時間';

  @override
  String get timestampPickerDateLabel => '日付';

  @override
  String get timestampPickerTimeSectionLabel => '時刻';

  @override
  String get timestampPickerTimezoneLabel => 'タイムゾーン';

  @override
  String get timestampPickerFormatPreviewLabel => '形式プレビュー';

  @override
  String get timestampPickerNlpPlaceholder => '例: 明日の午後3時、2時間後、今';

  @override
  String get timestampPickerSearchTimezones => 'タイムゾーンを検索...';

  @override
  String get userProfileTimezoneSettingLabel => 'タイムゾーン';

  @override
  String get userProfileTimezoneSettingDescription =>
      'プロフィールに現地時間を表示するために使用されます。';

  @override
  String get userProfileTimezoneNone => 'なし';

  @override
  String get chatReactAs => '別名でリアクション...';

  @override
  String get emojiCopy => '絵文字をコピー';

  @override
  String get emojiCopyLink => 'リンクをコピー';

  @override
  String get emojiPin => '絵文字をピン留め';

  @override
  String get emojiUnpin => '絵文字のピン留めを解除';

  @override
  String get emojiPinForPersona => 'このペルソナ用にピン留め';

  @override
  String get emojiUnpinForPersona => 'このペルソナ用のピン留めを解除';

  @override
  String get personaSignatureEmojisLabel => 'シグネチャー絵文字';

  @override
  String get personaSignatureEmojisDescription =>
      'シグネチャー絵文字でリアクションすると、アクティブなペルソナに関係なく、常にこのペルソナとしてリアクションします。';

  @override
  String get personaAddSignatureEmoji => '絵文字を追加';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'この絵文字はすでにシグネチャー絵文字として追加されています';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'シグネチャー絵文字はすでにペルソナ「$name」で使用されています';
  }

  @override
  String get personaRemoveSignatureEmoji => 'シグネチャー絵文字を削除';

  @override
  String get signalBarLabel => 'シグナルバー';

  @override
  String get signalBarShow => 'シグナルバーを表示';

  @override
  String get signalBarHide => 'シグナルバーを隠す';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label：$names';
  }

  @override
  String get signalBarNobody => 'このシグナルをオンにしている人はいません';

  @override
  String get signalBarReset => '全員のシグナルをリセット';

  @override
  String signalBarTurnOff(String name) {
    return '$name をオフにする';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'デフォルトのインスタンスには $domain を使用するか、別のインスタンスの正確なURLを入力してください。';
  }

  @override
  String get instanceResetToDefault => 'デフォルトのインスタンスにリセット';

  @override
  String get personaScopeTitle => 'ペルソナの適用範囲';

  @override
  String get personaScopeGlobal => 'すべての場所';

  @override
  String get personaScopeGlobalDescription => 'すべてのチャンネルで1つのペルソナ。';

  @override
  String get personaScopeChannel => 'チャンネルごと';

  @override
  String get personaScopeChannelDescription =>
      '各チャンネルがそれぞれのペルソナを保持します。新しいチャンネルはアカウントから始まります。';

  @override
  String get personaPickerChannelOnly => 'このチャンネルのみ';

  @override
  String get personaProfilePrivate => 'このペルソナのプロフィールは非公開です。';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return '画像ファイルが大きすぎます。$maxSize未満のファイルを選択してください。';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'KLIPYを検索';

  @override
  String get appUpdateDownloadFailed => 'アップデートをダウンロードできませんでした';

  @override
  String get appUpdateInstallFailed => 'アップデートをインストールできませんでした';

  @override
  String get personaChangeMessageFailed => 'メッセージのペルソナを変更できませんでした';

  @override
  String get personaActiveCleared => 'アクティブなペルソナを解除しました';

  @override
  String get klipyPoweredBy => 'KLIPY 提供';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'このペルソナでタグのペア「$pattern」が重複しています';
  }

  @override
  String personaAddTagPair(int count) {
    return 'タグのペアを追加 ($count/5)';
  }

  @override
  String get personaTagExampleText => 'テキスト';

  @override
  String get personaPreviewNameFallback => 'ユーザー';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne が予期せず終了しました。匿名のクラッシュデータとエラーデータを共有していただくと、問題をより早く修正できます。';

  @override
  String get crashReportingSectionDescription =>
      'クラッシュとパフォーマンスのデータを共有して、Tyne のバグ修正にご協力ください。デフォルトではオフです。';

  @override
  String get crashReportingDescription =>
      'レポートは、別のインスタンスにサインインしている場合でも、Tyne 独自のエラートラッカーに送信されます。インスタンス名、ID、メッセージの内容は含まれません。';

  @override
  String get instanceOfflineTitle => 'Tyne はオフラインです！';

  @override
  String get instanceOfflineBody => '現在調査中です。';

  @override
  String get instanceStatusSignalLink => '最新情報は Signal のチャットでお知らせします';

  @override
  String get convertEmoticonsLabel => '顔文字を絵文字に変換する';

  @override
  String guildCommandFailed(String name, String detail) {
    return '/$name を実行できませんでした: $detail';
  }

  @override
  String get guildCommandBroken => 'スクリプトに問題があります。';

  @override
  String guildCommandOneLine(String name) {
    return '/$name の後に入力する内容は1行に収めてください。';
  }

  @override
  String get permissionCreateCommands => 'コマンドを作成';

  @override
  String get permissionManageCommands => 'コマンドを管理';

  @override
  String get permissionUseExternalCommands => '外部のコマンドを使用';

  @override
  String get permissionCreateCommandsDescription =>
      'このコミュニティのコマンドを作成し、自分のコマンドを編集・削除できます。';

  @override
  String get permissionManageCommandsDescription =>
      'このコミュニティの誰のコマンドでも編集・削除できます。';

  @override
  String get permissionUseExternalCommandsDescription =>
      '他のコミュニティのコマンドを使用できます。';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'このチャンネルで他のコミュニティのコマンドを使用できます。';

  @override
  String get guildSettingsCategoryMessageTools => 'メッセージツール';

  @override
  String get guildSettingsCommands => 'コマンド';

  @override
  String get guildCommandsLoadFailed => 'コマンドを読み込めませんでした。';

  @override
  String get guildCommandsSubtitle => 'メンバーが /name と入力して投稿できるメッセージです。';

  @override
  String get guildCommandsSlots => 'コマンドスロット';

  @override
  String get guildCommandsNew => '新しいコマンド';

  @override
  String get guildCommandsSearch => 'コマンドを検索';

  @override
  String get guildCommandsEmptyTitle => 'コマンドがありません';

  @override
  String get guildCommandsEmptyBody => 'このコミュニティにはまだコマンドがありません。';

  @override
  String get guildCommandsSaved => 'コマンドを保存しました';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return '/$name を保存できませんでした: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return '/$name を編集';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return '/$name を削除しますか？';
  }

  @override
  String get guildCommandDeleteBody =>
      'この操作は取り消せません。このコマンドで作成されたメッセージには、引き続き作成元のコマンドが表示されます。';

  @override
  String get guildCommandDelete => '削除';

  @override
  String get guildCommandDeleteCommand => 'コマンドを削除';

  @override
  String get guildCommandSectionCommand => 'コマンド';

  @override
  String get guildCommandName => '名前';

  @override
  String get guildCommandNameInvalid => '小文字、数字、-、_ を使い、32文字以内にしてください。';

  @override
  String get guildCommandNameTaken => 'この名前は、別のコマンドまたは組み込みコマンドですでに使われています。';

  @override
  String get guildCommandDescription => '説明';

  @override
  String get guildCommandSectionInput => '入力';

  @override
  String get guildCommandInputNone => 'なし';

  @override
  String get guildCommandInputOptional => '任意';

  @override
  String get guildCommandInputRequired => '必須';

  @override
  String get guildCommandHint => 'ヒント';

  @override
  String get guildCommandMessage => 'メッセージ';

  @override
  String get guildCommandInsert => '挿入:';

  @override
  String get guildCommandInsertPerson => '使った人';

  @override
  String get guildCommandInsertInput => '入力された内容';

  @override
  String get guildCommandPreview => 'プレビュー';

  @override
  String get guildCommandSampleInput => '入力例';

  @override
  String guildCommandMadeWith(String name) {
    return '/$name で作成';
  }

  @override
  String guildCommandClearBox(String name) {
    return '/$name を使うには、メッセージ欄を空にしてください';
  }

  @override
  String get guildCommandEmptyMessage => '何も投稿されないため、コマンドは失敗します。';

  @override
  String get guildCommandUseScriptEditor => 'スクリプトエディターを使う';

  @override
  String get guildCommandUseBasicEditor => '基本エディターを使う';

  @override
  String get guildCommandScript => 'スクリプト';

  @override
  String get guildCommandRunAgain => 'もう一度実行';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return '$name というタグはありません。';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return '$name というフィルターはありません。';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name が閉じられていません。';
  }

  @override
  String get guildCommandIssueTooLong => 'スクリプトが長すぎます。';

  @override
  String get guildCommandIssueTooLarge => 'スクリプトが生成するテキストが多すぎます。';

  @override
  String get guildCommandIssueTooSlow => 'スクリプトの実行に時間がかかりすぎました。';

  @override
  String get guildCommandIssueInvalid => 'この部分を読み取れません。';

  @override
  String get guildCommandIssueFailed => 'この部分はエラーで停止しました。';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return '$line 行目、$column 列目: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'スクリプトリファレンス';

  @override
  String get guildCommandReferencePerson => '使った人のメンション';

  @override
  String get guildCommandReferencePersonName => '使った人の名前';

  @override
  String get guildCommandReferenceTarget => 'メンションされた最初の人（いる場合）';

  @override
  String get guildCommandReferenceTargetName => 'その人の名前';

  @override
  String get guildCommandReferenceChannel => 'チャンネルのメンション';

  @override
  String get guildCommandReferenceCommunity => 'このコミュニティの名前';

  @override
  String get guildCommandExampleRandom => '選択肢を1つランダムに選ぶ';

  @override
  String get guildCommandExampleDepends => '入力された内容に応じてメッセージを変える';

  @override
  String get guildCommandExampleOneWord => '単語を1つランダムに選ぶ';

  @override
  String get guildCommandExampleWordForNumber => '数に合わせて単語を選ぶ';

  @override
  String get guildCommandExampleOrdinal => '数を 1st, 2nd, 3rd の形で書く';

  @override
  String get guildCommandFullGuide => 'スクリプトの完全ガイド';

  @override
  String get guildCommandCounters => 'カウンター';

  @override
  String get guildCommandCounterAdd => 'カウンターを追加';

  @override
  String get guildCommandCounterSeparately => '次ごとに別々に数える:';

  @override
  String get guildCommandCounterPersonMentioned => 'メンションされた人';

  @override
  String get guildCommandCounterChannel => 'チャンネル';

  @override
  String get guildCommandCounterPersonas => 'ペルソナを別々に数える';

  @override
  String get guildCommandCounterRemove => 'カウンターを削除';

  @override
  String get guildCommandCounterReset => 'カウントをリセット';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return '$name のカウントをリセットしますか?元に戻すことはできません。';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      '小文字の英字、数字、_ を使い、英字で始めてください。スクリプトで既に使われている名前は使えません。';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'スクリプトでは $variable として使います。実行のたびに先に1増えるので、最初の実行では1になります。';
  }
}
