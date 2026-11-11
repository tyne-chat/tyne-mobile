// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class ForkLocalizationsId extends ForkLocalizations {
  ForkLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Ganti persona';

  @override
  String get chatAttachmentPanelVoice => 'Suara';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'Tombol Pengalih Cepat';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Ganti tombol pesan suara di kolom input dengan tombol Pengalih Cepat untuk navigasi cepat';

  @override
  String get userSettingsCheckForUpdates => 'Cek pembaruan';

  @override
  String get userSettingsCheckingForUpdates => 'Memeriksa pembaruan…';

  @override
  String get userSettingsAppUpToDate => 'Tyne sudah yang terbaru';

  @override
  String get userSettingsUpdateAvailableTitle => 'Pembaruan Tersedia';

  @override
  String get userSettingsUpdateDownloadAction => 'Unduh & Pasang';

  @override
  String get userSettingsUpdateInstallAction => 'Pasang Pembaruan';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Mengunduh pembaruan ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Gagal memeriksa atau mengunduh pembaruan.';

  @override
  String get personaSelectTitle => 'Pilih Persona';

  @override
  String get personaSettingsHeader => 'Pengaturan Persona';

  @override
  String get personaManageAction => 'Kelola';

  @override
  String get personaSearchPlaceholder => 'Cari persona, tag, kata ganti...';

  @override
  String get personaModeManual => 'Manual';

  @override
  String get personaModeLast => 'Terakhir Digunakan';

  @override
  String get personaModeManualDescription =>
      'Selalu mengirim sebagai persona yang dipilih sampai diubah.';

  @override
  String get personaModeLastDescription =>
      'Beralih otomatis ke persona yang digunakan dalam pesan terakhir Anda.';

  @override
  String get personaRecentHeader => 'PERSONA TERBARU';

  @override
  String personaAllHeader(int count) {
    return 'SEMUA PERSONA ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'HASIL PENCARIAN ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Akun Utama (Default)';

  @override
  String get personaEmptyState =>
      'Belum ada persona yang dikonfigurasi. Buat melalui Kelola Persona.';

  @override
  String get personaEmptySearch => 'Tidak ditemukan persona yang cocok.';

  @override
  String get personaEditTitle => 'Edit Persona';

  @override
  String get personaCreateTitle => 'Buat Persona';

  @override
  String get personaDisplayNameLabel => 'Nama Tampilan';

  @override
  String get personaPronounsLabel => 'Kata ganti';

  @override
  String get personaPronounsHint => 'mis. they/them';

  @override
  String get personaBioHint =>
      'Ceritakan tentang persona ini kepada yang lain...';

  @override
  String get personaUpdatedToast => 'Persona diperbarui';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Gagal memperbarui persona: $error';
  }

  @override
  String get personaSectionTitle => 'Persona';

  @override
  String get personaDisplayNameHint => 'Nama persona';

  @override
  String personaSendingAsTag(String name) {
    return 'Mengirim sebagai $name (Cocok dengan tag)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Mengirim sebagai $name (Terkunci)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Mengirim sebagai $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Memposting sebagai $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Mengirim sebagai @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'Belum terkirim: personamu belum selesai dimuat.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Belum terkirim: personamu belum selesai dimuat. Kirim sebagai @$username saja?';
  }

  @override
  String get personaSendAsAccountAction => 'Tetap kirim';

  @override
  String get personaMainAccount => 'Akun utama';

  @override
  String get personaEditPersona => 'Edit persona';

  @override
  String get userSettingsNavPersonas => 'Persona';

  @override
  String get personaSettingsDescription =>
      'Konfigurasikan mode persona aktif, tag tampilan kustom, dan kelola persona masing-masing.';

  @override
  String get personaDisplayTagSection => 'Tag Tampilan';

  @override
  String get personaDisplayTagDescription =>
      'Tag tampilan akan muncul di sebelah semua nama persona dalam pesan. Jika tag tampilan tidak diatur, foto profil akun Anda akan ditampilkan.';

  @override
  String get personaDisplayTagLabel => 'Teks Tag Tampilan';

  @override
  String get personaDisplayTagHint => 'mis. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Ikon Tag Tampilan';

  @override
  String get personaUploadTagIcon => 'Unggah ikon';

  @override
  String get personaChangeTagIcon => 'Ubah ikon';

  @override
  String get personaRemoveTagIcon => 'Hapus ikon';

  @override
  String get personaChatPreviewTitle => 'Pratinjau Obrolan';

  @override
  String get personaChatPreviewSampleMessage =>
      'Halo! Ini adalah pratinjau tampilan pesan dengan tag tampilan dan persona aktif Anda.';

  @override
  String get personaListTitle => 'Persona Terkonfigurasi';

  @override
  String get personaAddButton => 'Tambah Persona';

  @override
  String get personaActiveBadge => 'Aktif';

  @override
  String get personaMakeActive => 'Jadikan Aktif';

  @override
  String get personaDeleteTitle => 'Hapus Persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Apakah Anda yakin ingin menghapus \"$name\"? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get personaDeleteConfirm => 'Hapus';

  @override
  String get personaDeletedToast => 'Persona dihapus';

  @override
  String get personaCreatedToast => 'Persona dibuat';

  @override
  String personaCreateFailedToast(String error) {
    return 'Gagal membuat persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Ganti avatar';

  @override
  String get personaRemoveAvatar => 'Hapus avatar';

  @override
  String get personaUploadAvatar => 'Unggah avatar';

  @override
  String get personaTagsLabel => 'Tag Persona';

  @override
  String get personaAutoTagDisabledLabel => 'Jangan cocokkan tag persona ini';

  @override
  String get personaAutoTagDisabledDescription =>
      'Mengetik salah satu tag ini tidak akan beralih ke persona ini. Tag dikirim sesuai yang ditulis.';

  @override
  String get personaTagPrefixLabel => 'Awalan';

  @override
  String get personaTagSuffixLabel => 'Akhiran';

  @override
  String get personaVisibilityLabel => 'Visibilitas';

  @override
  String get personaVisibilityUnlisted => 'Tidak terdaftar';

  @override
  String get personaVisibilityPublic => 'Publik';

  @override
  String get personaVisibilityPrivate => 'Privat';

  @override
  String get personaNameRequired => 'Silakan masukkan nama tampilan persona';

  @override
  String get personaNameTooLong =>
      'Nama tampilan persona harus 100 karakter atau kurang';

  @override
  String get personaTagPrefixTooLong =>
      'Awalan tag persona harus 32 karakter atau kurang';

  @override
  String get personaTagSuffixTooLong =>
      'Akhiran tag persona harus 32 karakter atau kurang';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Tag \'$tag\' sudah digunakan oleh \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Sisipkan stempel waktu';

  @override
  String get chatAttachmentSendVoiceMessage => 'Kirim pesan suara';

  @override
  String get timestampPickerTitle => 'Sisipkan stempel waktu';

  @override
  String get timestampPickerInsert => 'Sisipkan';

  @override
  String get timestampCopied => 'Stempel waktu disalin';

  @override
  String get timestampPickerTimeLabel => 'Waktu';

  @override
  String get timestampPickerDateLabel => 'TANGGAL';

  @override
  String get timestampPickerTimeSectionLabel => 'WAKTU';

  @override
  String get timestampPickerTimezoneLabel => 'ZONA WAKTU';

  @override
  String get timestampPickerFormatPreviewLabel => 'PRATINJAU FORMAT';

  @override
  String get timestampPickerNlpPlaceholder =>
      'mis. besok jam 3 sore, dalam 2 jam, sekarang';

  @override
  String get timestampPickerSearchTimezones => 'Cari zona waktu...';

  @override
  String get userProfileTimezoneSettingLabel => 'Zona waktu';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Digunakan untuk menampilkan waktu lokal di profil Anda.';

  @override
  String get userProfileTimezoneNone => 'Tidak ada';

  @override
  String get chatReactAs => 'Bereaksi sebagai...';

  @override
  String get emojiCopy => 'Salin emoji';

  @override
  String get emojiCopyLink => 'Salin tautan';

  @override
  String get emojiPin => 'Sematkan emoji';

  @override
  String get emojiUnpin => 'Lepas sematan emoji';

  @override
  String get emojiPinForPersona => 'Sematkan untuk persona ini';

  @override
  String get emojiUnpinForPersona => 'Lepas sematan untuk persona ini';

  @override
  String get personaSignatureEmojisLabel => 'Emoji Tanda Tangan';

  @override
  String get personaSignatureEmojisDescription =>
      'Bereaksi dengan emoji tanda tangan akan selalu bereaksi sebagai persona ini, terlepas dari persona yang aktif.';

  @override
  String get personaAddSignatureEmoji => 'Tambah Emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Emoji ini sudah ditambahkan sebagai emoji tanda tangan';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Emoji tanda tangan sudah digunakan oleh persona \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Hapus emoji tanda tangan';

  @override
  String get signalBarLabel => 'Bilah Sinyal';

  @override
  String get signalBarShow => 'Tampilkan bilah sinyal';

  @override
  String get signalBarHide => 'Sembunyikan bilah sinyal';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Belum ada yang menyalakan sinyal ini';

  @override
  String get signalBarReset => 'Reset sinyal untuk semua orang';

  @override
  String signalBarTurnOff(String name) {
    return 'Matikan $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Gunakan $domain untuk instans default, atau URL persis dari instans lain.';
  }

  @override
  String get instanceResetToDefault => 'Atur ulang ke instans default';

  @override
  String get personaScopeTitle => 'Persona berlaku untuk';

  @override
  String get personaScopeGlobal => 'Di Mana Saja';

  @override
  String get personaScopeGlobalDescription =>
      'Satu persona untuk semua saluran.';

  @override
  String get personaScopeChannel => 'Di setiap saluran';

  @override
  String get personaScopeChannelDescription =>
      'Setiap saluran menyimpan personanya sendiri. Saluran baru dimulai sebagai akunmu.';

  @override
  String get personaPickerChannelOnly => 'Hanya untuk saluran ini';

  @override
  String get personaProfilePrivate => 'Profil persona ini bersifat pribadi.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'File gambar terlalu besar. Pilih file yang ukurannya kurang dari $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Cari KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Gagal mengunduh pembaruan';

  @override
  String get appUpdateInstallFailed => 'Gagal memasang pembaruan';

  @override
  String get personaChangeMessageFailed => 'Gagal mengubah persona pesan';

  @override
  String get personaActiveCleared => 'Persona aktif dihapus';

  @override
  String get klipyPoweredBy => 'Didukung oleh KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Pasangan tag \'$pattern\' duplikat pada persona ini';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Tambah Pasangan Tag ($count/5)';
  }

  @override
  String get personaTagExampleText => 'teks';

  @override
  String get personaPreviewNameFallback => 'Pengguna';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne tertutup secara tidak terduga. Membagikan data kerusakan dan kesalahan secara anonim membantu kami memperbaiki masalah lebih cepat.';

  @override
  String get crashReportingSectionDescription =>
      'Bantu perbaiki bug di Tyne dengan membagikan data kerusakan dan performa. Fitur ini nonaktif secara default.';

  @override
  String get crashReportingDescription =>
      'Laporan dikirim ke pelacak kesalahan milik Tyne sendiri, bahkan saat Anda masuk ke instance lain. Laporan tidak mencakup nama instance, ID, atau isi pesan.';

  @override
  String get instanceOfflineTitle => 'Tyne sedang offline!';

  @override
  String get instanceOfflineBody => 'Kami sedang menyelidikinya.';

  @override
  String get instanceStatusSignalLink =>
      'Gabung ke obrolan Signal kami untuk info terbaru';

  @override
  String get convertEmoticonsLabel => 'Ubah smiley teks menjadi emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Tidak dapat menjalankan /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Skripnya bermasalah.';

  @override
  String guildCommandOneLine(String name) {
    return 'Yang Anda ketik setelah /$name harus muat dalam satu baris.';
  }

  @override
  String get permissionCreateCommands => 'Buat perintah';

  @override
  String get permissionManageCommands => 'Kelola perintah';

  @override
  String get permissionUseExternalCommands => 'Gunakan perintah eksternal';

  @override
  String get permissionCreateCommandsDescription =>
      'Buat perintah untuk komunitas ini, dan ubah atau hapus perintah Anda sendiri.';

  @override
  String get permissionManageCommandsDescription =>
      'Ubah atau hapus perintah siapa pun di komunitas ini.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Gunakan perintah dari komunitas lain.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Gunakan perintah dari komunitas lain di saluran ini.';

  @override
  String get guildSettingsCategoryMessageTools => 'Alat Pesan';

  @override
  String get guildSettingsCommands => 'Perintah';

  @override
  String get guildCommandsLoadFailed => 'Tidak dapat memuat perintah.';

  @override
  String get guildCommandsSubtitle =>
      'Pesan yang dapat dikirim anggota dengan mengetik /name.';

  @override
  String get guildCommandsSlots => 'Slot perintah';

  @override
  String get guildCommandsNew => 'Perintah baru';

  @override
  String get guildCommandsSearch => 'Cari perintah';

  @override
  String get guildCommandsEmptyTitle => 'Tidak ada perintah';

  @override
  String get guildCommandsEmptyBody => 'Komunitas ini belum punya perintah.';

  @override
  String get guildCommandsSaved => 'Perintah disimpan';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Tidak dapat menyimpan /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Ubah /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Hapus /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Ini tidak dapat dibatalkan. Pesan yang dibuat dengannya tetap menunjukkan perintah yang membuatnya.';

  @override
  String get guildCommandDelete => 'Hapus';

  @override
  String get guildCommandDeleteCommand => 'Hapus perintah';

  @override
  String get guildCommandSectionCommand => 'Perintah';

  @override
  String get guildCommandName => 'Nama';

  @override
  String get guildCommandNameInvalid =>
      'Gunakan huruf kecil, angka, - dan _, maksimal 32 karakter.';

  @override
  String get guildCommandNameTaken =>
      'Perintah lain atau perintah bawaan sudah memakai nama ini.';

  @override
  String get guildCommandDescription => 'Deskripsi';

  @override
  String get guildCommandSectionInput => 'Masukan';

  @override
  String get guildCommandInputNone => 'Tidak ada';

  @override
  String get guildCommandInputOptional => 'Opsional';

  @override
  String get guildCommandInputRequired => 'Wajib';

  @override
  String get guildCommandHint => 'Petunjuk';

  @override
  String get guildCommandMessage => 'Pesan';

  @override
  String get guildCommandInsert => 'Sisipkan:';

  @override
  String get guildCommandInsertPerson => 'Orang yang menjalankannya';

  @override
  String get guildCommandInsertInput => 'Yang mereka ketik';

  @override
  String get guildCommandPreview => 'Pratinjau';

  @override
  String get guildCommandSampleInput => 'Contoh masukan';

  @override
  String guildCommandMadeWith(String name) {
    return 'Dibuat dengan /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Kosongkan kotak pesan untuk menggunakan /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Ini tidak akan memposting apa pun, jadi perintah akan gagal.';

  @override
  String get guildCommandUseScriptEditor => 'Gunakan editor skrip';

  @override
  String get guildCommandUseBasicEditor => 'Gunakan editor dasar';

  @override
  String get guildCommandScript => 'Skrip';

  @override
  String get guildCommandRunAgain => 'Jalankan lagi';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Tidak ada tag bernama $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Tidak ada filter bernama $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name tidak pernah ditutup.';
  }

  @override
  String get guildCommandIssueTooLong => 'Skrip terlalu panjang.';

  @override
  String get guildCommandIssueTooLarge =>
      'Skrip menghasilkan terlalu banyak teks.';

  @override
  String get guildCommandIssueTooSlow => 'Skrip terlalu lama dijalankan.';

  @override
  String get guildCommandIssueInvalid => 'Bagian ini tidak dapat dibaca.';

  @override
  String get guildCommandIssueFailed => 'Bagian ini berhenti karena kesalahan.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Baris $line, kolom $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Referensi skrip';

  @override
  String get guildCommandReferencePerson =>
      'Orang yang menjalankannya, sebagai sebutan';

  @override
  String get guildCommandReferencePersonName =>
      'Nama orang yang menjalankannya';

  @override
  String get guildCommandReferenceTarget =>
      'Orang pertama yang mereka sebut, jika ada';

  @override
  String get guildCommandReferenceTargetName => 'Nama orang tersebut';

  @override
  String get guildCommandReferenceChannel => 'Saluran, sebagai sebutan';

  @override
  String get guildCommandReferenceCommunity => 'Nama komunitas ini';

  @override
  String get guildCommandExampleRandom => 'Pilih satu opsi secara acak';

  @override
  String get guildCommandExampleDepends =>
      'Ubah pesan sesuai yang mereka ketik';

  @override
  String get guildCommandExampleOneWord => 'Pilih satu kata secara acak';

  @override
  String get guildCommandExampleWordForNumber => 'Pilih kata sesuai angka';

  @override
  String get guildCommandExampleOrdinal => 'Tulis angka sebagai 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Panduan lengkap skrip';

  @override
  String get guildCommandCounters => 'Penghitung';

  @override
  String get guildCommandCounterAdd => 'Tambah penghitung';

  @override
  String get guildCommandCounterSeparately => 'Hitung terpisah untuk setiap:';

  @override
  String get guildCommandCounterPersonMentioned => 'Orang yang disebut';

  @override
  String get guildCommandCounterChannel => 'Saluran';

  @override
  String get guildCommandCounterPersonas => 'Hitung persona secara terpisah';

  @override
  String get guildCommandCounterRemove => 'Hapus penghitung';

  @override
  String get guildCommandCounterReset => 'Atur ulang hitungan';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Atur ulang hitungan $name? Ini tidak dapat dibatalkan.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Gunakan huruf kecil, angka, dan _, mulai dengan huruf, dan jangan gunakan nama yang sudah dipakai skrip.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Gunakan dalam skrip sebagai $variable. Setiap jalannya menambah satu lebih dulu, jadi yang pertama membaca 1.';
  }

  @override
  String get notificationsAlertEveryMessageLabel => 'Beri tahu setiap pesan';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Jika nonaktif, percakapan yang ramai memberi tahu sekali, lalu diperbarui diam-diam sampai Anda membacanya atau menutupnya.';

  @override
  String personaGalleryTitle(int count) {
    return 'Persona ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Cari persona $name';
  }

  @override
  String get personaGallerySearchOwn => 'Cari personamu';

  @override
  String get personaGallerySortBy => 'Urutkan menurut';

  @override
  String get personaGallerySortName => 'Nama (A–Z)';

  @override
  String get personaGallerySortMostUsed => 'Paling sering dipakai';

  @override
  String get personaGallerySortRecentlyUsed => 'Baru-baru ini dipakai';

  @override
  String get personaGalleryViewGallery => 'Galeri';

  @override
  String get personaGalleryViewList => 'Daftar';

  @override
  String get personaGalleryViewAvatars => 'Avatar';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return '$shown dari $total persona';
  }

  @override
  String get personaGalleryNoMatch =>
      'Tidak ada persona yang cocok dengan pencarianmu.';

  @override
  String get personaGalleryLoadFailed => 'Tidak dapat memuat persona.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona publik',
    );
    return 'Orang lain melihat $_temp0.';
  }

  @override
  String get personaGalleryShowHidden =>
      'Tampilkan yang tidak terdaftar dan privat';

  @override
  String get personaGalleryManage => 'Kelola persona';

  @override
  String get personaGalleryNonePublic =>
      'Belum ada personamu yang publik. Orang lain melihat persona di sini setelah kamu mengatur visibilitasnya ke Publik.';

  @override
  String get personaGalleryNoBio => 'Belum ada bio.';

  @override
  String personaGalleryCreated(String date) {
    return 'Dibuat $date';
  }

  @override
  String get personaBulkSelect => 'Pilih';

  @override
  String get personaBulkSelectAll => 'Pilih semua';

  @override
  String personaBulkSelectedCount(int count) {
    return '$count dipilih';
  }

  @override
  String get personaFilterAll => 'Semua';

  @override
  String get personaBulkMakePublic => 'Jadikan publik';

  @override
  String get personaBulkMakeUnlisted => 'Jadikan tidak terdaftar';

  @override
  String get personaBulkMakePrivate => 'Jadikan privat';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
    );
    return 'Jadikan $_temp0 publik?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
    );
    return 'Jadikan $_temp0 privat?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
    );
    return 'Hapus $_temp0?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Orang lain akan melihatnya di daftar Persona-mu dan bisa membuka profilnya. Kamu bisa mengubahnya kembali kapan saja.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Profilnya akan disembunyikan dari orang lain. Nama dan avatarnya tetap tampil di pesan dan reaksinya.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Pesannya tetap menampilkan nama dan avatarnya, tetapi kamu tidak bisa lagi mengirim sebagai persona tersebut, dan tag serta emoji tanda tangannya menjadi bebas. Ini tidak dapat dibatalkan.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona kini publik',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona kini tidak terdaftar',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona kini privat',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona dihapus',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed => 'Tidak dapat mengubah persona. Coba lagi.';

  @override
  String get personaFilterEmpty => 'Tidak ada persona di sini.';

  @override
  String get personaGalleryChooseFeatured => 'Pilih persona untuk ditampilkan';

  @override
  String get personaUndo => 'Urungkan';

  @override
  String get personaReactionsTitle => 'Reaksi Anda';

  @override
  String get personaReactionsEveryoneElse => 'SEMUA YANG LAIN';

  @override
  String get personaReactionsCurrent => 'SAAT INI';

  @override
  String get personaReactionsAccount => 'Akun';

  @override
  String get personaReactionsSomeoneElse => 'Bereaksi sebagai orang lain...';

  @override
  String get personaReactionsDone => 'Selesai';

  @override
  String get personaSettingsReactionsHeader => 'Reaksi';

  @override
  String get personaSettingsMultiReactions =>
      'Bereaksi sebagai beberapa persona sekaligus';

  @override
  String get personaDuplicateButton => 'Duplikat Persona';

  @override
  String personaCopyOf(String name) {
    return 'Salinan $name';
  }

  @override
  String signalsEverywhereTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obrolan',
    );
    return 'Sinyalmu di mana saja · $_temp0';
  }

  @override
  String signalsEverywhereHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obrolan',
    );
    return 'Atur di mana saja ($_temp0)';
  }

  @override
  String signalsEverywhereSet(String label) {
    return 'Atur $label di mana saja';
  }

  @override
  String get signalsEverywhereTurnAllOff => 'Matikan semua';

  @override
  String get signalsEverywhereRestore => 'Pulihkan…';

  @override
  String get signalsEverywhereNone =>
      'Tidak ada sinyalmu yang menyala di mana pun.';

  @override
  String get signalsRestoreTitle => 'Pulihkan sinyalmu?';

  @override
  String signalsRestoreBeforeSet(String label, String time) {
    return 'Mengembalikan yang menyala sebelum kamu mengatur $label di mana saja pada $time. Yang menyala di sana sekarang akan dimatikan.';
  }

  @override
  String signalsRestoreBeforeOff(String time) {
    return 'Mengembalikan yang menyala sebelum kamu mematikan semuanya pada $time. Yang menyala di sana sekarang akan dimatikan.';
  }

  @override
  String signalsRestoreBeforeRestore(String time) {
    return 'Mengembalikan yang menyala sebelum pemulihan terakhirmu pada $time. Yang menyala di sana sekarang akan dimatikan.';
  }

  @override
  String get signalsRestoreNow => 'Sekarang';

  @override
  String get signalsRestoreAfter => 'Sesudah';

  @override
  String signalsRestoreLeftOut(String chats) {
    return 'Dilewati karena kamu tidak bisa lagi mengirim pesan di sana: $chats';
  }

  @override
  String get signalsRestoreConfirm => 'Pulihkan';

  @override
  String get signalsRestoreUnavailable =>
      'Tidak dapat memuat apa yang akan diubah oleh Pulihkan. Coba lagi.';

  @override
  String get signalsRestoreNothing => 'Tidak ada yang bisa dipulihkan.';

  @override
  String get signalsProfileMenu => 'Sinyal';

  @override
  String get signalsEverywhereTurnOffChat => 'Matikan sinyal';

  @override
  String signalsRestoreBeforeChange(String time) {
    return 'Mengembalikan yang menyala sebelum perubahan terakhirmu di mana saja pada $time. Yang menyala di sana sekarang akan dimatikan.';
  }
}
