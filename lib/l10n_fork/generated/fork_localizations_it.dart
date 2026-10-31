// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class ForkLocalizationsIt extends ForkLocalizations {
  ForkLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Cambia persona';

  @override
  String get chatAttachmentPanelVoice => 'Voce';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Pulsante selettore rapido';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Sostituisci il pulsante dei messaggi vocali nel campo di testo con un selettore rapido per una navigazione veloce';

  @override
  String get userSettingsCheckForUpdates => 'Controlla aggiornamenti';

  @override
  String get userSettingsCheckingForUpdates =>
      'Controllo aggiornamenti in corso…';

  @override
  String get userSettingsAppUpToDate => 'Tyne è aggiornato';

  @override
  String get userSettingsUpdateAvailableTitle => 'Aggiornamento disponibile';

  @override
  String get userSettingsUpdateDownloadAction => 'Scarica e installa';

  @override
  String get userSettingsUpdateInstallAction => 'Installa aggiornamento';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Download aggiornamento in corso ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Impossibile verificare o scaricare l\'aggiornamento.';

  @override
  String get personaSelectTitle => 'Seleziona persona';

  @override
  String get personaSettingsHeader => 'Impostazioni personas';

  @override
  String get personaManageAction => 'Gestisci';

  @override
  String get personaSearchPlaceholder => 'Cerca personas, tag, pronomi...';

  @override
  String get personaModeManual => 'Manuale';

  @override
  String get personaModeLast => 'Usata di recente';

  @override
  String get personaModeManualDescription =>
      'Invia sempre come persona selezionata finché non viene modificata.';

  @override
  String get personaModeLastDescription =>
      'Passa automaticamente alla persona usata nel tuo ultimo messaggio.';

  @override
  String get personaRecentHeader => 'PERSONAS RECENTI';

  @override
  String personaAllHeader(int count) {
    return 'TUTTE LE PERSONAS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'RISULTATI DELLA RICERCA ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Account principale (Predefinito)';

  @override
  String get personaEmptyState =>
      'Nessuna persona ancora configurata. Creane una tramite Gestisci personas.';

  @override
  String get personaEmptySearch => 'Nessuna persona corrispondente trovata.';

  @override
  String get personaEditTitle => 'Modifica persona';

  @override
  String get personaCreateTitle => 'Crea persona';

  @override
  String get personaDisplayNameLabel => 'Nome visualizzato';

  @override
  String get personaPronounsLabel => 'Pronomi';

  @override
  String get personaPronounsHint => 'es. lei/lui';

  @override
  String get personaBioHint => 'Racconta agli altri di questa persona...';

  @override
  String get personaUpdatedToast => 'Persona aggiornata';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Impossibile aggiornare la persona: $error';
  }

  @override
  String get personaSectionTitle => 'Personas';

  @override
  String get personaDisplayNameHint => 'Nome della persona';

  @override
  String personaSendingAsTag(String name) {
    return 'Invio come $name (Corrispondenza per tag)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Invio come $name (Fissata)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Invio come $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Pubblicazione come $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Invio come @$username';
  }

  @override
  String get personaMainAccount => 'Account principale';

  @override
  String get personaEditPersona => 'Modifica persona';

  @override
  String get userSettingsNavPersonas => 'Personas';

  @override
  String get personaSettingsDescription =>
      'Configura la modalità persona attiva, il tag di visualizzazione personalizzato e gestisci le singole personas.';

  @override
  String get personaDisplayTagSection => 'Tag di visualizzazione';

  @override
  String get personaDisplayTagDescription =>
      'Il tag di visualizzazione apparirà accanto a tutti i nomi delle personas nei messaggi. Se non imposti alcun tag, verrà mostrata l\'immagine del profilo del tuo account.';

  @override
  String get personaDisplayTagLabel => 'Testo del tag di visualizzazione';

  @override
  String get personaDisplayTagHint => 'es. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Icona del tag di visualizzazione';

  @override
  String get personaUploadTagIcon => 'Carica icona';

  @override
  String get personaChangeTagIcon => 'Cambia icona';

  @override
  String get personaRemoveTagIcon => 'Rimuovi icona';

  @override
  String get personaChatPreviewTitle => 'Anteprima della chat';

  @override
  String get personaChatPreviewSampleMessage =>
      'Ciao! Questa è un\'anteprima di come appaiono i messaggi con il tuo tag di visualizzazione e la persona attiva.';

  @override
  String get personaListTitle => 'Personas configurate';

  @override
  String get personaAddButton => 'Aggiungi persona';

  @override
  String get personaActiveBadge => 'Attiva';

  @override
  String get personaMakeActive => 'Imposta come attiva';

  @override
  String get personaDeleteTitle => 'Elimina persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Vuoi davvero eliminare \"$name\"? Questa azione non può essere annullata.';
  }

  @override
  String get personaDeleteConfirm => 'Elimina';

  @override
  String get personaDeletedToast => 'Persona eliminata';

  @override
  String get personaCreatedToast => 'Persona creata';

  @override
  String personaCreateFailedToast(String error) {
    return 'Impossibile creare la persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Cambia avatar';

  @override
  String get personaRemoveAvatar => 'Rimuovi avatar';

  @override
  String get personaUploadAvatar => 'Carica avatar';

  @override
  String get personaTagsLabel => 'Tag di persona';

  @override
  String get personaAutoTagDisabledLabel =>
      'Non riconoscere i tag di questa persona';

  @override
  String get personaAutoTagDisabledDescription =>
      'Digitare uno di questi tag non passerà a questa persona. Il tag viene inviato così come è scritto.';

  @override
  String get personaTagPrefixLabel => 'Prefisso';

  @override
  String get personaTagSuffixLabel => 'Suffisso';

  @override
  String get personaVisibilityLabel => 'Visibilità';

  @override
  String get personaVisibilityUnlisted => 'Non in elenco';

  @override
  String get personaVisibilityPublic => 'Pubblica';

  @override
  String get personaVisibilityPrivate => 'Privata';

  @override
  String get personaNameRequired =>
      'Inserisci un nome visualizzato per la persona';

  @override
  String get personaNameTooLong =>
      'Il nome visualizzato della persona deve contenere massimo 100 caratteri';

  @override
  String get personaTagPrefixTooLong =>
      'Il prefisso del tag della persona deve contenere massimo 32 caratteri';

  @override
  String get personaTagSuffixTooLong =>
      'Il suffisso del tag della persona deve contenere massimo 32 caratteri';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Il tag \'$tag\' è già utilizzato da \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Inserisci timestamp';

  @override
  String get chatAttachmentSendVoiceMessage => 'Invia messaggio vocale';

  @override
  String get timestampPickerTitle => 'Inserisci timestamp';

  @override
  String get timestampPickerInsert => 'Inserisci';

  @override
  String get timestampCopied => 'Timestamp copiato';

  @override
  String get timestampPickerTimeLabel => 'Ora';

  @override
  String get timestampPickerDateLabel => 'DATA';

  @override
  String get timestampPickerTimeSectionLabel => 'ORA';

  @override
  String get timestampPickerTimezoneLabel => 'FUSO ORARIO';

  @override
  String get timestampPickerFormatPreviewLabel => 'ANTEPRIMA FORMATO';

  @override
  String get timestampPickerNlpPlaceholder =>
      'es. domani alle 15:00, tra 2 ore, adesso';

  @override
  String get timestampPickerSearchTimezones => 'Cerca fusi orari...';

  @override
  String get userProfileTimezoneSettingLabel => 'Fuso orario';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Usato per mostrare la tua ora locale sul tuo profilo.';

  @override
  String get userProfileTimezoneNone => 'Nessuno';

  @override
  String get chatReactAs => 'Reagisci come...';

  @override
  String get emojiCopy => 'Copia emoji';

  @override
  String get emojiCopyLink => 'Copia link';

  @override
  String get emojiPin => 'Fissa emoji';

  @override
  String get emojiUnpin => 'Rimuovi emoji fissata';

  @override
  String get emojiPinForPersona => 'Fissa per questa persona';

  @override
  String get emojiUnpinForPersona => 'Rimuovi fissaggio per questa persona';

  @override
  String get personaSignatureEmojisLabel => 'Emoji distintive';

  @override
  String get personaSignatureEmojisDescription =>
      'Reagire con un\'emoji distintiva reagirà sempre come questa persona, indipendentemente dalla persona attiva.';

  @override
  String get personaAddSignatureEmoji => 'Aggiungi emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Questa emoji è già stata aggiunta come emoji distintiva';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Emoji distintiva già in uso dalla persona \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Rimuovi emoji distintiva';

  @override
  String get signalBarLabel => 'Barra dei segnali';

  @override
  String get signalBarShow => 'Mostra barra dei segnali';

  @override
  String get signalBarHide => 'Nascondi barra dei segnali';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Nessuno ha attivato questo segnale';

  @override
  String get signalBarReset => 'Reimposta il segnale per tutti';

  @override
  String signalBarTurnOff(String name) {
    return 'Disattiva $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Usa $domain per l’istanza predefinita, oppure l’URL esatto di un’altra istanza.';
  }

  @override
  String get instanceResetToDefault => 'Ripristina l’istanza predefinita';

  @override
  String get personaScopeTitle => 'La persona si applica a';

  @override
  String get personaScopeGlobal => 'Ovunque';

  @override
  String get personaScopeGlobalDescription =>
      'Una sola persona per tutti i canali.';

  @override
  String get personaScopeChannel => 'In ogni canale';

  @override
  String get personaScopeChannelDescription =>
      'Ogni canale mantiene la propria persona. I nuovi canali partono con il tuo account.';

  @override
  String get personaPickerChannelOnly => 'Solo per questo canale';

  @override
  String get personaProfilePrivate => 'Il profilo di questa persona è privato.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Il file immagine è troppo grande. Scegli un file più piccolo di $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Cerca KLIPY';

  @override
  String get appUpdateDownloadFailed =>
      'Impossibile scaricare l\'aggiornamento';

  @override
  String get appUpdateInstallFailed =>
      'Impossibile installare l\'aggiornamento';

  @override
  String get personaChangeMessageFailed =>
      'Impossibile cambiare la persona del messaggio';

  @override
  String get personaActiveCleared => 'Persona attiva rimossa';

  @override
  String get klipyPoweredBy => 'Fornito da KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Coppia di tag \'$pattern\' duplicata su questa persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Aggiungi coppia di tag ($count/5)';
  }

  @override
  String get personaTagExampleText => 'testo';

  @override
  String get personaPreviewNameFallback => 'Utente';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne si è chiuso in modo imprevisto. Condividere dati anonimi su arresti anomali ed errori ci aiuta a risolvere i problemi più velocemente.';

  @override
  String get crashReportingSectionDescription =>
      'Aiuta a correggere i bug di Tyne condividendo dati su arresti anomali e prestazioni. È disattivato per impostazione predefinita.';

  @override
  String get crashReportingDescription =>
      'I report vengono inviati al sistema di tracciamento degli errori di Tyne stesso, anche quando hai effettuato l\'accesso a un\'altra istanza. Non includono nomi di istanze, ID o contenuti dei messaggi.';

  @override
  String get instanceOfflineTitle => 'Tyne è offline!';

  @override
  String get instanceOfflineBody => 'Stiamo indagando.';

  @override
  String get instanceStatusSignalLink =>
      'Unisciti alla nostra chat Signal per gli aggiornamenti';

  @override
  String get convertEmoticonsLabel => 'Trasforma le emoticon in emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Impossibile eseguire /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Il suo script ha un problema.';

  @override
  String guildCommandOneLine(String name) {
    return 'Ciò che scrivi dopo /$name deve stare su una riga.';
  }

  @override
  String get permissionCreateCommands => 'Crea comandi';

  @override
  String get permissionManageCommands => 'Gestisci comandi';

  @override
  String get permissionUseExternalCommands => 'Usa comandi esterni';

  @override
  String get permissionCreateCommandsDescription =>
      'Crea comandi per questa community e modifica o elimina i tuoi.';

  @override
  String get permissionManageCommandsDescription =>
      'Modifica o elimina i comandi di chiunque in questa community.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Usa i comandi di altre community.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Usa i comandi di altre community in questo canale.';

  @override
  String get guildSettingsCategoryMessageTools => 'Strumenti messaggi';

  @override
  String get guildSettingsCommands => 'Comandi';

  @override
  String get guildCommandsLoadFailed => 'Impossibile caricare i comandi.';

  @override
  String get guildCommandsSubtitle =>
      'Messaggi che i membri possono pubblicare digitando /name.';

  @override
  String get guildCommandsSlots => 'Slot comandi';

  @override
  String get guildCommandsNew => 'Nuovo comando';

  @override
  String get guildCommandsSearch => 'Cerca comandi';

  @override
  String get guildCommandsEmptyTitle => 'Nessun comando';

  @override
  String get guildCommandsEmptyBody =>
      'Questa community non ha ancora comandi.';

  @override
  String get guildCommandsSaved => 'Comandi salvati';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Impossibile salvare /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Modifica /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Eliminare /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Non può essere annullato. I messaggi creati con questo comando continuano a mostrare quale comando li ha creati.';

  @override
  String get guildCommandDelete => 'Elimina';

  @override
  String get guildCommandDeleteCommand => 'Elimina comando';

  @override
  String get guildCommandSectionCommand => 'Comando';

  @override
  String get guildCommandName => 'Nome';

  @override
  String get guildCommandNameInvalid =>
      'Usa lettere minuscole, numeri, - e _, fino a 32 caratteri.';

  @override
  String get guildCommandNameTaken =>
      'Un altro comando o un comando integrato ha già questo nome.';

  @override
  String get guildCommandDescription => 'Descrizione';

  @override
  String get guildCommandSectionInput => 'Input';

  @override
  String get guildCommandInputNone => 'Nessuno';

  @override
  String get guildCommandInputOptional => 'Facoltativo';

  @override
  String get guildCommandInputRequired => 'Obbligatorio';

  @override
  String get guildCommandHint => 'Suggerimento';

  @override
  String get guildCommandMessage => 'Messaggio';

  @override
  String get guildCommandInsert => 'Inserisci:';

  @override
  String get guildCommandInsertPerson => 'Chi lo usa';

  @override
  String get guildCommandInsertInput => 'Ciò che si scrive';

  @override
  String get guildCommandPreview => 'Anteprima';

  @override
  String get guildCommandSampleInput => 'Testo di esempio';

  @override
  String guildCommandMadeWith(String name) {
    return 'Creato con /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Svuota la casella del messaggio per usare /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Non verrebbe pubblicato nulla, quindi il comando non riuscirebbe.';

  @override
  String get guildCommandUseScriptEditor => 'Usa l\'editor di script';

  @override
  String get guildCommandUseBasicEditor => 'Usa l\'editor di base';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Esegui di nuovo';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Non esiste nessun tag chiamato $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Non esiste nessun filtro chiamato $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name non viene mai chiuso.';
  }

  @override
  String get guildCommandIssueTooLong => 'Lo script è troppo lungo.';

  @override
  String get guildCommandIssueTooLarge => 'Lo script genera troppo testo.';

  @override
  String get guildCommandIssueTooSlow =>
      'L\'esecuzione dello script ha richiesto troppo tempo.';

  @override
  String get guildCommandIssueInvalid => 'Questa parte non può essere letta.';

  @override
  String get guildCommandIssueFailed =>
      'Questa parte si è fermata con un errore.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Riga $line, colonna $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Guida agli script';

  @override
  String get guildCommandReferencePerson => 'Chi lo usa, come menzione';

  @override
  String get guildCommandReferencePersonName => 'Il nome di chi lo usa';

  @override
  String get guildCommandReferenceTarget =>
      'La prima persona menzionata, se c\'è';

  @override
  String get guildCommandReferenceTargetName => 'Il nome di quella persona';

  @override
  String get guildCommandReferenceChannel => 'Il canale, come menzione';

  @override
  String get guildCommandReferenceCommunity => 'Il nome di questa community';

  @override
  String get guildCommandExampleRandom => 'Scegli un\'opzione a caso';

  @override
  String get guildCommandExampleDepends =>
      'Cambia il messaggio in base a ciò che è stato scritto';

  @override
  String get guildCommandExampleOneWord => 'Scegli una parola a caso';

  @override
  String get guildCommandExampleWordForNumber =>
      'Scegli la parola in base a un numero';

  @override
  String get guildCommandExampleOrdinal =>
      'Scrivi un numero come 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Guida completa agli script';

  @override
  String get guildCommandCounters => 'Contatori';

  @override
  String get guildCommandCounterAdd => 'Aggiungi contatore';

  @override
  String get guildCommandCounterSeparately => 'Conta separatamente per ogni:';

  @override
  String get guildCommandCounterPersonMentioned => 'Persona menzionata';

  @override
  String get guildCommandCounterChannel => 'Canale';

  @override
  String get guildCommandCounterPersonas => 'Conta le persona separatamente';

  @override
  String get guildCommandCounterRemove => 'Rimuovi contatore';

  @override
  String get guildCommandCounterReset => 'Azzera i conteggi';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Azzerare i conteggi di $name? L’azione non può essere annullata.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Usa lettere minuscole, numeri e _, inizia con una lettera e non usare un nome già usato dagli script.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Usalo in uno script come $variable. Ogni esecuzione aggiunge prima uno, quindi la prima legge 1.';
  }
}
