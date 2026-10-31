// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class ForkLocalizationsRo extends ForkLocalizations {
  ForkLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Schimbă persona';

  @override
  String get chatAttachmentPanelVoice => 'Vocal';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'Buton comutator rapid';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Înlocuiește butonul de mesaj vocal din bara de text cu un comutator rapid pentru navigare facilă';

  @override
  String get userSettingsCheckForUpdates => 'Caută actualizări';

  @override
  String get userSettingsCheckingForUpdates => 'Se caută actualizări…';

  @override
  String get userSettingsAppUpToDate => 'Tyne este la zi';

  @override
  String get userSettingsUpdateAvailableTitle => 'Actualizare disponibilă';

  @override
  String get userSettingsUpdateDownloadAction => 'Descarcă și instalează';

  @override
  String get userSettingsUpdateInstallAction => 'Instalează actualizarea';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Se descarcă actualizarea ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Nu s-a putut verifica sau descărca actualizarea.';

  @override
  String get personaSelectTitle => 'Selectează persona';

  @override
  String get personaSettingsHeader => 'Setări personas';

  @override
  String get personaManageAction => 'Gestionează';

  @override
  String get personaSearchPlaceholder => 'Caută personas, etichete, pronume...';

  @override
  String get personaModeManual => 'Manual';

  @override
  String get personaModeLast => 'Utilizată recent';

  @override
  String get personaModeManualDescription =>
      'Trimite întotdeauna ca persona selectată până când este schimbată.';

  @override
  String get personaModeLastDescription =>
      'Comută automat la persona utilizată în ultimul tău mesaj.';

  @override
  String get personaRecentHeader => 'PERSONAS RECENTE';

  @override
  String personaAllHeader(int count) {
    return 'TOATE PERSONAS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'REZULTATELE CĂUTĂRII ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Contul principal (Implicit)';

  @override
  String get personaEmptyState =>
      'Nicio persona configurată încă. Creează una din Gestionează personas.';

  @override
  String get personaEmptySearch => 'Nu s-au găsit personas potrivite.';

  @override
  String get personaEditTitle => 'Editează persona';

  @override
  String get personaCreateTitle => 'Creează persona';

  @override
  String get personaDisplayNameLabel => 'Nume afișat';

  @override
  String get personaPronounsLabel => 'Pronume';

  @override
  String get personaPronounsHint => 'de ex. ea/el';

  @override
  String get personaBioHint => 'Spune-le celorlalți despre această persona...';

  @override
  String get personaUpdatedToast => 'Persona actualizată';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Nu s-a putut actualiza persona: $error';
  }

  @override
  String get personaSectionTitle => 'Personas';

  @override
  String get personaDisplayNameHint => 'Numele personei';

  @override
  String personaSendingAsTag(String name) {
    return 'Se trimite ca $name (Potrivire după etichetă)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Se trimite ca $name (Fixată)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Se trimite ca $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Se postează ca $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Se trimite ca @$username';
  }

  @override
  String get personaMainAccount => 'Contul principal';

  @override
  String get personaEditPersona => 'Editează persona';

  @override
  String get userSettingsNavPersonas => 'Personas';

  @override
  String get personaSettingsDescription =>
      'Configurează modul activ de persona, eticheta de afișare personalizată și gestionează personas individuale.';

  @override
  String get personaDisplayTagSection => 'Etichetă de afișare';

  @override
  String get personaDisplayTagDescription =>
      'Eticheta de afișare va apărea lângă numele tuturor personas din mesaje. Dacă nu setezi nicio etichetă, se va afișa poza de profil a contului tău.';

  @override
  String get personaDisplayTagLabel => 'Textul etichetei de afișare';

  @override
  String get personaDisplayTagHint => 'de ex. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Pictograma etichetei de afișare';

  @override
  String get personaUploadTagIcon => 'Încarcă pictogramă';

  @override
  String get personaChangeTagIcon => 'Schimbă pictograma';

  @override
  String get personaRemoveTagIcon => 'Elimină pictograma';

  @override
  String get personaChatPreviewTitle => 'Previzualizare chat';

  @override
  String get personaChatPreviewSampleMessage =>
      'Bună! Aceasta este o previzualizare a modului în care arată mesajele cu eticheta ta de afișare și persona activă.';

  @override
  String get personaListTitle => 'Personas configurate';

  @override
  String get personaAddButton => 'Adaugă persona';

  @override
  String get personaActiveBadge => 'Activ';

  @override
  String get personaMakeActive => 'Setează ca activă';

  @override
  String get personaDeleteTitle => 'Șterge persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Sigur dorești să ștergi „$name”? Această acțiune nu poate fi anulată.';
  }

  @override
  String get personaDeleteConfirm => 'Șterge';

  @override
  String get personaDeletedToast => 'Persona ștearsă';

  @override
  String get personaCreatedToast => 'Persona creată';

  @override
  String personaCreateFailedToast(String error) {
    return 'Nu s-a putut crea persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Schimbă avatarul';

  @override
  String get personaRemoveAvatar => 'Elimină avatarul';

  @override
  String get personaUploadAvatar => 'Încarcă avatar';

  @override
  String get personaTagsLabel => 'Etichete persona';

  @override
  String get personaTagPrefixLabel => 'Prefix';

  @override
  String get personaTagSuffixLabel => 'Sufix';

  @override
  String get personaVisibilityLabel => 'Vizibilitate';

  @override
  String get personaVisibilityUnlisted => 'Nelistată';

  @override
  String get personaVisibilityPublic => 'Publică';

  @override
  String get personaVisibilityPrivate => 'Privată';

  @override
  String get personaNameRequired =>
      'Te rugăm să introduci un nume afișat pentru persona';

  @override
  String get personaNameTooLong =>
      'Numele afișat al personei trebuie să aibă maximum 100 de caractere';

  @override
  String get personaTagPrefixTooLong =>
      'Prefixul etichetei personei trebuie să aibă maximum 32 de caractere';

  @override
  String get personaTagSuffixTooLong =>
      'Sufixul etichetei personei trebuie să aibă maximum 32 de caractere';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Eticheta \'$tag\' este deja folosită de \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Inserează marcaj de timp';

  @override
  String get chatAttachmentSendVoiceMessage => 'Trimite mesaj vocal';

  @override
  String get timestampPickerTitle => 'Inserează marcaj de timp';

  @override
  String get timestampPickerInsert => 'Inserează';

  @override
  String get timestampCopied => 'Marcaj de timp copiat';

  @override
  String get timestampPickerTimeLabel => 'Oră';

  @override
  String get timestampPickerDateLabel => 'DATĂ';

  @override
  String get timestampPickerTimeSectionLabel => 'ORĂ';

  @override
  String get timestampPickerTimezoneLabel => 'FUS ORAR';

  @override
  String get timestampPickerFormatPreviewLabel => 'PREVIZUALIZARE FORMAT';

  @override
  String get timestampPickerNlpPlaceholder =>
      'de ex. mâine la 15:00, în 2 ore, acum';

  @override
  String get timestampPickerSearchTimezones => 'Caută fusuri orare...';

  @override
  String get userProfileTimezoneSettingLabel => 'Fus orar';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Folosit pentru a afișa ora locală pe profilul tău.';

  @override
  String get userProfileTimezoneNone => 'Niciunul';

  @override
  String get chatReactAs => 'Reacționează ca...';

  @override
  String get emojiCopy => 'Copiază emoji';

  @override
  String get emojiCopyLink => 'Copiază linkul';

  @override
  String get emojiPin => 'Fixează emoji';

  @override
  String get emojiUnpin => 'Anulează fixarea emoji-ului';

  @override
  String get emojiPinForPersona => 'Fixează pentru această persona';

  @override
  String get emojiUnpinForPersona => 'Anulează fixarea pentru această persona';

  @override
  String get personaSignatureEmojisLabel => 'Emoji-uri semnătură';

  @override
  String get personaSignatureEmojisDescription =>
      'Reacționarea cu un emoji semnătură va reacționa întotdeauna ca această persona, indiferent de persona activă.';

  @override
  String get personaAddSignatureEmoji => 'Adăugare emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Acest emoji este deja adăugat ca emoji semnătură';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Emoji-ul semnătură este deja utilizat de persona „$name”';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Elimină emoji semnătură';

  @override
  String get signalBarLabel => 'Bara de semnale';

  @override
  String get signalBarShow => 'Afișează bara de semnale';

  @override
  String get signalBarHide => 'Ascunde bara de semnale';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Nimeni nu are acest semnal activat';

  @override
  String get signalBarReset => 'Resetează semnalul pentru toți';

  @override
  String signalBarTurnOff(String name) {
    return 'Dezactivează $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Folosește $domain pentru instanța implicită sau adresa URL exactă a altei instanțe.';
  }

  @override
  String get instanceResetToDefault => 'Resetează la instanța implicită';

  @override
  String get personaScopeTitle => 'Persona se aplică pentru';

  @override
  String get personaScopeGlobal => 'Peste tot';

  @override
  String get personaScopeGlobalDescription =>
      'O singură persona pentru toate canalele.';

  @override
  String get personaScopeChannel => 'În fiecare canal';

  @override
  String get personaScopeChannelDescription =>
      'Fiecare canal își păstrează propria persona. Canalele noi pornesc cu contul tău.';

  @override
  String get personaPickerChannelOnly => 'Doar pentru acest canal';

  @override
  String get personaProfilePrivate => 'Profilul acestei persona este privat.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Fișierul imagine este prea mare. Alege un fișier mai mic de $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Caută în KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Actualizarea nu a putut fi descărcată';

  @override
  String get appUpdateInstallFailed => 'Actualizarea nu a putut fi instalată';

  @override
  String get personaChangeMessageFailed =>
      'Persona mesajului nu a putut fi schimbată';

  @override
  String get personaActiveCleared => 'Persona activă a fost eliminată';

  @override
  String get klipyPoweredBy => 'Oferit de KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Pereche de etichete \'$pattern\' duplicată la această persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Adaugă pereche de etichete ($count/5)';
  }

  @override
  String get personaTagExampleText => 'text';

  @override
  String get personaPreviewNameFallback => 'Utilizator';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne s-a închis în mod neașteptat. Partajarea datelor anonime despre blocări și erori ne ajută să rezolvăm problemele mai repede.';

  @override
  String get crashReportingSectionDescription =>
      'Ajută la remedierea erorilor din Tyne partajând date despre blocări și performanță. Este dezactivat în mod implicit.';

  @override
  String get crashReportingDescription =>
      'Rapoartele ajung în sistemul propriu de urmărire a erorilor al Tyne, chiar și atunci când ești conectat la altă instanță. Nu includ nume de instanțe, ID-uri sau conținutul mesajelor.';

  @override
  String get instanceOfflineTitle => 'Tyne este offline!';

  @override
  String get instanceOfflineBody => 'Investigăm problema.';

  @override
  String get instanceStatusSignalLink =>
      'Intră în chatul nostru de pe Signal pentru noutăți';

  @override
  String get convertEmoticonsLabel => 'Transformă smiley-urile text în emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Nu s-a putut rula /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Scriptul ei are o problemă.';

  @override
  String guildCommandOneLine(String name) {
    return 'Ce scrii după /$name trebuie să încapă pe un singur rând.';
  }

  @override
  String get permissionCreateCommands => 'Creează comenzi';

  @override
  String get permissionManageCommands => 'Gestionează comenzile';

  @override
  String get permissionUseExternalCommands => 'Folosește comenzi externe';

  @override
  String get permissionCreateCommandsDescription =>
      'Creează comenzi pentru această comunitate și editează sau șterge-le pe ale tale.';

  @override
  String get permissionManageCommandsDescription =>
      'Editează sau șterge comenzile oricui din această comunitate.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Folosește comenzi din alte comunități.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Folosește comenzi din alte comunități în acest canal.';

  @override
  String get guildSettingsCategoryMessageTools => 'Instrumente pentru mesaje';

  @override
  String get guildSettingsCommands => 'Comenzi';

  @override
  String get guildCommandsLoadFailed => 'Comenzile nu au putut fi încărcate.';

  @override
  String get guildCommandsSubtitle =>
      'Mesaje pe care membrii le pot posta scriind /name.';

  @override
  String get guildCommandsSlots => 'Sloturi pentru comenzi';

  @override
  String get guildCommandsNew => 'Comandă nouă';

  @override
  String get guildCommandsSearch => 'Caută comenzi';

  @override
  String get guildCommandsEmptyTitle => 'Nicio comandă';

  @override
  String get guildCommandsEmptyBody =>
      'Această comunitate nu are încă nicio comandă.';

  @override
  String get guildCommandsSaved => 'Comenzi salvate';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Nu s-a putut salva /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Editează /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Ștergi /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Acțiunea nu poate fi anulată. Mesajele făcute cu ea arată în continuare ce comandă le-a făcut.';

  @override
  String get guildCommandDelete => 'Șterge';

  @override
  String get guildCommandDeleteCommand => 'Șterge comanda';

  @override
  String get guildCommandSectionCommand => 'Comandă';

  @override
  String get guildCommandName => 'Nume';

  @override
  String get guildCommandNameInvalid =>
      'Folosește litere mici, cifre, - și _, cel mult 32 de caractere.';

  @override
  String get guildCommandNameTaken =>
      'O altă comandă sau o comandă integrată are deja acest nume.';

  @override
  String get guildCommandDescription => 'Descriere';

  @override
  String get guildCommandSectionInput => 'Introducere';

  @override
  String get guildCommandInputNone => 'Niciunul';

  @override
  String get guildCommandInputOptional => 'Opțional';

  @override
  String get guildCommandInputRequired => 'Obligatoriu';

  @override
  String get guildCommandHint => 'Indiciu';

  @override
  String get guildCommandMessage => 'Mesaj';

  @override
  String get guildCommandInsert => 'Inserează:';

  @override
  String get guildCommandInsertPerson => 'Persoana care o folosește';

  @override
  String get guildCommandInsertInput => 'Ce scriu';

  @override
  String get guildCommandPreview => 'Previzualizare';

  @override
  String get guildCommandSampleInput => 'Text de exemplu';

  @override
  String guildCommandMadeWith(String name) {
    return 'Făcut cu /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Golește caseta de mesaj ca să folosești /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Asta nu ar posta nimic, așa că comanda ar eșua.';

  @override
  String get guildCommandUseScriptEditor => 'Folosește editorul de scripturi';

  @override
  String get guildCommandUseBasicEditor => 'Folosește editorul de bază';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Rulează din nou';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Nu există niciun tag numit $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Nu există niciun filtru numit $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name nu se închide niciodată.';
  }

  @override
  String get guildCommandIssueTooLong => 'Scriptul este prea lung.';

  @override
  String get guildCommandIssueTooLarge => 'Scriptul generează prea mult text.';

  @override
  String get guildCommandIssueTooSlow =>
      'Rularea scriptului a durat prea mult.';

  @override
  String get guildCommandIssueInvalid => 'Această parte nu poate fi citită.';

  @override
  String get guildCommandIssueFailed => 'Această parte s-a oprit cu o eroare.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Linia $line, coloana $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Ghid pentru scripturi';

  @override
  String get guildCommandReferencePerson =>
      'Persoana care o folosește, ca mențiune';

  @override
  String get guildCommandReferencePersonName =>
      'Numele persoanei care o folosește';

  @override
  String get guildCommandReferenceTarget =>
      'Prima persoană menționată, dacă există';

  @override
  String get guildCommandReferenceTargetName => 'Numele acelei persoane';

  @override
  String get guildCommandReferenceChannel => 'Canalul, ca mențiune';

  @override
  String get guildCommandReferenceCommunity => 'Numele acestei comunități';

  @override
  String get guildCommandExampleRandom => 'Alege la întâmplare o opțiune';

  @override
  String get guildCommandExampleDepends =>
      'Schimbă mesajul în funcție de ce au scris';

  @override
  String get guildCommandExampleOneWord => 'Alege la întâmplare un cuvânt';

  @override
  String get guildCommandExampleWordForNumber =>
      'Alege cuvântul potrivit pentru un număr';

  @override
  String get guildCommandExampleOrdinal => 'Scrie un număr ca 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Ghid complet pentru scripturi';

  @override
  String get guildCommandCounters => 'Contoare';

  @override
  String get guildCommandCounterAdd => 'Adaugă contor';

  @override
  String get guildCommandCounterSeparately => 'Numără separat pentru fiecare:';

  @override
  String get guildCommandCounterPersonMentioned => 'Persoana menționată';

  @override
  String get guildCommandCounterChannel => 'Canal';

  @override
  String get guildCommandCounterPersonas => 'Numără personajele separat';

  @override
  String get guildCommandCounterRemove => 'Elimină contorul';

  @override
  String get guildCommandCounterReset => 'Resetează numărătorile';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Resetezi numărătorile pentru $name? Acțiunea nu poate fi anulată.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Folosește litere mici, cifre și _, începe cu o literă și evită numele folosite deja de scripturi.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Folosește-l într-un script ca $variable. Fiecare rulare adaugă mai întâi unu, deci prima citește 1.';
  }
}
