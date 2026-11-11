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
  String get personaSendHeldNotLoaded =>
      'Non envoyé : vos personas ne sont pas encore chargés.';

  @override
  String personaSendHeldAskAccount(String username) {
    return 'Non envoyé : vos personas ne sont pas encore chargés. L\'envoyer en tant que @$username ?';
  }

  @override
  String get personaSendAsAccountAction => 'Envoyer quand même';

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
  String get personaAutoTagDisabledLabel =>
      'Ne pas reconnaître les balises de cette persona';

  @override
  String get personaAutoTagDisabledDescription =>
      'Saisir l\'une de ces balises ne basculera pas sur cette persona. La balise est envoyée telle quelle.';

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

  @override
  String get notificationsAlertEveryMessageLabel =>
      'Alerter pour chaque message';

  @override
  String get notificationsAlertEveryMessageDescription =>
      'Si désactivé, une conversation animée vous alerte une seule fois, puis se met à jour en silence jusqu’à ce que vous la lisiez ou la fermiez.';

  @override
  String personaGalleryTitle(int count) {
    return 'Personas ($count)';
  }

  @override
  String personaGallerySearchOther(String name) {
    return 'Rechercher dans les personas de $name';
  }

  @override
  String get personaGallerySearchOwn => 'Rechercher dans vos personas';

  @override
  String get personaGallerySortBy => 'Trier par';

  @override
  String get personaGallerySortName => 'Nom (A–Z)';

  @override
  String get personaGallerySortMostUsed => 'Les plus utilisées';

  @override
  String get personaGallerySortRecentlyUsed => 'Utilisées récemment';

  @override
  String get personaGalleryViewGallery => 'Galerie';

  @override
  String get personaGalleryViewList => 'Liste';

  @override
  String get personaGalleryViewAvatars => 'Avatars';

  @override
  String personaGalleryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '$count persona',
    );
    return '$_temp0';
  }

  @override
  String personaGalleryCountFiltered(int shown, int total) {
    return '$shown sur $total personas';
  }

  @override
  String get personaGalleryNoMatch =>
      'Aucune persona ne correspond à votre recherche.';

  @override
  String get personaGalleryLoadFailed => 'Impossible de charger les personas.';

  @override
  String personaGalleryOthersSee(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas publiques',
      one: '$count persona publique',
    );
    return 'Les autres voient $_temp0.';
  }

  @override
  String get personaGalleryShowHidden =>
      'Afficher les non répertoriées et les privées';

  @override
  String get personaGalleryManage => 'Gérer les personas';

  @override
  String get personaGalleryNonePublic =>
      'Aucune de vos personas n’est encore publique. Les autres voient une persona ici dès que vous réglez sa visibilité sur Public.';

  @override
  String get personaGalleryNoBio => 'Pas encore de bio.';

  @override
  String personaGalleryCreated(String date) {
    return 'Créée le $date';
  }

  @override
  String get personaBulkSelect => 'Sélectionner';

  @override
  String get personaBulkSelectAll => 'Tout sélectionner';

  @override
  String personaBulkSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnées',
      one: '$count sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get personaFilterAll => 'Tous';

  @override
  String get personaBulkMakePublic => 'Rendre publiques';

  @override
  String get personaBulkMakeUnlisted => 'Rendre non répertoriées';

  @override
  String get personaBulkMakePrivate => 'Rendre privées';

  @override
  String personaBulkConfirmPublicTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas publiques',
      one: '$count persona publique',
    );
    return 'Rendre $_temp0 ?';
  }

  @override
  String personaBulkConfirmPrivateTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas privées',
      one: '$count persona privée',
    );
    return 'Rendre $_temp0 ?';
  }

  @override
  String personaBulkConfirmDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '$count persona',
    );
    return 'Supprimer $_temp0 ?';
  }

  @override
  String get personaBulkConfirmPublicBody =>
      'Les autres les verront dans votre liste de personas et pourront ouvrir leurs profils. Vous pouvez revenir en arrière à tout moment.';

  @override
  String get personaBulkConfirmPrivateBody =>
      'Leurs profils seront masqués aux autres. Leurs noms et avatars resteront visibles sur leurs messages et réactions.';

  @override
  String get personaBulkConfirmDeleteBody =>
      'Leurs messages continueront d’afficher leurs noms et avatars, mais vous ne pourrez plus écrire en leur nom, et leurs badges et emojis signature seront libérés. Cette action est irréversible.';

  @override
  String personaBulkNowPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas sont maintenant publiques',
      one: '$count persona est maintenant publique',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowUnlisted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas sont maintenant non répertoriées',
      one: '$count persona est maintenant non répertoriée',
    );
    return '$_temp0';
  }

  @override
  String personaBulkNowPrivate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas sont maintenant privées',
      one: '$count persona est maintenant privée',
    );
    return '$_temp0';
  }

  @override
  String personaBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas supprimées',
      one: '$count persona supprimée',
    );
    return '$_temp0';
  }

  @override
  String get personaBulkFailed =>
      'Impossible de modifier les personas. Réessayez.';

  @override
  String get personaFilterEmpty => 'Aucune persona ici.';

  @override
  String get personaGalleryChooseFeatured =>
      'Choisir les personas à mettre en avant';

  @override
  String get personaUndo => 'Annuler';

  @override
  String get personaReactionsTitle => 'Vos réactions';

  @override
  String get personaReactionsEveryoneElse => 'TOUS LES AUTRES';

  @override
  String get personaReactionsCurrent => 'ACTUEL';

  @override
  String get personaReactionsAccount => 'Compte';

  @override
  String get personaReactionsSomeoneElse =>
      'Réagir en tant que quelqu\'un d\'autre...';

  @override
  String get personaReactionsDone => 'Terminé';

  @override
  String get personaSettingsReactionsHeader => 'Réactions';

  @override
  String get personaSettingsMultiReactions =>
      'Réagir en tant que plusieurs personas à la fois';

  @override
  String get personaDuplicateButton => 'Dupliquer le persona';

  @override
  String personaCopyOf(String name) {
    return 'Copie de $name';
  }

  @override
  String signalsEverywhereTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count discussions',
      one: '$count discussion',
    );
    return 'Tes signaux partout · $_temp0';
  }

  @override
  String signalsEverywhereHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count discussions',
      one: '$count discussion',
    );
    return 'Activer partout ($_temp0)';
  }

  @override
  String signalsEverywhereSet(String label) {
    return 'Activer $label partout';
  }

  @override
  String get signalsEverywhereTurnAllOff => 'Tout désactiver';

  @override
  String get signalsEverywhereRestore => 'Restaurer…';

  @override
  String get signalsEverywhereNone =>
      'Aucun de tes signaux n’est activé nulle part.';

  @override
  String get signalsRestoreTitle => 'Restaurer tes signaux ?';

  @override
  String signalsRestoreBeforeSet(String label, String time) {
    return 'Rétablit ce que tu avais activé avant d’activer $label partout ($time). Ce que tu y as activé maintenant sera désactivé.';
  }

  @override
  String signalsRestoreBeforeOff(String time) {
    return 'Rétablit ce que tu avais activé avant de tout désactiver ($time). Ce que tu y as activé maintenant sera désactivé.';
  }

  @override
  String signalsRestoreBeforeRestore(String time) {
    return 'Rétablit ce que tu avais activé avant ta dernière restauration ($time). Ce que tu y as activé maintenant sera désactivé.';
  }

  @override
  String get signalsRestoreNow => 'Maintenant';

  @override
  String get signalsRestoreAfter => 'Après';

  @override
  String signalsRestoreMoreChats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count autres discussions',
      one: '+ $count autre discussion',
    );
    return '$_temp0';
  }

  @override
  String signalsRestoreLeftOut(String chats) {
    return 'Laissées de côté, car tu ne peux plus y écrire : $chats';
  }

  @override
  String get signalsRestoreConfirm => 'Restaurer';

  @override
  String get signalsRestoreUnavailable =>
      'Impossible de charger ce que « Restaurer » changerait. Réessaie.';

  @override
  String get signalsRestoreNothing => 'Il n’y a rien à restaurer.';

  @override
  String get signalsProfileMenu => 'Signaux';
}
