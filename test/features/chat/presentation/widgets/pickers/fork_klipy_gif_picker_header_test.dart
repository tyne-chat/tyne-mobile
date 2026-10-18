import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/domain/gif_selection.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/pickers/fork_klipy_gif_picker_header.dart';
import 'package:fluxer_app/l10n_fork/fork_localizations_x.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../../../helpers/test_l10n.dart';

Widget _buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    locale: kTestLocale,
    localizationsDelegates: fluxerLocalizationsDelegates,
    supportedLocales: FluxerLocalizations.supportedLocales,
    theme: buildFluxerTheme(
      colorTheme: colorTheme,
      textTheme: FluxerTextTheme.fromColors(colorTheme),
      layoutTheme: FluxerLayoutTheme.scaled(),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('shows the Powered by KLIPY mark beside a KLIPY picker header', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        const ForkKlipyGifPickerHeader(
          provider: GifProviderKind.klipy,
          child: Text('header'),
        ),
      ),
    );

    expect(find.text('header'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.bySemanticsLabel('Powered by KLIPY'), findsOneWidget);
  });

  testWidgets('leaves the header alone for another provider', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const ForkKlipyGifPickerHeader(
          provider: GifProviderKind.tenor,
          child: Text('header'),
        ),
      ),
    );

    expect(find.text('header'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('the KLIPY search placeholder writes the brand in capitals', (
    tester,
  ) async {
    late String hint;
    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) {
            hint = FluxerLocalizations.of(
              context,
            ).fork.gifPickerSearchKlipyBrand;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(hint, 'Search KLIPY');
  });
}
