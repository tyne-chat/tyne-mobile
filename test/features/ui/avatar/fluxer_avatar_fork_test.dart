import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/accessibility/presentation/allow_image_frame_animation.dart';
import 'package:fluxer_app/features/ui/avatar/fluxer_avatar.dart';
import 'package:fluxer_app/shared/widgets/fork_pause_when_out_of_view.dart';

import '../../../helpers/pump_fluxer_app.dart';

// tyne-chat/tyne#625: animated avatars pause while out of view; static ones
// get no visibility check. tyne-chat/tyne#621: animated avatars follow reduced
// motion.
void main() {
  testWidgets('an animated avatar is wrapped in ForkPauseWhenOutOfView', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      pumpFluxerApp(
        child: const FluxerNetworkAvatarImage(
          size: 40,
          imageUrl:
              'https://media.example/avatars/1/a_59f0515b.gif?animated=true&size=80',
        ),
      ),
    );
    expect(find.byType(ForkPauseWhenOutOfView), findsOneWidget);
    // tyne-chat/tyne#621: no exemption from reduced motion, so under it the
    // avatar shows its first frame and stops, as other images do.
    expect(find.byType(AllowImageFrameAnimation), findsNothing);
  });

  testWidgets('a static avatar is not', (WidgetTester tester) async {
    await tester.pumpWidget(
      pumpFluxerApp(
        child: const FluxerNetworkAvatarImage(
          size: 40,
          imageUrl: 'https://media.example/avatars/1/59f0515b.webp?size=80',
        ),
      ),
    );
    expect(find.byType(ForkPauseWhenOutOfView), findsNothing);
  });
}
