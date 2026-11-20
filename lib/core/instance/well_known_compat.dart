import 'package:fluxer_dart/export.dart';

const Map<String, Object> _featureDefaultsForOlderServers = <String, Object>{
  'phone_verification_enabled': false,
};

const String _kProxyAttachmentsFeature = 'proxy_attachments_through_api';

final Expando<bool> _proxiedAttachments = Expando<bool>(
  _kProxyAttachmentsFeature,
);

bool proxiesAttachmentsThroughApi(WellKnownFluxerResponse response) =>
    _proxiedAttachments[response] ?? false;

Map<String, dynamic> wellKnownFluxerToJson(WellKnownFluxerResponse response) {
  final Map<String, dynamic> json = response.toJson();
  if (!proxiesAttachmentsThroughApi(response)) {
    return json;
  }
  return <String, dynamic>{
    ...json,
    'features': <String, dynamic>{
      ...response.features.toJson(),
      _kProxyAttachmentsFeature: true,
    },
  };
}

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
  final WellKnownFluxerResponse response = WellKnownFluxerResponse.fromJson(
    <String, dynamic>{...json, 'features': filledFeatures},
  );
  if (features[_kProxyAttachmentsFeature] == true) {
    _proxiedAttachments[response] = true;
  }
  return response;
}

// Fork: [forkOnWellKnownParseFailure] is told about any document that fails to
// parse (tyne-chat/tyne#458). A hook rather than a call, so this file stays free
// of Flutter and tool/check_discovery_document.dart can run it with plain Dart.
WellKnownFluxerResponse parseWellKnownFluxer(Map<String, dynamic> json) {
  try {
    return _parseWellKnownFluxer(json);
  } on Object catch (error, stackTrace) {
    forkOnWellKnownParseFailure?.call(error, stackTrace);
    rethrow;
  }
}

void Function(Object error, StackTrace stackTrace)? forkOnWellKnownParseFailure;
