import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'fork_localizations_ar.dart';
import 'fork_localizations_bg.dart';
import 'fork_localizations_cs.dart';
import 'fork_localizations_da.dart';
import 'fork_localizations_de.dart';
import 'fork_localizations_el.dart';
import 'fork_localizations_en.dart';
import 'fork_localizations_es.dart';
import 'fork_localizations_fi.dart';
import 'fork_localizations_fr.dart';
import 'fork_localizations_he.dart';
import 'fork_localizations_hi.dart';
import 'fork_localizations_hr.dart';
import 'fork_localizations_hu.dart';
import 'fork_localizations_id.dart';
import 'fork_localizations_it.dart';
import 'fork_localizations_ja.dart';
import 'fork_localizations_ko.dart';
import 'fork_localizations_lt.dart';
import 'fork_localizations_nb.dart';
import 'fork_localizations_nl.dart';
import 'fork_localizations_pl.dart';
import 'fork_localizations_pt.dart';
import 'fork_localizations_ro.dart';
import 'fork_localizations_ru.dart';
import 'fork_localizations_sv.dart';
import 'fork_localizations_th.dart';
import 'fork_localizations_tr.dart';
import 'fork_localizations_uk.dart';
import 'fork_localizations_vi.dart';
import 'fork_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ForkLocalizations
/// returned by `ForkLocalizations.of(context)`.
///
/// Applications need to include `ForkLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/fork_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ForkLocalizations.localizationsDelegates,
///   supportedLocales: ForkLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ForkLocalizations.supportedLocales
/// property.
abstract class ForkLocalizations {
  ForkLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ForkLocalizations of(BuildContext context) {
    return Localizations.of<ForkLocalizations>(context, ForkLocalizations)!;
  }

  static const LocalizationsDelegate<ForkLocalizations> delegate =
      _ForkLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('bg'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en', 'GB'),
    Locale('en', 'US'),
    Locale('es'),
    Locale('es', '419'),
    Locale('fi'),
    Locale('fr'),
    Locale('he'),
    Locale('hi'),
    Locale('hr'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('lt'),
    Locale('nb'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ro'),
    Locale('ru'),
    Locale('sv'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// Action label for changing the persona of a message.
  ///
  /// In en, this message translates to:
  /// **'Change Persona'**
  String get chatMessageChangePersona;

  /// Label for the voice recording action on the attachment panel.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get chatAttachmentPanelVoice;

  /// No description provided for @advancedSettingQuickSwitcherButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick Switcher button'**
  String get advancedSettingQuickSwitcherButtonLabel;

  /// No description provided for @advancedSettingQuickSwitcherButtonDescription.
  ///
  /// In en, this message translates to:
  /// **'Replace the voice message button in the message input with a Quick Switcher button for fast navigation'**
  String get advancedSettingQuickSwitcherButtonDescription;

  /// Button and navigation item to check for application updates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get userSettingsCheckForUpdates;

  /// Toast message indicating that the app is checking for updates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get userSettingsCheckingForUpdates;

  /// Toast message indicating that the app is already on the latest version.
  ///
  /// In en, this message translates to:
  /// **'Tyne is up to date'**
  String get userSettingsAppUpToDate;

  /// Title of the modal sheet notifying the user that a new version of the app is available.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get userSettingsUpdateAvailableTitle;

  /// Button action to download and install the new update.
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get userSettingsUpdateDownloadAction;

  /// Button action to launch package installer for a downloaded update.
  ///
  /// In en, this message translates to:
  /// **'Install Update'**
  String get userSettingsUpdateInstallAction;

  /// Progress message while downloading an in-app update.
  ///
  /// In en, this message translates to:
  /// **'Downloading update ({percent}%)…'**
  String userSettingsDownloadingUpdate(int percent);

  /// Toast or error message shown when checking for or downloading an update fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to check or download update.'**
  String get userSettingsUpdateFailed;

  /// Title of the persona selection modal sheet.
  ///
  /// In en, this message translates to:
  /// **'Select Persona'**
  String get personaSelectTitle;

  /// Header for persona settings row in the persona picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Persona Settings'**
  String get personaSettingsHeader;

  /// Action button to open settings to manage personas.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get personaManageAction;

  /// Placeholder in the persona picker search input.
  ///
  /// In en, this message translates to:
  /// **'Search personas, tags, pronouns...'**
  String get personaSearchPlaceholder;

  /// Label for Manual mode in persona active mode selector.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get personaModeManual;

  /// Label for Last Used mode in persona active mode selector.
  ///
  /// In en, this message translates to:
  /// **'Last Used'**
  String get personaModeLast;

  /// Helper text explaining Manual persona mode.
  ///
  /// In en, this message translates to:
  /// **'Always sends as selected persona until changed.'**
  String get personaModeManualDescription;

  /// Helper text explaining Last Used persona mode.
  ///
  /// In en, this message translates to:
  /// **'Auto-switches to the persona used in your last message.'**
  String get personaModeLastDescription;

  /// Section header for recently used personas.
  ///
  /// In en, this message translates to:
  /// **'RECENT PERSONAS'**
  String get personaRecentHeader;

  /// Section header for all user personas with count.
  ///
  /// In en, this message translates to:
  /// **'ALL PERSONAS ({count})'**
  String personaAllHeader(int count);

  /// Section header for search results with count.
  ///
  /// In en, this message translates to:
  /// **'SEARCH RESULTS ({count})'**
  String personaSearchResultsHeader(int count);

  /// Label for the user's default/root account in persona picker.
  ///
  /// In en, this message translates to:
  /// **'Root Account (Default)'**
  String get personaRootAccountLabel;

  /// Empty state text when user has no personas.
  ///
  /// In en, this message translates to:
  /// **'No personas configured yet. Create one via Manage Personas.'**
  String get personaEmptyState;

  /// Empty state text when search yields no personas.
  ///
  /// In en, this message translates to:
  /// **'No matching personas found.'**
  String get personaEmptySearch;

  /// Title of the edit persona sheet.
  ///
  /// In en, this message translates to:
  /// **'Edit Persona'**
  String get personaEditTitle;

  /// Title of the create persona sheet.
  ///
  /// In en, this message translates to:
  /// **'Create Persona'**
  String get personaCreateTitle;

  /// Form label for persona display name field.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get personaDisplayNameLabel;

  /// Form label for persona pronouns field.
  ///
  /// In en, this message translates to:
  /// **'Pronouns'**
  String get personaPronounsLabel;

  /// Hint text for persona pronouns input.
  ///
  /// In en, this message translates to:
  /// **'e.g. they/them'**
  String get personaPronounsHint;

  /// Hint text for persona biography input.
  ///
  /// In en, this message translates to:
  /// **'Tell others about this persona...'**
  String get personaBioHint;

  /// Toast message displayed when persona is successfully updated.
  ///
  /// In en, this message translates to:
  /// **'Persona updated'**
  String get personaUpdatedToast;

  /// Toast message displayed when persona update fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to update persona: {error}'**
  String personaUpdateFailedToast(String error);

  /// Title for the personas settings section.
  ///
  /// In en, this message translates to:
  /// **'Personas'**
  String get personaSectionTitle;

  /// Hint text for persona display name input.
  ///
  /// In en, this message translates to:
  /// **'Persona name'**
  String get personaDisplayNameHint;

  /// Tooltip when composer will send as persona matched by tag.
  ///
  /// In en, this message translates to:
  /// **'Sending as {name} (Matched by tag)'**
  String personaSendingAsTag(String name);

  /// Tooltip when composer will send as latched persona.
  ///
  /// In en, this message translates to:
  /// **'Sending as {name} (Latched)'**
  String personaSendingAsLatched(String name);

  /// Row in the new thread sheet saying who the thread and its first message are sent as. name is a persona's name, or @username for the account.
  ///
  /// In en, this message translates to:
  /// **'Sending as {name}'**
  String personaSendingAs(String name);

  /// Row in the new forum post sheet saying who the post is made as. name is a persona's name, or @username for the account.
  ///
  /// In en, this message translates to:
  /// **'Posting as {name}'**
  String personaPostingAs(String name);

  /// Tooltip when composer will send as root user account.
  ///
  /// In en, this message translates to:
  /// **'Sending as @{username}'**
  String personaSendingAsRoot(String username);

  /// Header for root account section in persona profile card.
  ///
  /// In en, this message translates to:
  /// **'Main account'**
  String get personaMainAccount;

  /// Button to edit persona in persona profile card.
  ///
  /// In en, this message translates to:
  /// **'Edit persona'**
  String get personaEditPersona;

  /// Navigation item label for Personas in user settings.
  ///
  /// In en, this message translates to:
  /// **'Personas'**
  String get userSettingsNavPersonas;

  /// Description at the top of the persona settings section.
  ///
  /// In en, this message translates to:
  /// **'Configure your active persona mode, custom display tag, and manage individual personas.'**
  String get personaSettingsDescription;

  /// Header for display tag section in persona settings.
  ///
  /// In en, this message translates to:
  /// **'Display Tag'**
  String get personaDisplayTagSection;

  /// Description explaining what the display tag does.
  ///
  /// In en, this message translates to:
  /// **'Display tag will appear next to all persona names in messages. If no display tag is set, your account profile picture will be shown.'**
  String get personaDisplayTagDescription;

  /// Label for the display tag text input.
  ///
  /// In en, this message translates to:
  /// **'Display Tag Text'**
  String get personaDisplayTagLabel;

  /// Placeholder for the display tag text input.
  ///
  /// In en, this message translates to:
  /// **'e.g. SYS'**
  String get personaDisplayTagHint;

  /// Label for display tag icon upload in persona settings.
  ///
  /// In en, this message translates to:
  /// **'Display Tag Icon'**
  String get personaDisplayTagIconLabel;

  /// Button to upload an icon for the display tag.
  ///
  /// In en, this message translates to:
  /// **'Upload Icon'**
  String get personaUploadTagIcon;

  /// Button to change the display tag icon.
  ///
  /// In en, this message translates to:
  /// **'Change Icon'**
  String get personaChangeTagIcon;

  /// Button to remove the display tag icon.
  ///
  /// In en, this message translates to:
  /// **'Remove Icon'**
  String get personaRemoveTagIcon;

  /// Title of the live chat message preview card in persona settings.
  ///
  /// In en, this message translates to:
  /// **'Chat Preview'**
  String get personaChatPreviewTitle;

  /// Sample message body shown in the chat preview.
  ///
  /// In en, this message translates to:
  /// **'Hello! This is a preview of how messages look with your display tag and active persona.'**
  String get personaChatPreviewSampleMessage;

  /// Title of the configured personas list in settings.
  ///
  /// In en, this message translates to:
  /// **'Configured Personas'**
  String get personaListTitle;

  /// Button to create a new persona in settings.
  ///
  /// In en, this message translates to:
  /// **'Add Persona'**
  String get personaAddButton;

  /// Badge indicating this persona is currently active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get personaActiveBadge;

  /// Button to make this persona the active one.
  ///
  /// In en, this message translates to:
  /// **'Set Active'**
  String get personaMakeActive;

  /// Title of confirmation dialog when deleting a persona.
  ///
  /// In en, this message translates to:
  /// **'Delete Persona'**
  String get personaDeleteTitle;

  /// Confirmation message when deleting a persona.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String personaDeleteMessage(String name);

  /// Confirmation button to delete a persona.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get personaDeleteConfirm;

  /// Toast shown after deleting a persona.
  ///
  /// In en, this message translates to:
  /// **'Persona deleted'**
  String get personaDeletedToast;

  /// Toast shown after successfully creating a new persona.
  ///
  /// In en, this message translates to:
  /// **'Persona created'**
  String get personaCreatedToast;

  /// Toast shown when persona creation fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to create persona: {error}'**
  String personaCreateFailedToast(String error);

  /// Button to change persona avatar.
  ///
  /// In en, this message translates to:
  /// **'Change Avatar'**
  String get personaChangeAvatar;

  /// Button to remove persona avatar.
  ///
  /// In en, this message translates to:
  /// **'Remove Avatar'**
  String get personaRemoveAvatar;

  /// Button to upload persona avatar.
  ///
  /// In en, this message translates to:
  /// **'Upload Avatar'**
  String get personaUploadAvatar;

  /// Label for persona tags section in persona form.
  ///
  /// In en, this message translates to:
  /// **'Persona Tags'**
  String get personaTagsLabel;

  /// Label for tag prefix input.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get personaTagPrefixLabel;

  /// Label for tag suffix input.
  ///
  /// In en, this message translates to:
  /// **'Suffix'**
  String get personaTagSuffixLabel;

  /// Label for persona visibility selector.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get personaVisibilityLabel;

  /// Label for unlisted visibility option.
  ///
  /// In en, this message translates to:
  /// **'Unlisted'**
  String get personaVisibilityUnlisted;

  /// Label for public visibility option.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get personaVisibilityPublic;

  /// Label for private visibility option.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get personaVisibilityPrivate;

  /// Validation toast error when saving a persona with an empty display name.
  ///
  /// In en, this message translates to:
  /// **'Please enter a persona display name'**
  String get personaNameRequired;

  /// Validation toast error when persona display name exceeds 100 characters.
  ///
  /// In en, this message translates to:
  /// **'Persona display name must be 100 characters or less'**
  String get personaNameTooLong;

  /// Validation toast error when persona tag prefix exceeds 32 characters.
  ///
  /// In en, this message translates to:
  /// **'Persona tag prefix must be 32 characters or less'**
  String get personaTagPrefixTooLong;

  /// Validation toast error when persona tag suffix exceeds 32 characters.
  ///
  /// In en, this message translates to:
  /// **'Persona tag suffix must be 32 characters or less'**
  String get personaTagSuffixTooLong;

  /// Validation toast error when a persona prefix/suffix matches an existing persona's tag.
  ///
  /// In en, this message translates to:
  /// **'The tag \'{tag}\' is already in use by \'{name}\'.'**
  String personaTagCollisionError(String tag, String name);

  /// Menu action to insert a timestamp markdown pill into composer.
  ///
  /// In en, this message translates to:
  /// **'Insert timestamp'**
  String get chatInsertTimestamp;

  /// Menu item to open the voice message recorder.
  ///
  /// In en, this message translates to:
  /// **'Send voice message'**
  String get chatAttachmentSendVoiceMessage;

  /// Title of the timestamp picker modal/sheet.
  ///
  /// In en, this message translates to:
  /// **'Insert Timestamp'**
  String get timestampPickerTitle;

  /// Action button to insert timestamp.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get timestampPickerInsert;

  /// Toast message when timestamp pill text is copied to clipboard.
  ///
  /// In en, this message translates to:
  /// **'Timestamp copied'**
  String get timestampCopied;

  /// Short label for time button in the attachment panel source bar.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timestampPickerTimeLabel;

  /// Label for date section in timestamp picker.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get timestampPickerDateLabel;

  /// Label for time section in timestamp picker.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get timestampPickerTimeSectionLabel;

  /// Label for timezone section in timestamp picker.
  ///
  /// In en, this message translates to:
  /// **'TIME ZONE'**
  String get timestampPickerTimezoneLabel;

  /// Label for format preview section in timestamp picker.
  ///
  /// In en, this message translates to:
  /// **'FORMAT PREVIEW'**
  String get timestampPickerFormatPreviewLabel;

  /// Placeholder for natural language timestamp input.
  ///
  /// In en, this message translates to:
  /// **'e.g. tomorrow at 3pm, in 2 hours, now'**
  String get timestampPickerNlpPlaceholder;

  /// Placeholder for timezone search input.
  ///
  /// In en, this message translates to:
  /// **'Search time zones...'**
  String get timestampPickerSearchTimezones;

  /// Label for timezone setting in user profile settings.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get userProfileTimezoneSettingLabel;

  /// Description for timezone setting in user profile settings.
  ///
  /// In en, this message translates to:
  /// **'Used to show your local time on your profile.'**
  String get userProfileTimezoneSettingDescription;

  /// Option to clear timezone in user profile settings.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get userProfileTimezoneNone;

  /// Menu action and sheet title to react as a persona.
  ///
  /// In en, this message translates to:
  /// **'React as...'**
  String get chatReactAs;

  /// Action to copy an emoji character or markdown code to clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy emoji'**
  String get emojiCopy;

  /// Action to copy a custom emoji image URL to clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get emojiCopyLink;

  /// Action in the emoji info sheet that pins the emoji to the front of the frequently used emojis and quick reactions, whoever the account writes as.
  ///
  /// In en, this message translates to:
  /// **'Pin emoji'**
  String get emojiPin;

  /// Action in the emoji info sheet that removes the emoji from the pinned emojis.
  ///
  /// In en, this message translates to:
  /// **'Unpin emoji'**
  String get emojiUnpin;

  /// Action in the emoji info sheet that pins the emoji only for the persona the account is writing as.
  ///
  /// In en, this message translates to:
  /// **'Pin for this persona'**
  String get emojiPinForPersona;

  /// Action in the emoji info sheet that removes the emoji from the pins of the persona the account is writing as.
  ///
  /// In en, this message translates to:
  /// **'Unpin for this persona'**
  String get emojiUnpinForPersona;

  /// Section header for signature emojis on persona.
  ///
  /// In en, this message translates to:
  /// **'Signature Emojis'**
  String get personaSignatureEmojisLabel;

  /// Explanation text for persona signature emojis.
  ///
  /// In en, this message translates to:
  /// **'Reacting with a signature emoji will always react as this persona, regardless of active persona.'**
  String get personaSignatureEmojisDescription;

  /// Button to add a signature emoji to persona.
  ///
  /// In en, this message translates to:
  /// **'Add Emoji'**
  String get personaAddSignatureEmoji;

  /// Toast when attempting to add duplicate signature emoji to same persona.
  ///
  /// In en, this message translates to:
  /// **'This emoji is already added as a signature emoji'**
  String get personaSignatureEmojiAlreadyAdded;

  /// Toast when attempting to add signature emoji already assigned to another persona.
  ///
  /// In en, this message translates to:
  /// **'Signature emoji already in use by persona \"{name}\"'**
  String personaSignatureEmojiAlreadyUsedByOther(String name);

  /// Aria label for removing signature emoji from persona.
  ///
  /// In en, this message translates to:
  /// **'Remove signature emoji'**
  String get personaRemoveSignatureEmoji;

  /// Accessible label for the row of toggleable signal icons above the message box.
  ///
  /// In en, this message translates to:
  /// **'Signal bar'**
  String get signalBarLabel;

  /// Tooltip for the arrow button that expands the collapsed signal bar above the message box.
  ///
  /// In en, this message translates to:
  /// **'Show signal bar'**
  String get signalBarShow;

  /// Tooltip for the arrow button that collapses the signal bar above the message box.
  ///
  /// In en, this message translates to:
  /// **'Hide signal bar'**
  String get signalBarHide;

  /// Label of a lit signal icon. label is the signal name such as Reading; names is a comma-separated list of the people who turned it on.
  ///
  /// In en, this message translates to:
  /// **'{label}: {names}'**
  String signalBarSignalWithNames(String label, String names);

  /// Shown in the signal details sheet when no one has the signal on.
  ///
  /// In en, this message translates to:
  /// **'Nobody has this signal on'**
  String get signalBarNobody;

  /// Destructive action in the signal details sheet, for moderators, that turns the signal off for everyone.
  ///
  /// In en, this message translates to:
  /// **'Reset signal for everyone'**
  String get signalBarReset;

  /// Action in the signal details sheet, for moderators, that turns one person's signal off. name is the persona or account name the signal is shown as.
  ///
  /// In en, this message translates to:
  /// **'Turn off {name}'**
  String signalBarTurnOff(String name);

  /// Helper text under the instance URL field on the login screen. domain is the host of this build's default instance.
  ///
  /// In en, this message translates to:
  /// **'Use {domain} for the default instance, or the exact URL of another instance.'**
  String instanceUrlHelperDefault(String domain);

  /// Button on the instance selector that switches back to this build's default instance.
  ///
  /// In en, this message translates to:
  /// **'Reset to default instance'**
  String get instanceResetToDefault;

  /// Title of the setting that chooses whether the selected persona applies in every channel or is remembered per channel.
  ///
  /// In en, this message translates to:
  /// **'Persona applies to'**
  String get personaScopeTitle;

  /// Option of the persona scope setting: one persona for every channel.
  ///
  /// In en, this message translates to:
  /// **'Everywhere'**
  String get personaScopeGlobal;

  /// Helper text for the Everywhere option of the persona scope setting.
  ///
  /// In en, this message translates to:
  /// **'One persona for all channels.'**
  String get personaScopeGlobalDescription;

  /// Option of the persona scope setting: each channel remembers its own persona.
  ///
  /// In en, this message translates to:
  /// **'In each channel'**
  String get personaScopeChannel;

  /// Helper text for the In each channel option of the persona scope setting.
  ///
  /// In en, this message translates to:
  /// **'Each channel keeps its own persona. New channels start as your account.'**
  String get personaScopeChannelDescription;

  /// Note in the persona picker when personas are remembered per channel: the persona picked is used in the current channel only.
  ///
  /// In en, this message translates to:
  /// **'Only for this channel'**
  String get personaPickerChannelOnly;

  /// Shown on a persona's profile card in place of its bio and banner when the owner has made the persona private.
  ///
  /// In en, this message translates to:
  /// **'This persona’s profile is private.'**
  String get personaProfilePrivate;

  /// Error shown when a picked avatar, banner or icon is larger than the instance's image upload limit.
  ///
  /// In en, this message translates to:
  /// **'Image file is too large. Please choose a file smaller than {maxSize}.'**
  String imageFileTooLargeMaxSize(String maxSize);

  /// Placeholder of the GIF picker search box when GIFs come from KLIPY. KLIPY's attribution guidelines require the brand name in capitals.
  ///
  /// In en, this message translates to:
  /// **'Search KLIPY'**
  String get gifPickerSearchKlipyBrand;

  /// Shown in the in-app updater when downloading the new version fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to download update'**
  String get appUpdateDownloadFailed;

  /// Shown in the in-app updater when the downloaded update cannot be handed to the system installer, for example because the file failed its checks.
  ///
  /// In en, this message translates to:
  /// **'Failed to install update'**
  String get appUpdateInstallFailed;

  /// Error when changing which persona a sent message is from fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to change message persona'**
  String get personaChangeMessageFailed;

  /// Toast after the backslash command clears the active persona.
  ///
  /// In en, this message translates to:
  /// **'Active persona cleared'**
  String get personaActiveCleared;

  /// Accessible name of the KLIPY attribution mark in the GIF picker. KLIPY is a brand name, in capitals.
  ///
  /// In en, this message translates to:
  /// **'Powered by KLIPY'**
  String get klipyPoweredBy;

  /// Toast when saving a persona that lists the same tag pair twice; {pattern} shows the pair, such as a:text.
  ///
  /// In en, this message translates to:
  /// **'Duplicate tag pair \'{pattern}\' on this persona'**
  String personaTagPairDuplicate(String pattern);

  /// Button that adds a tag pair to a persona, with how many it has out of the maximum of five.
  ///
  /// In en, this message translates to:
  /// **'Add Tag Pair ({count}/5)'**
  String personaAddTagPair(int count);

  /// Stands for the message text between a tag pair's prefix and suffix inputs, as in a:text.
  ///
  /// In en, this message translates to:
  /// **'text'**
  String get personaTagExampleText;

  /// Name in the display tag preview when neither a persona nor the account has a name to show.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get personaPreviewNameFallback;

  /// Subtitle of the sheet that asks, after the app closed unexpectedly, whether to send crash reports. Replaces upstream's observabilityReportingConsentSubtitle, which names Fluxer.
  ///
  /// In en, this message translates to:
  /// **'Tyne closed unexpectedly. Sharing anonymous crash and error data helps us fix issues faster.'**
  String get crashReportingConsentSubtitle;

  /// Description of the crash and performance reporting section in Advanced settings. Replaces upstream's advancedCrashReportingSectionDescription, which names Fluxer.
  ///
  /// In en, this message translates to:
  /// **'Help fix bugs in Tyne by sharing crash and performance data. This is off by default.'**
  String get crashReportingSectionDescription;

  /// Description of the crash and performance reporting switch: where reports go and what they leave out. Replaces upstream's advancedCrashReportingDescription, which names Fluxer's error tracker.
  ///
  /// In en, this message translates to:
  /// **'Reports go to Tyne\'s own error tracker, even when you\'re signed in to another instance. They don\'t include instance names, IDs or message content.'**
  String get crashReportingDescription;

  /// Title on the screen shown while the app cannot reach the instance, and on the splash screen when the instance reports it is unavailable. Replaces upstream's reconnectingTitle ("We fluxed up!"), which names Fluxer, and splashConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Tyne is offline!'**
  String get instanceOfflineTitle;

  /// Text under instanceOfflineTitle. Replaces upstream's reconnectingBody, which promises the outage will be fixed in a second.
  ///
  /// In en, this message translates to:
  /// **'We\'re investigating.'**
  String get instanceOfflineBody;

  /// Link to the instance's status page when that page is a Signal group chat; other status pages use upstream's splashStatusPageLink ("Status page").
  ///
  /// In en, this message translates to:
  /// **'Join our Signal chat for updates'**
  String get instanceStatusSignalLink;

  /// Switch in Settings > Messages & media > Input. When on, text emoticons such as :) and <3 are turned into emoji when a message is sent or edited. Synced with the web app's setting of the same name (tyne-chat/tyne#260).
  ///
  /// In en, this message translates to:
  /// **'Turn text smileys into emoji'**
  String get convertEmoticonsLabel;

  /// Shown in the channel when a community command fails. {name} is the command, {detail} the reason. Keep the same wording as the web app.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t run /{name}: {detail}'**
  String guildCommandFailed(String name, String detail);

  /// Why a community command could not run, shown after "Couldn't run /name:".
  ///
  /// In en, this message translates to:
  /// **'Its script has a problem.'**
  String get guildCommandBroken;

  /// Shown in the channel when a community command is sent with a line break in its input. {name} is the command.
  ///
  /// In en, this message translates to:
  /// **'What you type after /{name} has to fit on one line.'**
  String guildCommandOneLine(String name);

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Create commands'**
  String get permissionCreateCommands;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Manage commands'**
  String get permissionManageCommands;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Use external commands'**
  String get permissionUseExternalCommands;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Create commands for this community, and edit or delete your own.'**
  String get permissionCreateCommandsDescription;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Edit or delete anyone\'s commands in this community.'**
  String get permissionManageCommandsDescription;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Use commands from other communities.'**
  String get permissionUseExternalCommandsDescription;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Use commands from other communities in this channel.'**
  String get permissionUseExternalCommandsChannelDescription;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Message Tools'**
  String get guildSettingsCategoryMessageTools;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get guildSettingsCommands;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the commands.'**
  String get guildCommandsLoadFailed;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Messages members can post by typing /name.'**
  String get guildCommandsSubtitle;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Command slots'**
  String get guildCommandsSlots;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'New command'**
  String get guildCommandsNew;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Search commands'**
  String get guildCommandsSearch;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'No commands'**
  String get guildCommandsEmptyTitle;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'This community doesn\'t have any commands yet.'**
  String get guildCommandsEmptyBody;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Commands saved'**
  String get guildCommandsSaved;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save /{name}: {detail}'**
  String guildCommandSaveFailed(String name, String detail);

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Edit /{name}'**
  String guildCommandEdit(String name);

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Delete /{name}?'**
  String guildCommandDeleteTitle(String name);

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone. Messages made with it still show which command made them.'**
  String get guildCommandDeleteBody;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get guildCommandDelete;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Delete command'**
  String get guildCommandDeleteCommand;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get guildCommandSectionCommand;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get guildCommandName;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Use lowercase letters, numbers, - and _, up to 32 characters.'**
  String get guildCommandNameInvalid;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Another command or a built-in command already has this name.'**
  String get guildCommandNameTaken;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get guildCommandDescription;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get guildCommandSectionInput;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get guildCommandInputNone;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get guildCommandInputOptional;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get guildCommandInputRequired;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get guildCommandHint;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get guildCommandMessage;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Insert:'**
  String get guildCommandInsert;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Person running it'**
  String get guildCommandInsertPerson;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'What they type'**
  String get guildCommandInsertInput;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get guildCommandPreview;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Sample input'**
  String get guildCommandSampleInput;

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Made with /{name}'**
  String guildCommandMadeWith(String name);

  /// Community commands on the phone. Same wording as the web app's string.
  ///
  /// In en, this message translates to:
  /// **'Clear the message box to use /{name}'**
  String guildCommandClearBox(String name);

  /// Shown on the phone when a community command's message is left empty, so it cannot be saved.
  ///
  /// In en, this message translates to:
  /// **'This would post nothing, so the command would fail.'**
  String get guildCommandEmptyMessage;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Use the script editor'**
  String get guildCommandUseScriptEditor;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Use the basic editor'**
  String get guildCommandUseBasicEditor;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Script'**
  String get guildCommandScript;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Run again'**
  String get guildCommandRunAgain;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'There\'s no tag called {name}.'**
  String guildCommandIssueUnknownTag(String name);

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'There\'s no filter called {name}.'**
  String guildCommandIssueUnknownFilter(String name);

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'{name} is never closed.'**
  String guildCommandIssueNotClosed(String name);

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'The script is too long.'**
  String get guildCommandIssueTooLong;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'The script builds too much text.'**
  String get guildCommandIssueTooLarge;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'The script took too long to run.'**
  String get guildCommandIssueTooSlow;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'This part can\'t be read.'**
  String get guildCommandIssueInvalid;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'This part stopped with an error.'**
  String get guildCommandIssueFailed;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Line {line}, column {column}: {problem}'**
  String guildCommandIssueAt(String line, String column, String problem);

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Script reference'**
  String get guildCommandReferenceTitle;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'The person running it, as a mention'**
  String get guildCommandReferencePerson;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Their name'**
  String get guildCommandReferencePersonName;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'The first person they mention, if any'**
  String get guildCommandReferenceTarget;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'That person’s name'**
  String get guildCommandReferenceTargetName;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'The channel, as a mention'**
  String get guildCommandReferenceChannel;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'The name of this community'**
  String get guildCommandReferenceCommunity;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Pick one option at random'**
  String get guildCommandExampleRandom;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Change the message depending on what they typed'**
  String get guildCommandExampleDepends;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Pick one word at random'**
  String get guildCommandExampleOneWord;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Pick the word for a number'**
  String get guildCommandExampleWordForNumber;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Write a number as 1st, 2nd, 3rd'**
  String get guildCommandExampleOrdinal;

  /// Community command scripts on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Full script guide'**
  String get guildCommandFullGuide;

  /// Community command counters on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Counters'**
  String get guildCommandCounters;

  /// Community command counters on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Add counter'**
  String get guildCommandCounterAdd;

  /// Community command counters on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Count separately for each:'**
  String get guildCommandCounterSeparately;

  /// Community command counters on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Person mentioned'**
  String get guildCommandCounterPersonMentioned;

  /// Community command counters on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get guildCommandCounterChannel;

  /// Community command counters on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Count personas separately'**
  String get guildCommandCounterPersonas;

  /// Community command counters on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Remove counter'**
  String get guildCommandCounterRemove;

  /// Community command counters on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Reset counts'**
  String get guildCommandCounterReset;

  /// Community command counters on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Reset the counts of {name}? This can\'t be undone.'**
  String guildCommandCounterResetConfirm(String name);

  /// Community command counters on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Use lowercase letters, numbers and _, starting with a letter, and not a name scripts already use.'**
  String get guildCommandCounterNameInvalid;

  /// Community command counters on the phone. Same wording as the web app's.
  ///
  /// In en, this message translates to:
  /// **'Use it in a script as {variable}. Each run adds one first, so the first run reads 1.'**
  String guildCommandCounterHowToUse(String variable);
}

class _ForkLocalizationsDelegate
    extends LocalizationsDelegate<ForkLocalizations> {
  const _ForkLocalizationsDelegate();

  @override
  Future<ForkLocalizations> load(Locale locale) {
    return SynchronousFuture<ForkLocalizations>(
      lookupForkLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bg',
    'cs',
    'da',
    'de',
    'el',
    'en',
    'es',
    'fi',
    'fr',
    'he',
    'hi',
    'hr',
    'hu',
    'id',
    'it',
    'ja',
    'ko',
    'lt',
    'nb',
    'nl',
    'pl',
    'pt',
    'ro',
    'ru',
    'sv',
    'th',
    'tr',
    'uk',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_ForkLocalizationsDelegate old) => false;
}

ForkLocalizations lookupForkLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return ForkLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return ForkLocalizationsEnGb();
          case 'US':
            return ForkLocalizationsEnUs();
        }
        break;
      }
    case 'es':
      {
        switch (locale.countryCode) {
          case '419':
            return ForkLocalizationsEs419();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return ForkLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return ForkLocalizationsAr();
    case 'bg':
      return ForkLocalizationsBg();
    case 'cs':
      return ForkLocalizationsCs();
    case 'da':
      return ForkLocalizationsDa();
    case 'de':
      return ForkLocalizationsDe();
    case 'el':
      return ForkLocalizationsEl();
    case 'en':
      return ForkLocalizationsEn();
    case 'es':
      return ForkLocalizationsEs();
    case 'fi':
      return ForkLocalizationsFi();
    case 'fr':
      return ForkLocalizationsFr();
    case 'he':
      return ForkLocalizationsHe();
    case 'hi':
      return ForkLocalizationsHi();
    case 'hr':
      return ForkLocalizationsHr();
    case 'hu':
      return ForkLocalizationsHu();
    case 'id':
      return ForkLocalizationsId();
    case 'it':
      return ForkLocalizationsIt();
    case 'ja':
      return ForkLocalizationsJa();
    case 'ko':
      return ForkLocalizationsKo();
    case 'lt':
      return ForkLocalizationsLt();
    case 'nb':
      return ForkLocalizationsNb();
    case 'nl':
      return ForkLocalizationsNl();
    case 'pl':
      return ForkLocalizationsPl();
    case 'pt':
      return ForkLocalizationsPt();
    case 'ro':
      return ForkLocalizationsRo();
    case 'ru':
      return ForkLocalizationsRu();
    case 'sv':
      return ForkLocalizationsSv();
    case 'th':
      return ForkLocalizationsTh();
    case 'tr':
      return ForkLocalizationsTr();
    case 'uk':
      return ForkLocalizationsUk();
    case 'vi':
      return ForkLocalizationsVi();
    case 'zh':
      return ForkLocalizationsZh();
  }

  throw FlutterError(
    'ForkLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
