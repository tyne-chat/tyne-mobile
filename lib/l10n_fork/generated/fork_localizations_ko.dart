// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class ForkLocalizationsKo extends ForkLocalizations {
  ForkLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get chatMessageChangePersona => '페르소나 변경';

  @override
  String get chatAttachmentPanelVoice => '음성';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => '빠른 전환 버튼';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      '입력창의 음성 메시지 버튼을 빠른 전환 버튼으로 교체하여 편리하게 이동';

  @override
  String get userSettingsCheckForUpdates => '업데이트 확인';

  @override
  String get userSettingsCheckingForUpdates => '업데이트 확인 중…';

  @override
  String get userSettingsAppUpToDate => 'Tyne가 최신 상태입니다';

  @override
  String get userSettingsUpdateAvailableTitle => '업데이트 사용 가능';

  @override
  String get userSettingsUpdateDownloadAction => '다운로드 및 설치';

  @override
  String get userSettingsUpdateInstallAction => '업데이트 설치';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return '업데이트 다운로드 중($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed => '업데이트 확인 또는 다운로드에 실패했습니다.';

  @override
  String get personaSelectTitle => '페르소나 선택';

  @override
  String get personaSettingsHeader => '페르소나 설정';

  @override
  String get personaManageAction => '관리';

  @override
  String get personaSearchPlaceholder => '페르소나, 태그, 대명사 검색...';

  @override
  String get personaModeManual => '수동';

  @override
  String get personaModeLast => '최근 사용됨';

  @override
  String get personaModeManualDescription => '변경할 때까지 항상 선택한 페르소나로 전송됩니다.';

  @override
  String get personaModeLastDescription => '마지막 메시지에서 사용한 페르소나로 자동 전환됩니다.';

  @override
  String get personaRecentHeader => '최근 페르소나';

  @override
  String personaAllHeader(int count) {
    return '모든 페르소나 ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return '검색 결과 ($count)';
  }

  @override
  String get personaRootAccountLabel => '기본 계정 (기본값)';

  @override
  String get personaEmptyState => '아직 구성된 페르소나가 없습니다. 페르소나 관리에서 생성하세요.';

  @override
  String get personaEmptySearch => '일치하는 페르소나를 찾을 수 없습니다.';

  @override
  String get personaEditTitle => '페르소나 편집';

  @override
  String get personaCreateTitle => '페르소나 생성';

  @override
  String get personaDisplayNameLabel => '표시 이름';

  @override
  String get personaPronounsLabel => '대명사';

  @override
  String get personaPronounsHint => '예: they/them';

  @override
  String get personaBioHint => '이 페르소나에 대해 알려주세요...';

  @override
  String get personaUpdatedToast => '페르소나 업데이트됨';

  @override
  String personaUpdateFailedToast(String error) {
    return '페르소나 업데이트 실패: $error';
  }

  @override
  String get personaSectionTitle => '페르소나';

  @override
  String get personaDisplayNameHint => '페르소나 이름';

  @override
  String personaSendingAsTag(String name) {
    return '$name 님으로 보내는 중 (태그로 일치)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return '$name 님으로 보내는 중 (고정됨)';
  }

  @override
  String personaSendingAs(String name) {
    return '$name 님으로 보내는 중';
  }

  @override
  String personaPostingAs(String name) {
    return '$name 님으로 게시하는 중';
  }

  @override
  String personaSendingAsRoot(String username) {
    return '@$username 님으로 보내는 중';
  }

  @override
  String get personaMainAccount => '기본 계정';

  @override
  String get personaEditPersona => '페르소나 편집';

  @override
  String get userSettingsNavPersonas => '페르소나';

  @override
  String get personaSettingsDescription =>
      '활성 페르소나 모드와 사용자 지정 표시 태그를 구성하고 개별 페르소나를 관리하세요.';

  @override
  String get personaDisplayTagSection => '표시 태그';

  @override
  String get personaDisplayTagDescription =>
      '메시지의 모든 페르소나 이름 옆에 표시 태그가 나타납니다. 표시 태그를 설정하지 않으면 계정 프로필 사진이 표시됩니다.';

  @override
  String get personaDisplayTagLabel => '표시 태그 텍스트';

  @override
  String get personaDisplayTagHint => '예: SYS';

  @override
  String get personaDisplayTagIconLabel => '표시 태그 아이콘';

  @override
  String get personaUploadTagIcon => '아이콘 업로드';

  @override
  String get personaChangeTagIcon => '아이콘 변경';

  @override
  String get personaRemoveTagIcon => '아이콘 삭제';

  @override
  String get personaChatPreviewTitle => '채팅 미리보기';

  @override
  String get personaChatPreviewSampleMessage =>
      '안녕하세요! 표시 태그와 활성 페르소나가 적용된 메시지가 어떻게 표시되는지 보여주는 미리보기입니다.';

  @override
  String get personaListTitle => '구성된 페르소나';

  @override
  String get personaAddButton => '페르소나 추가';

  @override
  String get personaActiveBadge => '활성';

  @override
  String get personaMakeActive => '활성 상태로 설정';

  @override
  String get personaDeleteTitle => '페르소나 삭제';

  @override
  String personaDeleteMessage(String name) {
    return '\"$name\"을(를) 삭제하시겠어요? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get personaDeleteConfirm => '삭제';

  @override
  String get personaDeletedToast => '페르소나 삭제됨';

  @override
  String get personaCreatedToast => '페르소나 생성됨';

  @override
  String personaCreateFailedToast(String error) {
    return '페르소나 생성 실패: $error';
  }

  @override
  String get personaChangeAvatar => '아바타 변경';

  @override
  String get personaRemoveAvatar => '아바타 삭제';

  @override
  String get personaUploadAvatar => '아바타 업로드';

  @override
  String get personaTagsLabel => '페르소나 태그';

  @override
  String get personaAutoTagDisabledLabel => '이 페르소나의 태그를 인식하지 않기';

  @override
  String get personaAutoTagDisabledDescription =>
      '이 태그를 입력해도 이 페르소나로 전환되지 않습니다. 태그는 입력한 그대로 전송됩니다.';

  @override
  String get personaTagPrefixLabel => '접두사';

  @override
  String get personaTagSuffixLabel => '접미사';

  @override
  String get personaVisibilityLabel => '공개 범위';

  @override
  String get personaVisibilityUnlisted => '일부 공개';

  @override
  String get personaVisibilityPublic => '공개';

  @override
  String get personaVisibilityPrivate => '비공개';

  @override
  String get personaNameRequired => '페르소나 표시 이름을 입력해 주세요';

  @override
  String get personaNameTooLong => '페르소나 표시 이름은 100자 이하여야 합니다';

  @override
  String get personaTagPrefixTooLong => '페르소나 태그 접두사는 32자 이하여야 합니다';

  @override
  String get personaTagSuffixTooLong => '페르소나 태그 접미사는 32자 이하여야 합니다';

  @override
  String personaTagCollisionError(String tag, String name) {
    return '\'$tag\' 태그는 이미 \'$name\'에서 사용 중입니다.';
  }

  @override
  String get chatInsertTimestamp => '타임스탬프 삽입';

  @override
  String get chatAttachmentSendVoiceMessage => '음성 메시지 보내기';

  @override
  String get timestampPickerTitle => '타임스탬프 삽입';

  @override
  String get timestampPickerInsert => '삽입';

  @override
  String get timestampCopied => '타임스탬프가 복사되었습니다';

  @override
  String get timestampPickerTimeLabel => '시간';

  @override
  String get timestampPickerDateLabel => '날짜';

  @override
  String get timestampPickerTimeSectionLabel => '시간';

  @override
  String get timestampPickerTimezoneLabel => '시간대';

  @override
  String get timestampPickerFormatPreviewLabel => '형식 미리보기';

  @override
  String get timestampPickerNlpPlaceholder => '예: 내일 오후 3시, 2시간 후, 지금';

  @override
  String get timestampPickerSearchTimezones => '시간대 검색...';

  @override
  String get userProfileTimezoneSettingLabel => '시간대';

  @override
  String get userProfileTimezoneSettingDescription =>
      '프로필에 현지 시간을 표시하는 데 사용됩니다.';

  @override
  String get userProfileTimezoneNone => '없음';

  @override
  String get chatReactAs => '다른 프로필로 반응하기...';

  @override
  String get emojiCopy => '이모티콘 복사';

  @override
  String get emojiCopyLink => '링크 복사';

  @override
  String get emojiPin => '이모지 고정';

  @override
  String get emojiUnpin => '이모지 고정 해제';

  @override
  String get emojiPinForPersona => '이 페르소나에 고정';

  @override
  String get emojiUnpinForPersona => '이 페르소나에서 고정 해제';

  @override
  String get personaSignatureEmojisLabel => '시그니처 이모지';

  @override
  String get personaSignatureEmojisDescription =>
      '시그니처 이모지로 반응하면 활성 페르소나와 관계없이 항상 이 페르소나로 반응합니다.';

  @override
  String get personaAddSignatureEmoji => '이모지 추가';

  @override
  String get personaSignatureEmojiAlreadyAdded => '이 이모지는 이미 시그니처 이모지로 추가되었습니다';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return '시그니처 이모지가 이미 \"$name\" 페르소나에서 사용 중입니다';
  }

  @override
  String get personaRemoveSignatureEmoji => '시그니처 이모지 삭제';

  @override
  String get signalBarLabel => '시그널 바';

  @override
  String get signalBarShow => '시그널 바 표시';

  @override
  String get signalBarHide => '시그널 바 숨기기';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => '이 시그널을 켠 사람이 없어요';

  @override
  String get signalBarReset => '모두의 시그널 초기화';

  @override
  String signalBarTurnOff(String name) {
    return '$name 끄기';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return '기본 인스턴스에는 $domain 주소를 사용하고, 다른 인스턴스는 정확한 URL을 입력하세요.';
  }

  @override
  String get instanceResetToDefault => '기본 인스턴스로 재설정';

  @override
  String get personaScopeTitle => '페르소나 적용 범위';

  @override
  String get personaScopeGlobal => '모든 곳';

  @override
  String get personaScopeGlobalDescription => '모든 채널에 하나의 페르소나.';

  @override
  String get personaScopeChannel => '채널마다';

  @override
  String get personaScopeChannelDescription =>
      '각 채널이 자신의 페르소나를 유지합니다. 새 채널은 내 계정으로 시작합니다.';

  @override
  String get personaPickerChannelOnly => '이 채널에서만';

  @override
  String get personaProfilePrivate => '이 페르소나의 프로필은 비공개입니다.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return '이미지 파일이 너무 큽니다. $maxSize 미만의 파일을 선택하세요.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'KLIPY 검색';

  @override
  String get appUpdateDownloadFailed => '업데이트를 다운로드하지 못했어요';

  @override
  String get appUpdateInstallFailed => '업데이트를 설치하지 못했어요';

  @override
  String get personaChangeMessageFailed => '메시지의 페르소나를 변경하지 못했어요';

  @override
  String get personaActiveCleared => '활성 페르소나가 해제됐어요';

  @override
  String get klipyPoweredBy => 'KLIPY 제공';

  @override
  String personaTagPairDuplicate(String pattern) {
    return '이 페르소나에 태그 쌍 \'$pattern\'이(가) 중복돼요';
  }

  @override
  String personaAddTagPair(int count) {
    return '태그 쌍 추가 ($count/5)';
  }

  @override
  String get personaTagExampleText => '텍스트';

  @override
  String get personaPreviewNameFallback => '사용자';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne가 예기치 않게 종료되었습니다. 익명의 충돌 및 오류 데이터를 공유하면 문제를 더 빠르게 해결하는 데 도움이 됩니다.';

  @override
  String get crashReportingSectionDescription =>
      '충돌 및 성능 데이터를 공유하여 Tyne의 버그 수정을 도와주세요. 기본적으로 꺼져 있습니다.';

  @override
  String get crashReportingDescription =>
      '다른 인스턴스에 로그인한 경우에도 보고서는 Tyne 자체 오류 추적기로 전송됩니다. 인스턴스 이름, ID 또는 메시지 내용은 포함되지 않습니다.';

  @override
  String get instanceOfflineTitle => 'Tyne이 오프라인 상태입니다!';

  @override
  String get instanceOfflineBody => '원인을 조사하고 있습니다.';

  @override
  String get instanceStatusSignalLink => 'Signal 채팅방에서 소식을 확인하세요';

  @override
  String get convertEmoticonsLabel => '텍스트 스마일리를 이모티콘으로 바꾸기';

  @override
  String guildCommandFailed(String name, String detail) {
    return '/$name을(를) 실행할 수 없습니다: $detail';
  }

  @override
  String get guildCommandBroken => '스크립트에 문제가 있습니다.';

  @override
  String guildCommandOneLine(String name) {
    return '/$name 뒤에 입력하는 내용은 한 줄이어야 합니다.';
  }

  @override
  String get permissionCreateCommands => '명령 만들기';

  @override
  String get permissionManageCommands => '명령 관리';

  @override
  String get permissionUseExternalCommands => '외부 명령 사용';

  @override
  String get permissionCreateCommandsDescription =>
      '이 커뮤니티의 명령을 만들고 내 명령을 수정하거나 삭제합니다.';

  @override
  String get permissionManageCommandsDescription =>
      '이 커뮤니티에서 누구의 명령이든 수정하거나 삭제합니다.';

  @override
  String get permissionUseExternalCommandsDescription => '다른 커뮤니티의 명령을 사용합니다.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      '이 채널에서 다른 커뮤니티의 명령을 사용합니다.';

  @override
  String get guildSettingsCategoryMessageTools => '메시지 도구';

  @override
  String get guildSettingsCommands => '명령';

  @override
  String get guildCommandsLoadFailed => '명령을 불러올 수 없습니다.';

  @override
  String get guildCommandsSubtitle => '멤버가 /name을 입력해 게시할 수 있는 메시지입니다.';

  @override
  String get guildCommandsSlots => '명령 슬롯';

  @override
  String get guildCommandsNew => '새 명령';

  @override
  String get guildCommandsSearch => '명령 검색';

  @override
  String get guildCommandsEmptyTitle => '명령 없음';

  @override
  String get guildCommandsEmptyBody => '이 커뮤니티에는 아직 명령이 없습니다.';

  @override
  String get guildCommandsSaved => '명령이 저장되었습니다';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return '/$name을(를) 저장할 수 없습니다: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return '/$name 수정';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return '/$name을(를) 삭제할까요?';
  }

  @override
  String get guildCommandDeleteBody =>
      '이 작업은 되돌릴 수 없습니다. 이 명령으로 만든 메시지에는 어떤 명령으로 만들었는지 계속 표시됩니다.';

  @override
  String get guildCommandDelete => '삭제';

  @override
  String get guildCommandDeleteCommand => '명령 삭제';

  @override
  String get guildCommandSectionCommand => '명령';

  @override
  String get guildCommandName => '이름';

  @override
  String get guildCommandNameInvalid => '소문자, 숫자, -, _만 사용해 32자 이내로 입력하세요.';

  @override
  String get guildCommandNameTaken => '다른 명령 또는 기본 제공 명령이 이미 이 이름을 사용하고 있습니다.';

  @override
  String get guildCommandDescription => '설명';

  @override
  String get guildCommandSectionInput => '입력';

  @override
  String get guildCommandInputNone => '없음';

  @override
  String get guildCommandInputOptional => '선택';

  @override
  String get guildCommandInputRequired => '필수';

  @override
  String get guildCommandHint => '힌트';

  @override
  String get guildCommandMessage => '메시지';

  @override
  String get guildCommandInsert => '삽입:';

  @override
  String get guildCommandInsertPerson => '실행한 사람';

  @override
  String get guildCommandInsertInput => '입력한 내용';

  @override
  String get guildCommandPreview => '미리보기';

  @override
  String get guildCommandSampleInput => '입력 예시';

  @override
  String guildCommandMadeWith(String name) {
    return '/$name(으)로 만든 메시지';
  }

  @override
  String guildCommandClearBox(String name) {
    return '/$name을(를) 사용하려면 메시지 입력란을 비우세요';
  }

  @override
  String get guildCommandEmptyMessage => '아무것도 게시되지 않으므로 명령이 실패합니다.';

  @override
  String get guildCommandUseScriptEditor => '스크립트 편집기 사용';

  @override
  String get guildCommandUseBasicEditor => '기본 편집기 사용';

  @override
  String get guildCommandScript => '스크립트';

  @override
  String get guildCommandRunAgain => '다시 실행';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return '$name(이)라는 태그가 없습니다.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return '$name(이)라는 필터가 없습니다.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name이(가) 닫히지 않았습니다.';
  }

  @override
  String get guildCommandIssueTooLong => '스크립트가 너무 깁니다.';

  @override
  String get guildCommandIssueTooLarge => '스크립트가 만드는 텍스트가 너무 많습니다.';

  @override
  String get guildCommandIssueTooSlow => '스크립트를 실행하는 데 시간이 너무 오래 걸렸습니다.';

  @override
  String get guildCommandIssueInvalid => '이 부분을 읽을 수 없습니다.';

  @override
  String get guildCommandIssueFailed => '이 부분에서 오류가 발생해 중단되었습니다.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return '$line행 $column열: $problem';
  }

  @override
  String get guildCommandReferenceTitle => '스크립트 참조';

  @override
  String get guildCommandReferencePerson => '실행한 사람 멘션';

  @override
  String get guildCommandReferencePersonName => '실행한 사람의 이름';

  @override
  String get guildCommandReferenceTarget => '멘션된 첫 번째 사람(있는 경우)';

  @override
  String get guildCommandReferenceTargetName => '그 사람의 이름';

  @override
  String get guildCommandReferenceChannel => '채널 멘션';

  @override
  String get guildCommandReferenceCommunity => '이 커뮤니티의 이름';

  @override
  String get guildCommandExampleRandom => '선택지 하나를 무작위로 고르기';

  @override
  String get guildCommandExampleDepends => '입력한 내용에 따라 메시지 바꾸기';

  @override
  String get guildCommandExampleOneWord => '단어 하나를 무작위로 고르기';

  @override
  String get guildCommandExampleWordForNumber => '숫자에 맞는 단어 고르기';

  @override
  String get guildCommandExampleOrdinal => '숫자를 1st, 2nd, 3rd처럼 쓰기';

  @override
  String get guildCommandFullGuide => '스크립트 전체 가이드';

  @override
  String get guildCommandCounters => '카운터';

  @override
  String get guildCommandCounterAdd => '카운터 추가';

  @override
  String get guildCommandCounterSeparately => '다음마다 따로 세기:';

  @override
  String get guildCommandCounterPersonMentioned => '멘션된 사람';

  @override
  String get guildCommandCounterChannel => '채널';

  @override
  String get guildCommandCounterPersonas => '페르소나를 따로 세기';

  @override
  String get guildCommandCounterRemove => '카운터 제거';

  @override
  String get guildCommandCounterReset => '횟수 초기화';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return '$name의 횟수를 초기화할까요? 되돌릴 수 없습니다.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      '영문 소문자, 숫자, _를 사용하고 문자로 시작하며, 스크립트가 이미 쓰는 이름은 피하세요.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return '스크립트에서 $variable(으)로 사용하세요. 실행할 때마다 먼저 1을 더하므로 첫 실행은 1을 읽습니다.';
  }
}
