// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Albanian (`sq`).
class ForkLocalizationsSq extends ForkLocalizations {
  ForkLocalizationsSq([String locale = 'sq']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Ndrysho personën';

  @override
  String get chatAttachmentPanelVoice => 'Zë';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Butoni i ndërruesit të shpejtë';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Zëvendëso butonin e mesazhit zanor te fusha e mesazhit me një buton të ndërruesit të shpejtë, për të lëvizur shpejt';

  @override
  String get userSettingsCheckForUpdates => 'Kontrollo për përditësime';

  @override
  String get userSettingsCheckingForUpdates =>
      'Po kontrollohet për përditësime…';

  @override
  String get userSettingsAppUpToDate => 'Tyne është në versionin më të fundit';

  @override
  String get userSettingsUpdateAvailableTitle => 'Ka një përditësim';

  @override
  String get userSettingsUpdateDownloadAction => 'Shkarko dhe instalo';

  @override
  String get userSettingsUpdateInstallAction => 'Instalo përditësimin';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Po shkarkohet përditësimi ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Kontrolli ose shkarkimi i përditësimit dështoi.';

  @override
  String get personaSelectTitle => 'Zgjidh personën';

  @override
  String get personaSettingsHeader => 'Cilësimet e personave';

  @override
  String get personaManageAction => 'Menaxho';

  @override
  String get personaSearchPlaceholder => 'Kërko persona, etiketa, përemra…';

  @override
  String get personaModeManual => 'Manuale';

  @override
  String get personaModeLast => 'E përdorura së fundi';

  @override
  String get personaModeManualDescription =>
      'Dërgon gjithmonë si persona e zgjedhur, derisa ta ndryshosh.';

  @override
  String get personaModeLastDescription =>
      'Kalon automatikisht te persona që përdore në mesazhin e fundit.';

  @override
  String get personaRecentHeader => 'PERSONAT E FUNDIT';

  @override
  String personaAllHeader(int count) {
    return 'TË GJITHA PERSONAT ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'REZULTATET E KËRKIMIT ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Llogaria kryesore (e parazgjedhur)';

  @override
  String get personaEmptyState =>
      'Ende nuk ka persona. Krijo një te “Menaxho personat”.';

  @override
  String get personaEmptySearch => 'Nuk u gjet asnjë personë që përputhet.';

  @override
  String get personaEditTitle => 'Redakto personën';

  @override
  String get personaCreateTitle => 'Krijo personë';

  @override
  String get personaDisplayNameLabel => 'Emri i shfaqur';

  @override
  String get personaPronounsLabel => 'Përemrat';

  @override
  String get personaPronounsHint => 'p.sh. ata/atyre';

  @override
  String get personaBioHint => 'U trego të tjerëve për këtë personë…';

  @override
  String get personaUpdatedToast => 'Persona u përditësua';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Persona nuk u përditësua: $error';
  }

  @override
  String get personaSectionTitle => 'Personat';

  @override
  String get personaDisplayNameHint => 'Emri i personës';

  @override
  String personaSendingAsTag(String name) {
    return 'Po dërgon si $name (sipas etiketës)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Po dërgon si $name (e përdorura së fundi)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Po dërgon si $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Po poston si $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Po dërgon si @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'Nuk u dërgua: personat e tua ende nuk janë ngarkuar.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Nuk u dërgua: personat e tua ende nuk janë ngarkuar. Ta dërgosh si @$username?';
  }

  @override
  String get personaSendAsAccountAction => 'Dërgoje gjithsesi';

  @override
  String get personaMainAccount => 'Llogaria kryesore';

  @override
  String get personaEditPersona => 'Redakto personën';

  @override
  String get userSettingsNavPersonas => 'Personat';

  @override
  String get personaSettingsDescription =>
      'Cakto mënyrën e personës aktive dhe etiketën tënde të shfaqur, dhe menaxho secilën personë.';

  @override
  String get personaDisplayTagSection => 'Etiketa e shfaqur';

  @override
  String get personaDisplayTagDescription =>
      'Etiketa e shfaqur del pranë emrave të të gjitha personave në mesazhe. Nëse nuk është caktuar, shfaqet fotoja e profilit të llogarisë sate.';

  @override
  String get personaDisplayTagLabel => 'Teksti i etiketës së shfaqur';

  @override
  String get personaDisplayTagHint => 'p.sh. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Ikona e etiketës së shfaqur';

  @override
  String get personaUploadTagIcon => 'Ngarko ikonë';

  @override
  String get personaChangeTagIcon => 'Ndrysho ikonën';

  @override
  String get personaRemoveTagIcon => 'Hiq ikonën';

  @override
  String get personaChatPreviewTitle => 'Pamje paraprake e bisedës';

  @override
  String get personaChatPreviewSampleMessage =>
      'Përshëndetje! Kështu duken mesazhet me etiketën tënde të shfaqur dhe personën aktive.';

  @override
  String get personaListTitle => 'Personat e konfiguruara';

  @override
  String get personaAddButton => 'Shto personë';

  @override
  String get personaActiveBadge => 'Aktive';

  @override
  String get personaMakeActive => 'Bëje aktive';

  @override
  String get personaDeleteTitle => 'Fshi personën';

  @override
  String personaDeleteMessage(String name) {
    return 'Do ta fshish vërtet “$name”? Personat e fshira mund t’i rikthesh më vonë te Cilësimet › Personat, te “Personat e fshira”.';
  }

  @override
  String get personaDeleteConfirm => 'Fshi';

  @override
  String get personaDeletedToast => 'Persona u fshi';

  @override
  String get personaCreatedToast => 'Persona u krijua';

  @override
  String personaCreateFailedToast(String error) {
    return 'Persona nuk u krijua: $error';
  }

  @override
  String get personaChangeAvatar => 'Ndrysho avatarin';

  @override
  String get personaRemoveAvatar => 'Hiq avatarin';

  @override
  String get personaUploadAvatar => 'Ngarko avatar';

  @override
  String get personaTagsLabel => 'Etiketat e personës';

  @override
  String get personaAutoTagDisabledLabel => 'Injoro etiketat e kësaj persone';

  @override
  String get personaAutoTagDisabledDescription =>
      'Shkrimi i njërës prej këtyre etiketave nuk kalon te kjo personë. Etiketa dërgohet siç është shkruar.';

  @override
  String get personaTagPrefixLabel => 'Parashtesë';

  @override
  String get personaTagSuffixLabel => 'Prapashtesë';

  @override
  String get personaVisibilityLabel => 'Dukshmëria';

  @override
  String get personaVisibilityUnlisted => 'Jashtë listës';

  @override
  String get personaVisibilityPublic => 'Publike';

  @override
  String get personaVisibilityPrivate => 'Private';

  @override
  String get personaNameRequired => 'Shkruaj emrin e shfaqur të personës';

  @override
  String get personaNameTooLong =>
      'Emri i shfaqur i personës duhet të ketë deri në 100 karaktere';

  @override
  String get personaTagPrefixTooLong =>
      'Parashtesa e etiketës duhet të ketë deri në 32 karaktere';

  @override
  String get personaTagSuffixTooLong =>
      'Prapashtesa e etiketës duhet të ketë deri në 32 karaktere';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Etiketa “$tag” përdoret tashmë nga “$name”.';
  }

  @override
  String get chatInsertTimestamp => 'Fut vulë kohore';

  @override
  String get chatAttachmentSendVoiceMessage => 'Dërgo mesazh zanor';

  @override
  String get timestampPickerTitle => 'Fut vulë kohore';

  @override
  String get timestampPickerInsert => 'Fut';

  @override
  String get timestampCopied => 'Vula kohore u kopjua';

  @override
  String get timestampPickerTimeLabel => 'Ora';

  @override
  String get timestampPickerDateLabel => 'DATA';

  @override
  String get timestampPickerTimeSectionLabel => 'ORA';

  @override
  String get timestampPickerTimezoneLabel => 'ZONA KOHORE';

  @override
  String get timestampPickerFormatPreviewLabel => 'PAMJA PARAPRAKE E FORMATIT';

  @override
  String get timestampPickerNlpPlaceholder =>
      'p.sh. tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'Kërko zona kohore…';

  @override
  String get userProfileTimezoneSettingLabel => 'Zona kohore';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Përdoret për të shfaqur orën tënde lokale në profil.';

  @override
  String get userProfileTimezoneNone => 'Asnjë';

  @override
  String get chatReactAs => 'Reago si…';

  @override
  String get emojiCopy => 'Kopjo emoji-n';

  @override
  String get emojiCopyLink => 'Kopjo lidhjen';

  @override
  String get emojiPin => 'Fikso emoji-n';

  @override
  String get emojiUnpin => 'Hiq fiksimin e emoji-t';

  @override
  String get emojiPinForPersona => 'Fikso për këtë personë';

  @override
  String get emojiUnpinForPersona => 'Hiq fiksimin për këtë personë';

  @override
  String get personaSignatureEmojisLabel => 'Emoji dallues';

  @override
  String get personaSignatureEmojisDescription =>
      'Kur reagon me një emoji dallues, reagon gjithmonë si kjo personë, pavarësisht personës aktive.';

  @override
  String get personaAddSignatureEmoji => 'Shto emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Ky emoji është shtuar tashmë si emoji dallues';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Ky emoji dallues përdoret tashmë nga persona “$name”';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Hiq emoji-n dallues';

  @override
  String get signalBarLabel => 'Shiriti i sinjaleve';

  @override
  String get signalBarShow => 'Shfaq shiritin e sinjaleve';

  @override
  String get signalBarHide => 'Fshih shiritin e sinjaleve';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Askush nuk e ka ndezur këtë sinjal';

  @override
  String get signalBarReset => 'Rivendos sinjalin për të gjithë';

  @override
  String signalBarTurnOff(String name) {
    return 'Fik sinjalin për $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Përdor $domain për instancën e parazgjedhur, ose URL-në e saktë të një instance tjetër.';
  }

  @override
  String get instanceResetToDefault => 'Kthehu te instanca e parazgjedhur';

  @override
  String get personaScopeTitle => 'Ku vlen persona';

  @override
  String get personaScopeGlobal => 'Kudo';

  @override
  String get personaScopeGlobalDescription =>
      'Një personë për të gjitha kanalet.';

  @override
  String get personaScopeChannel => 'Në çdo kanal';

  @override
  String get personaScopeChannelDescription =>
      'Çdo kanal mban personën e vet. Kanalet e reja nisin me llogarinë tënde.';

  @override
  String get personaPickerChannelOnly => 'Vetëm për këtë kanal';

  @override
  String get personaProfilePrivate => 'Profili i kësaj persone është privat.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Skedari i imazhit është shumë i madh. Zgjidh një skedar më të vogël se $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Kërko në KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Përditësimi nuk u shkarkua';

  @override
  String get appUpdateInstallFailed => 'Përditësimi nuk u instalua';

  @override
  String get personaChangeMessageFailed => 'Persona e mesazhit nuk u ndryshua';

  @override
  String get personaActiveCleared => 'Persona aktive u hoq';

  @override
  String get klipyPoweredBy => 'Mundësuar nga KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Çifti i etiketave “$pattern” përsëritet në këtë personë';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Shto çift etiketash ($count/5)';
  }

  @override
  String get personaTagExampleText => 'tekst';

  @override
  String get personaPreviewNameFallback => 'Përdorues';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne u mbyll papritur. Ndarja e të dhënave anonime për rrëzimet dhe gabimet na ndihmon t’i rregullojmë problemet më shpejt.';

  @override
  String get crashReportingSectionDescription =>
      'Ndihmo në rregullimin e defekteve në Tyne duke ndarë të dhëna për rrëzimet dhe performancën. Si parazgjedhje është çaktivizuar.';

  @override
  String get crashReportingDescription =>
      'Raportet shkojnë te gjurmuesi i gabimeve që mban vetë Tyne, edhe kur ke hyrë në një instancë tjetër. Ato nuk përfshijnë emra instancash, ID ose përmbajtje mesazhesh.';

  @override
  String get instanceOfflineTitle => 'Tyne është jashtë linje!';

  @override
  String get instanceOfflineBody => 'Po e hetojmë.';

  @override
  String get instanceStatusSignalLink =>
      'Bashkohu në bisedën tonë në Signal për përditësime';

  @override
  String get convertEmoticonsLabel => 'Shndërro emotikonat tekstuale në emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return '/$name nuk u ekzekutua: $detail';
  }

  @override
  String get guildCommandBroken => 'Skripti i saj ka një problem.';

  @override
  String guildCommandOneLine(String name) {
    return 'Ajo që shkruan pas /$name duhet të jetë në një rresht.';
  }

  @override
  String get permissionCreateCommands => 'Krijo komanda';

  @override
  String get permissionManageCommands => 'Menaxho komandat';

  @override
  String get permissionUseExternalCommands => 'Përdor komanda të jashtme';

  @override
  String get permissionCreateCommandsDescription =>
      'Krijo komanda për këtë komunitet, si dhe redakto ose fshi komandat e tua.';

  @override
  String get permissionManageCommandsDescription =>
      'Redakto ose fshi komandat e kujtdo në këtë komunitet.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Përdor komanda nga komunitete të tjera.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Përdor komanda nga komunitete të tjera në këtë kanal.';

  @override
  String get guildSettingsCategoryMessageTools => 'Mjetet e mesazheve';

  @override
  String get guildSettingsCommands => 'Komandat';

  @override
  String get guildCommandsLoadFailed => 'Komandat nuk u ngarkuan.';

  @override
  String get guildCommandsSubtitle =>
      'Mesazhe që anëtarët mund t’i postojnë duke shkruar /name.';

  @override
  String get guildCommandsSlots => 'Vende për komanda';

  @override
  String get guildCommandsNew => 'Komandë e re';

  @override
  String get guildCommandsSearch => 'Kërko komanda';

  @override
  String get guildCommandsEmptyTitle => 'Asnjë komandë';

  @override
  String get guildCommandsEmptyBody =>
      'Ky komunitet nuk ka ende asnjë komandë.';

  @override
  String get guildCommandsSaved => 'Komandat u ruajtën';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return '/$name nuk u ruajt: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Redakto /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Të fshihet /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Kjo nuk mund të zhbëhet. Mesazhet e krijuara me të vazhdojnë të tregojnë se cila komandë i krijoi.';

  @override
  String get guildCommandDelete => 'Fshi';

  @override
  String get guildCommandDeleteCommand => 'Fshi komandën';

  @override
  String get guildCommandSectionCommand => 'Komanda';

  @override
  String get guildCommandName => 'Emri';

  @override
  String get guildCommandNameInvalid =>
      'Përdor shkronja të vogla, numra, - dhe _, deri në 32 karaktere.';

  @override
  String get guildCommandNameTaken =>
      'Ky emër është tashmë i një komande tjetër ose i një komande të integruar.';

  @override
  String get guildCommandDescription => 'Përshkrimi';

  @override
  String get guildCommandSectionInput => 'Hyrja';

  @override
  String get guildCommandInputNone => 'Asnjë';

  @override
  String get guildCommandInputOptional => 'Opsionale';

  @override
  String get guildCommandInputRequired => 'E detyrueshme';

  @override
  String get guildCommandHint => 'Ndihmëz';

  @override
  String get guildCommandMessage => 'Mesazhi';

  @override
  String get guildCommandInsert => 'Fut:';

  @override
  String get guildCommandInsertPerson => 'Anëtari që e ekzekuton';

  @override
  String get guildCommandInsertInput => 'Çfarë shkruan anëtari';

  @override
  String get guildCommandPreview => 'Pamje paraprake';

  @override
  String get guildCommandSampleInput => 'Hyrje shembull';

  @override
  String guildCommandMadeWith(String name) {
    return 'Krijuar me /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Pastro kutinë e mesazhit për të përdorur /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Kjo nuk do të postonte asgjë, prandaj komanda do të dështonte.';

  @override
  String get guildCommandUseScriptEditor => 'Përdor redaktorin e skripteve';

  @override
  String get guildCommandUseBasicEditor => 'Përdor redaktorin bazë';

  @override
  String get guildCommandScript => 'Skript';

  @override
  String get guildCommandRunAgain => 'Ekzekuto sërish';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Nuk ka etiketë me emrin $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Nuk ka filtër me emrin $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name nuk mbyllet asnjëherë.';
  }

  @override
  String get guildCommandIssueTooLong => 'Skripti është tepër i gjatë.';

  @override
  String get guildCommandIssueTooLarge => 'Skripti prodhon tepër tekst.';

  @override
  String get guildCommandIssueTooSlow => 'Ekzekutimi i skriptit zgjati tepër.';

  @override
  String get guildCommandIssueInvalid => 'Kjo pjesë nuk mund të lexohet.';

  @override
  String get guildCommandIssueFailed => 'Kjo pjesë ndaloi me një gabim.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Rreshti $line, kolona $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Referenca e skripteve';

  @override
  String get guildCommandReferencePerson =>
      'Anëtari që e ekzekuton, si përmendje';

  @override
  String get guildCommandReferencePersonName => 'Emri i anëtarit';

  @override
  String get guildCommandReferenceTarget =>
      'Anëtari i parë që përmend, nëse ka';

  @override
  String get guildCommandReferenceTargetName => 'Emri i atij anëtari';

  @override
  String get guildCommandReferenceChannel => 'Kanali, si përmendje';

  @override
  String get guildCommandReferenceCommunity => 'Emri i këtij komuniteti';

  @override
  String get guildCommandExampleRandom => 'Zgjidh rastësisht një opsion';

  @override
  String get guildCommandExampleDepends =>
      'Ndrysho mesazhin sipas asaj që shkroi';

  @override
  String get guildCommandExampleOneWord => 'Zgjidh rastësisht një fjalë';

  @override
  String get guildCommandExampleWordForNumber => 'Zgjidh fjalën për një numër';

  @override
  String get guildCommandExampleOrdinal => 'Shkruaj një numër si 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Udhëzuesi i plotë i skripteve';

  @override
  String get guildCommandCounters => 'Numëruesit';

  @override
  String get guildCommandCounterAdd => 'Shto numërues';

  @override
  String get guildCommandCounterSeparately => 'Numëro veçmas sipas:';

  @override
  String get guildCommandCounterPersonMentioned => 'Anëtari i përmendur';

  @override
  String get guildCommandCounterChannel => 'Kanali';

  @override
  String get guildCommandCounterPersonas => 'Numëro personat veçmas';

  @override
  String get guildCommandCounterRemove => 'Hiq numëruesin';

  @override
  String get guildCommandCounterReset => 'Rivendos numërimet';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Të rivendosen numërimet për $name? Kjo nuk mund të zhbëhet.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Përdor shkronja të vogla, numra dhe _, duke filluar me shkronjë, dhe jo një emër që e përdorin tashmë skriptet.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Përdore në skript si $variable. Çdo ekzekutim i shton fillimisht një, kështu që në ekzekutimin e parë vlera është 1.';
  }

  @override
  String get notificationsAlertEveryMessageLabel => 'Njofto për çdo mesazh';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Kur është çaktivizuar, një bisedë e ngarkuar të njofton një herë, pastaj përditësohet në heshtje derisa ta lexosh ose ta heqësh njoftimin.';

  @override
  String personaGalleryTitle(int count) {
    return 'Personat ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Kërko te personat e $name';
  }

  @override
  String get personaGallerySearchOwn => 'Kërko te personat e tua';

  @override
  String get personaGallerySortBy => 'Rendit sipas';

  @override
  String get personaGallerySortName => 'Emri (A–Z)';

  @override
  String get personaGallerySortMostUsed => 'Më të përdorurat';

  @override
  String get personaGallerySortRecentlyUsed => 'Përdorur së fundi';

  @override
  String get personaGalleryViewGallery => 'Galeri';

  @override
  String get personaGalleryViewList => 'Listë';

  @override
  String get personaGalleryViewAvatars => 'Avatarë';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count personë',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return '$shown prej $total personash';
  }

  @override
  String get personaGalleryNoMatch =>
      'Asnjë personë nuk përputhet me kërkimin.';

  @override
  String get personaGalleryLoadFailed => 'Personat nuk u ngarkuan.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona publike',
      one: '$count personë publike',
    );
    return 'Të tjerët shohin $_temp0.';
  }

  @override
  String get personaGalleryShowHidden =>
      'Shfaq edhe ato jashtë listës dhe private';

  @override
  String get personaGalleryManage => 'Menaxho personat';

  @override
  String get personaGalleryNonePublic =>
      'Asnjë nga personat e tua nuk është ende publike. Të tjerët e shohin një personë këtu sapo t’ia caktosh dukshmërinë “Publike”.';

  @override
  String get personaGalleryNoBio => 'Ende pa biografi.';

  @override
  String personaGalleryCreated(String date) {
    return 'Krijuar më $date';
  }

  @override
  String get personaBulkSelect => 'Zgjidh';

  @override
  String get personaBulkSelectAll => 'Zgjidhi të gjitha';

  @override
  String personaBulkSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count të zgjedhura',
      one: '$count e zgjedhur',
    );
    return '$_temp0';
  }

  @override
  String get personaFilterAll => 'Të gjitha';

  @override
  String get personaBulkMakePublic => 'Bëji publike';

  @override
  String get personaBulkMakeUnlisted => 'Hiqi nga lista';

  @override
  String get personaBulkMakePrivate => 'Bëji private';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Të bëhen publike $count persona?',
      one: 'Të bëhet publike $count personë?',
    );
    return '$_temp0';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Të bëhen private $count persona?',
      one: 'Të bëhet private $count personë?',
    );
    return '$_temp0';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Të fshihen $count persona?',
      one: 'Të fshihet $count personë?',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Të tjerët do t’i shohin në listën tënde të personave dhe do të mund t’ua hapin profilet. Mund ta kthesh këtë si më parë në çdo kohë.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Profilet e tyre nuk do të jenë më të dukshme për të tjerët. Emrat dhe avatarët e tyre shfaqen ende në mesazhet dhe reagimet e tyre.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Personat e fshira mund t’i rikthesh më vonë te Cilësimet › Personat, te “Personat e fshira”.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona tani janë publike',
      one: '$count personë tani është publike',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona tani janë jashtë listës',
      one: '$count personë tani është jashtë listës',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona tani janë private',
      one: '$count personë tani është private',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'U fshinë $count persona',
      one: 'U fshi $count personë',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed => 'Personat nuk u ndryshuan. Provo sërish.';

  @override
  String get personaFilterEmpty => 'Nuk ka persona këtu.';

  @override
  String get personaGalleryChooseFeatured => 'Zgjidh cilat persona të shfaqen';

  @override
  String get personaUndo => 'Zhbëj';

  @override
  String get personaReactionsTitle => 'Reagimet e tua';

  @override
  String get personaReactionsEveryoneElse => 'TË GJITHË TË TJERËT';

  @override
  String get personaReactionsCurrent => 'AKTUALE';

  @override
  String get personaReactionsAccount => 'Llogaria';

  @override
  String get personaReactionsSomeoneElse => 'Reago si dikush tjetër…';

  @override
  String get personaReactionsDone => 'U krye';

  @override
  String get personaSettingsReactionsHeader => 'Reagimet';

  @override
  String get personaSettingsMultiReactions => 'Reago si disa persona njëherësh';

  @override
  String get personaDuplicateButton => 'Dyfisho personën';

  @override
  String personaCopyOf(String name) {
    return 'Kopje e personës $name';
  }

  @override
  String signalsEverywhereTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count biseda',
      one: '$count bisedë',
    );
    return 'Sinjalet e tua kudo · $_temp0';
  }

  @override
  String signalsEverywhereHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count biseda',
      one: '$count bisedë',
    );
    return 'Vendos kudo ($_temp0)';
  }

  @override
  String signalsEverywhereSet(String label) {
    return 'Vendos $label kudo';
  }

  @override
  String get signalsEverywhereTurnAllOff => 'Fiki të gjitha';

  @override
  String get signalsEverywhereRestore => 'Rikthe…';

  @override
  String get signalsEverywhereNone =>
      'Asnjë nga sinjalet e tua nuk është ndezur askund.';

  @override
  String get signalsRestoreTitle => 'Të rikthehen sinjalet e tua?';

  @override
  String signalsRestoreBeforeSet(String label, String time) {
    return 'Rikthen atë që kishe ndezur para se të vendosje $label kudo ($time). Ajo që ke ndezur aty tani do të fiket.';
  }

  @override
  String signalsRestoreBeforeOff(String time) {
    return 'Rikthen atë që kishe ndezur para se t’i fikje të gjitha ($time). Ajo që ke ndezur aty tani do të fiket.';
  }

  @override
  String signalsRestoreBeforeRestore(String time) {
    return 'Rikthen atë që kishe ndezur para rikthimit tënd të fundit ($time). Ajo që ke ndezur aty tani do të fiket.';
  }

  @override
  String get signalsRestoreNow => 'Tani';

  @override
  String get signalsRestoreAfter => 'Pas';

  @override
  String signalsRestoreLeftOut(String chats) {
    return 'Lënë jashtë, sepse nuk mund të shkruash më aty: $chats';
  }

  @override
  String get signalsRestoreConfirm => 'Rikthe';

  @override
  String get signalsRestoreUnavailable =>
      'Nuk u ngarkua dot se çfarë do të ndryshonte “Rikthe”. Provo sërish.';

  @override
  String get signalsRestoreNothing => 'Nuk ka asgjë për t’u rikthyer.';

  @override
  String get signalsProfileMenu => 'Sinjalet';

  @override
  String get signalsEverywhereTurnOffChat => 'Fik sinjalet';

  @override
  String signalsRestoreBeforeChange(String time) {
    return 'Rikthen atë që kishe ndezur para ndryshimit tënd të fundit kudo ($time). Ajo që ke ndezur aty tani do të fiket.';
  }

  @override
  String get personaCopyBadge => 'Personë e re';

  @override
  String get deletedPersonasTitle => 'Personat e fshira';

  @override
  String get deletedPersonasDescription =>
      'Personat e fshira shfaqen ende në mesazhet e tyre të vjetra, por askush nuk mund t’i zgjedhë dhe nuk llogariten në kufirin tënd. Rikthimi i njërës sjell sërish të njëjtën personë, me historikun e saj.';

  @override
  String get deletedPersonasShow => 'Shfaq personat e fshira';

  @override
  String get deletedPersonasLoadFailed => 'Personat e fshira nuk u ngarkuan.';

  @override
  String get deletedPersonasEmpty => 'Nuk ka persona të fshira.';

  @override
  String deletedPersonaDeletedAt(String date) {
    return 'Fshirë më $date';
  }

  @override
  String deletedPersonaUseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Përdorur $count herë',
      one: 'Përdorur një herë',
    );
    return '$_temp0';
  }

  @override
  String get deletedPersonaRestore => 'Rikthe';

  @override
  String personaRestored(String name) {
    return '$name u rikthye.';
  }

  @override
  String personaRestoredWithout(String items) {
    return 'U rikthye pa $items: tani i ka një personë tjetër.';
  }

  @override
  String get personaRestoreFailed => 'Persona nuk u rikthye.';

  @override
  String deletedPersonaRestoreLabel(String name) {
    return 'Rikthe $name';
  }
}
