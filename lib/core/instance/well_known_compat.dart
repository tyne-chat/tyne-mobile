import 'package:fluxer_dart/export.dart';

const Map<String, Object> _featureDefaultsForOlderServers = <String, Object>{
  'phone_verification_enabled': false,
};

WellKnownFluxerResponse _parseWellKnownFluxer(Map<String, dynamic> json) {
  final Object? features = json['features'];
  if (features is! Map) {
    return WellKnownFluxerResponse.fromJson(json);
  }
  final Map<String, dynamic> filledFeatures = Map<String, dynamic>.from(
    features,
  );
  _featureDefaultsForOlderServers.forEach((String key, Object value) {
    filledFeatures.putIfAbsent(key, () => value);
  });
  return WellKnownFluxerResponse.fromJson(<String, dynamic>{
    ...json,
    'features': filledFeatures,
  });
}

// Fork: the SDK types `hidden_built_in_guild_badges` as one enum value, but the
// server sends a list, so parsing fails on any document that has the key, an
// empty list included (tyne-chat/tyne#454). Nothing in the app reads the field.
// Remove this when the SDK's type is a list.
WellKnownFluxerResponse parseWellKnownFluxer(Map<String, dynamic> json) {
  return _parseWellKnownFluxer(
    Map<String, dynamic>.from(json)..remove('hidden_built_in_guild_badges'),
  );
}
