// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class ForkLocalizationsPl extends ForkLocalizations {
  ForkLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Zmień personę';

  @override
  String get chatAttachmentPanelVoice => 'Głos';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Przycisk szybkiego przełączania';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Zastąp przycisk wiadomości głosowej w polu wprowadzania przyciskiem szybkiego przełącznika';

  @override
  String get userSettingsCheckForUpdates => 'Sprawdź aktualizacje';

  @override
  String get userSettingsCheckingForUpdates => 'Sprawdzanie aktualizacji…';

  @override
  String get userSettingsAppUpToDate => 'Tyne jest aktualny';

  @override
  String get userSettingsUpdateAvailableTitle => 'Dostępna aktualizacja';

  @override
  String get userSettingsUpdateDownloadAction => 'Pobierz i zainstaluj';

  @override
  String get userSettingsUpdateInstallAction => 'Zainstaluj aktualizację';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Pobieranie aktualizacji ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Nie udało się sprawdzić lub pobrać aktualizacji.';

  @override
  String get personaSelectTitle => 'Wybierz personę';

  @override
  String get personaSettingsHeader => 'Ustawienia person';

  @override
  String get personaManageAction => 'Zarządzaj';

  @override
  String get personaSearchPlaceholder => 'Szukaj person, tagów, zaimków...';

  @override
  String get personaModeManual => 'Ręczny';

  @override
  String get personaModeLast => 'Ostatnio używana';

  @override
  String get personaModeManualDescription =>
      'Zawsze wysyła jako wybrana persona do momentu zmiany.';

  @override
  String get personaModeLastDescription =>
      'Automatycznie przełącza na personę użytą w ostatniej wiadomości.';

  @override
  String get personaRecentHeader => 'OSTATNIE PERSONY';

  @override
  String personaAllHeader(int count) {
    return 'WSZYSTKIE PERSONY ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'WYNIKI WYSZUKIWANIA ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Konto główne (domyślne)';

  @override
  String get personaEmptyState =>
      'Nie skonfigurowano jeszcze żadnych person. Utwórz jedną w menu „Zarządzaj personami”.';

  @override
  String get personaEmptySearch => 'Nie znaleziono pasujących person.';

  @override
  String get personaEditTitle => 'Edytuj personę';

  @override
  String get personaCreateTitle => 'Utwórz personę';

  @override
  String get personaDisplayNameLabel => 'Nazwa wyświetlana';

  @override
  String get personaPronounsLabel => 'Zaimki';

  @override
  String get personaPronounsHint => 'np. ono/jego';

  @override
  String get personaBioHint => 'Opowiedz innym o tej personie...';

  @override
  String get personaUpdatedToast => 'Zaktualizowano personę';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Nie udało się zaktualizować persony: $error';
  }

  @override
  String get personaSectionTitle => 'Persony';

  @override
  String get personaDisplayNameHint => 'Nazwa persony';

  @override
  String personaSendingAsTag(String name) {
    return 'Wysyłanie jako $name (dopasowane przez tag)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Wysyłanie jako $name (zablokowane)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Wysyłanie jako $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Publikowanie jako $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Wysyłanie jako @$username';
  }

  @override
  String get personaMainAccount => 'Konto główne';

  @override
  String get personaEditPersona => 'Edytuj personę';

  @override
  String get userSettingsNavPersonas => 'Persony';

  @override
  String get personaSettingsDescription =>
      'Skonfiguruj tryb aktywnej persony, własny widoczny tag i zarządzaj poszczególnymi personami.';

  @override
  String get personaDisplayTagSection => 'Widoczny tag';

  @override
  String get personaDisplayTagDescription =>
      'Widoczny tag pojawi się obok nazw wszystkich person w wiadomościach. Jeśli nie ustawiono tagu, zostanie pokazane zdjęcie profilowe twojego konta.';

  @override
  String get personaDisplayTagLabel => 'Tekst widocznego tagu';

  @override
  String get personaDisplayTagHint => 'np. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Ikona widocznego tagu';

  @override
  String get personaUploadTagIcon => 'Prześlij ikonę';

  @override
  String get personaChangeTagIcon => 'Zmień ikonę';

  @override
  String get personaRemoveTagIcon => 'Usuń ikonę';

  @override
  String get personaChatPreviewTitle => 'Podgląd czatu';

  @override
  String get personaChatPreviewSampleMessage =>
      'Cześć! To jest podgląd tego, jak wyglądają wiadomości z twoim widocznym tagiem i aktywną personą.';

  @override
  String get personaListTitle => 'Skonfigurowane persony';

  @override
  String get personaAddButton => 'Dodaj personę';

  @override
  String get personaActiveBadge => 'Aktywna';

  @override
  String get personaMakeActive => 'Ustaw jako aktywną';

  @override
  String get personaDeleteTitle => 'Usuń personę';

  @override
  String personaDeleteMessage(String name) {
    return 'Czy na pewno chcesz usunąć „$name”? Tej operacji nie można cofnąć.';
  }

  @override
  String get personaDeleteConfirm => 'Usuń';

  @override
  String get personaDeletedToast => 'Usunięto personę';

  @override
  String get personaCreatedToast => 'Utworzono personę';

  @override
  String personaCreateFailedToast(String error) {
    return 'Nie udało się utworzyć persony: $error';
  }

  @override
  String get personaChangeAvatar => 'Zmień awatar';

  @override
  String get personaRemoveAvatar => 'Usuń awatar';

  @override
  String get personaUploadAvatar => 'Prześlij awatar';

  @override
  String get personaTagsLabel => 'Tagi persony';

  @override
  String get personaAutoTagDisabledLabel => 'Nie rozpoznawaj tagów tej persony';

  @override
  String get personaAutoTagDisabledDescription =>
      'Wpisanie jednego z tych tagów nie przełączy na tę personę. Tag zostanie wysłany tak, jak został napisany.';

  @override
  String get personaTagPrefixLabel => 'Prefiks';

  @override
  String get personaTagSuffixLabel => 'Sufiks';

  @override
  String get personaVisibilityLabel => 'Widoczność';

  @override
  String get personaVisibilityUnlisted => 'Niepubliczna';

  @override
  String get personaVisibilityPublic => 'Publiczna';

  @override
  String get personaVisibilityPrivate => 'Prywatna';

  @override
  String get personaNameRequired => 'Wprowadź wyświetlaną nazwę persony';

  @override
  String get personaNameTooLong =>
      'Wyświetlana nazwa persony może mieć maksymalnie 100 znaków';

  @override
  String get personaTagPrefixTooLong =>
      'Prefiks tagu persony może mieć maksymalnie 32 znaki';

  @override
  String get personaTagSuffixTooLong =>
      'Sufiks tagu persony może mieć maksymalnie 32 znaki';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Tag \'$tag\' jest już używany przez \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Wstaw znacznik czasu';

  @override
  String get chatAttachmentSendVoiceMessage => 'Wyślij wiadomość głosową';

  @override
  String get timestampPickerTitle => 'Wstaw znacznik czasu';

  @override
  String get timestampPickerInsert => 'Wstaw';

  @override
  String get timestampCopied => 'Znacznik czasu skopiowany';

  @override
  String get timestampPickerTimeLabel => 'Czas';

  @override
  String get timestampPickerDateLabel => 'DATA';

  @override
  String get timestampPickerTimeSectionLabel => 'GODZINA';

  @override
  String get timestampPickerTimezoneLabel => 'STREFA CZASOWA';

  @override
  String get timestampPickerFormatPreviewLabel => 'PODGLĄD FORMATU';

  @override
  String get timestampPickerNlpPlaceholder =>
      'np. jutro o 15:00, za 2 godziny, teraz';

  @override
  String get timestampPickerSearchTimezones => 'Szukaj stref czasowych...';

  @override
  String get userProfileTimezoneSettingLabel => 'Strefa czasowa';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Służy do pokazywania Twojego czasu lokalnego na profilu.';

  @override
  String get userProfileTimezoneNone => 'Brak';

  @override
  String get chatReactAs => 'Zareaguj jako...';

  @override
  String get emojiCopy => 'Kopiuj emoji';

  @override
  String get emojiCopyLink => 'Kopiuj link';

  @override
  String get emojiPin => 'Przypnij emoji';

  @override
  String get emojiUnpin => 'Odepnij emoji';

  @override
  String get emojiPinForPersona => 'Przypnij dla tej persony';

  @override
  String get emojiUnpinForPersona => 'Odepnij dla tej persony';

  @override
  String get personaSignatureEmojisLabel => 'Emoji podpisu';

  @override
  String get personaSignatureEmojisDescription =>
      'Reagowanie za pomocą emoji podpisu zawsze doda reakcję jako ta persona, niezależnie od aktywnej persony.';

  @override
  String get personaAddSignatureEmoji => 'Dodaj emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'To emoji zostało już dodane jako emoji podpisu';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Emoji podpisu jest już używane przez personę \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Usuń emoji podpisu';

  @override
  String get signalBarLabel => 'Pasek sygnałów';

  @override
  String get signalBarShow => 'Pokaż pasek sygnałów';

  @override
  String get signalBarHide => 'Ukryj pasek sygnałów';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Nikt nie ma włączonego tego sygnału';

  @override
  String get signalBarReset => 'Zresetuj sygnał dla wszystkich';

  @override
  String signalBarTurnOff(String name) {
    return 'Wyłącz $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Użyj $domain dla domyślnej instancji lub podaj dokładny adres URL innej instancji.';
  }

  @override
  String get instanceResetToDefault => 'Przywróć domyślną instancję';

  @override
  String get personaScopeTitle => 'Persona dotyczy';

  @override
  String get personaScopeGlobal => 'Wszędzie';

  @override
  String get personaScopeGlobalDescription =>
      'Jedna persona dla wszystkich kanałów.';

  @override
  String get personaScopeChannel => 'W każdym kanale';

  @override
  String get personaScopeChannelDescription =>
      'Każdy kanał zachowuje własną personę. Nowe kanały zaczynają jako twoje konto.';

  @override
  String get personaPickerChannelOnly => 'Tylko dla tego kanału';

  @override
  String get personaProfilePrivate => 'Profil tej persony jest prywatny.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Plik obrazu jest za duży. Wybierz plik mniejszy niż $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Szukaj KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Nie udało się pobrać aktualizacji';

  @override
  String get appUpdateInstallFailed =>
      'Nie udało się zainstalować aktualizacji';

  @override
  String get personaChangeMessageFailed =>
      'Nie udało się zmienić persony wiadomości';

  @override
  String get personaActiveCleared => 'Wyczyszczono aktywną personę';

  @override
  String get klipyPoweredBy => 'Dostarczane przez KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Zduplikowana para tagów \'$pattern\' w tej personie';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Dodaj parę tagów ($count/5)';
  }

  @override
  String get personaTagExampleText => 'tekst';

  @override
  String get personaPreviewNameFallback => 'Użytkownik';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne nieoczekiwanie się zamknął. Udostępnianie anonimowych danych o awariach i błędach pomaga nam szybciej naprawiać problemy.';

  @override
  String get crashReportingSectionDescription =>
      'Pomóż naprawiać błędy w Tyne, udostępniając dane o awariach i wydajności. Domyślnie wyłączone.';

  @override
  String get crashReportingDescription =>
      'Raporty trafiają do własnego systemu śledzenia błędów Tyne, także po zalogowaniu się do innej instancji. Nie zawierają nazw instancji, identyfikatorów ani treści wiadomości.';

  @override
  String get instanceOfflineTitle => 'Tyne jest offline!';

  @override
  String get instanceOfflineBody => 'Sprawdzamy, co się dzieje.';

  @override
  String get instanceStatusSignalLink =>
      'Dołącz do naszego czatu na Signalu, aby być na bieżąco';

  @override
  String get convertEmoticonsLabel => 'Zamieniaj emotikony tekstowe na emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Nie udało się uruchomić /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Jego skrypt ma problem.';

  @override
  String guildCommandOneLine(String name) {
    return 'To, co wpiszesz po /$name, musi zmieścić się w jednym wierszu.';
  }

  @override
  String get permissionCreateCommands => 'Tworzenie poleceń';

  @override
  String get permissionManageCommands => 'Zarządzanie poleceniami';

  @override
  String get permissionUseExternalCommands => 'Używaj zewnętrznych poleceń';

  @override
  String get permissionCreateCommandsDescription =>
      'Twórz polecenia dla tej społeczności oraz edytuj i usuwaj własne.';

  @override
  String get permissionManageCommandsDescription =>
      'Edytuj i usuwaj polecenia każdego w tej społeczności.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Używaj poleceń z innych społeczności.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Używaj poleceń z innych społeczności na tym kanale.';

  @override
  String get guildSettingsCategoryMessageTools => 'Narzędzia wiadomości';

  @override
  String get guildSettingsCommands => 'Polecenia';

  @override
  String get guildCommandsLoadFailed => 'Nie udało się wczytać poleceń.';

  @override
  String get guildCommandsSubtitle =>
      'Wiadomości, które członkowie mogą publikować, wpisując /name.';

  @override
  String get guildCommandsSlots => 'Miejsca na polecenia';

  @override
  String get guildCommandsNew => 'Nowe polecenie';

  @override
  String get guildCommandsSearch => 'Szukaj poleceń';

  @override
  String get guildCommandsEmptyTitle => 'Brak poleceń';

  @override
  String get guildCommandsEmptyBody => 'Ta społeczność nie ma jeszcze poleceń.';

  @override
  String get guildCommandsSaved => 'Polecenia zapisane';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Nie udało się zapisać /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Edytuj /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Usunąć /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Tego nie można cofnąć. Wiadomości utworzone tym poleceniem nadal pokazują, które polecenie je utworzyło.';

  @override
  String get guildCommandDelete => 'Usuń';

  @override
  String get guildCommandDeleteCommand => 'Usuń polecenie';

  @override
  String get guildCommandSectionCommand => 'Polecenie';

  @override
  String get guildCommandName => 'Nazwa';

  @override
  String get guildCommandNameInvalid =>
      'Użyj małych liter, cyfr, - i _, maksymalnie 32 znaki.';

  @override
  String get guildCommandNameTaken =>
      'Inne polecenie lub wbudowane polecenie ma już tę nazwę.';

  @override
  String get guildCommandDescription => 'Opis';

  @override
  String get guildCommandSectionInput => 'Wprowadzanie';

  @override
  String get guildCommandInputNone => 'Brak';

  @override
  String get guildCommandInputOptional => 'Opcjonalnie';

  @override
  String get guildCommandInputRequired => 'Wymagane';

  @override
  String get guildCommandHint => 'Podpowiedź';

  @override
  String get guildCommandMessage => 'Wiadomość';

  @override
  String get guildCommandInsert => 'Wstaw:';

  @override
  String get guildCommandInsertPerson => 'Osoba, która go używa';

  @override
  String get guildCommandInsertInput => 'To, co wpisują';

  @override
  String get guildCommandPreview => 'Podgląd';

  @override
  String get guildCommandSampleInput => 'Przykładowy tekst';

  @override
  String guildCommandMadeWith(String name) {
    return 'Utworzone poleceniem /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Wyczyść pole wiadomości, aby użyć /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Nic nie zostałoby opublikowane, więc polecenie by się nie powiodło.';

  @override
  String get guildCommandUseScriptEditor => 'Użyj edytora skryptów';

  @override
  String get guildCommandUseBasicEditor => 'Użyj podstawowego edytora';

  @override
  String get guildCommandScript => 'Skrypt';

  @override
  String get guildCommandRunAgain => 'Uruchom ponownie';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Nie ma tagu o nazwie $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Nie ma filtra o nazwie $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name nigdy się nie zamyka.';
  }

  @override
  String get guildCommandIssueTooLong => 'Skrypt jest za długi.';

  @override
  String get guildCommandIssueTooLarge => 'Skrypt tworzy za dużo tekstu.';

  @override
  String get guildCommandIssueTooSlow => 'Wykonywanie skryptu trwało za długo.';

  @override
  String get guildCommandIssueInvalid => 'Tej części nie można odczytać.';

  @override
  String get guildCommandIssueFailed =>
      'Ta część zatrzymała się z powodu błędu.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Wiersz $line, kolumna $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Pomoc dotycząca skryptów';

  @override
  String get guildCommandReferencePerson =>
      'Osoba, która go używa, jako wzmianka';

  @override
  String get guildCommandReferencePersonName => 'Nazwa osoby, która go używa';

  @override
  String get guildCommandReferenceTarget =>
      'Pierwsza wspomniana osoba, jeśli jest';

  @override
  String get guildCommandReferenceTargetName => 'Nazwa tej osoby';

  @override
  String get guildCommandReferenceChannel => 'Kanał jako wzmianka';

  @override
  String get guildCommandReferenceCommunity => 'Nazwa tej społeczności';

  @override
  String get guildCommandExampleRandom => 'Wybierz losowo jedną opcję';

  @override
  String get guildCommandExampleDepends =>
      'Zmień wiadomość zależnie od tego, co wpisano';

  @override
  String get guildCommandExampleOneWord => 'Wybierz losowo jedno słowo';

  @override
  String get guildCommandExampleWordForNumber =>
      'Wybierz słowo pasujące do liczby';

  @override
  String get guildCommandExampleOrdinal => 'Zapisz liczbę jako 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Pełny przewodnik po skryptach';

  @override
  String get guildCommandCounters => 'Liczniki';

  @override
  String get guildCommandCounterAdd => 'Dodaj licznik';

  @override
  String get guildCommandCounterSeparately => 'Licz osobno dla każdego:';

  @override
  String get guildCommandCounterPersonMentioned => 'Wspomniana osoba';

  @override
  String get guildCommandCounterChannel => 'Kanał';

  @override
  String get guildCommandCounterPersonas => 'Licz persony osobno';

  @override
  String get guildCommandCounterRemove => 'Usuń licznik';

  @override
  String get guildCommandCounterReset => 'Wyzeruj liczby';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Wyzerować liczby dla $name? Tej operacji nie można cofnąć.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Użyj małych liter, cyfr i _, zacznij od litery i nie wybieraj nazwy, której używają już skrypty.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Użyj go w skrypcie jako $variable. Każde uruchomienie najpierw dodaje jeden, więc pierwsze odczyta 1.';
  }
}
