const String fluxerApiFeaturesHeaderName = 'X-Fluxer-Features';

const List<String> fluxerApiClientFeatures = <String>[
  // Fork: this app knows DM threads, so the API keeps their chips and starter
  // messages in DMs (tyne-chat/tyne#699).
  'fork_dm_threads',
  'view_channel_members_permission',
  'channel_threads',
];

String buildFluxerApiFeaturesHeaderValue() =>
    fluxerApiClientFeatures.join(', ');
