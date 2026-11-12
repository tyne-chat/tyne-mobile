// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class ForkLocalizationsEl extends ForkLocalizations {
  ForkLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Αλλαγή persona';

  @override
  String get chatAttachmentPanelVoice => 'Φωνή';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Κουμπί γρήγορης εναλλαγής';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Αντικατάσταση του κουμπιού φωνητικού μηνύματος στο πεδίο μηνύματος με κουμπί γρήγορης εναλλαγής για ταχύτερη πλοήγηση';

  @override
  String get userSettingsCheckForUpdates => 'Έλεγχος για ενημερώσεις';

  @override
  String get userSettingsCheckingForUpdates => 'Έλεγχος για ενημερώσεις…';

  @override
  String get userSettingsAppUpToDate => 'Το Tyne είναι ενημερωμένο';

  @override
  String get userSettingsUpdateAvailableTitle => 'Διαθέσιμη ενημέρωση';

  @override
  String get userSettingsUpdateDownloadAction => 'Λήψη & εγκατάσταση';

  @override
  String get userSettingsUpdateInstallAction => 'Εγκατάσταση ενημέρωσης';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Λήψη ενημέρωσης ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed => 'Αποτυχία ελέγχου ή λήψης ενημέρωσης.';

  @override
  String get personaSelectTitle => 'Επιλογή persona';

  @override
  String get personaSettingsHeader => 'Ρυθμίσεις persona';

  @override
  String get personaManageAction => 'Διαχείριση';

  @override
  String get personaSearchPlaceholder =>
      'Αναζήτηση persona, ετικετών, αντωνυμιών...';

  @override
  String get personaModeManual => 'Μη αυτόματα';

  @override
  String get personaModeLast => 'Τελευταία χρήση';

  @override
  String get personaModeManualDescription =>
      'Αποστέλλεται πάντα ως η επιλεγμένη persona μέχρι να αλλάξει.';

  @override
  String get personaModeLastDescription =>
      'Μεταβαίνει αυτόματα στην persona που χρησιμοποιήθηκε στο τελευταίο σας μήνυμα.';

  @override
  String get personaRecentHeader => 'ΠΡΟΣΦΑΤΕΣ PERSONA';

  @override
  String personaAllHeader(int count) {
    return 'ΟΛΕΣ ΟΙ PERSONA ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'ΑΠΟΤΕΛΕΣΜΑΤΑ ΑΝΑΖΗΤΗΣΗΣ ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Κύριος λογαριασμός (Προεπιλογή)';

  @override
  String get personaEmptyState =>
      'Δεν έχουν ρυθμιστεί ακόμη persona. Δημιουργήστε μία μέσω της Διαχείρισης persona.';

  @override
  String get personaEmptySearch => 'Δεν βρέθηκαν αντίστοιχες persona.';

  @override
  String get personaEditTitle => 'Επεξεργασία persona';

  @override
  String get personaCreateTitle => 'Δημιουργία persona';

  @override
  String get personaDisplayNameLabel => 'Όνομα εμφάνισης';

  @override
  String get personaPronounsLabel => 'Αντωνυμίες';

  @override
  String get personaPronounsHint => 'π.χ. αυτοί/αυτές';

  @override
  String get personaBioHint => 'Πείτε στους άλλους για αυτήν την persona...';

  @override
  String get personaUpdatedToast => 'Η persona ενημερώθηκε';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Αποτυχία ενημέρωσης persona: $error';
  }

  @override
  String get personaSectionTitle => 'Persona';

  @override
  String get personaDisplayNameHint => 'Όνομα persona';

  @override
  String personaSendingAsTag(String name) {
    return 'Αποστολή ως $name (Ταιριάζει με ετικέτα)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Αποστολή ως $name (Κλειδωμένο)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Αποστολή ως $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Δημοσίευση ως $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Αποστολή ως @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'Δεν στάλθηκε: οι persona σας δεν έχουν φορτωθεί ακόμη.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Δεν στάλθηκε: οι persona σας δεν έχουν φορτωθεί ακόμη. Να σταλεί ως @$username;';
  }

  @override
  String get personaSendAsAccountAction => 'Αποστολή ούτως ή άλλως';

  @override
  String get personaMainAccount => 'Κύριος λογαριασμός';

  @override
  String get personaEditPersona => 'Επεξεργασία persona';

  @override
  String get userSettingsNavPersonas => 'Persona';

  @override
  String get personaSettingsDescription =>
      'Ρυθμίστε τη λειτουργία ενεργής persona, την προσαρμοσμένη ετικέτα εμφάνισης και διαχειριστείτε μεμονωμένες persona.';

  @override
  String get personaDisplayTagSection => 'Ετικέτα εμφάνισης';

  @override
  String get personaDisplayTagDescription =>
      'Η ετικέτα εμφάνισης θα εμφανίζεται δίπλα σε όλα τα ονόματα persona στα μηνύματα. Αν δεν οριστεί ετικέτα εμφάνισης, θα εμφανίζεται η εικόνα προφίλ του λογαριασμού σας.';

  @override
  String get personaDisplayTagLabel => 'Κείμενο ετικέτας εμφάνισης';

  @override
  String get personaDisplayTagHint => 'π.χ. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Εικονίδιο ετικέτας εμφάνισης';

  @override
  String get personaUploadTagIcon => 'Ανέβασμα εικονιδίου';

  @override
  String get personaChangeTagIcon => 'Αλλαγή εικονιδίου';

  @override
  String get personaRemoveTagIcon => 'Αφαίρεση εικονιδίου';

  @override
  String get personaChatPreviewTitle => 'Προεπισκόπηση συνομιλίας';

  @override
  String get personaChatPreviewSampleMessage =>
      'Γεια σας! Αυτή είναι μια προεπισκόπηση του πώς φαίνονται τα μηνύματα με την ετικέτα εμφάνισης και την ενεργή persona σας.';

  @override
  String get personaListTitle => 'Διαμορφωμένες persona';

  @override
  String get personaAddButton => 'Προσθήκη persona';

  @override
  String get personaActiveBadge => 'Ενεργό';

  @override
  String get personaMakeActive => 'Ορισμός ως ενεργό';

  @override
  String get personaDeleteTitle => 'Διαγραφή persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Είστε σίγουροι ότι θέλετε να διαγράψετε το \"$name\"; Μπορείτε αργότερα να επαναφέρετε διαγραμμένες persona από τις Ρυθμίσεις › Persona, στις «Διαγραμμένες persona».';
  }

  @override
  String get personaDeleteConfirm => 'Διαγραφή';

  @override
  String get personaDeletedToast => 'Η persona διαγράφηκε';

  @override
  String get personaCreatedToast => 'Η persona δημιουργήθηκε';

  @override
  String personaCreateFailedToast(String error) {
    return 'Αποτυχία δημιουργίας persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Αλλαγή εικόνας προφίλ';

  @override
  String get personaRemoveAvatar => 'Αφαίρεση εικόνας προφίλ';

  @override
  String get personaUploadAvatar => 'Ανέβασμα εικόνας προφίλ';

  @override
  String get personaTagsLabel => 'Ετικέτες persona';

  @override
  String get personaAutoTagDisabledLabel =>
      'Να μην αναγνωρίζονται οι ετικέτες αυτής της persona';

  @override
  String get personaAutoTagDisabledDescription =>
      'Η πληκτρολόγηση μιας από αυτές τις ετικέτες δεν θα σας μεταφέρει σε αυτή την persona. Η ετικέτα αποστέλλεται όπως γράφτηκε.';

  @override
  String get personaTagPrefixLabel => 'Πρόθεμα';

  @override
  String get personaTagSuffixLabel => 'Επίθημα';

  @override
  String get personaVisibilityLabel => 'Ορατότητα';

  @override
  String get personaVisibilityUnlisted => 'Μη καταχωρισμένο';

  @override
  String get personaVisibilityPublic => 'Δημόσιο';

  @override
  String get personaVisibilityPrivate => 'Ιδιωτικό';

  @override
  String get personaNameRequired => 'Εισαγάγετε ένα εμφανιζόμενο όνομα persona';

  @override
  String get personaNameTooLong =>
      'Το εμφανιζόμενο όνομα persona πρέπει να περιέχει έως 100 χαρακτήρες';

  @override
  String get personaTagPrefixTooLong =>
      'Το πρόθεμα ετικέτας persona πρέπει να περιέχει έως 32 χαρακτήρες';

  @override
  String get personaTagSuffixTooLong =>
      'Το επίθημα ετικέτας persona πρέπει να περιέχει έως 32 χαρακτήρες';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Η ετικέτα \'$tag\' χρησιμοποιείται ήδη από την persona \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Εισαγωγή χρονικής σήμανσης';

  @override
  String get chatAttachmentSendVoiceMessage => 'Αποστολή φωνητικού μηνύματος';

  @override
  String get timestampPickerTitle => 'Εισαγωγή χρονικής σήμανσης';

  @override
  String get timestampPickerInsert => 'Εισαγωγή';

  @override
  String get timestampCopied => 'Η χρονική σήμανση αντιγράφηκε';

  @override
  String get timestampPickerTimeLabel => 'Ώρα';

  @override
  String get timestampPickerDateLabel => 'ΗΜΕΡΟΜΗΝΙΑ';

  @override
  String get timestampPickerTimeSectionLabel => 'ΩΡΑ';

  @override
  String get timestampPickerTimezoneLabel => 'ΖΩΝΗ ΩΡΑΣ';

  @override
  String get timestampPickerFormatPreviewLabel => 'ΠΡΟΕΠΙΣΚΟΠΗΣΗ ΜΟΡΦΗΣ';

  @override
  String get timestampPickerNlpPlaceholder =>
      'π.χ. αύριο στις 3 μ.μ., σε 2 ώρες, τώρα';

  @override
  String get timestampPickerSearchTimezones => 'Αναζήτηση ζωνών ώρας...';

  @override
  String get userProfileTimezoneSettingLabel => 'Ζώνη ώρας';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Χρησιμοποιείται για την εμφάνιση της τοπικής ώρας στο προφίλ σας.';

  @override
  String get userProfileTimezoneNone => 'Κανένα';

  @override
  String get chatReactAs => 'Αντίδραση ως...';

  @override
  String get emojiCopy => 'Αντιγραφή emoji';

  @override
  String get emojiCopyLink => 'Αντιγραφή συνδέσμου';

  @override
  String get emojiPin => 'Καρφίτσωμα emoji';

  @override
  String get emojiUnpin => 'Ξεκαρφίτσωμα emoji';

  @override
  String get emojiPinForPersona => 'Καρφίτσωμα για αυτήν την persona';

  @override
  String get emojiUnpinForPersona => 'Ξεκαρφίτσωμα για αυτήν την persona';

  @override
  String get personaSignatureEmojisLabel => 'Χαρακτηριστικά emoji';

  @override
  String get personaSignatureEmojisDescription =>
      'Η αντίδραση με ένα χαρακτηριστικό emoji θα αντιδρά πάντα ως αυτή η περσόνα, ανεξάρτητα από την ενεργή περσόνα.';

  @override
  String get personaAddSignatureEmoji => 'Προσθήκη emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Αυτό το emoji έχει ήδη προστεθεί ως χαρακτηριστικό emoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Το χαρακτηριστικό emoji χρησιμοποιείται ήδη από την περσόνα «$name»';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Κατάργηση χαρακτηριστικού emoji';

  @override
  String get signalBarLabel => 'Γραμμή σημάτων';

  @override
  String get signalBarShow => 'Εμφάνιση γραμμής σημάτων';

  @override
  String get signalBarHide => 'Απόκρυψη γραμμής σημάτων';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Κανείς δεν έχει ενεργό αυτό το σήμα';

  @override
  String get signalBarReset => 'Επαναφορά σήματος για όλους';

  @override
  String signalBarTurnOff(String name) {
    return 'Απενεργοποίηση $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Χρησιμοποιήστε το $domain για την προεπιλεγμένη εγκατάσταση ή την ακριβή διεύθυνση URL μιας άλλης εγκατάστασης.';
  }

  @override
  String get instanceResetToDefault =>
      'Επαναφορά στην προεπιλεγμένη εγκατάσταση';

  @override
  String get personaScopeTitle => 'Η persona ισχύει για';

  @override
  String get personaScopeGlobal => 'Παντού';

  @override
  String get personaScopeGlobalDescription => 'Μία persona για όλα τα κανάλια.';

  @override
  String get personaScopeChannel => 'Σε κάθε κανάλι';

  @override
  String get personaScopeChannelDescription =>
      'Κάθε κανάλι κρατά τη δική του persona. Τα νέα κανάλια ξεκινούν με τον λογαριασμό σας.';

  @override
  String get personaPickerChannelOnly => 'Μόνο για αυτό το κανάλι';

  @override
  String get personaProfilePrivate =>
      'Το προφίλ αυτής της persona είναι ιδιωτικό.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Το αρχείο εικόνας είναι πολύ μεγάλο. Επιλέξτε ένα αρχείο μικρότερο από $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Αναζήτηση KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Η λήψη της ενημέρωσης απέτυχε';

  @override
  String get appUpdateInstallFailed => 'Η εγκατάσταση της ενημέρωσης απέτυχε';

  @override
  String get personaChangeMessageFailed =>
      'Η αλλαγή της persona του μηνύματος απέτυχε';

  @override
  String get personaActiveCleared => 'Η ενεργή persona καταργήθηκε';

  @override
  String get klipyPoweredBy => 'Με την υποστήριξη του KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Διπλό ζεύγος ετικετών \'$pattern\' σε αυτήν την persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Προσθήκη ζεύγους ετικετών ($count/5)';
  }

  @override
  String get personaTagExampleText => 'κείμενο';

  @override
  String get personaPreviewNameFallback => 'Χρήστης';

  @override
  String get crashReportingConsentSubtitle =>
      'Το Tyne έκλεισε απροσδόκητα. Η κοινοποίηση ανώνυμων δεδομένων κατάρρευσης και σφαλμάτων μάς βοηθά να διορθώνουμε τα προβλήματα πιο γρήγορα.';

  @override
  String get crashReportingSectionDescription =>
      'Βοηθήστε στη διόρθωση σφαλμάτων στο Tyne κοινοποιώντας δεδομένα κατάρρευσης και απόδοσης. Είναι απενεργοποιημένο από προεπιλογή.';

  @override
  String get crashReportingDescription =>
      'Οι αναφορές αποστέλλονται στο δικό σύστημα παρακολούθησης σφαλμάτων του Tyne, ακόμη και όταν είστε συνδεδεμένοι σε άλλη παρουσία. Δεν περιλαμβάνουν ονόματα παρουσιών, αναγνωριστικά ή περιεχόμενο μηνυμάτων.';

  @override
  String get instanceOfflineTitle => 'Το Tyne είναι εκτός σύνδεσης!';

  @override
  String get instanceOfflineBody => 'Το διερευνούμε.';

  @override
  String get instanceStatusSignalLink =>
      'Μπείτε στη συνομιλία μας στο Signal για ενημερώσεις';

  @override
  String get convertEmoticonsLabel => 'Μετατροπή φατσούλων κειμένου σε emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Δεν ήταν δυνατή η εκτέλεση της /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Το σενάριό της έχει πρόβλημα.';

  @override
  String guildCommandOneLine(String name) {
    return 'Ό,τι πληκτρολογείτε μετά την /$name πρέπει να χωράει σε μία γραμμή.';
  }

  @override
  String get permissionCreateCommands => 'Δημιουργία εντολών';

  @override
  String get permissionManageCommands => 'Διαχείριση εντολών';

  @override
  String get permissionUseExternalCommands => 'Χρήση εξωτερικών εντολών';

  @override
  String get permissionCreateCommandsDescription =>
      'Δημιουργήστε εντολές για αυτή την κοινότητα και επεξεργαστείτε ή διαγράψτε τις δικές σας.';

  @override
  String get permissionManageCommandsDescription =>
      'Επεξεργαστείτε ή διαγράψτε τις εντολές οποιουδήποτε σε αυτή την κοινότητα.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Χρησιμοποιήστε εντολές από άλλες κοινότητες.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Χρησιμοποιήστε εντολές από άλλες κοινότητες σε αυτό το κανάλι.';

  @override
  String get guildSettingsCategoryMessageTools => 'Εργαλεία μηνυμάτων';

  @override
  String get guildSettingsCommands => 'Εντολές';

  @override
  String get guildCommandsLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση των εντολών.';

  @override
  String get guildCommandsSubtitle =>
      'Μηνύματα που μπορούν να δημοσιεύσουν τα μέλη πληκτρολογώντας /name.';

  @override
  String get guildCommandsSlots => 'Θέσεις για εντολές';

  @override
  String get guildCommandsNew => 'Νέα εντολή';

  @override
  String get guildCommandsSearch => 'Αναζήτηση εντολών';

  @override
  String get guildCommandsEmptyTitle => 'Δεν υπάρχουν εντολές';

  @override
  String get guildCommandsEmptyBody =>
      'Αυτή η κοινότητα δεν έχει ακόμη εντολές.';

  @override
  String get guildCommandsSaved => 'Οι εντολές αποθηκεύτηκαν';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Δεν ήταν δυνατή η αποθήκευση της /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Επεξεργασία της /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Διαγραφή της /$name;';
  }

  @override
  String get guildCommandDeleteBody =>
      'Αυτό δεν μπορεί να αναιρεθεί. Τα μηνύματα που δημιουργήθηκαν με αυτήν εξακολουθούν να δείχνουν ποια εντολή τα δημιούργησε.';

  @override
  String get guildCommandDelete => 'Διαγραφή';

  @override
  String get guildCommandDeleteCommand => 'Διαγραφή εντολής';

  @override
  String get guildCommandSectionCommand => 'Εντολή';

  @override
  String get guildCommandName => 'Όνομα';

  @override
  String get guildCommandNameInvalid =>
      'Χρησιμοποιήστε πεζά γράμματα, αριθμούς, - και _, έως 32 χαρακτήρες.';

  @override
  String get guildCommandNameTaken =>
      'Μια άλλη εντολή ή μια ενσωματωμένη εντολή έχει ήδη αυτό το όνομα.';

  @override
  String get guildCommandDescription => 'Περιγραφή';

  @override
  String get guildCommandSectionInput => 'Εισαγωγή';

  @override
  String get guildCommandInputNone => 'Καμία';

  @override
  String get guildCommandInputOptional => 'Προαιρετικό';

  @override
  String get guildCommandInputRequired => 'Απαιτείται';

  @override
  String get guildCommandHint => 'Υπόδειξη';

  @override
  String get guildCommandMessage => 'Μήνυμα';

  @override
  String get guildCommandInsert => 'Εισαγωγή:';

  @override
  String get guildCommandInsertPerson => 'Όποιος τη χρησιμοποιεί';

  @override
  String get guildCommandInsertInput => 'Τι πληκτρολογούν';

  @override
  String get guildCommandPreview => 'Προεπισκόπηση';

  @override
  String get guildCommandSampleInput => 'Δείγμα κειμένου';

  @override
  String guildCommandMadeWith(String name) {
    return 'Δημιουργήθηκε με την /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Αδειάστε το πλαίσιο μηνύματος για να χρησιμοποιήσετε την /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Αυτό δεν θα δημοσίευε τίποτα, οπότε η εντολή θα αποτύγχανε.';

  @override
  String get guildCommandUseScriptEditor => 'Χρήση του επεξεργαστή σεναρίων';

  @override
  String get guildCommandUseBasicEditor => 'Χρήση του βασικού επεξεργαστή';

  @override
  String get guildCommandScript => 'Σενάριο';

  @override
  String get guildCommandRunAgain => 'Εκτέλεση ξανά';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Δεν υπάρχει ετικέτα με το όνομα $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Δεν υπάρχει φίλτρο με το όνομα $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return 'Το $name δεν κλείνει ποτέ.';
  }

  @override
  String get guildCommandIssueTooLong => 'Το σενάριο είναι υπερβολικά μεγάλο.';

  @override
  String get guildCommandIssueTooLarge =>
      'Το σενάριο παράγει υπερβολικά πολύ κείμενο.';

  @override
  String get guildCommandIssueTooSlow =>
      'Η εκτέλεση του σεναρίου διήρκεσε υπερβολικά πολύ.';

  @override
  String get guildCommandIssueInvalid =>
      'Αυτό το τμήμα δεν μπορεί να διαβαστεί.';

  @override
  String get guildCommandIssueFailed => 'Αυτό το τμήμα σταμάτησε με σφάλμα.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Γραμμή $line, στήλη $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Οδηγός σεναρίων';

  @override
  String get guildCommandReferencePerson =>
      'Όποιος τη χρησιμοποιεί, ως αναφορά';

  @override
  String get guildCommandReferencePersonName =>
      'Το όνομα όποιου τη χρησιμοποιεί';

  @override
  String get guildCommandReferenceTarget =>
      'Το πρώτο άτομο που αναφέρουν, αν υπάρχει';

  @override
  String get guildCommandReferenceTargetName => 'Το όνομα αυτού του ατόμου';

  @override
  String get guildCommandReferenceChannel => 'Το κανάλι, ως αναφορά';

  @override
  String get guildCommandReferenceCommunity => 'Το όνομα αυτής της κοινότητας';

  @override
  String get guildCommandExampleRandom => 'Τυχαία επιλογή μίας εναλλακτικής';

  @override
  String get guildCommandExampleDepends =>
      'Αλλαγή του μηνύματος ανάλογα με το τι πληκτρολόγησαν';

  @override
  String get guildCommandExampleOneWord => 'Τυχαία επιλογή μίας λέξης';

  @override
  String get guildCommandExampleWordForNumber =>
      'Επιλογή της λέξης ανάλογα με έναν αριθμό';

  @override
  String get guildCommandExampleOrdinal => 'Γραφή αριθμού ως 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Πλήρης οδηγός σεναρίων';

  @override
  String get guildCommandCounters => 'Μετρητές';

  @override
  String get guildCommandCounterAdd => 'Προσθήκη μετρητή';

  @override
  String get guildCommandCounterSeparately => 'Ξεχωριστή μέτρηση για κάθε:';

  @override
  String get guildCommandCounterPersonMentioned => 'Άτομο που αναφέρθηκε';

  @override
  String get guildCommandCounterChannel => 'Κανάλι';

  @override
  String get guildCommandCounterPersonas => 'Ξεχωριστή μέτρηση persona';

  @override
  String get guildCommandCounterRemove => 'Αφαίρεση μετρητή';

  @override
  String get guildCommandCounterReset => 'Επαναφορά μετρήσεων';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Επαναφορά των μετρήσεων του $name; Αυτό δεν αναιρείται.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Χρησιμοποίησε πεζά λατινικά γράμματα, αριθμούς και _, ξεκίνα με γράμμα και απόφυγε ονόματα που χρησιμοποιούν ήδη τα σενάρια.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Χρησιμοποίησέ το σε σενάριο ως $variable. Κάθε εκτέλεση προσθέτει πρώτα ένα, οπότε η πρώτη διαβάζει 1.';
  }

  @override
  String get notificationsAlertEveryMessageLabel =>
      'Ειδοποίηση για κάθε μήνυμα';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Όταν είναι ανενεργό, μια πολυσύχναστη συνομιλία σε ειδοποιεί μία φορά και μετά ενημερώνεται αθόρυβα μέχρι να τη διαβάσεις ή να την απορρίψεις.';

  @override
  String personaGalleryTitle(int count) {
    return 'Persona ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Αναζήτηση στις persona του χρήστη $name';
  }

  @override
  String get personaGallerySearchOwn => 'Αναζήτηση στις persona σας';

  @override
  String get personaGallerySortBy => 'Ταξινόμηση κατά';

  @override
  String get personaGallerySortName => 'Όνομα (Α–Ω)';

  @override
  String get personaGallerySortMostUsed => 'Οι πιο χρησιμοποιημένες';

  @override
  String get personaGallerySortRecentlyUsed => 'Πρόσφατα χρησιμοποιημένες';

  @override
  String get personaGalleryViewGallery => 'Συλλογή';

  @override
  String get personaGalleryViewList => 'Λίστα';

  @override
  String get personaGalleryViewAvatars => 'Εικόνες προφίλ';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return '$shown από $total persona';
  }

  @override
  String get personaGalleryNoMatch =>
      'Καμία persona δεν ταιριάζει με την αναζήτησή σας.';

  @override
  String get personaGalleryLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση των persona.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count δημόσιες persona',
      one: '$count δημόσια persona',
    );
    return 'Οι άλλοι βλέπουν $_temp0.';
  }

  @override
  String get personaGalleryShowHidden =>
      'Εμφάνιση μη καταχωρισμένων και ιδιωτικών';

  @override
  String get personaGalleryManage => 'Διαχείριση persona';

  @override
  String get personaGalleryNonePublic =>
      'Καμία από τις persona σας δεν είναι ακόμη δημόσια. Οι άλλοι βλέπουν μια persona εδώ μόλις ορίσετε την ορατότητά της σε «Δημόσιο».';

  @override
  String get personaGalleryNoBio => 'Δεν υπάρχει ακόμη βιογραφικό.';

  @override
  String personaGalleryCreated(String date) {
    return 'Δημιουργήθηκε $date';
  }

  @override
  String get personaBulkSelect => 'Επιλογή';

  @override
  String get personaBulkSelectAll => 'Επιλογή όλων';

  @override
  String personaBulkSelectedCount(int count) {
    return '$count επιλεγμένες';
  }

  @override
  String get personaFilterAll => 'Όλες';

  @override
  String get personaBulkMakePublic => 'Ορισμός ως δημόσιες';

  @override
  String get personaBulkMakeUnlisted => 'Ορισμός ως μη καταχωρισμένες';

  @override
  String get personaBulkMakePrivate => 'Ορισμός ως ιδιωτικές';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return 'Ορισμός $_temp0 ως δημόσιων;';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return 'Ορισμός $_temp0 ως ιδιωτικών;';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona',
      one: '$count persona',
    );
    return 'Διαγραφή $_temp0;';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Οι άλλοι θα τις βλέπουν στη λίστα persona σας και θα μπορούν να ανοίγουν τα προφίλ τους. Μπορείτε να το αλλάξετε ξανά οποιαδήποτε στιγμή.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Τα προφίλ τους θα κρυφτούν από τους άλλους. Τα ονόματα και τα avatar τους θα εμφανίζονται ακόμη στα μηνύματα και στις αντιδράσεις τους.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Μπορείτε αργότερα να επαναφέρετε διαγραμμένες persona από τις Ρυθμίσεις › Persona, στις «Διαγραμμένες persona».';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona είναι πλέον δημόσιες',
      one: '$count persona είναι πλέον δημόσια',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona είναι πλέον μη καταχωρισμένες',
      one: '$count persona είναι πλέον μη καταχωρισμένη',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persona είναι πλέον ιδιωτικές',
      one: '$count persona είναι πλέον ιδιωτική',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Διαγράφηκαν $count persona',
      one: 'Διαγράφηκε $count persona',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed =>
      'Δεν ήταν δυνατή η αλλαγή των persona. Δοκιμάστε ξανά.';

  @override
  String get personaFilterEmpty => 'Δεν υπάρχουν persona εδώ.';

  @override
  String get personaGalleryChooseFeatured => 'Επιλέξτε persona για προβολή';

  @override
  String get personaUndo => 'Αναίρεση';

  @override
  String get personaReactionsTitle => 'Οι αντιδράσεις σας';

  @override
  String get personaReactionsEveryoneElse => 'ΟΛΟΙ ΟΙ ΑΛΛΟΙ';

  @override
  String get personaReactionsCurrent => 'ΤΡΕΧΟΥΣΑ';

  @override
  String get personaReactionsAccount => 'Λογαριασμός';

  @override
  String get personaReactionsSomeoneElse => 'Αντίδραση ως κάποιος άλλος...';

  @override
  String get personaReactionsDone => 'Τέλος';

  @override
  String get personaSettingsReactionsHeader => 'Αντιδράσεις';

  @override
  String get personaSettingsMultiReactions =>
      'Αντίδραση ως πολλές persona ταυτόχρονα';

  @override
  String get personaDuplicateButton => 'Αντιγραφή persona';

  @override
  String personaCopyOf(String name) {
    return 'Αντίγραφο της persona $name';
  }

  @override
  String signalsEverywhereTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count συνομιλίες',
      one: '$count συνομιλία',
    );
    return 'Τα σήματά σου παντού · $_temp0';
  }

  @override
  String signalsEverywhereHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count συνομιλίες',
      one: '$count συνομιλία',
    );
    return 'Ορισμός παντού ($_temp0)';
  }

  @override
  String signalsEverywhereSet(String label) {
    return 'Ορισμός του $label παντού';
  }

  @override
  String get signalsEverywhereTurnAllOff => 'Απενεργοποίηση όλων';

  @override
  String get signalsEverywhereRestore => 'Επαναφορά…';

  @override
  String get signalsEverywhereNone =>
      'Κανένα από τα σήματά σου δεν είναι ενεργό πουθενά.';

  @override
  String get signalsRestoreTitle => 'Επαναφορά των σημάτων σου;';

  @override
  String signalsRestoreBeforeSet(String label, String time) {
    return 'Επαναφέρει ό,τι είχες ενεργό πριν ορίσεις το $label παντού ($time). Ό,τι έχεις ενεργό εκεί τώρα θα απενεργοποιηθεί.';
  }

  @override
  String signalsRestoreBeforeOff(String time) {
    return 'Επαναφέρει ό,τι είχες ενεργό πριν τα απενεργοποιήσεις όλα ($time). Ό,τι έχεις ενεργό εκεί τώρα θα απενεργοποιηθεί.';
  }

  @override
  String signalsRestoreBeforeRestore(String time) {
    return 'Επαναφέρει ό,τι είχες ενεργό πριν από την τελευταία σου επαναφορά ($time). Ό,τι έχεις ενεργό εκεί τώρα θα απενεργοποιηθεί.';
  }

  @override
  String get signalsRestoreNow => 'Τώρα';

  @override
  String get signalsRestoreAfter => 'Μετά';

  @override
  String signalsRestoreLeftOut(String chats) {
    return 'Παραλείπονται, επειδή δεν μπορείς πια να γράψεις εκεί: $chats';
  }

  @override
  String get signalsRestoreConfirm => 'Επαναφορά';

  @override
  String get signalsRestoreUnavailable =>
      'Δεν ήταν δυνατή η φόρτωση όσων θα άλλαζε η «Επαναφορά». Δοκίμασε ξανά.';

  @override
  String get signalsRestoreNothing => 'Δεν υπάρχει τίποτα για επαναφορά.';

  @override
  String get signalsProfileMenu => 'Σήματα';

  @override
  String get signalsEverywhereTurnOffChat => 'Απενεργοποίηση σημάτων';

  @override
  String signalsRestoreBeforeChange(String time) {
    return 'Επαναφέρει ό,τι είχες ενεργό πριν από την τελευταία σου αλλαγή παντού ($time). Ό,τι έχεις ενεργό εκεί τώρα θα απενεργοποιηθεί.';
  }

  @override
  String get personaCopyBadge => 'Νέα persona';

  @override
  String get deletedPersonasTitle => 'Διαγραμμένες persona';

  @override
  String get deletedPersonasDescription =>
      'Οι διαγραμμένες persona εξακολουθούν να εμφανίζονται στα παλιά τους μηνύματα, αλλά κανείς δεν μπορεί να τις επιλέξει και δεν μετρούν στο όριό σας. Η επαναφορά μιας persona τη φέρνει πίσω ίδια, με το ιστορικό της.';

  @override
  String get deletedPersonasShow => 'Εμφάνιση διαγραμμένων persona';

  @override
  String get deletedPersonasLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση των διαγραμμένων persona.';

  @override
  String get deletedPersonasEmpty => 'Δεν υπάρχουν διαγραμμένες persona.';

  @override
  String deletedPersonaDeletedAt(String date) {
    return 'Διαγράφηκε στις $date';
  }

  @override
  String deletedPersonaUseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Χρησιμοποιήθηκε $count φορές',
      one: 'Χρησιμοποιήθηκε μία φορά',
    );
    return '$_temp0';
  }

  @override
  String get deletedPersonaRestore => 'Επαναφορά';

  @override
  String personaRestored(String name) {
    return 'Η persona $name επέστρεψε.';
  }

  @override
  String personaRestoredWithout(String items) {
    return 'Επέστρεψε χωρίς $items: τα έχει πλέον άλλη persona.';
  }

  @override
  String get personaRestoreFailed => 'Δεν ήταν δυνατή η επαναφορά της persona.';

  @override
  String deletedPersonaRestoreLabel(String name) {
    return 'Επαναφορά $name';
  }
}
