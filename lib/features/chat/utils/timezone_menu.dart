import 'package:fluxer_app/features/chat/utils/timezone_menu_data.dart';

/// Fork: what the time zone menus offer (tyne-chat/tyne#429). Lookups use the
/// whole database, so any valid name gives the right time, while the menus show
/// IANA's current names and the older ones lead to their current entry.

/// Whether [name] gets an entry of its own in a time zone menu.
bool isMenuTimezone(String name) =>
    name == 'UTC' || kOfficialTimezoneNames.contains(name);

/// The menu entry for [name]: its current name when it has one.
String timezoneMenuName(String name) => kTimezoneAliases[name] ?? name;

final Map<String, List<String>> _aliasesByEntry = () {
  final Map<String, List<String>> byEntry = <String, List<String>>{};
  kTimezoneAliases.forEach((String alias, String entry) {
    (byEntry[entry] ??= <String>[]).add(alias);
  });
  return byEntry;
}();

/// The older names of the entry [name], for the menus' search: Saigon finds
/// Ho Chi Minh without being an entry itself.
String timezoneAliasSearchTerms(String name) {
  final List<String>? aliases = _aliasesByEntry[name];
  if (aliases == null) {
    return '';
  }
  return aliases
      .map((String alias) => alias.replaceAll('_', ' ').replaceAll('/', ' '))
      .join(' ');
}
