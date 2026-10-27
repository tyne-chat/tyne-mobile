import 'package:fluxer_app/features/shell/data/service_status_client.dart';
import 'package:fluxer_app/features/shell/domain/service_status_incident.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Fork imports.
// ignore: directives_ordering
import 'package:fluxer_app/core/providers/instance/well_known_provider.dart';
import 'package:fluxer_app/features/shell/presentation/widgets/instance_status_link.dart';

part 'service_status_incident_provider.g.dart';

@Riverpod(keepAlive: true)
class ServiceStatusIncidentRead extends _$ServiceStatusIncidentRead {
  @override
  ServiceStatusIncident? build() => null;

  Future<void> refresh() async {
    // Fork: Fluxer's status page only for an instance Fluxer hosts
    // (tyne-chat/tyne#134).
    if (!forkInstanceIsFluxerHosted(ref.read(wellKnownProvider))) {
      state = null;
      return;
    }
    final ServiceStatusClient client = ServiceStatusClient();
    final ServiceStatusIncident? next = await client.fetchActiveIncident();
    state = next;
  }
}
