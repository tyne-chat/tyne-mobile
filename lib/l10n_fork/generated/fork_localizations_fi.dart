// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fork_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class ForkLocalizationsFi extends ForkLocalizations {
  ForkLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get chatMessageChangePersona => 'Vaihda persoonaa';

  @override
  String get chatAttachmentPanelVoice => 'Ääni';

  @override
  String get advancedSettingQuickSwitcherButtonLabel => 'Pikavaihdin-painike';

  @override
  String get advancedSettingQuickSwitcherButtonDescription =>
      'Korvaa viestikentän ääniviestipainike pikavaihtimella nopeaa siirtymistä varten';

  @override
  String get userSettingsCheckForUpdates => 'Tarkista päivitykset';

  @override
  String get userSettingsCheckingForUpdates => 'Tarkistetaan päivityksiä…';

  @override
  String get userSettingsAppUpToDate => 'Tyne on ajan tasalla';

  @override
  String get userSettingsUpdateAvailableTitle => 'Päivitys saatavilla';

  @override
  String get userSettingsUpdateDownloadAction => 'Lataa ja asenna';

  @override
  String get userSettingsUpdateInstallAction => 'Asenna päivitys';

  @override
  String userSettingsDownloadingUpdate(int percent) {
    return 'Ladataan päivitystä ($percent %)…';
  }

  @override
  String get userSettingsUpdateFailed =>
      'Päivityksen tarkistaminen tai lataaminen epäonnistui.';

  @override
  String get personaSelectTitle => 'Valitse persoona';

  @override
  String get personaSettingsHeader => 'Persoona-asetukset';

  @override
  String get personaManageAction => 'Hallitse';

  @override
  String get personaSearchPlaceholder =>
      'Hae persoonia, tunnisteita, pronomineja...';

  @override
  String get personaModeManual => 'Manuaalinen';

  @override
  String get personaModeLast => 'Viimeksi käytetty';

  @override
  String get personaModeManualDescription =>
      'Lähettää aina valittuna persoonana, kunnes muutetaan.';

  @override
  String get personaModeLastDescription =>
      'Vaihtaa automaattisesti viimeisimmässä viestissäsi käytettyyn persoonaan.';

  @override
  String get personaRecentHeader => 'VIIMEAIKAISET PERSOONAT';

  @override
  String personaAllHeader(int count) {
    return 'KAIKKI PERSOONAT ($count)';
  }

  @override
  String personaSearchResultsHeader(int count) {
    return 'HAKUTULOKSET ($count)';
  }

  @override
  String get personaRootAccountLabel => 'Päätili (Oletus)';

  @override
  String get personaEmptyState =>
      'Persoonia ei ole vielä määritetty. Luo sellainen kohdasta Hallitse persoonia.';

  @override
  String get personaEmptySearch => 'Vastaavia persoonia ei löytynyt.';

  @override
  String get personaEditTitle => 'Muokkaa persoonaa';

  @override
  String get personaCreateTitle => 'Luo persoona';

  @override
  String get personaDisplayNameLabel => 'Näyttönimi';

  @override
  String get personaPronounsLabel => 'Pronominit';

  @override
  String get personaPronounsHint => 'esim. hän/hänelle';

  @override
  String get personaBioHint => 'Kerro muille tästä persoonasta...';

  @override
  String get personaUpdatedToast => 'Persoona päivitetty';

  @override
  String personaUpdateFailedToast(String error) {
    return 'Persoonan päivittäminen epäonnistui: $error';
  }

  @override
  String get personaSectionTitle => 'Persoonat';

  @override
  String get personaDisplayNameHint => 'Persoonan nimi';

  @override
  String personaSendingAsTag(String name) {
    return 'Lähetetään nimellä $name (yhdistetty tunnisteella)';
  }

  @override
  String personaSendingAsLatched(String name) {
    return 'Lähetetään nimellä $name (lukittu)';
  }

  @override
  String personaSendingAs(String name) {
    return 'Lähetetään nimellä $name';
  }

  @override
  String personaPostingAs(String name) {
    return 'Julkaistaan nimellä $name';
  }

  @override
  String personaSendingAsRoot(String username) {
    return 'Lähetetään tunnuksella @$username';
  }

  @override
  String get personaMainAccount => 'Päätili';

  @override
  String get personaEditPersona => 'Muokkaa persoonaa';

  @override
  String get userSettingsNavPersonas => 'Persoonat';

  @override
  String get personaSettingsDescription =>
      'Määritä aktiivisen persoonan tila, mukautettu näyttötunniste ja hallitse yksittäisiä persoonia.';

  @override
  String get personaDisplayTagSection => 'Näyttötunniste';

  @override
  String get personaDisplayTagDescription =>
      'Näyttötunniste näkyy kaikkien persoonien nimien vieressä viesteissä. Jos näyttötunnistetta ei ole asetettu, näytetään tilisi profiilikuva.';

  @override
  String get personaDisplayTagLabel => 'Näyttötunnisteen teksti';

  @override
  String get personaDisplayTagHint => 'esim. SYS';

  @override
  String get personaDisplayTagIconLabel => 'Näyttötunnisteen kuvake';

  @override
  String get personaUploadTagIcon => 'Lataa kuvake';

  @override
  String get personaChangeTagIcon => 'Vaihda kuvake';

  @override
  String get personaRemoveTagIcon => 'Poista kuvake';

  @override
  String get personaChatPreviewTitle => 'Keskustelun esikatselu';

  @override
  String get personaChatPreviewSampleMessage =>
      'Hei! Tämä on esikatselu siitä, miltä viestit näyttävät näyttötunnisteellasi ja aktiivisella persoonallasi.';

  @override
  String get personaListTitle => 'Määritetyt persoonat';

  @override
  String get personaAddButton => 'Lisää persoona';

  @override
  String get personaActiveBadge => 'Aktiivinen';

  @override
  String get personaMakeActive => 'Aseta aktiiviseksi';

  @override
  String get personaDeleteTitle => 'Poista persoona';

  @override
  String personaDeleteMessage(String name) {
    return 'Haluatko varmasti poistaa kohteen \"$name\"? Tätä ei voi perua.';
  }

  @override
  String get personaDeleteConfirm => 'Poista';

  @override
  String get personaDeletedToast => 'Persoona poistettu';

  @override
  String get personaCreatedToast => 'Persoona luotu';

  @override
  String personaCreateFailedToast(String error) {
    return 'Persoonan luominen epäonnistui: $error';
  }

  @override
  String get personaChangeAvatar => 'Vaihda avatar';

  @override
  String get personaRemoveAvatar => 'Poista avatar';

  @override
  String get personaUploadAvatar => 'Lataa avatar';

  @override
  String get personaTagsLabel => 'Persoonatunnisteet';

  @override
  String get personaTagPrefixLabel => 'Etuliite';

  @override
  String get personaTagSuffixLabel => 'Jälkiliite';

  @override
  String get personaVisibilityLabel => 'Näkyvyys';

  @override
  String get personaVisibilityUnlisted => 'Piilotettu';

  @override
  String get personaVisibilityPublic => 'Julkinen';

  @override
  String get personaVisibilityPrivate => 'Yksityinen';

  @override
  String get personaNameRequired => 'Anna persoonan näyttönimi';

  @override
  String get personaNameTooLong =>
      'Persoonan näyttönimi saa olla enintään 100 merkkiä';

  @override
  String get personaTagPrefixTooLong =>
      'Persoonatunnisteen etuliite saa olla enintään 32 merkkiä';

  @override
  String get personaTagSuffixTooLong =>
      'Persoonatunnisteen jälkiliite saa olla enintään 32 merkkiä';

  @override
  String personaTagCollisionError(String tag, String name) {
    return 'Tunniste \'$tag\' on jo käytössä persoonalla \'$name\'.';
  }

  @override
  String get chatInsertTimestamp => 'Lisää aikaleima';

  @override
  String get chatAttachmentSendVoiceMessage => 'Lähetä ääniviesti';

  @override
  String get timestampPickerTitle => 'Lisää aikaleima';

  @override
  String get timestampPickerInsert => 'Lisää';

  @override
  String get timestampCopied => 'Aikaleima kopioitu';

  @override
  String get timestampPickerTimeLabel => 'Aika';

  @override
  String get timestampPickerDateLabel => 'PÄIVÄMÄÄRÄ';

  @override
  String get timestampPickerTimeSectionLabel => 'AIKA';

  @override
  String get timestampPickerTimezoneLabel => 'AIKAVYÖHYKE';

  @override
  String get timestampPickerFormatPreviewLabel => 'MUODON ESIKATSELU';

  @override
  String get timestampPickerNlpPlaceholder =>
      'esim. huomenna klo 15, 2 tunnin kuluttua, nyt';

  @override
  String get timestampPickerSearchTimezones => 'Hae aikavyöhykkeitä...';

  @override
  String get userProfileTimezoneSettingLabel => 'Aikavyöhyke';

  @override
  String get userProfileTimezoneSettingDescription =>
      'Käytetään paikallisen aikasi näyttämiseen profiilissasi.';

  @override
  String get userProfileTimezoneNone => 'Ei mitään';

  @override
  String get chatReactAs => 'Reagoi käyttäjänä...';

  @override
  String get emojiCopy => 'Kopioi emoji';

  @override
  String get emojiCopyLink => 'Kopioi linkki';

  @override
  String get emojiPin => 'Kiinnitä emoji';

  @override
  String get emojiUnpin => 'Irrota emoji';

  @override
  String get emojiPinForPersona => 'Kiinnitä tälle persoonalle';

  @override
  String get emojiUnpinForPersona => 'Irrota tältä persoonalta';

  @override
  String get personaSignatureEmojisLabel => 'Nimikkoemojit';

  @override
  String get personaSignatureEmojisDescription =>
      'Nimikkoemojilla reagoiminen reagoi aina tällä persoonalla aktiivisesta persoonasta riippumatta.';

  @override
  String get personaAddSignatureEmoji => 'Lisää emoji';

  @override
  String get personaSignatureEmojiAlreadyAdded =>
      'Tämä emoji on jo lisätty nimikkoemojiksi';

  @override
  String personaSignatureEmojiAlreadyUsedByOther(String name) {
    return 'Nimikkoemoji on jo käytössä persoonalla \"$name\"';
  }

  @override
  String get personaRemoveSignatureEmoji => 'Poista nimikkoemoji';

  @override
  String get signalBarLabel => 'Signaalipalkki';

  @override
  String get signalBarShow => 'Näytä signaalipalkki';

  @override
  String get signalBarHide => 'Piilota signaalipalkki';

  @override
  String signalBarSignalWithNames(String label, String names) {
    return '$label: $names';
  }

  @override
  String get signalBarNobody => 'Kenelläkään ei ole tätä signaalia päällä';

  @override
  String get signalBarReset => 'Nollaa signaali kaikilta';

  @override
  String signalBarTurnOff(String name) {
    return 'Kytke $name pois';
  }

  @override
  String instanceUrlHelperDefault(String domain) {
    return 'Käytä oletusinstanssille osoitetta $domain tai anna toisen instanssin tarkka URL-osoite.';
  }

  @override
  String get instanceResetToDefault => 'Palauta oletusinstanssi';

  @override
  String get personaScopeTitle => 'Persoona koskee';

  @override
  String get personaScopeGlobal => 'Kaikkialla';

  @override
  String get personaScopeGlobalDescription =>
      'Yksi persoona kaikille kanaville.';

  @override
  String get personaScopeChannel => 'Kullakin kanavalla';

  @override
  String get personaScopeChannelDescription =>
      'Jokainen kanava säilyttää oman persoonansa. Uudet kanavat alkavat tilinäsi.';

  @override
  String get personaPickerChannelOnly => 'Vain tälle kanavalle';

  @override
  String get personaProfilePrivate => 'Tämän persoonan profiili on yksityinen.';

  @override
  String imageFileTooLargeMaxSize(String maxSize) {
    return 'Kuvatiedosto on liian suuri. Valitse tiedosto, joka on pienempi kuin $maxSize.';
  }

  @override
  String get gifPickerSearchKlipyBrand => 'Hae KLIPYstä';

  @override
  String get appUpdateDownloadFailed => 'Päivityksen lataaminen epäonnistui';

  @override
  String get appUpdateInstallFailed => 'Päivityksen asentaminen epäonnistui';

  @override
  String get personaChangeMessageFailed =>
      'Viestin persoonan vaihtaminen epäonnistui';

  @override
  String get personaActiveCleared => 'Aktiivinen persoona poistettu';

  @override
  String get klipyPoweredBy => 'Palvelun tarjoaa KLIPY';

  @override
  String personaTagPairDuplicate(String pattern) {
    return 'Tunnistepari \'$pattern\' on jo tällä persoonalla';
  }

  @override
  String personaAddTagPair(int count) {
    return 'Lisää tunnistepari ($count/5)';
  }

  @override
  String get personaTagExampleText => 'teksti';

  @override
  String get personaPreviewNameFallback => 'Käyttäjä';

  @override
  String get crashReportingConsentSubtitle =>
      'Tyne sulkeutui odottamatta. Nimettömien kaatumis- ja virhetietojen jakaminen auttaa meitä korjaamaan ongelmat nopeammin.';

  @override
  String get crashReportingSectionDescription =>
      'Auta korjaamaan Tyne-sovelluksen virheitä jakamalla kaatumis- ja suorituskykytietoja. Tämä on oletuksena pois päältä.';

  @override
  String get crashReportingDescription =>
      'Raportit lähetetään Tyne-sovelluksen omaan virheenseurantaan, vaikka olisit kirjautuneena toiseen instanssiin. Ne eivät sisällä instanssien nimiä, tunnisteita tai viestien sisältöä.';

  @override
  String get instanceOfflineTitle => 'Tyne ei ole tavoitettavissa!';

  @override
  String get instanceOfflineBody => 'Selvitämme asiaa.';

  @override
  String get instanceStatusSignalLink =>
      'Liity Signal-keskusteluumme saadaksesi tietoa';

  @override
  String get convertEmoticonsLabel => 'Muunna tekstihymiöt emojeiksi';

  @override
  String guildCommandFailed(String name, String detail) {
    return 'Komentoa /$name ei voitu suorittaa: $detail';
  }

  @override
  String get guildCommandBroken => 'Sen skriptissä on ongelma.';

  @override
  String guildCommandOneLine(String name) {
    return 'Komennon /$name jälkeen kirjoittamasi tekstin on mahduttava yhdelle riville.';
  }

  @override
  String get permissionCreateCommands => 'Luo komentoja';

  @override
  String get permissionManageCommands => 'Hallitse komentoja';

  @override
  String get permissionUseExternalCommands => 'Käytä ulkoisia komentoja';

  @override
  String get permissionCreateCommandsDescription =>
      'Luo komentoja tälle yhteisölle ja muokkaa tai poista omiasi.';

  @override
  String get permissionManageCommandsDescription =>
      'Muokkaa tai poista kenen tahansa komentoja tässä yhteisössä.';

  @override
  String get permissionUseExternalCommandsDescription =>
      'Käytä muiden yhteisöjen komentoja.';

  @override
  String get permissionUseExternalCommandsChannelDescription =>
      'Käytä muiden yhteisöjen komentoja tällä kanavalla.';

  @override
  String get guildSettingsCategoryMessageTools => 'Viestityökalut';

  @override
  String get guildSettingsCommands => 'Komennot';

  @override
  String get guildCommandsLoadFailed => 'Komentoja ei voitu ladata.';

  @override
  String get guildCommandsSubtitle =>
      'Viestejä, joita jäsenet voivat lähettää kirjoittamalla /name.';

  @override
  String get guildCommandsSlots => 'Komentopaikat';

  @override
  String get guildCommandsNew => 'Uusi komento';

  @override
  String get guildCommandsSearch => 'Hae komentoja';

  @override
  String get guildCommandsEmptyTitle => 'Ei komentoja';

  @override
  String get guildCommandsEmptyBody =>
      'Tällä yhteisöllä ei ole vielä komentoja.';

  @override
  String get guildCommandsSaved => 'Komennot tallennettu';

  @override
  String guildCommandSaveFailed(String name, String detail) {
    return 'Komentoa /$name ei voitu tallentaa: $detail';
  }

  @override
  String guildCommandEdit(String name) {
    return 'Muokkaa komentoa /$name';
  }

  @override
  String guildCommandDeleteTitle(String name) {
    return 'Poistetaanko /$name?';
  }

  @override
  String get guildCommandDeleteBody =>
      'Tätä ei voi kumota. Sillä tehdyt viestit näyttävät edelleen, mikä komento ne teki.';

  @override
  String get guildCommandDelete => 'Poista';

  @override
  String get guildCommandDeleteCommand => 'Poista komento';

  @override
  String get guildCommandSectionCommand => 'Komento';

  @override
  String get guildCommandName => 'Nimi';

  @override
  String get guildCommandNameInvalid =>
      'Käytä pieniä kirjaimia, numeroita, - ja _, enintään 32 merkkiä.';

  @override
  String get guildCommandNameTaken =>
      'Toisella komennolla tai sisäänrakennetulla komennolla on jo tämä nimi.';

  @override
  String get guildCommandDescription => 'Kuvaus';

  @override
  String get guildCommandSectionInput => 'Syöttö';

  @override
  String get guildCommandInputNone => 'Ei mitään';

  @override
  String get guildCommandInputOptional => 'Valinnainen';

  @override
  String get guildCommandInputRequired => 'Pakollinen';

  @override
  String get guildCommandHint => 'Vihje';

  @override
  String get guildCommandMessage => 'Viesti';

  @override
  String get guildCommandInsert => 'Lisää:';

  @override
  String get guildCommandInsertPerson => 'Käyttäjä';

  @override
  String get guildCommandInsertInput => 'Mitä kirjoitetaan';

  @override
  String get guildCommandPreview => 'Esikatselu';

  @override
  String get guildCommandSampleInput => 'Esimerkkisyöte';

  @override
  String guildCommandMadeWith(String name) {
    return 'Tehty komennolla /$name';
  }

  @override
  String guildCommandClearBox(String name) {
    return 'Tyhjennä viestikenttä käyttääksesi komentoa /$name';
  }

  @override
  String get guildCommandEmptyMessage =>
      'Tämä ei lähettäisi mitään, joten komento epäonnistuisi.';

  @override
  String get guildCommandUseScriptEditor => 'Käytä skriptimuokkainta';

  @override
  String get guildCommandUseBasicEditor => 'Käytä perusmuokkainta';

  @override
  String get guildCommandScript => 'Skripti';

  @override
  String get guildCommandRunAgain => 'Suorita uudelleen';

  @override
  String guildCommandIssueUnknownTag(String name) {
    return 'Tunnistetta $name ei ole.';
  }

  @override
  String guildCommandIssueUnknownFilter(String name) {
    return 'Suodatinta $name ei ole.';
  }

  @override
  String guildCommandIssueNotClosed(String name) {
    return '$name jää sulkematta.';
  }

  @override
  String get guildCommandIssueTooLong => 'Skripti on liian pitkä.';

  @override
  String get guildCommandIssueTooLarge => 'Skripti tuottaa liikaa tekstiä.';

  @override
  String get guildCommandIssueTooSlow => 'Skriptin suoritus kesti liian kauan.';

  @override
  String get guildCommandIssueInvalid => 'Tätä kohtaa ei voi lukea.';

  @override
  String get guildCommandIssueFailed => 'Tämä kohta pysähtyi virheeseen.';

  @override
  String guildCommandIssueAt(String line, String column, String problem) {
    return 'Rivi $line, sarake $column: $problem';
  }

  @override
  String get guildCommandReferenceTitle => 'Skriptiopas';

  @override
  String get guildCommandReferencePerson => 'Käyttäjä mainintana';

  @override
  String get guildCommandReferencePersonName => 'Käyttäjän nimi';

  @override
  String get guildCommandReferenceTarget =>
      'Ensimmäinen mainittu henkilö, jos sellainen on';

  @override
  String get guildCommandReferenceTargetName => 'Tämän henkilön nimi';

  @override
  String get guildCommandReferenceChannel => 'Kanava mainintana';

  @override
  String get guildCommandReferenceCommunity => 'Tämän yhteisön nimi';

  @override
  String get guildCommandExampleRandom =>
      'Valitse yksi vaihtoehto satunnaisesti';

  @override
  String get guildCommandExampleDepends =>
      'Muuta viestiä sen mukaan, mitä kirjoitettiin';

  @override
  String get guildCommandExampleOneWord => 'Valitse yksi sana satunnaisesti';

  @override
  String get guildCommandExampleWordForNumber => 'Valitse sana luvun mukaan';

  @override
  String get guildCommandExampleOrdinal =>
      'Kirjoita luku muodossa 1st, 2nd, 3rd';

  @override
  String get guildCommandFullGuide => 'Täydellinen skriptiopas';

  @override
  String get guildCommandCounters => 'Laskurit';

  @override
  String get guildCommandCounterAdd => 'Lisää laskuri';

  @override
  String get guildCommandCounterSeparately => 'Laske erikseen jokaiselle:';

  @override
  String get guildCommandCounterPersonMentioned => 'Mainittu henkilö';

  @override
  String get guildCommandCounterChannel => 'Kanava';

  @override
  String get guildCommandCounterPersonas => 'Laske persoonat erikseen';

  @override
  String get guildCommandCounterRemove => 'Poista laskuri';

  @override
  String get guildCommandCounterReset => 'Nollaa laskennat';

  @override
  String guildCommandCounterResetConfirm(String name) {
    return 'Nollataanko laskurin $name laskennat? Tätä ei voi perua.';
  }

  @override
  String get guildCommandCounterNameInvalid =>
      'Käytä pieniä kirjaimia, numeroita ja _-merkkiä, aloita kirjaimella äläkä käytä nimeä, jota skriptit jo käyttävät.';

  @override
  String guildCommandCounterHowToUse(String variable) {
    return 'Käytä sitä skriptissä muodossa $variable. Jokainen suoritus lisää ensin yhden, joten ensimmäinen lukee 1.';
  }
}
