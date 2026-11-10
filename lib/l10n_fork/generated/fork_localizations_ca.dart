// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class ForkLocalizationsCa extends ForkLocalizations {
  ForkLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Canvia de persona';

  @override
  String get chatAttachmentPanelVoice => 'Veu';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Botó del selector ràpid';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Substitueix el botó de missatge de veu del quadre de missatge per un botó del selector ràpid per moure’t més de pressa';

  @override
  String get userSettingsCheckForUpdates => 'Cerca actualitzacions';

  @override
  String get userSettingsCheckingForUpdates =>
      'S’estan cercant actualitzacions…';

  @override
  String get userSettingsAppUpToDate => 'Tyne està al dia';

  @override
  String get userSettingsUpdateAvailableTitle => 'Actualització disponible';

  @override
  String get userSettingsUpdateDownloadAction => 'Baixa i instal·la';

  @override
  String get userSettingsUpdateInstallAction => 'Instal·la l’actualització';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'S’està baixant l’actualització ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'No s’ha pogut cercar o baixar l’actualització.';

  @override
  String get personaSelectTitle => 'Tria una persona';

  @override
  String get personaSettingsHeader => 'Configuració de les persones';

  @override
  String get personaManageAction => 'Gestiona';

  @override
  String get personaSearchPlaceholder => 'Cerca persones, etiquetes, pronoms…';

  @override
  String get personaModeManual => 'Manual';

  @override
  String get personaModeLast => 'Última usada';

  @override
  String get personaModeManualDescription =>
      'Envia sempre com la persona triada fins que la canviïs.';

  @override
  String get personaModeLastDescription =>
      'Canvia automàticament a la persona que vas fer servir a l’últim missatge.';

  @override
  String get personaRecentHeader => 'PERSONES RECENTS';

  @override
  String personaAllHeader(int count) {
    return 'TOTES LES PERSONES ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'RESULTATS DE LA CERCA ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Compte principal (per defecte)';

  @override
  String get personaEmptyState =>
      'Encara no has configurat cap persona. Crea’n una des de «Gestiona».';

  @override
  String get personaEmptySearch => 'No s’ha trobat cap persona.';

  @override
  String get personaEditTitle => 'Edita la persona';

  @override
  String get personaCreateTitle => 'Crea una persona';

  @override
  String get personaDisplayNameLabel => 'Nom visible';

  @override
  String get personaPronounsLabel => 'Pronoms';

  @override
  String get personaPronounsHint => 'p. ex. elli';

  @override
  String get personaBioHint =>
      'Explica als altres alguna cosa sobre aquesta persona…';

  @override
  String get personaUpdatedToast => 'S’ha actualitzat la persona';

  @override
  String personaUpdateFailedToast(String error) {
    return 'No s’ha pogut actualitzar la persona: $error';
  }

  @override
  String get personaSectionTitle => 'Persones';

  @override
  String get personaDisplayNameHint => 'Nom de la persona';

  @override
  String personaSendingAsTag(String name) {
    return 'Envies com a $name (reconeguda per l’etiqueta)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Envies com a $name (última usada)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Envies com a $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Publiques com a $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Envies com a @$username';
  }

  @override
  String get personaSendHeldNotLoaded =>
      'No s’ha enviat: encara no s’han carregat les teves persones.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'No s’ha enviat: encara no s’han carregat les teves persones. Vols enviar-lo com a @$username?';
  }

  @override
  String get personaSendAsAccountAction => 'Envia igualment';

  @override
  String get personaMainAccount => 'Compte principal';

  @override
  String get personaEditPersona => 'Edita la persona';

  @override
  String get userSettingsNavPersonas => 'Persones';

  @override
  String get personaSettingsDescription =>
      'Configura el mode de persona activa i l’etiqueta visible personalitzada, i gestiona cada persona.';

  @override
  String get personaDisplayTagSection => 'Etiqueta visible';

  @override
  String get personaDisplayTagDescription =>
      'L’etiqueta visible apareixerà al costat del nom de totes les persones als missatges. Si no n’hi ha cap, es mostrarà la foto de perfil del teu compte.';

  @override
  String get personaDisplayTagLabel => 'Text de l’etiqueta visible';

  @override
  String get personaDisplayTagHint => 'p. ex. SIS';

  @override
  String get personaDisplayTagIconLabel => 'Icona de l’etiqueta visible';

  @override
  String get personaUploadTagIcon => 'Puja una icona';

  @override
  String get personaChangeTagIcon => 'Canvia la icona';

  @override
  String get personaRemoveTagIcon => 'Elimina la icona';

  @override
  String get personaChatPreviewTitle => 'Previsualització del xat';

  @override
  String get personaChatPreviewSampleMessage =>
      'Hola! Així es veuen els missatges amb la teva etiqueta visible i la persona activa.';

  @override
  String get personaListTitle => 'Persones configurades';

  @override
  String get personaAddButton => 'Afegeix una persona';

  @override
  String get personaActiveBadge => 'Activa';

  @override
  String get personaMakeActive => 'Fes-la activa';

  @override
  String get personaDeleteTitle => 'Suprimeix la persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Segur que vols suprimir «$name»? No es pot desfer.';
  }

  @override
  String get personaDeleteConfirm => 'Suprimeix';

  @override
  String get personaDeletedToast => 'S’ha suprimit la persona';

  @override
  String get personaCreatedToast => 'S’ha creat la persona';

  @override
  String personaCreateFailedToast(String error) {
    return 'No s’ha pogut crear la persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Canvia l’avatar';

  @override
  String get personaRemoveAvatar => 'Elimina l’avatar';

  @override
  String get personaUploadAvatar => 'Puja un avatar';

  @override
  String get personaTagsLabel => 'Etiquetes de la persona';

  @override
  String get personaAutoTagDisabledLabel =>
      'Ignora les etiquetes d’aquesta persona';

  @override
  String get personaAutoTagDisabledDescription =>
      'Si escrius una d’aquestes etiquetes, no es canviarà a aquesta persona. L’etiqueta s’envia tal com l’has escrita.';

  @override
  String get personaTagPrefixLabel => 'Prefix';

  @override
  String get personaTagSuffixLabel => 'Sufix';

  @override
  String get personaVisibilityLabel => 'Visibilitat';

  @override
  String get personaVisibilityUnlisted => 'No llistada';

  @override
  String get personaVisibilityPublic => 'Pública';

  @override
  String get personaVisibilityPrivate => 'Privada';

  @override
  String get personaNameRequired => 'Escriu un nom visible per a la persona';

  @override
  String get personaNameTooLong =>
      'El nom visible de la persona ha de tenir 100 caràcters o menys';

  @override
  String get personaTagPrefixTooLong =>
      'El prefix de l’etiqueta ha de tenir 32 caràcters o menys';

  @override
  String get personaTagSuffixTooLong =>
      'El sufix de l’etiqueta ha de tenir 32 caràcters o menys';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'L’etiqueta «$tag» ja la fa servir «$name».';
  }

  @override
  String get chatInsertTimestamp => 'Insereix una marca de temps';

  @override
  String get chatAttachmentSendVoiceMessage => 'Envia un missatge de veu';

  @override
  String get timestampPickerTitle => 'Insereix una marca de temps';

  @override
  String get timestampPickerInsert => 'Insereix';

  @override
  String get timestampCopied => 'S’ha copiat la marca de temps';

  @override
  String get timestampPickerTimeLabel => 'Hora';

  @override
  String get timestampPickerDateLabel => 'DATA';

  @override
  String get timestampPickerTimeSectionLabel => 'HORA';

  @override
  String get timestampPickerTimezoneLabel => 'FUS HORARI';

  @override
  String get timestampPickerFormatPreviewLabel => 'PREVISUALITZACIÓ DEL FORMAT';

  @override
  String get timestampPickerNlpPlaceholder =>
      'p. ex. tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'Cerca fusos horaris…';

  @override
  String get userProfileTimezoneSettingLabel => 'Fus horari';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Serveix per mostrar la teva hora local al perfil.';

  @override
  String get userProfileTimezoneNone => 'Cap';

  @override
  String get chatReactAs => 'Reacciona com a…';

  @override
  String get emojiCopy => 'Copia l’emoji';

  @override
  String get emojiCopyLink => 'Copia l’enllaç';

  @override
  String get emojiPin => 'Fixa l’emoji';

  @override
  String get emojiUnpin => 'Deixa de fixar l’emoji';

  @override
  String get emojiPinForPersona => 'Fixa per a aquesta persona';

  @override
  String get emojiUnpinForPersona => 'Deixa de fixar per a aquesta persona';

  @override
  String get personaSignatureEmojisLabel => 'Emojis distintius';

  @override
  String get personaSignatureEmojisDescription =>
      'Si reacciones amb un emoji distintiu, sempre reaccionaràs com a aquesta persona, sigui quina sigui la persona activa.';

  @override
  String get personaAddSignatureEmoji => 'Afegeix un emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Aquest emoji ja és un emoji distintiu';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'L’emoji distintiu ja el fa servir la persona «$name»';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Elimina l’emoji distintiu';

  @override
  String get signalBarLabel => 'Barra de senyals';

  @override
  String get signalBarShow => 'Mostra la barra de senyals';

  @override
  String get signalBarHide => 'Amaga la barra de senyals';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Ningú no té aquest senyal activat';

  @override
  String get signalBarReset => 'Desactiva el senyal per a tothom';

  @override
  String signalBarTurnOff(String name) {
    return 'Desactiva per a $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Fes servir $domain per a la instància per defecte, o l’adreça exacta d’una altra instància.';
  }

  @override
  String get instanceResetToDefault => 'Torna a la instància per defecte';

  @override
  String get personaScopeTitle => 'La persona s’aplica a';

  @override
  String get personaScopeGlobal => 'A tot arreu';

  @override
  String get personaScopeGlobalDescription =>
      'Una persona per a tots els canals.';

  @override
  String get personaScopeChannel => 'A cada canal';

  @override
  String get personaScopeChannelDescription =>
      'Cada canal recorda la seva persona. Els canals nous comencen amb el teu compte.';

  @override
  String get personaPickerChannelOnly => 'Només per a aquest canal';

  @override
  String get personaProfilePrivate => 'El perfil d’aquesta persona és privat.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'El fitxer d’imatge és massa gran. Tria un fitxer de menys de $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Cerca a KLIPY';

  @override
  String get appUpdateDownloadFailed => 'No s’ha pogut baixar l’actualització';

  @override
  String get appUpdateInstallFailed =>
      'No s’ha pogut instal·lar l’actualització';

  @override
  String get personaChangeMessageFailed =>
      'No s’ha pogut canviar la persona del missatge';

  @override
  String get personaActiveCleared => 'Ja no hi ha cap persona activa';

  @override
  String get klipyPoweredBy => 'Amb la tecnologia de KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Parell d’etiquetes «$pattern» duplicat en aquesta persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Afegeix un parell d’etiquetes ($count/5)';
  }

  @override
  String get personaTagExampleText => 'text';

  @override
  String get personaPreviewNameFallback => 'Usuari';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne s’ha tancat inesperadament. Si comparteixes dades anònimes d’errors i bloquejos, ens ajudes a solucionar els problemes més de pressa.';

  @override
  String get crashReportingSectionDescription =>
      'Ajuda a corregir errors de Tyne compartint dades de bloquejos i de rendiment. Està desactivat per defecte.';

  @override
  String get crashReportingDescription =>
      'Els informes van al servei de seguiment d’errors propi de Tyne, fins i tot si has iniciat la sessió en una altra instància. No inclouen noms d’instàncies, identificadors ni el contingut dels missatges.';

  @override
  String get instanceOfflineTitle => 'Tyne està fora de línia!';

  @override
  String get instanceOfflineBody => 'Ho estem investigant.';

  @override
  String get instanceStatusSignalLink =>
      'Uneix-te al nostre xat de Signal per estar al dia';

  @override
  String get convertEmoticonsLabel =>
      'Converteix les emoticones de text en emojis';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'No s’ha pogut executar /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'El seu script té un problema.';

  @override
  String guildCommandOneLine(String name) {
    return 'El que escriguis després de /$name ha de cabre en una línia.';
  }

  @override
  String get permissionCreateCommands => 'Crear ordres';

  @override
  String get permissionManageCommands => 'Gestionar ordres';

  @override
  String get permissionUseExternalCommands => 'Fer servir ordres externes';

  @override
  String get permissionCreateCommandsDescription =>
      'Permet crear ordres per a aquesta comunitat, i editar o suprimir les pròpies.';

  @override
  String get permissionManageCommandsDescription =>
      'Permet editar o suprimir les ordres de qualsevol membre d’aquesta comunitat.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Permet fer servir ordres d’altres comunitats.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Permet fer servir ordres d’altres comunitats en aquest canal.';

  @override
  String get guildSettingsCategoryMessageTools => 'Eines de missatges';

  @override
  String get guildSettingsCommands => 'Ordres';

  @override
  String get guildCommandsLoadFailed => 'No s’han pogut carregar les ordres.';

  @override
  String get guildCommandsSubtitle =>
      'Missatges que els membres poden publicar escrivint /name.';

  @override
  String get guildCommandsSlots => 'Espais per a ordres';

  @override
  String get guildCommandsNew => 'Ordre nova';

  @override
  String get guildCommandsSearch => 'Cerca ordres';

  @override
  String get guildCommandsEmptyTitle => 'No hi ha ordres';

  @override
  String get guildCommandsEmptyBody =>
      'Aquesta comunitat encara no té cap ordre.';

  @override
  String get guildCommandsSaved => 'S’han desat les ordres';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'No s’ha pogut desar /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Edita /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Vols suprimir /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'No es pot desfer. Els missatges fets amb aquesta ordre continuaran mostrant quina ordre els ha fet.';

  @override
  String get guildCommandDelete => 'Suprimeix';

  @override
  String get guildCommandDeleteCommand => 'Suprimeix l’ordre';

  @override
  String get guildCommandSectionCommand => 'Ordre';

  @override
  String get guildCommandName => 'Nom';

  @override
  String get guildCommandNameInvalid =>
      'Fes servir minúscules, xifres, - i _, fins a 32 caràcters.';

  @override
  String get guildCommandNameTaken =>
      'Ja hi ha una altra ordre o una ordre integrada amb aquest nom.';

  @override
  String get guildCommandDescription => 'Descripció';

  @override
  String get guildCommandSectionInput => 'Entrada';

  @override
  String get guildCommandInputNone => 'Cap';

  @override
  String get guildCommandInputOptional => 'Opcional';

  @override
  String get guildCommandInputRequired => 'Obligatòria';

  @override
  String get guildCommandHint => 'Indicació';

  @override
  String get guildCommandMessage => 'Missatge';

  @override
  String get guildCommandInsert => 'Insereix:';

  @override
  String get guildCommandInsertPerson => 'Membre que l’executa';

  @override
  String get guildCommandInsertInput => 'El que escriuen';

  @override
  String get guildCommandPreview => 'Previsualització';

  @override
  String get guildCommandSampleInput => 'Text d’exemple';

  @override
  String guildCommandMadeWith(String name) {
    return 'Fet amb /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Buida el quadre de missatge per fer servir /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Això no publicaria res i l’ordre fallaria.';

  @override
  String get guildCommandUseScriptEditor => 'Fes servir l’editor de scripts';

  @override
  String get guildCommandUseBasicEditor => 'Fes servir l’editor bàsic';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Torna a executar';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'No hi ha cap etiqueta anomenada $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'No hi ha cap filtre anomenat $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name no es tanca mai.';
  }

  @override
  String get guildCommandIssueTooLong => 'Aquest script és massa llarg.';

  @override
  String get guildCommandIssueTooLarge => 'Aquest script genera massa text.';

  @override
  String get guildCommandIssueTooSlow =>
      'Aquest script ha trigat massa a executar-se.';

  @override
  String get guildCommandIssueInvalid => 'Aquesta part no es pot llegir.';

  @override
  String get guildCommandIssueFailed =>
      'Aquesta part s’ha aturat amb un error.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Línia $line, columna $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Referència dels scripts';

  @override
  String get guildCommandReferencePerson =>
      'El membre que l’executa, com a menció';

  @override
  String get guildCommandReferencePersonName => 'El seu nom';

  @override
  String get guildCommandReferenceTarget =>
      'El primer membre que esmentin, si n’hi ha';

  @override
  String get guildCommandReferenceTargetName => 'El nom d’aquest membre';

  @override
  String get guildCommandReferenceChannel => 'El canal, com a menció';

  @override
  String get guildCommandReferenceCommunity => 'El nom d’aquesta comunitat';

  @override
  String get guildCommandExampleRandom => 'Tria una opció a l’atzar';

  @override
  String get guildCommandExampleDepends =>
      'Canvia el missatge segons el que hagin escrit';

  @override
  String get guildCommandExampleOneWord => 'Tria una paraula a l’atzar';

  @override
  String get guildCommandExampleWordForNumber => 'Escriu un nombre amb lletres';

  @override
  String get guildCommandExampleOrdinal =>
      'Escriu un nombre com a ordinal: 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Guia completa dels scripts';

  @override
  String get guildCommandCounters => 'Comptadors';

  @override
  String get guildCommandCounterAdd => 'Afegeix un comptador';

  @override
  String get guildCommandCounterSeparately => 'Compta per separat per a cada:';

  @override
  String get guildCommandCounterPersonMentioned => 'Membre esmentat';

  @override
  String get guildCommandCounterChannel => 'Canal';

  @override
  String get guildCommandCounterPersonas => 'Compta les persones per separat';

  @override
  String get guildCommandCounterRemove => 'Elimina el comptador';

  @override
  String get guildCommandCounterReset => 'Reinicia els recomptes';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Vols reiniciar els recomptes de $name? No es pot desfer.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Fes servir minúscules, xifres i _, comença per una lletra i no facis servir cap nom que ja usin els scripts.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Fes-lo servir en un script com a $variable. Cada execució hi suma 1 abans de res, així que la primera dona 1.';
  }

  @override
  String get notificationsAlertEveryMessageLabel => 'Avisa de cada missatge';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Si està desactivat, una conversa amb molta activitat t’avisa una sola vegada i després s’actualitza en silenci fins que la llegeixis o la descartis.';

  @override
  String personaGalleryTitle(int count) {
    return 'Persones ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Cerca les persones de $name';
  }

  @override
  String get personaGallerySearchOwn => 'Cerca les teves persones';

  @override
  String get personaGallerySortBy => 'Ordena per';

  @override
  String get personaGallerySortName => 'Nom (A–Z)';

  @override
  String get personaGallerySortMostUsed => 'Més usades';

  @override
  String get personaGallerySortRecentlyUsed => 'Usades recentment';

  @override
  String get personaGalleryViewGallery => 'Galeria';

  @override
  String get personaGalleryViewList => 'Llista';

  @override
  String get personaGalleryViewAvatars => 'Avatars';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persones',
      many: '$count persones',
      one: '$count persona',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return '$shown de $total persones';
  }

  @override
  String get personaGalleryNoMatch => 'Cap persona coincideix amb la cerca.';

  @override
  String get personaGalleryLoadFailed =>
      'No s’han pogut carregar les persones.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persones públiques',
      many: '$count persones públiques',
      one: '$count persona pública',
    );
    return 'Els altres veuen $_temp0.';
  }

  @override
  String get personaGalleryShowHidden =>
      'Mostra les no llistades i les privades';

  @override
  String get personaGalleryManage => 'Gestiona les persones';

  @override
  String get personaGalleryNonePublic =>
      'Encara no tens cap persona pública. Els altres veuran una persona aquí quan en posis la visibilitat a Pública.';

  @override
  String get personaGalleryNoBio => 'Encara no té biografia.';

  @override
  String personaGalleryCreated(String date) {
    return 'Creada el $date';
  }

  @override
  String get personaBulkSelect => 'Selecciona';

  @override
  String get personaBulkSelectAll => 'Selecciona-les totes';

  @override
  String personaBulkSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionades',
      many: '$count seleccionades',
      one: '$count seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get personaFilterAll => 'Totes';

  @override
  String get personaBulkMakePublic => 'Fes-les públiques';

  @override
  String get personaBulkMakeUnlisted => 'Fes-les no llistades';

  @override
  String get personaBulkMakePrivate => 'Fes-les privades';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persones siguin públiques',
      many: '$count persones siguin públiques',
      one: '$count persona sigui pública',
    );
    return 'Vols que $_temp0?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persones siguin privades',
      many: '$count persones siguin privades',
      one: '$count persona sigui privada',
    );
    return 'Vols que $_temp0?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persones',
      many: '$count persones',
      one: '$count persona',
    );
    return 'Vols suprimir $_temp0?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Els altres les veuran a la teva llista de persones i en podran obrir els perfils. Pots desfer-ho quan vulguis.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Els seus perfils quedaran ocults per als altres. Els noms i els avatars continuaran apareixent als seus missatges i reaccions.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Els seus missatges continuaran mostrant els noms i els avatars, però ja no podràs enviar com a aquestes persones, i les seves etiquetes i emojis distintius quedaran lliures. No es pot desfer.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persones ara són públiques',
      many: '$count persones ara són públiques',
      one: '$count persona ara és pública',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persones ara són no llistades',
      many: '$count persones ara són no llistades',
      one: '$count persona ara és no llistada',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persones ara són privades',
      many: '$count persones ara són privades',
      one: '$count persona ara és privada',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'S’han suprimit $count persones',
      many: 'S’han suprimit $count persones',
      one: 'S’ha suprimit $count persona',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed =>
      'No s’han pogut canviar les persones. Torna-ho a provar.';

  @override
  String get personaFilterEmpty => 'Aquí no hi ha cap persona.';

  @override
  String get personaGalleryChooseFeatured =>
      'Tria les persones que vols destacar';

  @override
  String get personaUndo => 'Desfés';

  @override
  String get personaReactionsTitle => 'Les teves reaccions';

  @override
  String get personaReactionsEveryoneElse => 'LA RESTA';

  @override
  String get personaReactionsCurrent => 'ACTUAL';

  @override
  String get personaReactionsAccount => 'Compte';

  @override
  String get personaReactionsSomeoneElse => 'Reacciona com a algú altre…';

  @override
  String get personaReactionsDone => 'Fet';

  @override
  String get personaSettingsReactionsHeader => 'Reaccions';

  @override
  String get personaSettingsMultiReactions =>
      'Reacciona com a diverses persones alhora';

  @override
  String get personaDuplicateButton => 'Duplica la persona';

  @override
  String personaCopyOf(String name) {
    return 'Còpia de $name';
  }
}
