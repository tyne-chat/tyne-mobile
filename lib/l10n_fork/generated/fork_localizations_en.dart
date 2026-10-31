// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ForkLocalizationsEn extends ForkLocalizations {
  ForkLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Change Persona';

  @override
  String get chatAttachmentPanelVoice => 'Voice';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'Quick Switcher button';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Replace the voice message button in the message input with a Quick Switcher button for fast navigation';

  @override
  String get userSettingsCheckForUpdates => 'Check for updates';

  @override
  String get userSettingsCheckingForUpdates => 'Checking for updates…';

  @override
  String get userSettingsAppUpToDate => 'Tyne is up to date';

  @override
  String get userSettingsUpdateAvailableTitle => 'Update Available';

  @override
  String get userSettingsUpdateDownloadAction => 'Download & Install';

  @override
  String get userSettingsUpdateInstallAction => 'Install Update';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Downloading update ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed => 'Failed to check or download update.';

  @override
  String get personaSelectTitle => 'Select Persona';

  @override
  String get personaSettingsHeader => 'Persona Settings';

  @override
  String get personaManageAction => 'Manage';

  @override
  String get personaSearchPlaceholder => 'Search personas, tags, pronouns...';

  @override
  String get personaModeManual => 'Manual';

  @override
  String get personaModeLast => 'Last Used';

  @override
  String get personaModeManualDescription =>
      'Always sends as selected persona until changed.';

  @override
  String get personaModeLastDescription =>
      'Auto-switches to the persona used in your last message.';

  @override
  String get personaRecentHeader => 'RECENT PERSONAS';

  @override
  String personaAllHeader(int count) {
    return 'ALL PERSONAS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'SEARCH RESULTS ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Root Account (Default)';

  @override
  String get personaEmptyState =>
      'No personas configured yet. Create one via Manage Personas.';

  @override
  String get personaEmptySearch => 'No matching personas found.';

  @override
  String get personaEditTitle => 'Edit Persona';

  @override
  String get personaCreateTitle => 'Create Persona';

  @override
  String get personaDisplayNameLabel => 'Display Name';

  @override
  String get personaPronounsLabel => 'Pronouns';

  @override
  String get personaPronounsHint => 'e.g. they/them';

  @override
  String get personaBioHint => 'Tell others about this persona...';

  @override
  String get personaUpdatedToast => 'Persona updated';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Failed to update persona: $error';
  }

  @override
  String get personaSectionTitle => 'Personas';

  @override
  String get personaDisplayNameHint => 'Persona name';

  @override
  String personaSendingAsTag(String name) {
    return 'Sending as $name (Matched by tag)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Sending as $name (Latched)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Sending as $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Posting as $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Sending as @$username';
  }

  @override
  String get personaMainAccount => 'Main account';

  @override
  String get personaEditPersona => 'Edit persona';

  @override
  String get userSettingsNavPersonas => 'Personas';

  @override
  String get personaSettingsDescription =>
      'Configure your active persona mode, custom display tag, and manage individual personas.';

  @override
  String get personaDisplayTagSection => 'Display Tag';

  @override
  String get personaDisplayTagDescription =>
      'Display tag will appear next to all persona names in messages. If no display tag is set, your account profile picture will be shown.';

  @override
  String get personaDisplayTagLabel => 'Display Tag Text';

  @override
  String get personaDisplayTagHint => 'e.g. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Display Tag Icon';

  @override
  String get personaUploadTagIcon => 'Upload Icon';

  @override
  String get personaChangeTagIcon => 'Change Icon';

  @override
  String get personaRemoveTagIcon => 'Remove Icon';

  @override
  String get personaChatPreviewTitle => 'Chat Preview';

  @override
  String get personaChatPreviewSampleMessage =>
      'Hello! This is a preview of how messages look with your display tag and active persona.';

  @override
  String get personaListTitle => 'Configured Personas';

  @override
  String get personaAddButton => 'Add Persona';

  @override
  String get personaActiveBadge => 'Active';

  @override
  String get personaMakeActive => 'Set Active';

  @override
  String get personaDeleteTitle => 'Delete Persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Are you sure you want to delete \"$name\"? This cannot be undone.';
  }

  @override
  String get personaDeleteConfirm => 'Delete';

  @override
  String get personaDeletedToast => 'Persona deleted';

  @override
  String get personaCreatedToast => 'Persona created';

  @override
  String personaCreateFailedToast(String error) {
    return 'Failed to create persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Change Avatar';

  @override
  String get personaRemoveAvatar => 'Remove Avatar';

  @override
  String get personaUploadAvatar => 'Upload Avatar';

  @override
  String get personaTagsLabel => 'Persona Tags';

  @override
  String get personaTagPrefixLabel => 'Prefix';

  @override
  String get personaTagSuffixLabel => 'Suffix';

  @override
  String get personaVisibilityLabel => 'Visibility';

  @override
  String get personaVisibilityUnlisted => 'Unlisted';

  @override
  String get personaVisibilityPublic => 'Public';

  @override
  String get personaVisibilityPrivate => 'Private';

  @override
  String get personaNameRequired => 'Please enter a persona display name';

  @override
  String get personaNameTooLong =>
      'Persona display name must be 100 characters or less';

  @override
  String get personaTagPrefixTooLong =>
      'Persona tag prefix must be 32 characters or less';

  @override
  String get personaTagSuffixTooLong =>
      'Persona tag suffix must be 32 characters or less';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'The tag \'$tag\' is already in use by \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Insert timestamp';

  @override
  String get chatAttachmentSendVoiceMessage => 'Send voice message';

  @override
  String get timestampPickerTitle => 'Insert Timestamp';

  @override
  String get timestampPickerInsert => 'Insert';

  @override
  String get timestampCopied => 'Timestamp copied';

  @override
  String get timestampPickerTimeLabel => 'Time';

  @override
  String get timestampPickerDateLabel => 'DATE';

  @override
  String get timestampPickerTimeSectionLabel => 'TIME';

  @override
  String get timestampPickerTimezoneLabel => 'TIME ZONE';

  @override
  String get timestampPickerFormatPreviewLabel => 'FORMAT PREVIEW';

  @override
  String get timestampPickerNlpPlaceholder =>
      'e.g. tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'Search time zones...';

  @override
  String get userProfileTimezoneSettingLabel => 'Time zone';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Used to show your local time on your profile.';

  @override
  String get userProfileTimezoneNone => 'None';

  @override
  String get chatReactAs => 'React as...';

  @override
  String get emojiCopy => 'Copy emoji';

  @override
  String get emojiCopyLink => 'Copy link';

  @override
  String get emojiPin => 'Pin emoji';

  @override
  String get emojiUnpin => 'Unpin emoji';

  @override
  String get emojiPinForPersona => 'Pin for this persona';

  @override
  String get emojiUnpinForPersona => 'Unpin for this persona';

  @override
  String get personaSignatureEmojisLabel => 'Signature Emojis';

  @override
  String get personaSignatureEmojisDescription =>
      'Reacting with a signature emoji will always react as this persona, regardless of active persona.';

  @override
  String get personaAddSignatureEmoji => 'Add Emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'This emoji is already added as a signature emoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Signature emoji already in use by persona \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Remove signature emoji';

  @override
  String get signalBarLabel => 'Signal bar';

  @override
  String get signalBarShow => 'Show signal bar';

  @override
  String get signalBarHide => 'Hide signal bar';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Nobody has this signal on';

  @override
  String get signalBarReset => 'Reset signal for everyone';

  @override
  String signalBarTurnOff(String name) {
    return 'Turn off $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Use $domain for the default instance, or the exact URL of another instance.';
  }

  @override
  String get instanceResetToDefault => 'Reset to default instance';

  @override
  String get personaScopeTitle => 'Persona applies to';

  @override
  String get personaScopeGlobal => 'Everywhere';

  @override
  String get personaScopeGlobalDescription => 'One persona for all channels.';

  @override
  String get personaScopeChannel => 'In each channel';

  @override
  String get personaScopeChannelDescription =>
      'Each channel keeps its own persona. New channels start as your account.';

  @override
  String get personaPickerChannelOnly => 'Only for this channel';

  @override
  String get personaProfilePrivate => 'This persona’s profile is private.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Image file is too large. Please choose a file smaller than $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Search KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Failed to download update';

  @override
  String get appUpdateInstallFailed => 'Failed to install update';

  @override
  String get personaChangeMessageFailed => 'Failed to change message persona';

  @override
  String get personaActiveCleared => 'Active persona cleared';

  @override
  String get klipyPoweredBy => 'Powered by KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Duplicate tag pair \'$pattern\' on this persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Add Tag Pair ($count/5)';
  }

  @override
  String get personaTagExampleText => 'text';

  @override
  String get personaPreviewNameFallback => 'User';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne closed unexpectedly. Sharing anonymous crash and error data helps us fix issues faster.';

  @override
  String get crashReportingSectionDescription =>
      'Help fix bugs in Tyne by sharing crash and performance data. This is off by default.';

  @override
  String get crashReportingDescription =>
      'Reports go to Tyne\'s own error tracker, even when you\'re signed in to another instance. They don\'t include instance names, IDs or message content.';

  @override
  String get instanceOfflineTitle => 'Tyne is offline!';

  @override
  String get instanceOfflineBody => 'We\'re investigating.';

  @override
  String get instanceStatusSignalLink => 'Join our Signal chat for updates';

  @override
  String get convertEmoticonsLabel => 'Turn text smileys into emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Couldn\'t run /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Its script has a problem.';

  @override
  String guildCommandOneLine(String name) {
    return 'What you type after /$name has to fit on one line.';
  }

  @override
  String get permissionCreateCommands => 'Create commands';

  @override
  String get permissionManageCommands => 'Manage commands';

  @override
  String get permissionUseExternalCommands => 'Use external commands';

  @override
  String get permissionCreateCommandsDescription =>
      'Create commands for this community, and edit or delete your own.';

  @override
  String get permissionManageCommandsDescription =>
      'Edit or delete anyone\'s commands in this community.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Use commands from other communities.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Use commands from other communities in this channel.';

  @override
  String get guildSettingsCategoryMessageTools => 'Message Tools';

  @override
  String get guildSettingsCommands => 'Commands';

  @override
  String get guildCommandsLoadFailed => 'Couldn\'t load the commands.';

  @override
  String get guildCommandsSubtitle =>
      'Messages members can post by typing /name.';

  @override
  String get guildCommandsSlots => 'Command slots';

  @override
  String get guildCommandsNew => 'New command';

  @override
  String get guildCommandsSearch => 'Search commands';

  @override
  String get guildCommandsEmptyTitle => 'No commands';

  @override
  String get guildCommandsEmptyBody =>
      'This community doesn\'t have any commands yet.';

  @override
  String get guildCommandsSaved => 'Commands saved';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Couldn\'t save /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Edit /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Delete /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'This can\'t be undone. Messages made with it still show which command made them.';

  @override
  String get guildCommandDelete => 'Delete';

  @override
  String get guildCommandDeleteCommand => 'Delete command';

  @override
  String get guildCommandSectionCommand => 'Command';

  @override
  String get guildCommandName => 'Name';

  @override
  String get guildCommandNameInvalid =>
      'Use lowercase letters, numbers, - and _, up to 32 characters.';

  @override
  String get guildCommandNameTaken =>
      'Another command or a built-in command already has this name.';

  @override
  String get guildCommandDescription => 'Description';

  @override
  String get guildCommandSectionInput => 'Input';

  @override
  String get guildCommandInputNone => 'None';

  @override
  String get guildCommandInputOptional => 'Optional';

  @override
  String get guildCommandInputRequired => 'Required';

  @override
  String get guildCommandHint => 'Hint';

  @override
  String get guildCommandMessage => 'Message';

  @override
  String get guildCommandInsert => 'Insert:';

  @override
  String get guildCommandInsertPerson => 'Person running it';

  @override
  String get guildCommandInsertInput => 'What they type';

  @override
  String get guildCommandPreview => 'Preview';

  @override
  String get guildCommandSampleInput => 'Sample input';

  @override
  String guildCommandMadeWith(String name) {
    return 'Made with /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Clear the message box to use /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'This would post nothing, so the command would fail.';

  @override
  String get guildCommandUseScriptEditor => 'Use the script editor';

  @override
  String get guildCommandUseBasicEditor => 'Use the basic editor';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Run again';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'There\'s no tag called $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'There\'s no filter called $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name is never closed.';
  }

  @override
  String get guildCommandIssueTooLong => 'The script is too long.';

  @override
  String get guildCommandIssueTooLarge => 'The script builds too much text.';

  @override
  String get guildCommandIssueTooSlow => 'The script took too long to run.';

  @override
  String get guildCommandIssueInvalid => 'This part can\'t be read.';

  @override
  String get guildCommandIssueFailed => 'This part stopped with an error.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Line $line, column $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Script reference';

  @override
  String get guildCommandReferencePerson =>
      'The person running it, as a mention';

  @override
  String get guildCommandReferencePersonName => 'Their name';

  @override
  String get guildCommandReferenceTarget =>
      'The first person they mention, if any';

  @override
  String get guildCommandReferenceTargetName => 'That person’s name';

  @override
  String get guildCommandReferenceChannel => 'The channel, as a mention';

  @override
  String get guildCommandReferenceCommunity => 'The name of this community';

  @override
  String get guildCommandExampleRandom => 'Pick one option at random';

  @override
  String get guildCommandExampleDepends =>
      'Change the message depending on what they typed';

  @override
  String get guildCommandExampleOneWord => 'Pick one word at random';

  @override
  String get guildCommandExampleWordForNumber => 'Pick the word for a number';

  @override
  String get guildCommandExampleOrdinal => 'Write a number as 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Full script guide';

  @override
  String get guildCommandCounters => 'Counters';

  @override
  String get guildCommandCounterAdd => 'Add counter';

  @override
  String get guildCommandCounterSeparately => 'Count separately for each:';

  @override
  String get guildCommandCounterPersonMentioned => 'Person mentioned';

  @override
  String get guildCommandCounterChannel => 'Channel';

  @override
  String get guildCommandCounterPersonas => 'Count personas separately';

  @override
  String get guildCommandCounterRemove => 'Remove counter';

  @override
  String get guildCommandCounterReset => 'Reset counts';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Reset the counts of $name? This can\'t be undone.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Use lowercase letters, numbers and _, starting with a letter, and not a name scripts already use.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Use it in a script as $variable. Each run adds one first, so the first run reads 1.';
  }
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class ForkLocalizationsEnGb extends ForkLocalizationsEn {
  ForkLocalizationsEnGb() : super('en_GB');

  @override
  String get chatMessageChangePersona => 'Change Persona';

  @override
  String get chatAttachmentPanelVoice => 'Voice';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'Quick Switcher button';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Replace the voice message button in the message input with a Quick Switcher button for fast navigation';

  @override
  String get userSettingsCheckForUpdates => 'Check for updates';

  @override
  String get userSettingsCheckingForUpdates => 'Checking for updates…';

  @override
  String get userSettingsAppUpToDate => 'Tyne is up to date';

  @override
  String get userSettingsUpdateAvailableTitle => 'Update Available';

  @override
  String get userSettingsUpdateDownloadAction => 'Download & Install';

  @override
  String get userSettingsUpdateInstallAction => 'Install Update';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Downloading update ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed => 'Failed to check or download update.';

  @override
  String get personaSelectTitle => 'Select Persona';

  @override
  String get personaSettingsHeader => 'Persona Settings';

  @override
  String get personaManageAction => 'Manage';

  @override
  String get personaSearchPlaceholder => 'Search personas, tags, pronouns...';

  @override
  String get personaModeManual => 'Manual';

  @override
  String get personaModeLast => 'Last Used';

  @override
  String get personaModeManualDescription =>
      'Always sends as selected persona until changed.';

  @override
  String get personaModeLastDescription =>
      'Auto-switches to the persona used in your last message.';

  @override
  String get personaRecentHeader => 'RECENT PERSONAS';

  @override
  String personaAllHeader(int count) {
    return 'ALL PERSONAS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'SEARCH RESULTS ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Root Account (Default)';

  @override
  String get personaEmptyState =>
      'No personas configured yet. Create one via Manage Personas.';

  @override
  String get personaEmptySearch => 'No matching personas found.';

  @override
  String get personaEditTitle => 'Edit Persona';

  @override
  String get personaCreateTitle => 'Create Persona';

  @override
  String get personaDisplayNameLabel => 'Display Name';

  @override
  String get personaPronounsLabel => 'Pronouns';

  @override
  String get personaPronounsHint => 'e.g. they/them';

  @override
  String get personaBioHint => 'Tell others about this persona...';

  @override
  String get personaUpdatedToast => 'Persona updated';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Failed to update persona: $error';
  }

  @override
  String get personaSectionTitle => 'Personas';

  @override
  String get personaDisplayNameHint => 'Persona name';

  @override
  String personaSendingAsTag(String name) {
    return 'Sending as $name (Matched by tag)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Sending as $name (Latched)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Sending as $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Posting as $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Sending as @$username';
  }

  @override
  String get personaMainAccount => 'Main account';

  @override
  String get personaEditPersona => 'Edit persona';

  @override
  String get userSettingsNavPersonas => 'Personas';

  @override
  String get personaSettingsDescription =>
      'Configure your active persona mode, custom display tag, and manage individual personas.';

  @override
  String get personaDisplayTagSection => 'Display Tag';

  @override
  String get personaDisplayTagDescription =>
      'Display tag will appear next to all persona names in messages. If no display tag is set, your account profile picture will be shown.';

  @override
  String get personaDisplayTagLabel => 'Display Tag Text';

  @override
  String get personaDisplayTagHint => 'e.g. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Display Tag Icon';

  @override
  String get personaUploadTagIcon => 'Upload Icon';

  @override
  String get personaChangeTagIcon => 'Change Icon';

  @override
  String get personaRemoveTagIcon => 'Remove Icon';

  @override
  String get personaChatPreviewTitle => 'Chat Preview';

  @override
  String get personaChatPreviewSampleMessage =>
      'Hello! This is a preview of how messages look with your display tag and active persona.';

  @override
  String get personaListTitle => 'Configured Personas';

  @override
  String get personaAddButton => 'Add Persona';

  @override
  String get personaActiveBadge => 'Active';

  @override
  String get personaMakeActive => 'Set Active';

  @override
  String get personaDeleteTitle => 'Delete Persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Are you sure you want to delete \"$name\"? This cannot be undone.';
  }

  @override
  String get personaDeleteConfirm => 'Delete';

  @override
  String get personaDeletedToast => 'Persona deleted';

  @override
  String get personaCreatedToast => 'Persona created';

  @override
  String personaCreateFailedToast(String error) {
    return 'Failed to create persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Change Avatar';

  @override
  String get personaRemoveAvatar => 'Remove Avatar';

  @override
  String get personaUploadAvatar => 'Upload Avatar';

  @override
  String get personaTagsLabel => 'Persona Tags';

  @override
  String get personaTagPrefixLabel => 'Prefix';

  @override
  String get personaTagSuffixLabel => 'Suffix';

  @override
  String get personaVisibilityLabel => 'Visibility';

  @override
  String get personaVisibilityUnlisted => 'Unlisted';

  @override
  String get personaVisibilityPublic => 'Public';

  @override
  String get personaVisibilityPrivate => 'Private';

  @override
  String get personaNameRequired => 'Please enter a persona display name';

  @override
  String get personaNameTooLong =>
      'Persona display name must be 100 characters or less';

  @override
  String get personaTagPrefixTooLong =>
      'Persona tag prefix must be 32 characters or less';

  @override
  String get personaTagSuffixTooLong =>
      'Persona tag suffix must be 32 characters or less';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'The tag \'$tag\' is already in use by \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Insert timestamp';

  @override
  String get chatAttachmentSendVoiceMessage => 'Send voice message';

  @override
  String get timestampPickerTitle => 'Insert Timestamp';

  @override
  String get timestampPickerInsert => 'Insert';

  @override
  String get timestampCopied => 'Timestamp copied';

  @override
  String get timestampPickerTimeLabel => 'Time';

  @override
  String get timestampPickerDateLabel => 'DATE';

  @override
  String get timestampPickerTimeSectionLabel => 'TIME';

  @override
  String get timestampPickerTimezoneLabel => 'TIME ZONE';

  @override
  String get timestampPickerFormatPreviewLabel => 'FORMAT PREVIEW';

  @override
  String get timestampPickerNlpPlaceholder =>
      'e.g. tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'Search time zones...';

  @override
  String get userProfileTimezoneSettingLabel => 'Time zone';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Used to show your local time on your profile.';

  @override
  String get userProfileTimezoneNone => 'None';

  @override
  String get chatReactAs => 'React as...';

  @override
  String get emojiCopy => 'Copy emoji';

  @override
  String get emojiCopyLink => 'Copy link';

  @override
  String get emojiPin => 'Pin emoji';

  @override
  String get emojiUnpin => 'Unpin emoji';

  @override
  String get emojiPinForPersona => 'Pin for this persona';

  @override
  String get emojiUnpinForPersona => 'Unpin for this persona';

  @override
  String get personaSignatureEmojisLabel => 'Signature Emojis';

  @override
  String get personaSignatureEmojisDescription =>
      'Reacting with a signature emoji will always react as this persona, regardless of active persona.';

  @override
  String get personaAddSignatureEmoji => 'Add Emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'This emoji is already added as a signature emoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Signature emoji already in use by persona \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Remove signature emoji';

  @override
  String get signalBarLabel => 'Signal bar';

  @override
  String get signalBarShow => 'Show signal bar';

  @override
  String get signalBarHide => 'Hide signal bar';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Nobody has this signal on';

  @override
  String get signalBarReset => 'Reset signal for everyone';

  @override
  String signalBarTurnOff(String name) {
    return 'Turn off $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Use $domain for the default instance, or the exact URL of another instance.';
  }

  @override
  String get instanceResetToDefault => 'Reset to default instance';

  @override
  String get personaScopeTitle => 'Persona applies to';

  @override
  String get personaScopeGlobal => 'Everywhere';

  @override
  String get personaScopeGlobalDescription => 'One persona for all channels.';

  @override
  String get personaScopeChannel => 'In each channel';

  @override
  String get personaScopeChannelDescription =>
      'Each channel keeps its own persona. New channels start as your account.';

  @override
  String get personaPickerChannelOnly => 'Only for this channel';

  @override
  String get personaProfilePrivate => 'This persona’s profile is private.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Image file is too large. Please choose a file smaller than $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Search KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Failed to download update';

  @override
  String get appUpdateInstallFailed => 'Failed to install update';

  @override
  String get personaChangeMessageFailed => 'Failed to change message persona';

  @override
  String get personaActiveCleared => 'Active persona cleared';

  @override
  String get klipyPoweredBy => 'Powered by KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Duplicate tag pair \'$pattern\' on this persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Add Tag Pair ($count/5)';
  }

  @override
  String get personaTagExampleText => 'text';

  @override
  String get personaPreviewNameFallback => 'User';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne closed unexpectedly. Sharing anonymous crash and error data helps us fix issues faster.';

  @override
  String get crashReportingSectionDescription =>
      'Help fix bugs in Tyne by sharing crash and performance data. This is off by default.';

  @override
  String get crashReportingDescription =>
      'Reports go to Tyne\'s own error tracker, even when you\'re signed in to another instance. They don\'t include instance names, IDs or message content.';

  @override
  String get instanceOfflineTitle => 'Tyne is offline!';

  @override
  String get instanceOfflineBody => 'We\'re investigating.';

  @override
  String get instanceStatusSignalLink => 'Join our Signal chat for updates';

  @override
  String get convertEmoticonsLabel => 'Turn text smileys into emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Couldn\'t run /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Its script has a problem.';

  @override
  String guildCommandOneLine(String name) {
    return 'What you type after /$name has to fit on one line.';
  }

  @override
  String get permissionCreateCommands => 'Create commands';

  @override
  String get permissionManageCommands => 'Manage commands';

  @override
  String get permissionUseExternalCommands => 'Use external commands';

  @override
  String get permissionCreateCommandsDescription =>
      'Create commands for this community, and edit or delete your own.';

  @override
  String get permissionManageCommandsDescription =>
      'Edit or delete anyone\'s commands in this community.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Use commands from other communities.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Use commands from other communities in this channel.';

  @override
  String get guildSettingsCategoryMessageTools => 'Message Tools';

  @override
  String get guildSettingsCommands => 'Commands';

  @override
  String get guildCommandsLoadFailed => 'Couldn\'t load the commands.';

  @override
  String get guildCommandsSubtitle =>
      'Messages members can post by typing /name.';

  @override
  String get guildCommandsSlots => 'Command slots';

  @override
  String get guildCommandsNew => 'New command';

  @override
  String get guildCommandsSearch => 'Search commands';

  @override
  String get guildCommandsEmptyTitle => 'No commands';

  @override
  String get guildCommandsEmptyBody =>
      'This community doesn\'t have any commands yet.';

  @override
  String get guildCommandsSaved => 'Commands saved';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Couldn\'t save /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Edit /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Delete /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'This can\'t be undone. Messages made with it still show which command made them.';

  @override
  String get guildCommandDelete => 'Delete';

  @override
  String get guildCommandDeleteCommand => 'Delete command';

  @override
  String get guildCommandSectionCommand => 'Command';

  @override
  String get guildCommandName => 'Name';

  @override
  String get guildCommandNameInvalid =>
      'Use lowercase letters, numbers, - and _, up to 32 characters.';

  @override
  String get guildCommandNameTaken =>
      'Another command or a built-in command already has this name.';

  @override
  String get guildCommandDescription => 'Description';

  @override
  String get guildCommandSectionInput => 'Input';

  @override
  String get guildCommandInputNone => 'None';

  @override
  String get guildCommandInputOptional => 'Optional';

  @override
  String get guildCommandInputRequired => 'Required';

  @override
  String get guildCommandHint => 'Hint';

  @override
  String get guildCommandMessage => 'Message';

  @override
  String get guildCommandInsert => 'Insert:';

  @override
  String get guildCommandInsertPerson => 'Person running it';

  @override
  String get guildCommandInsertInput => 'What they type';

  @override
  String get guildCommandPreview => 'Preview';

  @override
  String get guildCommandSampleInput => 'Sample input';

  @override
  String guildCommandMadeWith(String name) {
    return 'Made with /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Clear the message box to use /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'This would post nothing, so the command would fail.';

  @override
  String get guildCommandUseScriptEditor => 'Use the script editor';

  @override
  String get guildCommandUseBasicEditor => 'Use the basic editor';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Run again';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'There\'s no tag called $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'There\'s no filter called $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name is never closed.';
  }

  @override
  String get guildCommandIssueTooLong => 'The script is too long.';

  @override
  String get guildCommandIssueTooLarge => 'The script builds too much text.';

  @override
  String get guildCommandIssueTooSlow => 'The script took too long to run.';

  @override
  String get guildCommandIssueInvalid => 'This part can\'t be read.';

  @override
  String get guildCommandIssueFailed => 'This part stopped with an error.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Line $line, column $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Script reference';

  @override
  String get guildCommandReferencePerson =>
      'The person running it, as a mention';

  @override
  String get guildCommandReferencePersonName => 'Their name';

  @override
  String get guildCommandReferenceTarget =>
      'The first person they mention, if any';

  @override
  String get guildCommandReferenceTargetName => 'That person’s name';

  @override
  String get guildCommandReferenceChannel => 'The channel, as a mention';

  @override
  String get guildCommandReferenceCommunity => 'The name of this community';

  @override
  String get guildCommandExampleRandom => 'Pick one option at random';

  @override
  String get guildCommandExampleDepends =>
      'Change the message depending on what they typed';

  @override
  String get guildCommandExampleOneWord => 'Pick one word at random';

  @override
  String get guildCommandExampleWordForNumber => 'Pick the word for a number';

  @override
  String get guildCommandExampleOrdinal => 'Write a number as 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Full script guide';

  @override
  String get guildCommandCounters => 'Counters';

  @override
  String get guildCommandCounterAdd => 'Add counter';

  @override
  String get guildCommandCounterSeparately => 'Count separately for each:';

  @override
  String get guildCommandCounterPersonMentioned => 'Person mentioned';

  @override
  String get guildCommandCounterChannel => 'Channel';

  @override
  String get guildCommandCounterPersonas => 'Count personas separately';

  @override
  String get guildCommandCounterRemove => 'Remove counter';

  @override
  String get guildCommandCounterReset => 'Reset counts';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Reset the counts of $name? This can\'t be undone.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Use lowercase letters, numbers and _, starting with a letter, and not a name scripts already use.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Use it in a script as $variable. Each run adds one first, so the first run reads 1.';
  }
}

/// The translations for English, as used in the United States (`en_US`).
class ForkLocalizationsEnUs extends ForkLocalizationsEn {
  ForkLocalizationsEnUs() : super('en_US');

  @override
  String get chatMessageChangePersona => 'Change Persona';

  @override
  String get chatAttachmentPanelVoice => 'Voice';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'Quick Switcher button';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Replace the voice message button in the message input with a Quick Switcher button for fast navigation';

  @override
  String get userSettingsCheckForUpdates => 'Check for updates';

  @override
  String get userSettingsCheckingForUpdates => 'Checking for updates…';

  @override
  String get userSettingsAppUpToDate => 'Tyne is up to date';

  @override
  String get userSettingsUpdateAvailableTitle => 'Update Available';

  @override
  String get userSettingsUpdateDownloadAction => 'Download & Install';

  @override
  String get userSettingsUpdateInstallAction => 'Install Update';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Downloading update ($percent%)…';
  }

  @override
  String get userSettingsUpdateFailed => 'Failed to check or download update.';

  @override
  String get personaSelectTitle => 'Select Persona';

  @override
  String get personaSettingsHeader => 'Persona Settings';

  @override
  String get personaManageAction => 'Manage';

  @override
  String get personaSearchPlaceholder => 'Search personas, tags, pronouns...';

  @override
  String get personaModeManual => 'Manual';

  @override
  String get personaModeLast => 'Last Used';

  @override
  String get personaModeManualDescription =>
      'Always sends as selected persona until changed.';

  @override
  String get personaModeLastDescription =>
      'Auto-switches to the persona used in your last message.';

  @override
  String get personaRecentHeader => 'RECENT PERSONAS';

  @override
  String personaAllHeader(int count) {
    return 'ALL PERSONAS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'SEARCH RESULTS ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Root Account (Default)';

  @override
  String get personaEmptyState =>
      'No personas configured yet. Create one via Manage Personas.';

  @override
  String get personaEmptySearch => 'No matching personas found.';

  @override
  String get personaEditTitle => 'Edit Persona';

  @override
  String get personaCreateTitle => 'Create Persona';

  @override
  String get personaDisplayNameLabel => 'Display Name';

  @override
  String get personaPronounsLabel => 'Pronouns';

  @override
  String get personaPronounsHint => 'e.g. they/them';

  @override
  String get personaBioHint => 'Tell others about this persona...';

  @override
  String get personaUpdatedToast => 'Persona updated';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Failed to update persona: $error';
  }

  @override
  String get personaSectionTitle => 'Personas';

  @override
  String get personaDisplayNameHint => 'Persona name';

  @override
  String personaSendingAsTag(String name) {
    return 'Sending as $name (Matched by tag)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Sending as $name (Latched)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Sending as $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Posting as $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Sending as @$username';
  }

  @override
  String get personaMainAccount => 'Main account';

  @override
  String get personaEditPersona => 'Edit persona';

  @override
  String get userSettingsNavPersonas => 'Personas';

  @override
  String get personaSettingsDescription =>
      'Configure your active persona mode, custom display tag, and manage individual personas.';

  @override
  String get personaDisplayTagSection => 'Display Tag';

  @override
  String get personaDisplayTagDescription =>
      'Display tag will appear next to all persona names in messages. If no display tag is set, your account profile picture will be shown.';

  @override
  String get personaDisplayTagLabel => 'Display Tag Text';

  @override
  String get personaDisplayTagHint => 'e.g. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Display Tag Icon';

  @override
  String get personaUploadTagIcon => 'Upload Icon';

  @override
  String get personaChangeTagIcon => 'Change Icon';

  @override
  String get personaRemoveTagIcon => 'Remove Icon';

  @override
  String get personaChatPreviewTitle => 'Chat Preview';

  @override
  String get personaChatPreviewSampleMessage =>
      'Hello! This is a preview of how messages look with your display tag and active persona.';

  @override
  String get personaListTitle => 'Configured Personas';

  @override
  String get personaAddButton => 'Add Persona';

  @override
  String get personaActiveBadge => 'Active';

  @override
  String get personaMakeActive => 'Set Active';

  @override
  String get personaDeleteTitle => 'Delete Persona';

  @override
  String personaDeleteMessage(String name) {
    return 'Are you sure you want to delete \"$name\"? This cannot be undone.';
  }

  @override
  String get personaDeleteConfirm => 'Delete';

  @override
  String get personaDeletedToast => 'Persona deleted';

  @override
  String get personaCreatedToast => 'Persona created';

  @override
  String personaCreateFailedToast(String error) {
    return 'Failed to create persona: $error';
  }

  @override
  String get personaChangeAvatar => 'Change Avatar';

  @override
  String get personaRemoveAvatar => 'Remove Avatar';

  @override
  String get personaUploadAvatar => 'Upload Avatar';

  @override
  String get personaTagsLabel => 'Persona Tags';

  @override
  String get personaTagPrefixLabel => 'Prefix';

  @override
  String get personaTagSuffixLabel => 'Suffix';

  @override
  String get personaVisibilityLabel => 'Visibility';

  @override
  String get personaVisibilityUnlisted => 'Unlisted';

  @override
  String get personaVisibilityPublic => 'Public';

  @override
  String get personaVisibilityPrivate => 'Private';

  @override
  String get personaNameRequired => 'Please enter a persona display name';

  @override
  String get personaNameTooLong =>
      'Persona display name must be 100 characters or less';

  @override
  String get personaTagPrefixTooLong =>
      'Persona tag prefix must be 32 characters or less';

  @override
  String get personaTagSuffixTooLong =>
      'Persona tag suffix must be 32 characters or less';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'The tag \'$tag\' is already in use by \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Insert timestamp';

  @override
  String get chatAttachmentSendVoiceMessage => 'Send voice message';

  @override
  String get timestampPickerTitle => 'Insert Timestamp';

  @override
  String get timestampPickerInsert => 'Insert';

  @override
  String get timestampCopied => 'Timestamp copied';

  @override
  String get timestampPickerTimeLabel => 'Time';

  @override
  String get timestampPickerDateLabel => 'DATE';

  @override
  String get timestampPickerTimeSectionLabel => 'TIME';

  @override
  String get timestampPickerTimezoneLabel => 'TIME ZONE';

  @override
  String get timestampPickerFormatPreviewLabel => 'FORMAT PREVIEW';

  @override
  String get timestampPickerNlpPlaceholder =>
      'e.g. tomorrow at 3pm, in 2 hours, now';

  @override
  String get timestampPickerSearchTimezones => 'Search time zones...';

  @override
  String get userProfileTimezoneSettingLabel => 'Time zone';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Used to show your local time on your profile.';

  @override
  String get userProfileTimezoneNone => 'None';

  @override
  String get chatReactAs => 'React as...';

  @override
  String get emojiCopy => 'Copy emoji';

  @override
  String get emojiCopyLink => 'Copy link';

  @override
  String get emojiPin => 'Pin emoji';

  @override
  String get emojiUnpin => 'Unpin emoji';

  @override
  String get emojiPinForPersona => 'Pin for this persona';

  @override
  String get emojiUnpinForPersona => 'Unpin for this persona';

  @override
  String get personaSignatureEmojisLabel => 'Signature Emojis';

  @override
  String get personaSignatureEmojisDescription =>
      'Reacting with a signature emoji will always react as this persona, regardless of active persona.';

  @override
  String get personaAddSignatureEmoji => 'Add Emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'This emoji is already added as a signature emoji';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Signature emoji already in use by persona \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Remove signature emoji';

  @override
  String get signalBarLabel => 'Signal bar';

  @override
  String get signalBarShow => 'Show signal bar';

  @override
  String get signalBarHide => 'Hide signal bar';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Nobody has this signal on';

  @override
  String get signalBarReset => 'Reset signal for everyone';

  @override
  String signalBarTurnOff(String name) {
    return 'Turn off $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Use $domain for the default instance, or the exact URL of another instance.';
  }

  @override
  String get instanceResetToDefault => 'Reset to default instance';

  @override
  String get personaScopeTitle => 'Persona applies to';

  @override
  String get personaScopeGlobal => 'Everywhere';

  @override
  String get personaScopeGlobalDescription => 'One persona for all channels.';

  @override
  String get personaScopeChannel => 'In each channel';

  @override
  String get personaScopeChannelDescription =>
      'Each channel keeps its own persona. New channels start as your account.';

  @override
  String get personaPickerChannelOnly => 'Only for this channel';

  @override
  String get personaProfilePrivate => 'This persona’s profile is private.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Image file is too large. Please choose a file smaller than $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Search KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Failed to download update';

  @override
  String get appUpdateInstallFailed => 'Failed to install update';

  @override
  String get personaChangeMessageFailed => 'Failed to change message persona';

  @override
  String get personaActiveCleared => 'Active persona cleared';

  @override
  String get klipyPoweredBy => 'Powered by KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Duplicate tag pair \'$pattern\' on this persona';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Add Tag Pair ($count/5)';
  }

  @override
  String get personaTagExampleText => 'text';

  @override
  String get personaPreviewNameFallback => 'User';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne closed unexpectedly. Sharing anonymous crash and error data helps us fix issues faster.';

  @override
  String get crashReportingSectionDescription =>
      'Help fix bugs in Tyne by sharing crash and performance data. This is off by default.';

  @override
  String get crashReportingDescription =>
      'Reports go to Tyne\'s own error tracker, even when you\'re signed in to another instance. They don\'t include instance names, IDs or message content.';

  @override
  String get instanceOfflineTitle => 'Tyne is offline!';

  @override
  String get instanceOfflineBody => 'We\'re investigating.';

  @override
  String get instanceStatusSignalLink => 'Join our Signal chat for updates';

  @override
  String get convertEmoticonsLabel => 'Turn text smileys into emoji';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Couldn\'t run /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Its script has a problem.';

  @override
  String guildCommandOneLine(String name) {
    return 'What you type after /$name has to fit on one line.';
  }

  @override
  String get permissionCreateCommands => 'Create commands';

  @override
  String get permissionManageCommands => 'Manage commands';

  @override
  String get permissionUseExternalCommands => 'Use external commands';

  @override
  String get permissionCreateCommandsDescription =>
      'Create commands for this community, and edit or delete your own.';

  @override
  String get permissionManageCommandsDescription =>
      'Edit or delete anyone\'s commands in this community.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Use commands from other communities.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Use commands from other communities in this channel.';

  @override
  String get guildSettingsCategoryMessageTools => 'Message Tools';

  @override
  String get guildSettingsCommands => 'Commands';

  @override
  String get guildCommandsLoadFailed => 'Couldn\'t load the commands.';

  @override
  String get guildCommandsSubtitle =>
      'Messages members can post by typing /name.';

  @override
  String get guildCommandsSlots => 'Command slots';

  @override
  String get guildCommandsNew => 'New command';

  @override
  String get guildCommandsSearch => 'Search commands';

  @override
  String get guildCommandsEmptyTitle => 'No commands';

  @override
  String get guildCommandsEmptyBody =>
      'This community doesn\'t have any commands yet.';

  @override
  String get guildCommandsSaved => 'Commands saved';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Couldn\'t save /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Edit /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Delete /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'This can\'t be undone. Messages made with it still show which command made them.';

  @override
  String get guildCommandDelete => 'Delete';

  @override
  String get guildCommandDeleteCommand => 'Delete command';

  @override
  String get guildCommandSectionCommand => 'Command';

  @override
  String get guildCommandName => 'Name';

  @override
  String get guildCommandNameInvalid =>
      'Use lowercase letters, numbers, - and _, up to 32 characters.';

  @override
  String get guildCommandNameTaken =>
      'Another command or a built-in command already has this name.';

  @override
  String get guildCommandDescription => 'Description';

  @override
  String get guildCommandSectionInput => 'Input';

  @override
  String get guildCommandInputNone => 'None';

  @override
  String get guildCommandInputOptional => 'Optional';

  @override
  String get guildCommandInputRequired => 'Required';

  @override
  String get guildCommandHint => 'Hint';

  @override
  String get guildCommandMessage => 'Message';

  @override
  String get guildCommandInsert => 'Insert:';

  @override
  String get guildCommandInsertPerson => 'Person running it';

  @override
  String get guildCommandInsertInput => 'What they type';

  @override
  String get guildCommandPreview => 'Preview';

  @override
  String get guildCommandSampleInput => 'Sample input';

  @override
  String guildCommandMadeWith(String name) {
    return 'Made with /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Clear the message box to use /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'This would post nothing, so the command would fail.';

  @override
  String get guildCommandUseScriptEditor => 'Use the script editor';

  @override
  String get guildCommandUseBasicEditor => 'Use the basic editor';

  @override
  String get guildCommandScript => 'Script';

  @override
  String get guildCommandRunAgain => 'Run again';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'There\'s no tag called $name.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'There\'s no filter called $name.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name is never closed.';
  }

  @override
  String get guildCommandIssueTooLong => 'The script is too long.';

  @override
  String get guildCommandIssueTooLarge => 'The script builds too much text.';

  @override
  String get guildCommandIssueTooSlow => 'The script took too long to run.';

  @override
  String get guildCommandIssueInvalid => 'This part can\'t be read.';

  @override
  String get guildCommandIssueFailed => 'This part stopped with an error.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Line $line, column $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Script reference';

  @override
  String get guildCommandReferencePerson =>
      'The person running it, as a mention';

  @override
  String get guildCommandReferencePersonName => 'Their name';

  @override
  String get guildCommandReferenceTarget =>
      'The first person they mention, if any';

  @override
  String get guildCommandReferenceTargetName => 'That person’s name';

  @override
  String get guildCommandReferenceChannel => 'The channel, as a mention';

  @override
  String get guildCommandReferenceCommunity => 'The name of this community';

  @override
  String get guildCommandExampleRandom => 'Pick one option at random';

  @override
  String get guildCommandExampleDepends =>
      'Change the message depending on what they typed';

  @override
  String get guildCommandExampleOneWord => 'Pick one word at random';

  @override
  String get guildCommandExampleWordForNumber => 'Pick the word for a number';

  @override
  String get guildCommandExampleOrdinal => 'Write a number as 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Full script guide';

  @override
  String get guildCommandCounters => 'Counters';

  @override
  String get guildCommandCounterAdd => 'Add counter';

  @override
  String get guildCommandCounterSeparately => 'Count separately for each:';

  @override
  String get guildCommandCounterPersonMentioned => 'Person mentioned';

  @override
  String get guildCommandCounterChannel => 'Channel';

  @override
  String get guildCommandCounterPersonas => 'Count personas separately';

  @override
  String get guildCommandCounterRemove => 'Remove counter';

  @override
  String get guildCommandCounterReset => 'Reset counts';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Reset the counts of $name? This can\'t be undone.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Use lowercase letters, numbers and _, starting with a letter, and not a name scripts already use.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Use it in a script as $variable. Each run adds one first, so the first run reads 1.';
  }
}
