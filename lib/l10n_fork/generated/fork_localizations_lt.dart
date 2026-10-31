// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class ForkLocalizationsLt extends ForkLocalizations {
  ForkLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Keisti personą';

  @override
  String get chatAttachmentPanelVoice => 'Garsas';

  @override
  String get advancedSettingQuickSwitcherButtonLabel =>
      'Greitojo perjungiklio mygtukas';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Pakeisti balso pranešimo mygtuką įvesties lauke greituoju perjungikliu patogesnei navigacijai';

  @override
  String get userSettingsCheckForUpdates => 'Tikrinti, ar yra naujinimų';

  @override
  String get userSettingsCheckingForUpdates => 'Tikrinama, ar yra naujinimų…';

  @override
  String get userSettingsAppUpToDate => '„Tyne“ yra atnaujintas';

  @override
  String get userSettingsUpdateAvailableTitle => 'Yra naujinimas';

  @override
  String get userSettingsUpdateDownloadAction => 'Atsisiųsti ir įdiegti';

  @override
  String get userSettingsUpdateInstallAction => 'Įdiegti naujinimą';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Atsisiunčiamas naujinimas ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Nepavyko patikrinti arba atsisiųsti naujinimo.';

  @override
  String get personaSelectTitle => 'Pasirinkite personą';

  @override
  String get personaSettingsHeader => 'Personų nustatymai';

  @override
  String get personaManageAction => 'Tvarkyti';

  @override
  String get personaSearchPlaceholder => 'Ieškoti personų, žymų, įvardžių...';

  @override
  String get personaModeManual => 'Rankinis';

  @override
  String get personaModeLast => 'Paskiausiai naudota';

  @override
  String get personaModeManualDescription =>
      'Visada siunčiama kaip pasirinkta persona, kol nepakeista.';

  @override
  String get personaModeLastDescription =>
      'Automatiškai persijungia į personą, naudotą paskutiniame pranešime.';

  @override
  String get personaRecentHeader => 'PASTAROSIOS PERSONOS';

  @override
  String personaAllHeader(int count) {
    return 'VISOS PERSONOS ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'PAIEŠKOS REZULTATAI ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Šakninė paskyra (Numatytoji)';

  @override
  String get personaEmptyState =>
      'Dar nėra sukonfigūruotų personų. Sukurkite skiltyje „Tvarkyti personas“.';

  @override
  String get personaEmptySearch => 'Atitinkančių personų nerasta.';

  @override
  String get personaEditTitle => 'Redaguoti personą';

  @override
  String get personaCreateTitle => 'Sukurti personą';

  @override
  String get personaDisplayNameLabel => 'Rodomasis vardas';

  @override
  String get personaPronounsLabel => 'Įvardžiai';

  @override
  String get personaPronounsHint => 'pvz., jie/jų';

  @override
  String get personaBioHint => 'Papasakokite kitiems apie šią personą...';

  @override
  String get personaUpdatedToast => 'Persona atnaujinta';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Nepavyko atnaujinti personos: $error';
  }

  @override
  String get personaSectionTitle => 'Personos';

  @override
  String get personaDisplayNameHint => 'Personos vardas';

  @override
  String personaSendingAsTag(String name) {
    return 'Siunčiama kaip $name (Atskirta pagal žymą)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Siunčiama kaip $name (Užfiksuota)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Siunčiama kaip $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Skelbiama kaip $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Siunčiama kaip @$username';
  }

  @override
  String get personaMainAccount => 'Pagrindinė paskyra';

  @override
  String get personaEditPersona => 'Redaguoti personą';

  @override
  String get userSettingsNavPersonas => 'Personos';

  @override
  String get personaSettingsDescription =>
      'Konfigūruokite aktyvios personos režimą, pasirinktinę rodomą žymą ir tvarkykite atskiras personas.';

  @override
  String get personaDisplayTagSection => 'Rodoma žyma';

  @override
  String get personaDisplayTagDescription =>
      'Rodoma žyma pasirodys šalia visų personų pavadinimų pranešimuose. Jei rodoma žyma nenustatyta, bus rodoma jūsų paskyros profilio nuotrauka.';

  @override
  String get personaDisplayTagLabel => 'Rodomos žymos tekstas';

  @override
  String get personaDisplayTagHint => 'pvz., SYS';

  @override
  String get personaDisplayTagIconLabel => 'Rodomos žymos piktograma';

  @override
  String get personaUploadTagIcon => 'Įkelti piktogramą';

  @override
  String get personaChangeTagIcon => 'Keisti piktogramą';

  @override
  String get personaRemoveTagIcon => 'Pašalinti piktogramą';

  @override
  String get personaChatPreviewTitle => 'Pokalbio peržiūra';

  @override
  String get personaChatPreviewSampleMessage =>
      'Sveiki! Tai peržiūra, kaip atrodo pranešimai su jūsų rodoma žyma ir aktyvia persona.';

  @override
  String get personaListTitle => 'Sukonfigūruotos personos';

  @override
  String get personaAddButton => 'Pridėti personą';

  @override
  String get personaActiveBadge => 'Aktyvus';

  @override
  String get personaMakeActive => 'Nustatyti kaip aktyvią';

  @override
  String get personaDeleteTitle => 'Ištrinti personą';

  @override
  String personaDeleteMessage(String name) {
    return 'Ar tikrai norite ištrinti „$name“? Šio veiksmo anuliuoti negalima.';
  }

  @override
  String get personaDeleteConfirm => 'Ištrinti';

  @override
  String get personaDeletedToast => 'Persona ištrinta';

  @override
  String get personaCreatedToast => 'Persona sukurta';

  @override
  String personaCreateFailedToast(String error) {
    return 'Nepavyko sukurti personos: $error';
  }

  @override
  String get personaChangeAvatar => 'Keisti avatarą';

  @override
  String get personaRemoveAvatar => 'Pašalinti avatarą';

  @override
  String get personaUploadAvatar => 'Įkelti avatarą';

  @override
  String get personaTagsLabel => 'Personos žymos';

  @override
  String get personaTagPrefixLabel => 'Priešdėlis';

  @override
  String get personaTagSuffixLabel => 'Priesaga';

  @override
  String get personaVisibilityLabel => 'Matomumas';

  @override
  String get personaVisibilityUnlisted => 'Neįtrauktas į sąrašą';

  @override
  String get personaVisibilityPublic => 'Viešas';

  @override
  String get personaVisibilityPrivate => 'Privatus';

  @override
  String get personaNameRequired => 'Įveskite personos rodomą vardą';

  @override
  String get personaNameTooLong =>
      'Personos rodomas vardas negali viršyti 100 simbolių';

  @override
  String get personaTagPrefixTooLong =>
      'Personos žymos priešdėlis negali viršyti 32 simbolių';

  @override
  String get personaTagSuffixTooLong =>
      'Personos žymos galūnė negali viršyti 32 simbolių';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Žymą „$tag“ jau naudoja „$name“.';
  }

  @override
  String get chatInsertTimestamp => 'Įterpti laiko žymą';

  @override
  String get chatAttachmentSendVoiceMessage => 'Siųsti balso žinutę';

  @override
  String get timestampPickerTitle => 'Įterpti laiko žymą';

  @override
  String get timestampPickerInsert => 'Įterpti';

  @override
  String get timestampCopied => 'Laiko žyma nukopijuota';

  @override
  String get timestampPickerTimeLabel => 'Laikas';

  @override
  String get timestampPickerDateLabel => 'DATA';

  @override
  String get timestampPickerTimeSectionLabel => 'LAIKAS';

  @override
  String get timestampPickerTimezoneLabel => 'LAIKO JUOSTA';

  @override
  String get timestampPickerFormatPreviewLabel => 'FORMATO PERŽIŪRA';

  @override
  String get timestampPickerNlpPlaceholder =>
      'pvz., rytoj 15:00, po 2 valandų, dabar';

  @override
  String get timestampPickerSearchTimezones => 'Ieškoti laiko juostų...';

  @override
  String get userProfileTimezoneSettingLabel => 'Laiko juosta';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Naudojama vietiniam laikui rodyti jūsų profilyje.';

  @override
  String get userProfileTimezoneNone => 'Nėra';

  @override
  String get chatReactAs => 'Reaguoti kaip...';

  @override
  String get emojiCopy => 'Kopijuoti jaustuką';

  @override
  String get emojiCopyLink => 'Kopijuoti nuorodą';

  @override
  String get emojiPin => 'Prisegti jaustuką';

  @override
  String get emojiUnpin => 'Atsegti jaustuką';

  @override
  String get emojiPinForPersona => 'Prisegti šiai personai';

  @override
  String get emojiUnpinForPersona => 'Atsegti šiai personai';

  @override
  String get personaSignatureEmojisLabel => 'Parašo jaustukai';

  @override
  String get personaSignatureEmojisDescription =>
      'Reagavimas su parašo jaustuku visada reaguos kaip šis profilis, nepriklausomai nuo aktyvaus profilio.';

  @override
  String get personaAddSignatureEmoji => 'Pridėti jaustuką';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Šis jaustukas jau pridėtas kaip parašo jaustukas';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Parašo jaustuką jau naudoja profilis „$name“';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Pašalinti parašo jaustuką';

  @override
  String get signalBarLabel => 'Signalų juosta';

  @override
  String get signalBarShow => 'Rodyti signalų juostą';

  @override
  String get signalBarHide => 'Slėpti signalų juostą';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Niekas neįjungė šio signalo';

  @override
  String get signalBarReset => 'Atstatyti signalą visiems';

  @override
  String signalBarTurnOff(String name) {
    return 'Išjungti $name';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Numatytajam egzemplioriui naudokite $domain arba įveskite tikslų kito egzemplioriaus URL.';
  }

  @override
  String get instanceResetToDefault => 'Atstatyti numatytąjį egzempliorių';

  @override
  String get personaScopeTitle => 'Persona taikoma';

  @override
  String get personaScopeGlobal => 'Visur';

  @override
  String get personaScopeGlobalDescription => 'Viena persona visiems kanalams.';

  @override
  String get personaScopeChannel => 'Kiekviename kanale';

  @override
  String get personaScopeChannelDescription =>
      'Kiekvienas kanalas išlaiko savo personą. Nauji kanalai prasideda kaip jūsų paskyra.';

  @override
  String get personaPickerChannelOnly => 'Tik šiam kanalui';

  @override
  String get personaProfilePrivate => 'Šios personos profilis yra privatus.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Vaizdo failas yra per didelis. Pasirinkite failą, mažesnį nei $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Ieškoti KLIPY';

  @override
  String get appUpdateDownloadFailed => 'Nepavyko atsisiųsti atnaujinimo';

  @override
  String get appUpdateInstallFailed => 'Nepavyko įdiegti atnaujinimo';

  @override
  String get personaChangeMessageFailed => 'Nepavyko pakeisti žinutės personos';

  @override
  String get personaActiveCleared => 'Aktyvi persona išvalyta';

  @override
  String get klipyPoweredBy => 'Teikia KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Pasikartojanti žymų pora „$pattern“ šioje personoje';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Pridėti žymų porą ($count/5)';
  }

  @override
  String get personaTagExampleText => 'tekstas';

  @override
  String get personaPreviewNameFallback => 'Naudotojas';

  @override
  String get crashReportingConsentSubtitle =>
      '„Tyne“ netikėtai užsidarė. Dalindamasis anoniminiais strigčių ir klaidų duomenimis padedi mums greičiau ištaisyti problemas.';

  @override
  String get crashReportingSectionDescription =>
      'Padėk taisyti „Tyne“ klaidas dalindamasis strigčių ir našumo duomenimis. Pagal numatytuosius nustatymus išjungta.';

  @override
  String get crashReportingDescription =>
      'Ataskaitos siunčiamos į pačios „Tyne“ klaidų sekimo sistemą, net jei prisijungta prie kito serverio. Jose nėra serverių pavadinimų, ID ar žinučių turinio.';

  @override
  String get instanceOfflineTitle => '„Tyne“ neveikia!';

  @override
  String get instanceOfflineBody => 'Aiškinamės, kas nutiko.';

  @override
  String get instanceStatusSignalLink =>
      'Prisijunk prie mūsų „Signal“ pokalbio ir sužinok naujienas';

  @override
  String get convertEmoticonsLabel => 'Keisti tekstines šypsenėles jaustukais';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Nepavyko įvykdyti /$name: $detail';
  }

  @override
  String get guildCommandBroken => 'Jos scenarijuje yra problema.';

  @override
  String guildCommandOneLine(String name) {
    return 'Tai, ką įvedate po /$name, turi tilpti vienoje eilutėje.';
  }

  @override
  String get permissionCreateCommands => 'Kurti komandas';

  @override
  String get permissionManageCommands => 'Tvarkyti komandas';

  @override
  String get permissionUseExternalCommands => 'Naudoti išorines komandas';

  @override
  String get permissionCreateCommandsDescription =>
      'Kurti šios bendruomenės komandas ir redaguoti ar ištrinti savo.';

  @override
  String get permissionManageCommandsDescription =>
      'Redaguoti ar ištrinti bet kurio nario komandas šioje bendruomenėje.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Naudoti kitų bendruomenių komandas.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Naudoti kitų bendruomenių komandas šiame kanale.';

  @override
  String get guildSettingsCategoryMessageTools => 'Žinučių įrankiai';

  @override
  String get guildSettingsCommands => 'Komandos';

  @override
  String get guildCommandsLoadFailed => 'Nepavyko įkelti komandų.';

  @override
  String get guildCommandsSubtitle =>
      'Žinutės, kurias nariai gali paskelbti įvesdami /name.';

  @override
  String get guildCommandsSlots => 'Komandų vietos';

  @override
  String get guildCommandsNew => 'Nauja komanda';

  @override
  String get guildCommandsSearch => 'Ieškoti komandų';

  @override
  String get guildCommandsEmptyTitle => 'Komandų nėra';

  @override
  String get guildCommandsEmptyBody => 'Ši bendruomenė dar neturi komandų.';

  @override
  String get guildCommandsSaved => 'Komandos išsaugotos';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Nepavyko išsaugoti /$name: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Redaguoti /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Ištrinti /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'To negalima atšaukti. Ja sukurtos žinutės vis tiek rodo, kuri komanda jas sukūrė.';

  @override
  String get guildCommandDelete => 'Ištrinti';

  @override
  String get guildCommandDeleteCommand => 'Ištrinti komandą';

  @override
  String get guildCommandSectionCommand => 'Komanda';

  @override
  String get guildCommandName => 'Pavadinimas';

  @override
  String get guildCommandNameInvalid =>
      'Naudokite mažąsias raides, skaičius, - ir _, ne daugiau kaip 32 simbolius.';

  @override
  String get guildCommandNameTaken =>
      'Kita komanda arba integruota komanda jau turi šį pavadinimą.';

  @override
  String get guildCommandDescription => 'Aprašymas';

  @override
  String get guildCommandSectionInput => 'Įvestis';

  @override
  String get guildCommandInputNone => 'Nėra';

  @override
  String get guildCommandInputOptional => 'Neprivaloma';

  @override
  String get guildCommandInputRequired => 'Būtina';

  @override
  String get guildCommandHint => 'Užuomina';

  @override
  String get guildCommandMessage => 'Žinutė';

  @override
  String get guildCommandInsert => 'Įterpti:';

  @override
  String get guildCommandInsertPerson => 'Ją naudojantis asmuo';

  @override
  String get guildCommandInsertInput => 'Ką jie įveda';

  @override
  String get guildCommandPreview => 'Peržiūra';

  @override
  String get guildCommandSampleInput => 'Pavyzdinė įvestis';

  @override
  String guildCommandMadeWith(String name) {
    return 'Sukurta su /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Išvalykite žinutės laukelį, kad galėtumėte naudoti /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Nieko nebūtų paskelbta, todėl komandos nepavyktų įvykdyti.';

  @override
  String get guildCommandUseScriptEditor => 'Naudoti scenarijų redaktorių';

  @override
  String get guildCommandUseBasicEditor => 'Naudoti paprastą redaktorių';

  @override
  String get guildCommandScript => 'Scenarijus';

  @override
  String get guildCommandRunAgain => 'Vykdyti dar kartą';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Žymos $name nėra.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Filtro $name nėra.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name niekada neužsidaro.';
  }

  @override
  String get guildCommandIssueTooLong => 'Scenarijus per ilgas.';

  @override
  String get guildCommandIssueTooLarge => 'Scenarijus sukuria per daug teksto.';

  @override
  String get guildCommandIssueTooSlow =>
      'Scenarijaus vykdymas užtruko per ilgai.';

  @override
  String get guildCommandIssueInvalid => 'Šios dalies nepavyksta perskaityti.';

  @override
  String get guildCommandIssueFailed => 'Ši dalis sustojo dėl klaidos.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Eilutė $line, stulpelis $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Scenarijų žinynas';

  @override
  String get guildCommandReferencePerson =>
      'Ją naudojantis asmuo kaip paminėjimas';

  @override
  String get guildCommandReferencePersonName => 'Ją naudojančio asmens vardas';

  @override
  String get guildCommandReferenceTarget =>
      'Pirmas paminėtas asmuo, jei toks yra';

  @override
  String get guildCommandReferenceTargetName => 'To asmens vardas';

  @override
  String get guildCommandReferenceChannel => 'Kanalas kaip paminėjimas';

  @override
  String get guildCommandReferenceCommunity => 'Šios bendruomenės pavadinimas';

  @override
  String get guildCommandExampleRandom =>
      'Atsitiktinai pasirinkti vieną parinktį';

  @override
  String get guildCommandExampleDepends =>
      'Keisti žinutę pagal tai, kas įvesta';

  @override
  String get guildCommandExampleOneWord => 'Atsitiktinai pasirinkti vieną žodį';

  @override
  String get guildCommandExampleWordForNumber =>
      'Pasirinkti žodį pagal skaičių';

  @override
  String get guildCommandExampleOrdinal => 'Rašyti skaičių kaip 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Išsamus scenarijų vadovas';

  @override
  String get guildCommandCounters => 'Skaitikliai';

  @override
  String get guildCommandCounterAdd => 'Pridėti skaitiklį';

  @override
  String get guildCommandCounterSeparately => 'Skaičiuoti atskirai kiekvienam:';

  @override
  String get guildCommandCounterPersonMentioned => 'Paminėtas asmuo';

  @override
  String get guildCommandCounterChannel => 'Kanalas';

  @override
  String get guildCommandCounterPersonas => 'Skaičiuoti personas atskirai';

  @override
  String get guildCommandCounterRemove => 'Pašalinti skaitiklį';

  @override
  String get guildCommandCounterReset => 'Nustatyti skaičius iš naujo';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Nustatyti $name skaičius iš naujo? To atšaukti negalima.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Naudok mažąsias raides, skaičius ir _, pradėk raide ir nerink vardo, kurį jau naudoja scenarijai.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Scenarijuje naudok kaip $variable. Kiekvienas paleidimas pirmiausia prideda vienetą, todėl pirmas nuskaito 1.';
  }
}
