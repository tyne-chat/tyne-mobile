// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class ForkLocalizationsHr extends ForkLocalizations {
  ForkLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Promijeni personu';

  @override
  String get chatAttachmentPanelVoice => 'Glasovno';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Gumb brzog prebacivanja';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Zamijenite gumb glasovne poruke u polju za unos brzim prebacivanjem za lakšu navigaciju';

  @override
  String get userSettingsCheckForUpdates => 'Provjeri ažuriranja';

  @override
  String get userSettingsCheckingForUpdates => 'Provjera ažuriranja…';

  @override
  String get userSettingsAppUpToDate => 'Tyne je ažuran';

  @override
  String get userSettingsUpdateAvailableTitle => 'Dostupno ažuriranje';

  @override
  String get userSettingsUpdateDownloadAction => 'Preuzmi i instaliraj';

  @override
  String get userSettingsUpdateInstallAction => 'Instaliraj ažuriranje';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Preuzimanje ažuriranja ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Provjera ili preuzimanje ažuriranja nije uspjelo.';

  @override
  String get personaSelectTitle => 'Odaberite personu';

  @override
  String get personaSettingsHeader => 'Postavke persona';

  @override
  String get personaManageAction => 'Upravljaj';

  @override
  String get personaSearchPlaceholder =>
      'Pretraži persone, oznake, zamjenice...';

  @override
  String get personaModeManual => 'Ručno';

  @override
  String get personaModeLast => 'Zadnje korišteno';

  @override
  String get personaModeManualDescription =>
      'Uvijek šalje kao odabrana persona dok se ne promijeni.';

  @override
  String get personaModeLastDescription =>
      'Automatski se prebacuje na personu korištenu u vašoj posljednjoj poruci.';

  @override
  String get personaRecentHeader => 'NEDAVNE PERSONE';

  @override
  String personaAllHeader(int count) {
    return 'SVE PERSONE ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'REZULTATI PRETRAŽIVANJA ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Glavni račun (Zadano)';

  @override
  String get personaEmptyState =>
      'Još nema konfiguriranih persona. Stvorite jednu u „Upravljanje personama”.';

  @override
  String get personaEmptySearch => 'Nisu pronađene odgovarajuće persone.';

  @override
  String get personaEditTitle => 'Uredi personu';

  @override
  String get personaCreateTitle => 'Stvori personu';

  @override
  String get personaDisplayNameLabel => 'Ime za prikaz';

  @override
  String get personaPronounsLabel => 'Zamjenice';

  @override
  String get personaPronounsHint => 'npr. oni/njih';

  @override
  String get personaBioHint => 'Recite drugima nešto o ovoj personi...';

  @override
  String get personaUpdatedToast => 'Persona je ažurirana';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Ažuriranje persone nije uspjelo: $error';
  }

  @override
  String get personaSectionTitle => 'Persone';

  @override
  String get personaDisplayNameHint => 'Ime persone';

  @override
  String personaSendingAsTag(String name) {
    return 'Šalje se kao $name (Upareno po oznaci)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Šalje se kao $name (Zaključano)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Šalje se kao $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Objavljuje se kao $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Šalje se kao @$username';
  }

  @override
  String get personaMainAccount => 'Glavni račun';

  @override
  String get personaEditPersona => 'Uredi personu';

  @override
  String get userSettingsNavPersonas => 'Persone';

  @override
  String get personaSettingsDescription =>
      'Konfigurirajte način aktivne persone, prilagođenu oznaku prikaza i upravljajte pojedinačnim personama.';

  @override
  String get personaDisplayTagSection => 'Oznaka prikaza';

  @override
  String get personaDisplayTagDescription =>
      'Oznaka prikaza pojavit će se pored svih imena persona u porukama. Ako oznaka prikaza nije postavljena, prikazat će se slika vašeg računa.';

  @override
  String get personaDisplayTagLabel => 'Tekst oznake prikaza';

  @override
  String get personaDisplayTagHint => 'npr. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Ikona oznake prikaza';

  @override
  String get personaUploadTagIcon => 'Učitaj ikonu';

  @override
  String get personaChangeTagIcon => 'Promijeni ikonu';

  @override
  String get personaRemoveTagIcon => 'Ukloni ikonu';

  @override
  String get personaChatPreviewTitle => 'Pretpregled razgovora';

  @override
  String get personaChatPreviewSampleMessage =>
      'Pozdrav! Ovo je pretpregled kako poruke izgledaju s vašom oznakom prikaza i aktivnom personom.';

  @override
  String get personaListTitle => 'Konfigurirane persone';

  @override
  String get personaAddButton => 'Dodaj personu';

  @override
  String get personaActiveBadge => 'Aktivno';

  @override
  String get personaMakeActive => 'Postavi kao aktivno';

  @override
  String get personaDeleteTitle => 'Izbriši personu';

  @override
  String personaDeleteMessage(String name) {
    return 'Jeste li sigurni da želite izbrisati „$name”? Ovo se ne može poništiti.';
  }

  @override
  String get personaDeleteConfirm => 'Izbriši';

  @override
  String get personaDeletedToast => 'Persona je izbrisana';

  @override
  String get personaCreatedToast => 'Persona je stvorena';

  @override
  String personaCreateFailedToast(String error) {
    return 'Stvaranje persone nije uspjelo: $error';
  }

  @override
  String get personaChangeAvatar => 'Promijeni avatar';

  @override
  String get personaRemoveAvatar => 'Ukloni avatar';

  @override
  String get personaUploadAvatar => 'Učitaj avatar';

  @override
  String get personaTagsLabel => 'Oznake persone';

  @override
  String get personaTagPrefixLabel => 'Prefiks';

  @override
  String get personaTagSuffixLabel => 'Sufiks';

  @override
  String get personaVisibilityLabel => 'Vidljivost';

  @override
  String get personaVisibilityUnlisted => 'Nenavedeno';

  @override
  String get personaVisibilityPublic => 'Javno';

  @override
  String get personaVisibilityPrivate => 'Privatno';

  @override
  String get personaNameRequired => 'Unesite prikazano ime persone';

  @override
  String get personaNameTooLong =>
      'Prikazano ime persone mora imati najviše 100 znakova';

  @override
  String get personaTagPrefixTooLong =>
      'Prefiks oznake persone mora imati najviše 32 znaka';

  @override
  String get personaTagSuffixTooLong =>
      'Sufiks oznake persone mora imati najviše 32 znaka';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Oznaku \'$tag\' već koristi \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Umetni vremensku oznaku';

  @override
  String get chatAttachmentSendVoiceMessage => 'Pošalji glasovnu poruku';

  @override
  String get timestampPickerTitle => 'Umetni vremensku oznaku';

  @override
  String get timestampPickerInsert => 'Umetni';

  @override
  String get timestampCopied => 'Vremenska oznaka kopirana';

  @override
  String get timestampPickerTimeLabel => 'Vrijeme';

  @override
  String get timestampPickerDateLabel => 'DATUM';

  @override
  String get timestampPickerTimeSectionLabel => 'VRIJEME';

  @override
  String get timestampPickerTimezoneLabel => 'VREMENSKA ZONA';

  @override
  String get timestampPickerFormatPreviewLabel => 'PREGLED OBLIKA';

  @override
  String get timestampPickerNlpPlaceholder =>
      'npr. sutra u 15:00, za 2 sata, sada';

  @override
  String get timestampPickerSearchTimezones => 'Pretraži vremenske zone...';

  @override
  String get userProfileTimezoneSettingLabel => 'Vremenska zona';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Koristi se za prikaz vašeg lokalnog vremena na profilu.';

  @override
  String get userProfileTimezoneNone => 'Nijedno';

  @override
  String get chatReactAs => 'Reagiraj kao...';

  @override
  String get emojiCopy => 'Kopiraj emoji';

  @override
  String get emojiCopyLink => 'Kopiraj poveznicu';

  @override
  String get emojiPin => 'Prikvači emotikon';

  @override
  String get emojiUnpin => 'Otkvači emotikon';

  @override
  String get emojiPinForPersona => 'Prikvači za ovu personu';

  @override
  String get emojiUnpinForPersona => 'Otkvači za ovu personu';

  @override
  String get personaSignatureEmojisLabel => 'Prepoznatljivi emojiji';

  @override
  String get personaSignatureEmojisDescription =>
      'Reagiranje s prepoznatljivim emojijem uvijek će reagirati kao ova persona, bez obzira na aktivnu personu.';

  @override
  String get personaAddSignatureEmoji => 'Dodaj emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Ovaj emoji je već dodan kao prepoznatljivi emoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Prepoznatljivi emoji već koristi persona \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Ukloni prepoznatljivi emoji';

  @override
  String get signalBarLabel => 'Traka signala';

  @override
  String get signalBarShow => 'Prikaži traku signala';

  @override
  String get signalBarHide => 'Sakrij traku signala';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Nitko nema uključen ovaj signal';

  @override
  String get signalBarReset => 'Poništi signal za sve';

  @override
  String signalBarTurnOff(String name) {
    return 'Isključi $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Upotrijebite $domain za zadanu instancu ili točan URL druge instance.';
  }

  @override
  String get instanceResetToDefault => 'Vrati na zadanu instancu';

  @override
  String get personaScopeTitle => 'Persona vrijedi za';

  @override
  String get personaScopeGlobal => 'Svugdje';

  @override
  String get personaScopeGlobalDescription => 'Jedna persona za sve kanale.';

  @override
  String get personaScopeChannel => 'U svakom kanalu';

  @override
  String get personaScopeChannelDescription =>
      'Svaki kanal zadržava svoju personu. Novi kanali počinju kao vaš račun.';

  @override
  String get personaPickerChannelOnly => 'Samo za ovaj kanal';

  @override
  String get personaProfilePrivate => 'Profil ove persone je privatan.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Datoteka slike je prevelika. Odaberite datoteku manju od $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Pretraži KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Preuzimanje ažuriranja nije uspjelo';

  @override
  String get appUpdateInstallFailed => 'Instaliranje ažuriranja nije uspjelo';

  @override
  String get personaChangeMessageFailed =>
      'Promjena persone poruke nije uspjela';

  @override
  String get personaActiveCleared => 'Aktivna persona uklonjena';

  @override
  String get klipyPoweredBy => 'Pokreće KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Dvostruki par oznaka \'$pattern\' na ovoj personi';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Dodaj par oznaka ($count/5)';
  }

  @override
  String get personaTagExampleText => 'tekst';

  @override
  String get personaPreviewNameFallback => 'Korisnik';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne se neočekivano zatvorio. Dijeljenje anonimnih podataka o rušenjima i pogreškama pomaže nam brže ispraviti probleme.';

  @override
  String get crashReportingSectionDescription =>
      'Pomozite ispraviti pogreške u aplikaciji Tyne dijeljenjem podataka o rušenjima i performansama. Prema zadanim postavkama isključeno je.';

  @override
  String get crashReportingDescription =>
      'Izvješća se šalju u vlastiti sustav za praćenje pogrešaka aplikacije Tyne, čak i kada ste prijavljeni na drugu instancu. Ne sadrže nazive instanci, ID-ove ni sadržaj poruka.';

  @override
  String get instanceOfflineTitle => 'Tyne je izvan mreže!';

  @override
  String get instanceOfflineBody => 'Istražujemo što se događa.';

  @override
  String get instanceStatusSignalLink =>
      'Pridružite se našem Signal chatu za novosti';

  @override
  String get convertEmoticonsLabel => 'Pretvori tekstualne smajliće u emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Nije moguće pokrenuti /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Njezina skripta ima problem.';

  @override
  String guildCommandOneLine(String name) {
    return 'Ono što upišete nakon /$name mora stati u jedan redak.';
  }

  @override
  String get permissionCreateCommands => 'Stvaranje naredbi';

  @override
  String get permissionManageCommands => 'Upravljanje naredbama';

  @override
  String get permissionUseExternalCommands => 'Koristi vanjske naredbe';

  @override
  String get permissionCreateCommandsDescription =>
      'Stvarajte naredbe za ovu zajednicu te uređujte ili brišite vlastite.';

  @override
  String get permissionManageCommandsDescription =>
      'Uređujte ili brišite naredbe bilo koga u ovoj zajednici.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Upotrebljavaj naredbe iz drugih zajednica.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Upotrebljavaj naredbe iz drugih zajednica u ovom kanalu.';

  @override
  String get guildSettingsCategoryMessageTools => 'Alati za poruke';

  @override
  String get guildSettingsCommands => 'Naredbe';

  @override
  String get guildCommandsLoadFailed => 'Nije moguće učitati naredbe.';

  @override
  String get guildCommandsSubtitle =>
      'Poruke koje članovi mogu objaviti upisivanjem /name.';

  @override
  String get guildCommandsSlots => 'Mjesta za naredbe';

  @override
  String get guildCommandsNew => 'Nova naredba';

  @override
  String get guildCommandsSearch => 'Pretraži naredbe';

  @override
  String get guildCommandsEmptyTitle => 'Nema naredbi';

  @override
  String get guildCommandsEmptyBody => 'Ova zajednica još nema naredbi.';

  @override
  String get guildCommandsSaved => 'Naredbe su spremljene';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Nije moguće spremiti /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Uredi /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Izbrisati /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Ovo se ne može poništiti. Poruke napravljene njome i dalje pokazuju koja ih je naredba napravila.';

  @override
  String get guildCommandDelete => 'Izbriši';

  @override
  String get guildCommandDeleteCommand => 'Izbriši naredbu';

  @override
  String get guildCommandSectionCommand => 'Naredba';

  @override
  String get guildCommandName => 'Naziv';

  @override
  String get guildCommandNameInvalid =>
      'Koristite mala slova, brojeve, - i _, najviše 32 znaka.';

  @override
  String get guildCommandNameTaken =>
      'Druga naredba ili ugrađena naredba već ima ovaj naziv.';

  @override
  String get guildCommandDescription => 'Opis';

  @override
  String get guildCommandSectionInput => 'Unos';

  @override
  String get guildCommandInputNone => 'Ništa';

  @override
  String get guildCommandInputOptional => 'Neobavezno';

  @override
  String get guildCommandInputRequired => 'Obavezno';

  @override
  String get guildCommandHint => 'Savjet';

  @override
  String get guildCommandMessage => 'Poruka';

  @override
  String get guildCommandInsert => 'Umetni:';

  @override
  String get guildCommandInsertPerson => 'Osoba koja je koristi';

  @override
  String get guildCommandInsertInput => 'Ono što upišu';

  @override
  String get guildCommandPreview => 'Pretpregled';

  @override
  String get guildCommandSampleInput => 'Primjer unosa';

  @override
  String guildCommandMadeWith(String name) {
    return 'Napravljeno s /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Ispraznite okvir poruke da biste upotrijebili /$name';
  }

  @override
  String get guildCommandScriptReadOnly =>
      'Ova naredba je skripta. Uredi je u web ili desktop aplikaciji.';

  @override
  String get guildCommandEmptyMessage =>
      'Ovo ne bi ništa objavilo, pa naredba ne bi uspjela.';
}
