// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class ForkLocalizationsVi extends ForkLocalizations {
  ForkLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Đổi persona';

  @override
  String get chatAttachmentPanelVoice => 'Thoại';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'Nút chuyển nhanh';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Thay thế nút tin nhắn thoại trong khung soạn thảo bằng nút chuyển nhanh để điều hướng thuận tiện';

  @override
  String get userSettingsCheckForUpdates => 'Kiểm tra cập nhật';

  @override
  String get userSettingsCheckingForUpdates => 'Đang kiểm tra cập nhật…';

  @override
  String get userSettingsAppUpToDate => 'Tyne đã được cập nhật';

  @override
  String get userSettingsUpdateAvailableTitle => 'Có bản cập nhật mới';

  @override
  String get userSettingsUpdateDownloadAction => 'Tải về và cài đặt';

  @override
  String get userSettingsUpdateInstallAction => 'Cài đặt bản cập nhật';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Đang tải bản cập nhật ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Không thể kiểm tra hoặc tải xuống bản cập nhật.';

  @override
  String get personaSelectTitle => 'Chọn persona';

  @override
  String get personaSettingsHeader => 'Cài đặt persona';

  @override
  String get personaManageAction => 'Quản lý';

  @override
  String get personaSearchPlaceholder => 'Tìm kiếm persona, thẻ, đại từ...';

  @override
  String get personaModeManual => 'Thủ công';

  @override
  String get personaModeLast => 'Sử dụng lần cuối';

  @override
  String get personaModeManualDescription =>
      'Luôn gửi dưới dạng persona đã chọn cho đến khi thay đổi.';

  @override
  String get personaModeLastDescription =>
      'Tự động chuyển sang persona được sử dụng trong tin nhắn gần nhất của bạn.';

  @override
  String get personaRecentHeader => 'PERSONA GẦN ĐÂY';

  @override
  String personaAllHeader(int count) {
    return 'TẤT CẢ PERSONA ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'KẾT QUẢ TÌM KIẾM ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Tài khoản gốc (Mặc định)';

  @override
  String get personaEmptyState =>
      'Chưa cấu hình persona nào. Hãy tạo một persona qua Quản lý persona.';

  @override
  String get personaEmptySearch => 'Không tìm thấy persona nào phù hợp.';

  @override
  String get personaEditTitle => 'Chỉnh sửa persona';

  @override
  String get personaCreateTitle => 'Tạo persona';

  @override
  String get personaDisplayNameLabel => 'Tên hiển thị';

  @override
  String get personaPronounsLabel => 'Đại từ nhân xưng';

  @override
  String get personaPronounsHint => 'vd. they/them';

  @override
  String get personaBioHint => 'Giới thiệu với người khác về persona này...';

  @override
  String get personaUpdatedToast => 'Đã cập nhật persona';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Không thể cập nhật persona: $error';
  }

  @override
  String get personaSectionTitle => 'Persona';

  @override
  String get personaDisplayNameHint => 'Tên persona';

  @override
  String personaSendingAsTag(String name) {
    return 'Đang gửi dưới dạng $name (Khớp theo thẻ)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Đang gửi dưới dạng $name (Đã khóa)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Đang gửi dưới dạng $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Đang đăng dưới dạng $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Đang gửi dưới dạng @$username';
  }

  @override
  String get personaMainAccount => 'Tài khoản chính';

  @override
  String get personaEditPersona => 'Chỉnh sửa persona';

  @override
  String get userSettingsNavPersonas => 'Persona';

  @override
  String get personaSettingsDescription =>
      'Cấu hình chế độ persona đang hoạt động, thẻ hiển thị tùy chỉnh và quản lý các persona riêng lẻ.';

  @override
  String get personaDisplayTagSection => 'Thẻ hiển thị';

  @override
  String get personaDisplayTagDescription =>
      'Thẻ hiển thị sẽ xuất hiện cạnh tất cả tên persona trong tin nhắn. Nếu không có thẻ hiển thị, ảnh đại diện tài khoản của bạn sẽ được hiển thị.';

  @override
  String get personaDisplayTagLabel => 'Văn bản thẻ hiển thị';

  @override
  String get personaDisplayTagHint => 'vd. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Biểu tượng thẻ hiển thị';

  @override
  String get personaUploadTagIcon => 'Tải biểu tượng lên';

  @override
  String get personaChangeTagIcon => 'Đổi biểu tượng';

  @override
  String get personaRemoveTagIcon => 'Xóa biểu tượng';

  @override
  String get personaChatPreviewTitle => 'Xem trước đoạn chat';

  @override
  String get personaChatPreviewSampleMessage =>
      'Xin chào! Đây là bản xem trước cách tin nhắn xuất hiện cùng thẻ hiển thị và persona đang hoạt động của bạn.';

  @override
  String get personaListTitle => 'Persona đã cấu hình';

  @override
  String get personaAddButton => 'Thêm persona';

  @override
  String get personaActiveBadge => 'Đang hoạt động';

  @override
  String get personaMakeActive => 'Đặt làm hoạt động';

  @override
  String get personaDeleteTitle => 'Xóa persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Bạn có chắc chắn muốn xóa \"$name\" không? Hành động này không thể hoàn tác.';
  }

  @override
  String get personaDeleteConfirm => 'Xóa';

  @override
  String get personaDeletedToast => 'Đã xóa persona';

  @override
  String get personaCreatedToast => 'Đã tạo persona';

  @override
  String personaCreateFailedToast(String error) {
    return 'Không thể tạo persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Đổi ảnh đại diện';

  @override
  String get personaRemoveAvatar => 'Xóa ảnh đại diện';

  @override
  String get personaUploadAvatar => 'Tải ảnh đại diện lên';

  @override
  String get personaTagsLabel => 'Thẻ persona';

  @override
  String get personaTagPrefixLabel => 'Tiền tố';

  @override
  String get personaTagSuffixLabel => 'Hậu tố';

  @override
  String get personaVisibilityLabel => 'Chế độ hiển thị';

  @override
  String get personaVisibilityUnlisted => 'Không được liệt kê';

  @override
  String get personaVisibilityPublic => 'Công khai';

  @override
  String get personaVisibilityPrivate => 'Riêng tư';

  @override
  String get personaNameRequired => 'Vui lòng nhập tên hiển thị cho persona';

  @override
  String get personaNameTooLong =>
      'Tên hiển thị của persona phải có từ 100 ký tự trở xuống';

  @override
  String get personaTagPrefixTooLong =>
      'Tiền tố thẻ persona phải có từ 32 ký tự trở xuống';

  @override
  String get personaTagSuffixTooLong =>
      'Hậu tố thẻ persona phải có từ 32 ký tự trở xuống';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Thẻ \'$tag\' đã được \'$name\' sử dụng.';
  }

  @override
  String get chatInsertTimestamp => 'Chèn dấu thời gian';

  @override
  String get chatAttachmentSendVoiceMessage => 'Gửi tin nhắn thoại';

  @override
  String get timestampPickerTitle => 'Chèn dấu thời gian';

  @override
  String get timestampPickerInsert => 'Chèn';

  @override
  String get timestampCopied => 'Đã sao chép dấu thời gian';

  @override
  String get timestampPickerTimeLabel => 'Thời gian';

  @override
  String get timestampPickerDateLabel => 'NGÀY';

  @override
  String get timestampPickerTimeSectionLabel => 'GIỜ';

  @override
  String get timestampPickerTimezoneLabel => 'MÚI GIỜ';

  @override
  String get timestampPickerFormatPreviewLabel => 'XEM TRƯỚC ĐỊNH DẠNG';

  @override
  String get timestampPickerNlpPlaceholder =>
      'ví dụ: ngày mai lúc 3 giờ chiều, trong 2 giờ nữa, bây giờ';

  @override
  String get timestampPickerSearchTimezones => 'Tìm kiếm múi giờ...';

  @override
  String get userProfileTimezoneSettingLabel => 'Múi giờ';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Được sử dụng để hiển thị giờ địa phương trên hồ sơ của bạn.';

  @override
  String get userProfileTimezoneNone => 'Không có';

  @override
  String get chatReactAs => 'Thả cảm xúc dưới tên...';

  @override
  String get emojiCopy => 'Sao chép biểu tượng cảm xúc';

  @override
  String get emojiCopyLink => 'Sao chép liên kết';

  @override
  String get emojiPin => 'Ghim biểu tượng cảm xúc';

  @override
  String get emojiUnpin => 'Bỏ ghim biểu tượng cảm xúc';

  @override
  String get emojiPinForPersona => 'Ghim cho persona này';

  @override
  String get emojiUnpinForPersona => 'Bỏ ghim cho persona này';

  @override
  String get personaSignatureEmojisLabel => 'Biểu tượng cảm xúc đặc trưng';

  @override
  String get personaSignatureEmojisDescription =>
      'Bày tỏ cảm xúc bằng biểu tượng đặc trưng sẽ luôn phản hồi dưới tư cách nhân cách này, bất kể nhân cách đang hoạt động là gì.';

  @override
  String get personaAddSignatureEmoji => 'Thêm biểu tượng cảm xúc';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Biểu tượng cảm xúc này đã được thêm làm biểu tượng đặc trưng';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Biểu tượng cảm xúc đặc trưng đã được nhân cách \"$name\" sử dụng';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Xóa biểu tượng cảm xúc đặc trưng';

  @override
  String get signalBarLabel => 'Thanh tín hiệu';

  @override
  String get signalBarShow => 'Hiện thanh tín hiệu';

  @override
  String get signalBarHide => 'Ẩn thanh tín hiệu';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Chưa ai bật tín hiệu này';

  @override
  String get signalBarReset => 'Đặt lại tín hiệu cho mọi người';

  @override
  String signalBarTurnOff(String name) {
    return 'Tắt $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Dùng $domain cho máy chủ mặc định, hoặc URL chính xác của một máy chủ khác.';
  }

  @override
  String get instanceResetToDefault => 'Đặt lại về máy chủ mặc định';

  @override
  String get personaScopeTitle => 'Persona áp dụng cho';

  @override
  String get personaScopeGlobal => 'Mọi nơi';

  @override
  String get personaScopeGlobalDescription => 'Một persona cho mọi kênh.';

  @override
  String get personaScopeChannel => 'Trong từng kênh';

  @override
  String get personaScopeChannelDescription =>
      'Mỗi kênh giữ persona riêng của mình. Kênh mới bắt đầu bằng tài khoản của bạn.';

  @override
  String get personaPickerChannelOnly => 'Chỉ cho kênh này';

  @override
  String get personaProfilePrivate =>
      'Hồ sơ của persona này ở chế độ riêng tư.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Tệp ảnh quá lớn. Vui lòng chọn tệp có dung lượng nhỏ hơn $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Tìm kiếm KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Không tải được bản cập nhật';

  @override
  String get appUpdateInstallFailed => 'Không cài đặt được bản cập nhật';

  @override
  String get personaChangeMessageFailed =>
      'Không đổi được persona của tin nhắn';

  @override
  String get personaActiveCleared => 'Đã xóa persona đang hoạt động';

  @override
  String get klipyPoweredBy => 'Được cung cấp bởi KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Cặp thẻ \'$pattern\' bị trùng trên persona này';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Thêm cặp thẻ ($count/5)';
  }

  @override
  String get personaTagExampleText => 'văn bản';

  @override
  String get personaPreviewNameFallback => 'Người dùng';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne đã đóng đột ngột. Chia sẻ dữ liệu sự cố và lỗi ẩn danh giúp chúng tôi khắc phục vấn đề nhanh hơn.';

  @override
  String get crashReportingSectionDescription =>
      'Giúp sửa lỗi trong Tyne bằng cách chia sẻ dữ liệu sự cố và hiệu suất. Tùy chọn này tắt theo mặc định.';

  @override
  String get crashReportingDescription =>
      'Báo cáo được gửi đến hệ thống theo dõi lỗi riêng của Tyne, ngay cả khi bạn đăng nhập vào máy chủ khác. Báo cáo không bao gồm tên máy chủ, ID hoặc nội dung tin nhắn.';

  @override
  String get instanceOfflineTitle => 'Tyne đang ngoại tuyến!';

  @override
  String get instanceOfflineBody => 'Chúng tôi đang kiểm tra.';

  @override
  String get instanceStatusSignalLink =>
      'Tham gia nhóm chat Signal của chúng tôi để nhận thông tin mới';

  @override
  String get convertEmoticonsLabel =>
      'Chuyển mặt cười dạng văn bản thành biểu tượng cảm xúc';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Không thể chạy /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Tập lệnh có vấn đề.';

  @override
  String guildCommandOneLine(String name) {
    return 'Nội dung bạn gõ sau /$name phải nằm trên một dòng.';
  }

  @override
  String get permissionCreateCommands => 'Tạo lệnh';

  @override
  String get permissionManageCommands => 'Quản lý lệnh';

  @override
  String get permissionUseExternalCommands => 'Dùng lệnh bên ngoài';

  @override
  String get permissionCreateCommandsDescription =>
      'Tạo lệnh cho cộng đồng này, và sửa hoặc xóa lệnh của bạn.';

  @override
  String get permissionManageCommandsDescription =>
      'Sửa hoặc xóa lệnh của bất kỳ ai trong cộng đồng này.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Dùng lệnh từ các cộng đồng khác.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Dùng lệnh từ các cộng đồng khác trong kênh này.';

  @override
  String get guildSettingsCategoryMessageTools => 'Công cụ tin nhắn';

  @override
  String get guildSettingsCommands => 'Lệnh';

  @override
  String get guildCommandsLoadFailed => 'Không thể tải các lệnh.';

  @override
  String get guildCommandsSubtitle =>
      'Tin nhắn mà thành viên có thể đăng bằng cách gõ /name.';

  @override
  String get guildCommandsSlots => 'Ô lệnh';

  @override
  String get guildCommandsNew => 'Lệnh mới';

  @override
  String get guildCommandsSearch => 'Tìm lệnh';

  @override
  String get guildCommandsEmptyTitle => 'Không có lệnh nào';

  @override
  String get guildCommandsEmptyBody => 'Cộng đồng này chưa có lệnh nào.';

  @override
  String get guildCommandsSaved => 'Đã lưu lệnh';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Không thể lưu /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Sửa /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Xóa /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Không thể hoàn tác. Tin nhắn được tạo bằng lệnh này vẫn cho biết lệnh nào đã tạo ra chúng.';

  @override
  String get guildCommandDelete => 'Xóa';

  @override
  String get guildCommandDeleteCommand => 'Xóa lệnh';

  @override
  String get guildCommandSectionCommand => 'Lệnh';

  @override
  String get guildCommandName => 'Tên';

  @override
  String get guildCommandNameInvalid =>
      'Dùng chữ thường, số, - và _, tối đa 32 ký tự.';

  @override
  String get guildCommandNameTaken =>
      'Một lệnh khác hoặc một lệnh có sẵn đã dùng tên này.';

  @override
  String get guildCommandDescription => 'Mô tả';

  @override
  String get guildCommandSectionInput => 'Nhập liệu';

  @override
  String get guildCommandInputNone => 'Không';

  @override
  String get guildCommandInputOptional => 'Không bắt buộc';

  @override
  String get guildCommandInputRequired => 'Bắt buộc';

  @override
  String get guildCommandHint => 'Gợi ý';

  @override
  String get guildCommandMessage => 'Tin nhắn';

  @override
  String get guildCommandInsert => 'Chèn:';

  @override
  String get guildCommandInsertPerson => 'Người chạy lệnh';

  @override
  String get guildCommandInsertInput => 'Nội dung họ gõ';

  @override
  String get guildCommandPreview => 'Xem trước';

  @override
  String get guildCommandSampleInput => 'Nội dung mẫu';

  @override
  String guildCommandMadeWith(String name) {
    return 'Được tạo bằng /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Xóa trống ô tin nhắn để dùng /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Thao tác này sẽ không đăng gì cả, nên lệnh sẽ thất bại.';

  @override
  String get guildCommandUseScriptEditor => 'Dùng trình chỉnh sửa tập lệnh';

  @override
  String get guildCommandUseBasicEditor => 'Dùng trình chỉnh sửa cơ bản';

  @override
  String get guildCommandScript => 'Tập lệnh';

  @override
  String get guildCommandRunAgain => 'Chạy lại';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Không có thẻ nào tên là $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Không có bộ lọc nào tên là $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name không bao giờ được đóng.';
  }

  @override
  String get guildCommandIssueTooLong => 'Tập lệnh quá dài.';

  @override
  String get guildCommandIssueTooLarge => 'Tập lệnh tạo ra quá nhiều văn bản.';

  @override
  String get guildCommandIssueTooSlow => 'Tập lệnh chạy quá lâu.';

  @override
  String get guildCommandIssueInvalid => 'Không thể đọc phần này.';

  @override
  String get guildCommandIssueFailed => 'Phần này đã dừng vì lỗi.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Dòng $line, cột $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Tài liệu tham khảo tập lệnh';

  @override
  String get guildCommandReferencePerson =>
      'Người chạy lệnh, dưới dạng lượt nhắc đến';

  @override
  String get guildCommandReferencePersonName => 'Tên của người chạy lệnh';

  @override
  String get guildCommandReferenceTarget =>
      'Người đầu tiên họ nhắc đến, nếu có';

  @override
  String get guildCommandReferenceTargetName => 'Tên của người đó';

  @override
  String get guildCommandReferenceChannel => 'Kênh, dưới dạng lượt nhắc đến';

  @override
  String get guildCommandReferenceCommunity => 'Tên của cộng đồng này';

  @override
  String get guildCommandExampleRandom => 'Chọn ngẫu nhiên một tùy chọn';

  @override
  String get guildCommandExampleDepends =>
      'Đổi tin nhắn tùy theo nội dung họ gõ';

  @override
  String get guildCommandExampleOneWord => 'Chọn ngẫu nhiên một từ';

  @override
  String get guildCommandExampleWordForNumber => 'Chọn từ theo con số';

  @override
  String get guildCommandExampleOrdinal => 'Viết số dưới dạng 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Hướng dẫn đầy đủ về tập lệnh';

  @override
  String get guildCommandCounters => 'Bộ đếm';

  @override
  String get guildCommandCounterAdd => 'Thêm bộ đếm';

  @override
  String get guildCommandCounterSeparately => 'Đếm riêng cho mỗi:';

  @override
  String get guildCommandCounterPersonMentioned => 'Người được nhắc đến';

  @override
  String get guildCommandCounterChannel => 'Kênh';

  @override
  String get guildCommandCounterPersonas => 'Đếm riêng từng persona';

  @override
  String get guildCommandCounterRemove => 'Xóa bộ đếm';

  @override
  String get guildCommandCounterReset => 'Đặt lại số đếm';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Đặt lại số đếm của $name? Không thể hoàn tác.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Dùng chữ thường, số và _, bắt đầu bằng chữ cái và không dùng tên mà tập lệnh đã dùng.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Dùng trong tập lệnh là $variable. Mỗi lần chạy cộng một trước, nên lần đầu đọc được 1.';
  }
}
