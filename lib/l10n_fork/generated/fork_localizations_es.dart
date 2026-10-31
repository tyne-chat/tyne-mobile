// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class ForkLocalizationsEs extends ForkLocalizations {
  ForkLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Cambiar persona';

  @override
  String get chatAttachmentPanelVoice => 'Voz';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Botón del selector rápido';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Reemplaza el botón de mensaje de voz por un botón de selector rápido para una navegación ágil';

  @override
  String get userSettingsCheckForUpdates => 'Buscar actualizaciones';

  @override
  String get userSettingsCheckingForUpdates => 'Buscando actualizaciones…';

  @override
  String get userSettingsAppUpToDate => 'Tyne está actualizado';

  @override
  String get userSettingsUpdateAvailableTitle => 'Actualización disponible';

  @override
  String get userSettingsUpdateDownloadAction => 'Descargar e instalar';

  @override
  String get userSettingsUpdateInstallAction => 'Instalar actualización';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Descargando actualización ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Error al buscar o descargar la actualización.';

  @override
  String get personaSelectTitle => 'Seleccionar persona';

  @override
  String get personaSettingsHeader => 'Ajustes de personas';

  @override
  String get personaManageAction => 'Gestionar';

  @override
  String get personaSearchPlaceholder =>
      'Buscar personas, etiquetas, pronombres...';

  @override
  String get personaModeManual => 'Manual';

  @override
  String get personaModeLast => 'Usada por última vez';

  @override
  String get personaModeManualDescription =>
      'Envía siempre como la persona seleccionada hasta que se cambie.';

  @override
  String get personaModeLastDescription =>
      'Cambia automáticamente a la persona utilizada en tu último mensaje.';

  @override
  String get personaRecentHeader => 'PERSONAS RECIENTES';

  @override
  String personaAllHeader(int count) {
    return 'TODAS LAS PERSONAS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'RESULTADOS DE BÚSQUEDA ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Cuenta principal (Por defecto)';

  @override
  String get personaEmptyState =>
      'Aún no hay ninguna persona configurada. Crea una desde Gestionar personas.';

  @override
  String get personaEmptySearch => 'No se encontraron personas que coincidan.';

  @override
  String get personaEditTitle => 'Editar persona';

  @override
  String get personaCreateTitle => 'Crear persona';

  @override
  String get personaDisplayNameLabel => 'Nombre visible';

  @override
  String get personaPronounsLabel => 'Pronombres';

  @override
  String get personaPronounsHint => 'p. ej. ella/él';

  @override
  String get personaBioHint => 'Cuenta a los demás sobre esta persona...';

  @override
  String get personaUpdatedToast => 'Persona actualizada';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Error al actualizar la persona: $error';
  }

  @override
  String get personaSectionTitle => 'Personas';

  @override
  String get personaDisplayNameHint => 'Nombre de la persona';

  @override
  String personaSendingAsTag(String name) {
    return 'Enviando como $name (Coincidencia por etiqueta)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Enviando como $name (Fijada)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Enviando como $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Publicando como $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Enviando como @$username';
  }

  @override
  String get personaMainAccount => 'Cuenta principal';

  @override
  String get personaEditPersona => 'Editar persona';

  @override
  String get userSettingsNavPersonas => 'Personas';

  @override
  String get personaSettingsDescription =>
      'Configura tu modo de persona activo, tu etiqueta de visualización personalizada y gestiona personas individuales.';

  @override
  String get personaDisplayTagSection => 'Etiqueta de visualización';

  @override
  String get personaDisplayTagDescription =>
      'La etiqueta de visualización aparecerá junto al nombre de todas las personas en los mensajes. Si no configuras ninguna, se mostrará la foto de perfil de tu cuenta.';

  @override
  String get personaDisplayTagLabel => 'Texto de la etiqueta de visualización';

  @override
  String get personaDisplayTagHint => 'p. ej. SYS';

  @override
  String get personaDisplayTagIconLabel =>
      'Icono de la etiqueta de visualización';

  @override
  String get personaUploadTagIcon => 'Subir icono';

  @override
  String get personaChangeTagIcon => 'Cambiar icono';

  @override
  String get personaRemoveTagIcon => 'Eliminar icono';

  @override
  String get personaChatPreviewTitle => 'Vista previa del chat';

  @override
  String get personaChatPreviewSampleMessage =>
      '¡Hola! Esta es una vista previa de cómo se ven los mensajes con tu etiqueta de visualización y tu persona activa.';

  @override
  String get personaListTitle => 'Personas configuradas';

  @override
  String get personaAddButton => 'Añadir persona';

  @override
  String get personaActiveBadge => 'Activa';

  @override
  String get personaMakeActive => 'Activar';

  @override
  String get personaDeleteTitle => 'Eliminar persona';

  @override
  String personaDeleteMessage(String name) {
    return '¿Seguro que quieres eliminar \"$name\"? Esta acción no se puede deshacer.';
  }

  @override
  String get personaDeleteConfirm => 'Eliminar';

  @override
  String get personaDeletedToast => 'Persona eliminada';

  @override
  String get personaCreatedToast => 'Persona creada';

  @override
  String personaCreateFailedToast(String error) {
    return 'Error al crear la persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Cambiar avatar';

  @override
  String get personaRemoveAvatar => 'Eliminar avatar';

  @override
  String get personaUploadAvatar => 'Subir avatar';

  @override
  String get personaTagsLabel => 'Etiquetas de persona';

  @override
  String get personaAutoTagDisabledLabel =>
      'No reconocer las etiquetas de esta persona';

  @override
  String get personaAutoTagDisabledDescription =>
      'Escribir una de estas etiquetas no cambiará a esta persona. La etiqueta se envía tal como está escrita.';

  @override
  String get personaTagPrefixLabel => 'Prefijo';

  @override
  String get personaTagSuffixLabel => 'Sufijo';

  @override
  String get personaVisibilityLabel => 'Visibilidad';

  @override
  String get personaVisibilityUnlisted => 'Oculta';

  @override
  String get personaVisibilityPublic => 'Pública';

  @override
  String get personaVisibilityPrivate => 'Privada';

  @override
  String get personaNameRequired =>
      'Introduce un nombre para mostrar de la persona';

  @override
  String get personaNameTooLong =>
      'El nombre de la persona debe tener 100 caracteres o menos';

  @override
  String get personaTagPrefixTooLong =>
      'El prefijo de la etiqueta debe tener 32 caracteres o menos';

  @override
  String get personaTagSuffixTooLong =>
      'El sufijo de la etiqueta debe tener 32 caracteres o menos';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'La etiqueta \'$tag\' ya está en uso por \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Insertar marca de tiempo';

  @override
  String get chatAttachmentSendVoiceMessage => 'Enviar mensaje de voz';

  @override
  String get timestampPickerTitle => 'Insertar marca de tiempo';

  @override
  String get timestampPickerInsert => 'Insertar';

  @override
  String get timestampCopied => 'Marca de tiempo copiada';

  @override
  String get timestampPickerTimeLabel => 'Hora';

  @override
  String get timestampPickerDateLabel => 'FECHA';

  @override
  String get timestampPickerTimeSectionLabel => 'HORA';

  @override
  String get timestampPickerTimezoneLabel => 'ZONA HORARIA';

  @override
  String get timestampPickerFormatPreviewLabel => 'VISTA PREVIA DEL FORMATO';

  @override
  String get timestampPickerNlpPlaceholder =>
      'ej. mañana a las 3pm, en 2 horas, ahora';

  @override
  String get timestampPickerSearchTimezones => 'Buscar zonas horarias...';

  @override
  String get userProfileTimezoneSettingLabel => 'Zona horaria';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Se usa para mostrar tu hora local en tu perfil.';

  @override
  String get userProfileTimezoneNone => 'Ninguno';

  @override
  String get chatReactAs => 'Reaccionar como...';

  @override
  String get emojiCopy => 'Copiar emoji';

  @override
  String get emojiCopyLink => 'Copiar enlace';

  @override
  String get emojiPin => 'Fijar emoji';

  @override
  String get emojiUnpin => 'Desfijar emoji';

  @override
  String get emojiPinForPersona => 'Fijar para esta persona';

  @override
  String get emojiUnpinForPersona => 'Desfijar para esta persona';

  @override
  String get personaSignatureEmojisLabel => 'Emojis de firma';

  @override
  String get personaSignatureEmojisDescription =>
      'Reaccionar con un emoji de firma siempre reaccionará como esta persona, independientemente de la persona activa.';

  @override
  String get personaAddSignatureEmoji => 'Añadir emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Este emoji ya está añadido como emoji de firma';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'El emoji de firma ya está en uso por la persona \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Eliminar emoji de firma';

  @override
  String get signalBarLabel => 'Barra de señales';

  @override
  String get signalBarShow => 'Mostrar barra de señales';

  @override
  String get signalBarHide => 'Ocultar barra de señales';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Nadie tiene esta señal activada';

  @override
  String get signalBarReset => 'Restablecer señal para todos';

  @override
  String signalBarTurnOff(String name) {
    return 'Desactivar $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Usa $domain para la instancia predeterminada o la URL exacta de otra instancia.';
  }

  @override
  String get instanceResetToDefault =>
      'Restablecer a la instancia predeterminada';

  @override
  String get personaScopeTitle => 'La persona se aplica a';

  @override
  String get personaScopeGlobal => 'En todas partes';

  @override
  String get personaScopeGlobalDescription =>
      'Una persona para todos los canales.';

  @override
  String get personaScopeChannel => 'En cada canal';

  @override
  String get personaScopeChannelDescription =>
      'Cada canal conserva su propia persona. Los canales nuevos empiezan como tu cuenta.';

  @override
  String get personaPickerChannelOnly => 'Solo para este canal';

  @override
  String get personaProfilePrivate => 'El perfil de esta persona es privado.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'El archivo de imagen es demasiado grande. Por favor, elige un archivo de menos de $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Buscar en KLIPY';

  @override
  String get appUpdateDownloadFailed => 'No se pudo descargar la actualización';

  @override
  String get appUpdateInstallFailed => 'No se pudo instalar la actualización';

  @override
  String get personaChangeMessageFailed =>
      'No se pudo cambiar la persona del mensaje';

  @override
  String get personaActiveCleared => 'Persona activa quitada';

  @override
  String get klipyPoweredBy => 'Con la tecnología de KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Par de etiquetas \'$pattern\' duplicado en esta persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Añadir par de etiquetas ($count/5)';
  }

  @override
  String get personaTagExampleText => 'texto';

  @override
  String get personaPreviewNameFallback => 'Usuario';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne se cerró inesperadamente. Compartir datos anónimos de fallos y errores nos ayuda a solucionar los problemas más rápido.';

  @override
  String get crashReportingSectionDescription =>
      'Ayuda a corregir errores en Tyne compartiendo datos de fallos y rendimiento. Está desactivado de forma predeterminada.';

  @override
  String get crashReportingDescription =>
      'Los informes se envían al sistema de seguimiento de errores propio de Tyne, incluso cuando hayas iniciado sesión en otra instancia. No incluyen nombres de instancias, identificadores ni el contenido de los mensajes.';

  @override
  String get instanceOfflineTitle => '¡Tyne está desconectado!';

  @override
  String get instanceOfflineBody => 'Lo estamos investigando.';

  @override
  String get instanceStatusSignalLink =>
      'Únete a nuestro chat de Signal para recibir novedades';

  @override
  String get convertEmoticonsLabel =>
      'Convertir los emoticonos de texto en emojis';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'No se pudo ejecutar /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'El script del comando tiene un problema.';

  @override
  String guildCommandOneLine(String name) {
    return 'Lo que escribas después de /$name tiene que caber en una línea.';
  }

  @override
  String get permissionCreateCommands => 'Crear comandos';

  @override
  String get permissionManageCommands => 'Gestionar comandos';

  @override
  String get permissionUseExternalCommands => 'Usar comandos externos';

  @override
  String get permissionCreateCommandsDescription =>
      'Crear comandos para esta comunidad y editar o eliminar los tuyos.';

  @override
  String get permissionManageCommandsDescription =>
      'Editar o eliminar los comandos de cualquiera en esta comunidad.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Usar comandos de otras comunidades.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Usar comandos de otras comunidades en este canal.';

  @override
  String get guildSettingsCategoryMessageTools => 'Herramientas de mensajes';

  @override
  String get guildSettingsCommands => 'Comandos';

  @override
  String get guildCommandsLoadFailed => 'No se pudieron cargar los comandos.';

  @override
  String get guildCommandsSubtitle =>
      'Mensajes que los miembros pueden publicar escribiendo /name.';

  @override
  String get guildCommandsSlots => 'Espacios para comandos';

  @override
  String get guildCommandsNew => 'Nuevo comando';

  @override
  String get guildCommandsSearch => 'Buscar comandos';

  @override
  String get guildCommandsEmptyTitle => 'No hay comandos';

  @override
  String get guildCommandsEmptyBody => 'Esta comunidad aún no tiene comandos.';

  @override
  String get guildCommandsSaved => 'Comandos guardados';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'No se pudo guardar /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Editar /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return '¿Eliminar /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'No se puede deshacer. Los mensajes hechos con él siguen mostrando qué comando los hizo.';

  @override
  String get guildCommandDelete => 'Eliminar';

  @override
  String get guildCommandDeleteCommand => 'Eliminar comando';

  @override
  String get guildCommandSectionCommand => 'Comando';

  @override
  String get guildCommandName => 'Nombre';

  @override
  String get guildCommandNameInvalid =>
      'Usa minúsculas, números, - y _, hasta 32 caracteres.';

  @override
  String get guildCommandNameTaken =>
      'Otro comando o un comando integrado ya tiene este nombre.';

  @override
  String get guildCommandDescription => 'Descripción';

  @override
  String get guildCommandSectionInput => 'Entrada';

  @override
  String get guildCommandInputNone => 'Ninguno';

  @override
  String get guildCommandInputOptional => 'Opcional';

  @override
  String get guildCommandInputRequired => 'Obligatorio';

  @override
  String get guildCommandHint => 'Pista';

  @override
  String get guildCommandMessage => 'Mensaje';

  @override
  String get guildCommandInsert => 'Insertar:';

  @override
  String get guildCommandInsertPerson => 'Quien lo usa';

  @override
  String get guildCommandInsertInput => 'Lo que escriben';

  @override
  String get guildCommandPreview => 'Vista previa';

  @override
  String get guildCommandSampleInput => 'Texto de ejemplo';

  @override
  String guildCommandMadeWith(String name) {
    return 'Hecho con /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Vacía el cuadro de mensaje para usar /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Esto no publicaría nada, así que el comando fallaría.';

  @override
  String get guildCommandUseScriptEditor => 'Usar el editor de scripts';

  @override
  String get guildCommandUseBasicEditor => 'Usar el editor básico';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Ejecutar de nuevo';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'No hay ninguna etiqueta llamada $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'No hay ningún filtro llamado $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name nunca se cierra.';
  }

  @override
  String get guildCommandIssueTooLong => 'El script es demasiado largo.';

  @override
  String get guildCommandIssueTooLarge => 'El script genera demasiado texto.';

  @override
  String get guildCommandIssueTooSlow =>
      'El script ha tardado demasiado en ejecutarse.';

  @override
  String get guildCommandIssueInvalid => 'Esta parte no se puede leer.';

  @override
  String get guildCommandIssueFailed =>
      'Esta parte se ha detenido con un error.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Línea $line, columna $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Referencia de scripts';

  @override
  String get guildCommandReferencePerson => 'Quien lo usa, como mención';

  @override
  String get guildCommandReferencePersonName => 'El nombre de quien lo usa';

  @override
  String get guildCommandReferenceTarget =>
      'La primera persona que mencionen, si hay alguna';

  @override
  String get guildCommandReferenceTargetName => 'El nombre de esa persona';

  @override
  String get guildCommandReferenceChannel => 'El canal, como mención';

  @override
  String get guildCommandReferenceCommunity => 'El nombre de esta comunidad';

  @override
  String get guildCommandExampleRandom => 'Elegir una opción al azar';

  @override
  String get guildCommandExampleDepends =>
      'Cambiar el mensaje según lo que hayan escrito';

  @override
  String get guildCommandExampleOneWord => 'Elegir una palabra al azar';

  @override
  String get guildCommandExampleWordForNumber =>
      'Elegir la palabra según un número';

  @override
  String get guildCommandExampleOrdinal =>
      'Escribir un número como 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Guía completa de scripts';

  @override
  String get guildCommandCounters => 'Contadores';

  @override
  String get guildCommandCounterAdd => 'Añadir contador';

  @override
  String get guildCommandCounterSeparately => 'Contar por separado para cada:';

  @override
  String get guildCommandCounterPersonMentioned => 'Persona mencionada';

  @override
  String get guildCommandCounterChannel => 'Canal';

  @override
  String get guildCommandCounterPersonas => 'Contar las personas por separado';

  @override
  String get guildCommandCounterRemove => 'Quitar contador';

  @override
  String get guildCommandCounterReset => 'Restablecer recuentos';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return '¿Restablecer los recuentos de $name? Esto no se puede deshacer.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Usa minúsculas, números y _, empieza por una letra y no uses un nombre que ya usen los scripts.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Úsalo en un script como $variable. Cada ejecución suma uno primero, así que la primera lee 1.';
  }
}

/// The translations for Spanish Castilian, as used in Latin America and the Caribbean (`es_419`).
class ForkLocalizationsEs419 extends ForkLocalizationsEs {
  ForkLocalizationsEs419() : super('es_419');

  @override
  String get chatMessageChangePersona => 'Cambiar persona';

  @override
  String get chatAttachmentPanelVoice => 'Voz';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Botón del selector rápido';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Reemplaza el botón de mensaje de voz por un botón de selector rápido para una navegación ágil';

  @override
  String get userSettingsCheckForUpdates => 'Buscar actualizaciones';

  @override
  String get userSettingsCheckingForUpdates => 'Buscando actualizaciones…';

  @override
  String get userSettingsAppUpToDate => 'Tyne está actualizado';

  @override
  String get userSettingsUpdateAvailableTitle => 'Actualización disponible';

  @override
  String get userSettingsUpdateDownloadAction => 'Descargar e instalar';

  @override
  String get userSettingsUpdateInstallAction => 'Instalar actualización';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Descargando actualización ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Error al buscar o descargar la actualización.';

  @override
  String get personaSelectTitle => 'Seleccionar persona';

  @override
  String get personaSettingsHeader => 'Configuración de personas';

  @override
  String get personaManageAction => 'Administrar';

  @override
  String get personaSearchPlaceholder =>
      'Buscar personas, etiquetas, pronombres...';

  @override
  String get personaModeManual => 'Manual';

  @override
  String get personaModeLast => 'Usada por última vez';

  @override
  String get personaModeManualDescription =>
      'Siempre envía como la persona seleccionada hasta que se cambie.';

  @override
  String get personaModeLastDescription =>
      'Cambia automáticamente a la persona utilizada en tu último mensaje.';

  @override
  String get personaRecentHeader => 'PERSONAS RECIENTES';

  @override
  String personaAllHeader(int count) {
    return 'TODAS LAS PERSONAS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'RESULTADOS DE BÚSQUEDA ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Cuenta principal (Por defecto)';

  @override
  String get personaEmptyState =>
      'Aún no hay ninguna persona configurada. Crea una desde Administrar personas.';

  @override
  String get personaEmptySearch => 'No se encontraron personas que coincidan.';

  @override
  String get personaEditTitle => 'Editar persona';

  @override
  String get personaCreateTitle => 'Crear persona';

  @override
  String get personaDisplayNameLabel => 'Nombre visible';

  @override
  String get personaPronounsLabel => 'Pronombres';

  @override
  String get personaPronounsHint => 'ej. ella/él';

  @override
  String get personaBioHint => 'Cuéntale a los demás sobre esta persona...';

  @override
  String get personaUpdatedToast => 'Persona actualizada';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Error al actualizar la persona: $error';
  }

  @override
  String get personaSectionTitle => 'Personas';

  @override
  String get personaDisplayNameHint => 'Nombre de la persona';

  @override
  String personaSendingAsTag(String name) {
    return 'Enviando como $name (Coincidencia por etiqueta)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Enviando como $name (Fijada)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Enviando como $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Publicando como $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Enviando como @$username';
  }

  @override
  String get personaMainAccount => 'Cuenta principal';

  @override
  String get personaEditPersona => 'Editar persona';

  @override
  String get userSettingsNavPersonas => 'Personas';

  @override
  String get personaSettingsDescription =>
      'Configura tu modo de persona activo, tu etiqueta de visualización personalizada y administra personas individuales.';

  @override
  String get personaDisplayTagSection => 'Etiqueta de visualización';

  @override
  String get personaDisplayTagDescription =>
      'La etiqueta de visualización aparecerá junto al nombre de todas las personas en los mensajes. Si no configuras ninguna, se mostrará la foto de perfil de tu cuenta.';

  @override
  String get personaDisplayTagLabel => 'Texto de la etiqueta de visualización';

  @override
  String get personaDisplayTagHint => 'ej. SYS';

  @override
  String get personaDisplayTagIconLabel =>
      'Ícono de la etiqueta de visualización';

  @override
  String get personaUploadTagIcon => 'Subir ícono';

  @override
  String get personaChangeTagIcon => 'Cambiar ícono';

  @override
  String get personaRemoveTagIcon => 'Quitar ícono';

  @override
  String get personaChatPreviewTitle => 'Vista previa del chat';

  @override
  String get personaChatPreviewSampleMessage =>
      '¡Hola! Esta es una vista previa de cómo se ven los mensajes con tu etiqueta de visualización y tu persona activa.';

  @override
  String get personaListTitle => 'Personas configuradas';

  @override
  String get personaAddButton => 'Agregar persona';

  @override
  String get personaActiveBadge => 'Activa';

  @override
  String get personaMakeActive => 'Activar';

  @override
  String get personaDeleteTitle => 'Eliminar persona';

  @override
  String personaDeleteMessage(String name) {
    return '¿Seguro que quieres eliminar \"$name\"? Esta acción no se puede deshacer.';
  }

  @override
  String get personaDeleteConfirm => 'Eliminar';

  @override
  String get personaDeletedToast => 'Persona eliminada';

  @override
  String get personaCreatedToast => 'Persona creada';

  @override
  String personaCreateFailedToast(String error) {
    return 'Error al crear la persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Cambiar avatar';

  @override
  String get personaRemoveAvatar => 'Eliminar avatar';

  @override
  String get personaUploadAvatar => 'Subir avatar';

  @override
  String get personaTagsLabel => 'Etiquetas de persona';

  @override
  String get personaAutoTagDisabledLabel =>
      'No reconocer las etiquetas de esta persona';

  @override
  String get personaAutoTagDisabledDescription =>
      'Escribir una de estas etiquetas no cambiará a esta persona. La etiqueta se envía tal como está escrita.';

  @override
  String get personaTagPrefixLabel => 'Prefijo';

  @override
  String get personaTagSuffixLabel => 'Sufijo';

  @override
  String get personaVisibilityLabel => 'Visibilidad';

  @override
  String get personaVisibilityUnlisted => 'No listada';

  @override
  String get personaVisibilityPublic => 'Pública';

  @override
  String get personaVisibilityPrivate => 'Privada';

  @override
  String get personaNameRequired =>
      'Ingresa un nombre para mostrar de la persona';

  @override
  String get personaNameTooLong =>
      'El nombre de la persona debe tener 100 caracteres o menos';

  @override
  String get personaTagPrefixTooLong =>
      'El prefijo de la etiqueta debe tener 32 caracteres o menos';

  @override
  String get personaTagSuffixTooLong =>
      'El sufijo de la etiqueta debe tener 32 caracteres o menos';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'La etiqueta \'$tag\' ya está en uso por \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Insertar marca de tiempo';

  @override
  String get chatAttachmentSendVoiceMessage => 'Enviar mensaje de voz';

  @override
  String get timestampPickerTitle => 'Insertar marca de tiempo';

  @override
  String get timestampPickerInsert => 'Insertar';

  @override
  String get timestampCopied => 'Marca de tiempo copiada';

  @override
  String get timestampPickerTimeLabel => 'Hora';

  @override
  String get timestampPickerDateLabel => 'FECHA';

  @override
  String get timestampPickerTimeSectionLabel => 'HORA';

  @override
  String get timestampPickerTimezoneLabel => 'ZONA HORARIA';

  @override
  String get timestampPickerFormatPreviewLabel => 'VISTA PREVIA DEL FORMATO';

  @override
  String get timestampPickerNlpPlaceholder =>
      'ej. mañana a las 3pm, en 2 horas, ahora';

  @override
  String get timestampPickerSearchTimezones => 'Buscar zonas horarias...';

  @override
  String get userProfileTimezoneSettingLabel => 'Zona horaria';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Se usa para mostrar tu hora local en tu perfil.';

  @override
  String get userProfileTimezoneNone => 'Ninguno';

  @override
  String get chatReactAs => 'Reaccionar como...';

  @override
  String get emojiCopy => 'Copiar emoji';

  @override
  String get emojiCopyLink => 'Copiar enlace';

  @override
  String get emojiPin => 'Fijar emoji';

  @override
  String get emojiUnpin => 'Desfijar emoji';

  @override
  String get emojiPinForPersona => 'Fijar para esta persona';

  @override
  String get emojiUnpinForPersona => 'Desfijar para esta persona';

  @override
  String get personaSignatureEmojisLabel => 'Emojis de firma';

  @override
  String get personaSignatureEmojisDescription =>
      'Reaccionar con un emoji de firma siempre reaccionará como esta persona, independientemente de la persona activa.';

  @override
  String get personaAddSignatureEmoji => 'Agregar emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Este emoji ya está agregado como emoji de firma';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'El emoji de firma ya está en uso por la persona \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Eliminar emoji de firma';

  @override
  String get signalBarLabel => 'Barra de señales';

  @override
  String get signalBarShow => 'Mostrar barra de señales';

  @override
  String get signalBarHide => 'Ocultar barra de señales';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Nadie tiene esta señal activada';

  @override
  String get signalBarReset => 'Restablecer señal para todos';

  @override
  String signalBarTurnOff(String name) {
    return 'Desactivar $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Usa $domain para la instancia predeterminada o la URL exacta de otra instancia.';
  }

  @override
  String get instanceResetToDefault =>
      'Restablecer a la instancia predeterminada';

  @override
  String get personaScopeTitle => 'La persona se aplica a';

  @override
  String get personaScopeGlobal => 'En todas partes';

  @override
  String get personaScopeGlobalDescription =>
      'Una persona para todos los canales.';

  @override
  String get personaScopeChannel => 'En cada canal';

  @override
  String get personaScopeChannelDescription =>
      'Cada canal conserva su propia persona. Los canales nuevos empiezan como tu cuenta.';

  @override
  String get personaPickerChannelOnly => 'Solo para este canal';

  @override
  String get personaProfilePrivate => 'El perfil de esta persona es privado.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'El archivo de imagen es demasiado grande. Por favor, elige un archivo inferior a $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Buscar KLIPY';

  @override
  String get appUpdateDownloadFailed => 'No se pudo descargar la actualización';

  @override
  String get appUpdateInstallFailed => 'No se pudo instalar la actualización';

  @override
  String get personaChangeMessageFailed =>
      'No se pudo cambiar la persona del mensaje';

  @override
  String get personaActiveCleared => 'Persona activa quitada';

  @override
  String get klipyPoweredBy => 'Con la tecnología de KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Par de etiquetas \'$pattern\' duplicado en esta persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Agregar par de etiquetas ($count/5)';
  }

  @override
  String get personaTagExampleText => 'texto';

  @override
  String get personaPreviewNameFallback => 'Usuario';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne se cerró inesperadamente. Compartir datos anónimos de fallas y errores nos ayuda a solucionar los problemas más rápido.';

  @override
  String get crashReportingSectionDescription =>
      'Ayuda a corregir errores en Tyne compartiendo datos de fallas y rendimiento. Está desactivado de manera predeterminada.';

  @override
  String get crashReportingDescription =>
      'Los informes se envían al sistema de seguimiento de errores propio de Tyne, incluso si iniciaste sesión en otro servidor. No incluyen nombres de servidores, identificadores ni el contenido de los mensajes.';

  @override
  String get instanceOfflineTitle => '¡Tyne está desconectado!';

  @override
  String get instanceOfflineBody => 'Lo estamos investigando.';

  @override
  String get instanceStatusSignalLink =>
      'Únete a nuestro chat de Signal para recibir novedades';

  @override
  String get convertEmoticonsLabel =>
      'Convertir los emoticonos de texto en emojis';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'No se pudo ejecutar /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'El script del comando tiene un problema.';

  @override
  String guildCommandOneLine(String name) {
    return 'Lo que escribas después de /$name debe caber en una línea.';
  }

  @override
  String get permissionCreateCommands => 'Crear comandos';

  @override
  String get permissionManageCommands => 'Administrar comandos';

  @override
  String get permissionUseExternalCommands => 'Usar comandos externos';

  @override
  String get permissionCreateCommandsDescription =>
      'Crear comandos para esta comunidad y editar o eliminar los tuyos.';

  @override
  String get permissionManageCommandsDescription =>
      'Editar o eliminar los comandos de cualquier persona en esta comunidad.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Usar comandos de otras comunidades.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Usar comandos de otras comunidades en este canal.';

  @override
  String get guildSettingsCategoryMessageTools => 'Herramientas de mensajes';

  @override
  String get guildSettingsCommands => 'Comandos';

  @override
  String get guildCommandsLoadFailed => 'No se pudieron cargar los comandos.';

  @override
  String get guildCommandsSubtitle =>
      'Mensajes que los miembros pueden publicar escribiendo /name.';

  @override
  String get guildCommandsSlots => 'Espacios para comandos';

  @override
  String get guildCommandsNew => 'Nuevo comando';

  @override
  String get guildCommandsSearch => 'Buscar comandos';

  @override
  String get guildCommandsEmptyTitle => 'No hay comandos';

  @override
  String get guildCommandsEmptyBody =>
      'Esta comunidad todavía no tiene comandos.';

  @override
  String get guildCommandsSaved => 'Comandos guardados';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'No se pudo guardar /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Editar /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return '¿Eliminar /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'No se puede deshacer. Los mensajes hechos con él siguen mostrando qué comando los hizo.';

  @override
  String get guildCommandDelete => 'Eliminar';

  @override
  String get guildCommandDeleteCommand => 'Eliminar comando';

  @override
  String get guildCommandSectionCommand => 'Comando';

  @override
  String get guildCommandName => 'Nombre';

  @override
  String get guildCommandNameInvalid =>
      'Usa minúsculas, números, - y _, hasta 32 caracteres.';

  @override
  String get guildCommandNameTaken =>
      'Otro comando o un comando integrado ya tiene este nombre.';

  @override
  String get guildCommandDescription => 'Descripción';

  @override
  String get guildCommandSectionInput => 'Entrada';

  @override
  String get guildCommandInputNone => 'Ninguno';

  @override
  String get guildCommandInputOptional => 'Opcional';

  @override
  String get guildCommandInputRequired => 'Obligatorio';

  @override
  String get guildCommandHint => 'Pista';

  @override
  String get guildCommandMessage => 'Mensaje';

  @override
  String get guildCommandInsert => 'Insertar:';

  @override
  String get guildCommandInsertPerson => 'Quien lo usa';

  @override
  String get guildCommandInsertInput => 'Lo que escriben';

  @override
  String get guildCommandPreview => 'Vista previa';

  @override
  String get guildCommandSampleInput => 'Texto de ejemplo';

  @override
  String guildCommandMadeWith(String name) {
    return 'Hecho con /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Vacía el cuadro de mensaje para usar /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Esto no publicaría nada, así que el comando fallaría.';

  @override
  String get guildCommandUseScriptEditor => 'Usar el editor de scripts';

  @override
  String get guildCommandUseBasicEditor => 'Usar el editor básico';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Ejecutar de nuevo';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'No hay ninguna etiqueta llamada $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'No hay ningún filtro llamado $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name nunca se cierra.';
  }

  @override
  String get guildCommandIssueTooLong => 'El script es demasiado largo.';

  @override
  String get guildCommandIssueTooLarge => 'El script genera demasiado texto.';

  @override
  String get guildCommandIssueTooSlow =>
      'El script tardó demasiado en ejecutarse.';

  @override
  String get guildCommandIssueInvalid => 'Esta parte no se puede leer.';

  @override
  String get guildCommandIssueFailed => 'Esta parte se detuvo con un error.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Línea $line, columna $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Referencia de scripts';

  @override
  String get guildCommandReferencePerson => 'Quien lo usa, como mención';

  @override
  String get guildCommandReferencePersonName => 'El nombre de quien lo usa';

  @override
  String get guildCommandReferenceTarget =>
      'La primera persona que mencionen, si hay alguna';

  @override
  String get guildCommandReferenceTargetName => 'El nombre de esa persona';

  @override
  String get guildCommandReferenceChannel => 'El canal, como mención';

  @override
  String get guildCommandReferenceCommunity => 'El nombre de esta comunidad';

  @override
  String get guildCommandExampleRandom => 'Elegir una opción al azar';

  @override
  String get guildCommandExampleDepends =>
      'Cambiar el mensaje según lo que hayan escrito';

  @override
  String get guildCommandExampleOneWord => 'Elegir una palabra al azar';

  @override
  String get guildCommandExampleWordForNumber =>
      'Elegir la palabra según un número';

  @override
  String get guildCommandExampleOrdinal =>
      'Escribir un número como 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Guía completa de scripts';

  @override
  String get guildCommandCounters => 'Contadores';

  @override
  String get guildCommandCounterAdd => 'Agregar contador';

  @override
  String get guildCommandCounterSeparately => 'Contar por separado para cada:';

  @override
  String get guildCommandCounterPersonMentioned => 'Persona mencionada';

  @override
  String get guildCommandCounterChannel => 'Canal';

  @override
  String get guildCommandCounterPersonas => 'Contar las personas por separado';

  @override
  String get guildCommandCounterRemove => 'Quitar contador';

  @override
  String get guildCommandCounterReset => 'Restablecer conteos';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return '¿Restablecer los conteos de $name? Esto no se puede deshacer.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Usa minúsculas, números y _, empieza con una letra y no uses un nombre que ya usen los scripts.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Úsalo en un script como $variable. Cada ejecución suma uno primero, así que la primera lee 1.';
  }
}
