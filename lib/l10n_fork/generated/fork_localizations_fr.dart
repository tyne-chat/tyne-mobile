// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class ForkLocalizationsFr extends ForkLocalizations {
  ForkLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Changer de persona';

  @override
  String get chatAttachmentPanelVoice => 'Voix';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Bouton du sélecteur rapide';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Remplacer le bouton de message vocal par un sélecteur rapide dans le champ de saisie pour une navigation rapide';

  @override
  String get userSettingsCheckForUpdates => 'Rechercher les mises à jour';

  @override
  String get userSettingsCheckingForUpdates => 'Recherche de mises à jour…';

  @override
  String get userSettingsAppUpToDate => 'Tyne est à jour';

  @override
  String get userSettingsUpdateAvailableTitle => 'Mise à jour disponible';

  @override
  String get userSettingsUpdateDownloadAction => 'Télécharger et installer';

  @override
  String get userSettingsUpdateInstallAction => 'Installer la mise à jour';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Téléchargement de la mise à jour ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Échec de la recherche ou du téléchargement de la mise à jour.';

  @override
  String get personaSelectTitle => 'Sélectionner un persona';

  @override
  String get personaSettingsHeader => 'Paramètres des personas';

  @override
  String get personaManageAction => 'Gérer';

  @override
  String get personaSearchPlaceholder =>
      'Rechercher des personas, balises, pronoms…';

  @override
  String get personaModeManual => 'Manuel';

  @override
  String get personaModeLast => 'Dernier utilisé';

  @override
  String get personaModeManualDescription =>
      'Envoie toujours en tant que ce persona jusqu\'à modification.';

  @override
  String get personaModeLastDescription =>
      'Bascule automatiquement sur le persona utilisé dans votre dernier message.';

  @override
  String get personaRecentHeader => 'PERSONAS RÉCENTS';

  @override
  String personaAllHeader(int count) {
    return 'TOUS LES PERSONAS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'RÉSULTATS DE RECHERCHE ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Compte principal (par défaut)';

  @override
  String get personaEmptyState =>
      'Aucun persona configuré pour l\'instant. Créez-en un dans Gérer les personas.';

  @override
  String get personaEmptySearch => 'Aucun persona correspondant trouvé.';

  @override
  String get personaEditTitle => 'Modifier le persona';

  @override
  String get personaCreateTitle => 'Créer un persona';

  @override
  String get personaDisplayNameLabel => 'Nom affiché';

  @override
  String get personaPronounsLabel => 'Pronoms';

  @override
  String get personaPronounsHint => 'ex. iel/elle/il';

  @override
  String get personaBioHint => 'Présentez ce persona aux autres…';

  @override
  String get personaUpdatedToast => 'Persona mis à jour';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Échec de la mise à jour du persona : $error';
  }

  @override
  String get personaSectionTitle => 'Personas';

  @override
  String get personaDisplayNameHint => 'Nom du persona';

  @override
  String personaSendingAsTag(String name) {
    return 'Envoi en tant que $name (Associé par balise)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Envoi en tant que $name (Verrouillé)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Envoi en tant que $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Publication en tant que $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Envoi en tant que @$username';
  }

  @override
  String get personaMainAccount => 'Compte principal';

  @override
  String get personaEditPersona => 'Modifier le persona';

  @override
  String get userSettingsNavPersonas => 'Personas';

  @override
  String get personaSettingsDescription =>
      'Configurez votre mode de persona actif, votre badge d\'affichage personnalisé et gérez vos personas.';

  @override
  String get personaDisplayTagSection => 'Badge d\'affichage';

  @override
  String get personaDisplayTagDescription =>
      'Le badge d\'affichage apparaîtra à côté du nom de toutes vos personas dans les messages. Si aucun badge n\'est configuré, votre photo de profil de compte sera affichée.';

  @override
  String get personaDisplayTagLabel => 'Texte du badge';

  @override
  String get personaDisplayTagHint => 'ex. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Icône du badge';

  @override
  String get personaUploadTagIcon => 'Importer une icône';

  @override
  String get personaChangeTagIcon => 'Modifier l\'icône';

  @override
  String get personaRemoveTagIcon => 'Supprimer l\'icône';

  @override
  String get personaChatPreviewTitle => 'Aperçu du chat';

  @override
  String get personaChatPreviewSampleMessage =>
      'Bonjour ! Ceci est un aperçu de l\'affichage des messages avec votre badge d\'affichage et votre persona actif.';

  @override
  String get personaListTitle => 'Personas configurés';

  @override
  String get personaAddButton => 'Ajouter un persona';

  @override
  String get personaActiveBadge => 'Actif';

  @override
  String get personaMakeActive => 'Définir comme actif';

  @override
  String get personaDeleteTitle => 'Supprimer le persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Voulez-vous vraiment supprimer « $name » ? Cette action est irréversible.';
  }

  @override
  String get personaDeleteConfirm => 'Supprimer';

  @override
  String get personaDeletedToast => 'Persona supprimé';

  @override
  String get personaCreatedToast => 'Persona créé';

  @override
  String personaCreateFailedToast(String error) {
    return 'Échec de la création du persona : $error';
  }

  @override
  String get personaChangeAvatar => 'Modifier l\'avatar';

  @override
  String get personaRemoveAvatar => 'Supprimer l\'avatar';

  @override
  String get personaUploadAvatar => 'Importer un avatar';

  @override
  String get personaTagsLabel => 'Balises de persona';

  @override
  String get personaTagPrefixLabel => 'Préfixe';

  @override
  String get personaTagSuffixLabel => 'Suffixe';

  @override
  String get personaVisibilityLabel => 'Visibilité';

  @override
  String get personaVisibilityUnlisted => 'Non répertorié';

  @override
  String get personaVisibilityPublic => 'Public';

  @override
  String get personaVisibilityPrivate => 'Privé';

  @override
  String get personaNameRequired =>
      'Veuillez saisir un nom d\'affichage de persona';

  @override
  String get personaNameTooLong =>
      'Le nom d\'affichage du persona doit comporter 100 caractères ou moins';

  @override
  String get personaTagPrefixTooLong =>
      'Le préfixe de balise de persona doit comporter 32 caractères ou moins';

  @override
  String get personaTagSuffixTooLong =>
      'Le suffixe de balise de persona doit comporter 32 caractères ou moins';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'La balise « $tag » est déjà utilisée par « $name ».';
  }

  @override
  String get chatInsertTimestamp => 'Insérer un horodatage';

  @override
  String get chatAttachmentSendVoiceMessage => 'Envoyer un message vocal';

  @override
  String get timestampPickerTitle => 'Insérer un horodatage';

  @override
  String get timestampPickerInsert => 'Insérer';

  @override
  String get timestampCopied => 'Horodatage copié';

  @override
  String get timestampPickerTimeLabel => 'Heure';

  @override
  String get timestampPickerDateLabel => 'DATE';

  @override
  String get timestampPickerTimeSectionLabel => 'HEURE';

  @override
  String get timestampPickerTimezoneLabel => 'FUSEAU HORAIRE';

  @override
  String get timestampPickerFormatPreviewLabel => 'APERÇU DU FORMAT';

  @override
  String get timestampPickerNlpPlaceholder =>
      'ex. demain à 15h, dans 2 heures, maintenant';

  @override
  String get timestampPickerSearchTimezones =>
      'Rechercher des fuseaux horaires...';

  @override
  String get userProfileTimezoneSettingLabel => 'Fuseau horaire';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Utilisé pour afficher votre heure locale sur votre profil.';

  @override
  String get userProfileTimezoneNone => 'Aucun';

  @override
  String get chatReactAs => 'Réagir en tant que...';

  @override
  String get emojiCopy => 'Copier l\'emoji';

  @override
  String get emojiCopyLink => 'Copier le lien';

  @override
  String get emojiPin => 'Épingler l\'émoji';

  @override
  String get emojiUnpin => 'Désépingler l\'émoji';

  @override
  String get emojiPinForPersona => 'Épingler pour cette persona';

  @override
  String get emojiUnpinForPersona => 'Désépingler pour cette persona';

  @override
  String get personaSignatureEmojisLabel => 'Emojis signature';

  @override
  String get personaSignatureEmojisDescription =>
      'Réagir avec un emoji signature réagira toujours sous cette persona, quelle que soit la persona active.';

  @override
  String get personaAddSignatureEmoji => 'Ajouter un emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Cet emoji est déjà ajouté comme emoji signature';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'L\'emoji signature est déjà utilisé par la persona « $name »';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Supprimer l\'emoji signature';

  @override
  String get signalBarLabel => 'Barre de signaux';

  @override
  String get signalBarShow => 'Afficher la barre de signaux';

  @override
  String get signalBarHide => 'Masquer la barre de signaux';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label : $names';
  }

  @override
  String get signalBarNobody => 'Personne n’a activé ce signal';

  @override
  String get signalBarReset => 'Réinitialiser le signal pour tout le monde';

  @override
  String signalBarTurnOff(String name) {
    return 'Désactiver $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Utilisez $domain pour l’instance par défaut, ou l’URL exacte d’une autre instance.';
  }

  @override
  String get instanceResetToDefault => 'Réinitialiser à l’instance par défaut';

  @override
  String get personaScopeTitle => 'Le persona s’applique à';

  @override
  String get personaScopeGlobal => 'Partout';

  @override
  String get personaScopeGlobalDescription =>
      'Un seul persona pour tous les salons.';

  @override
  String get personaScopeChannel => 'Dans chaque salon';

  @override
  String get personaScopeChannelDescription =>
      'Chaque salon conserve son propre persona. Les nouveaux salons commencent avec votre compte.';

  @override
  String get personaPickerChannelOnly => 'Uniquement pour ce salon';

  @override
  String get personaProfilePrivate => 'Le profil de cette persona est privé.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Le fichier image est trop volumineux. Veuillez choisir un fichier de moins de $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Rechercher sur KLIPY';

  @override
  String get appUpdateDownloadFailed =>
      'Impossible de télécharger la mise à jour';

  @override
  String get appUpdateInstallFailed => 'Impossible d\'installer la mise à jour';

  @override
  String get personaChangeMessageFailed =>
      'Impossible de changer la persona du message';

  @override
  String get personaActiveCleared => 'Persona active retirée';

  @override
  String get klipyPoweredBy => 'Fourni par KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Paire de balises « $pattern » déjà présente sur cette persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Ajouter une paire de balises ($count/5)';
  }

  @override
  String get personaTagExampleText => 'texte';

  @override
  String get personaPreviewNameFallback => 'Utilisateur';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne s\'est fermé de manière inattendue. Partager des données anonymes de plantage et d\'erreur nous aide à corriger les problèmes plus rapidement.';

  @override
  String get crashReportingSectionDescription =>
      'Aidez à corriger les bugs de Tyne en partageant des données de plantage et de performances. Désactivé par défaut.';

  @override
  String get crashReportingDescription =>
      'Les rapports sont envoyés à l\'outil de suivi des erreurs de Tyne lui-même, même lorsque vous êtes connecté à une autre instance. Ils n\'incluent ni noms d\'instance, ni identifiants, ni contenu de message.';

  @override
  String get instanceOfflineTitle => 'Tyne est hors ligne !';

  @override
  String get instanceOfflineBody => 'Nous examinons le problème.';

  @override
  String get instanceStatusSignalLink =>
      'Rejoignez notre discussion Signal pour suivre les nouvelles';

  @override
  String get convertEmoticonsLabel =>
      'Activer la conversion des émoticônes en emojis';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Impossible d\'exécuter /$name : $detail';
  }

  @override
  String get guildCommandBroken => 'Son script a un problème.';

  @override
  String guildCommandOneLine(String name) {
    return 'Ce que vous tapez après /$name doit tenir sur une ligne.';
  }

  @override
  String get permissionCreateCommands => 'Créer des commandes';

  @override
  String get permissionManageCommands => 'Gérer les commandes';

  @override
  String get permissionUseExternalCommands => 'Utiliser des commandes externes';

  @override
  String get permissionCreateCommandsDescription =>
      'Créer des commandes pour cette communauté, et modifier ou supprimer les vôtres.';

  @override
  String get permissionManageCommandsDescription =>
      'Modifier ou supprimer les commandes de n\'importe qui dans cette communauté.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Utiliser les commandes d\'autres communautés.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Utiliser les commandes d\'autres communautés dans ce salon.';

  @override
  String get guildSettingsCategoryMessageTools => 'Outils de message';

  @override
  String get guildSettingsCommands => 'Commandes';

  @override
  String get guildCommandsLoadFailed => 'Impossible de charger les commandes.';

  @override
  String get guildCommandsSubtitle =>
      'Des messages que les membres peuvent publier en tapant /name.';

  @override
  String get guildCommandsSlots => 'Emplacements de commandes';

  @override
  String get guildCommandsNew => 'Nouvelle commande';

  @override
  String get guildCommandsSearch => 'Rechercher des commandes';

  @override
  String get guildCommandsEmptyTitle => 'Aucune commande';

  @override
  String get guildCommandsEmptyBody =>
      'Cette communauté n\'a encore aucune commande.';

  @override
  String get guildCommandsSaved => 'Commandes enregistrées';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Impossible d\'enregistrer /$name : $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Modifier /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Supprimer /$name ?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Cette action est irréversible. Les messages créés avec elle indiquent toujours la commande qui les a créés.';

  @override
  String get guildCommandDelete => 'Supprimer';

  @override
  String get guildCommandDeleteCommand => 'Supprimer la commande';

  @override
  String get guildCommandSectionCommand => 'Commande';

  @override
  String get guildCommandName => 'Nom';

  @override
  String get guildCommandNameInvalid =>
      'Utilisez des minuscules, des chiffres, - et _, 32 caractères au maximum.';

  @override
  String get guildCommandNameTaken =>
      'Une autre commande ou une commande intégrée porte déjà ce nom.';

  @override
  String get guildCommandDescription => 'Description';

  @override
  String get guildCommandSectionInput => 'Entrée';

  @override
  String get guildCommandInputNone => 'Aucun';

  @override
  String get guildCommandInputOptional => 'Facultative';

  @override
  String get guildCommandInputRequired => 'Obligatoire';

  @override
  String get guildCommandHint => 'Indice';

  @override
  String get guildCommandMessage => 'Message';

  @override
  String get guildCommandInsert => 'Insérer :';

  @override
  String get guildCommandInsertPerson => 'Personne qui l\'utilise';

  @override
  String get guildCommandInsertInput => 'Ce qu\'on tape';

  @override
  String get guildCommandPreview => 'Prévisualiser';

  @override
  String get guildCommandSampleInput => 'Exemple de saisie';

  @override
  String guildCommandMadeWith(String name) {
    return 'Créé avec /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Videz la zone de message pour utiliser /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Cela ne publierait rien, donc la commande échouerait.';

  @override
  String get guildCommandUseScriptEditor => 'Utiliser l\'éditeur de script';

  @override
  String get guildCommandUseBasicEditor => 'Utiliser l\'éditeur de base';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Exécuter à nouveau';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Il n\'existe aucune balise nommée $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Il n\'existe aucun filtre nommé $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name n\'est jamais fermé.';
  }

  @override
  String get guildCommandIssueTooLong => 'Le script est trop long.';

  @override
  String get guildCommandIssueTooLarge => 'Le script génère trop de texte.';

  @override
  String get guildCommandIssueTooSlow =>
      'Le script a mis trop de temps à s\'exécuter.';

  @override
  String get guildCommandIssueInvalid => 'Impossible de lire cette partie.';

  @override
  String get guildCommandIssueFailed =>
      'Cette partie s\'est arrêtée sur une erreur.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Ligne $line, colonne $column : $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Référence des scripts';

  @override
  String get guildCommandReferencePerson =>
      'La personne qui l\'utilise, sous forme de mention';

  @override
  String get guildCommandReferencePersonName =>
      'Le nom de la personne qui l\'utilise';

  @override
  String get guildCommandReferenceTarget =>
      'La première personne mentionnée, s\'il y en a une';

  @override
  String get guildCommandReferenceTargetName => 'Le nom de cette personne';

  @override
  String get guildCommandReferenceChannel => 'Le salon, sous forme de mention';

  @override
  String get guildCommandReferenceCommunity => 'Le nom de cette communauté';

  @override
  String get guildCommandExampleRandom => 'Choisir une option au hasard';

  @override
  String get guildCommandExampleDepends =>
      'Changer le message selon ce qui a été tapé';

  @override
  String get guildCommandExampleOneWord => 'Choisir un mot au hasard';

  @override
  String get guildCommandExampleWordForNumber =>
      'Choisir le mot selon un nombre';

  @override
  String get guildCommandExampleOrdinal =>
      'Écrire un nombre sous la forme 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Guide complet des scripts';

  @override
  String get guildCommandCounters => 'Compteurs';

  @override
  String get guildCommandCounterAdd => 'Ajouter un compteur';

  @override
  String get guildCommandCounterSeparately =>
      'Compter séparément pour chaque :';

  @override
  String get guildCommandCounterPersonMentioned => 'Personne mentionnée';

  @override
  String get guildCommandCounterChannel => 'Salon';

  @override
  String get guildCommandCounterPersonas => 'Compter les personas séparément';

  @override
  String get guildCommandCounterRemove => 'Retirer le compteur';

  @override
  String get guildCommandCounterReset => 'Réinitialiser les comptes';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Réinitialiser les comptes de $name ? Cette action est irréversible.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Utilise des minuscules, des chiffres et _, commence par une lettre et évite les noms déjà utilisés par les scripts.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Utilise-le dans un script sous la forme $variable. Chaque exécution ajoute d’abord un, donc la première lit 1.';
  }
}
