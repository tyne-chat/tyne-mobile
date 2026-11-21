// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/presentation/sheets/timestamp_picker_sheet.dart';
import 'package:fluxer_app/features/chat/providers/pickers/timestamp_insert_provider.dart';
import 'package:fluxer_app/features/settings/providers/preferences/time_format_providers.dart';
import 'package:fluxer_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/select/fluxer_select.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../helpers/pump_fluxer_app.dart';

class _FakeUserSettings extends UserSettingsViewModel {
  _FakeUserSettings([this.timezone = 'UTC']);

  final String timezone;

  @override
  UserSettingsViewState build() => UserSettingsViewState(
    userId: '1',
    username: 'tester',
    displayName: 'Root User',
    discriminator: '0001',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: const <String>[],
    timezone: timezone,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestBed({
    int? initialEpoch,
    String? initialStyle,
    String timezone = 'UTC',
    void Function(int epoch, String style)? onInsert,
  }) {
    return pumpFluxerApp(
      overrides: [
        userSettingsViewModelProvider.overrideWith(
          () => _FakeUserSettings(timezone),
        ),
        use12HourTimeFormatProvider.overrideWith((ref) => true),
      ],
      child: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => ElevatedButton(
              key: const ValueKey('open_timestamp_picker_btn'),
              onPressed: () => TimestampPickerSheet.show(
                context,
                initialEpoch: initialEpoch,
                initialStyle: initialStyle,
                onInsert: onInsert,
              ),
              child: const Text('Open Timestamp Picker'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openPicker(
    WidgetTester tester, {
    int? initialEpoch,
    String? initialStyle,
    String timezone = 'UTC',
    void Function(int epoch, String style)? onInsert,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestBed(
        initialEpoch: initialEpoch,
        initialStyle: initialStyle,
        timezone: timezone,
        onInsert: onInsert,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open_timestamp_picker_btn')));
    await tester.pumpAndSettle();
  }

  group('TimestampPickerSheet', () {
    testWidgets('renders all controls with initial values', (tester) async {
      // 2026-03-20 12:00:00 UTC = 1774008000
      await openPicker(tester, initialEpoch: 1774008000, initialStyle: 'f');

      expect(find.text('Insert Timestamp'), findsWidgets);
      expect(
        find.text('e.g. tomorrow at 3pm, in 2 hours, now'),
        findsOneWidget,
      );
      expect(find.text('DATE'), findsOneWidget);
      expect(find.text('TIME'), findsOneWidget);
      expect(find.text('TIME ZONE'), findsOneWidget);
      expect(find.text('FORMAT PREVIEW'), findsOneWidget);
      expect(find.text('Insert'), findsOneWidget);
    });

    testWidgets(
      'typing NLP expression updates input and clear icon resets it',
      (tester) async {
        await openPicker(tester);

        final nlpInput = find.byType(TextField).first;
        await tester.enterText(nlpInput, 'tomorrow at 3pm');
        await tester.pumpAndSettle();

        expect(find.text('tomorrow at 3pm'), findsOneWidget);

        // Suffix icon PhosphorIconsFill.xCircle should be visible
        final clearIcon = find.byIcon(PhosphorIconsFill.xCircle);
        expect(clearIcon, findsOneWidget);

        await tester.tap(clearIcon);
        await tester.pumpAndSettle();

        expect(find.text('tomorrow at 3pm'), findsNothing);
      },
    );

    // The tests run with the device on UTC, so these zones differ from it.
    for (final String zone in <String>['Asia/Tokyo', 'America/New_York']) {
      testWidgets('Insert keeps the time with the profile in $zone', (
        tester,
      ) async {
        int? capturedEpoch;

        await openPicker(
          tester,
          initialEpoch: 1774008007,
          timezone: zone,
          onInsert: (epoch, style) => capturedEpoch = epoch,
        );

        await tester.tap(find.text('Insert'));
        await tester.pumpAndSettle();

        expect(capturedEpoch, 1774008007);
      });
    }

    testWidgets('tapping Insert invokes onInsert callback and closes sheet', (
      tester,
    ) async {
      int? capturedEpoch;
      String? capturedStyle;

      await openPicker(
        tester,
        initialEpoch: 1774008000,
        initialStyle: 'R',
        onInsert: (epoch, style) {
          capturedEpoch = epoch;
          capturedStyle = style;
        },
      );

      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();

      expect(capturedEpoch, isNotNull);
      expect(capturedStyle, 'R');

      // Sheet is closed
      expect(find.text('FORMAT PREVIEW'), findsNothing);
    });

    testWidgets(
      'tapping Insert without callback emits to pendingTimestampInsertProvider',
      (tester) async {
        late WidgetRef capturedRef;

        await tester.pumpWidget(
          pumpFluxerApp(
            overrides: [
              userSettingsViewModelProvider.overrideWith(_FakeUserSettings.new),
              use12HourTimeFormatProvider.overrideWith((ref) => true),
            ],
            child: Scaffold(
              body: Center(
                child: Consumer(
                  builder: (context, ref, _) {
                    capturedRef = ref;
                    return ElevatedButton(
                      key: const ValueKey('open_btn'),
                      onPressed: () => TimestampPickerSheet.show(
                        context,
                        initialEpoch: 1774008000,
                        initialStyle: 'D',
                      ),
                      child: const Text('Open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('open_btn')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Insert'));
        await tester.pumpAndSettle();

        final emitted = capturedRef.read(pendingTimestampInsertProvider);
        expect(emitted, isNotNull);
        expect(emitted?.style, 'D');
      },
    );

    testWidgets(
      'initializes with default current time and combo style when no arguments passed',
      (tester) async {
        await openPicker(tester);

        expect(find.text('FORMAT PREVIEW'), findsOneWidget);
        expect(find.text('Insert'), findsOneWidget);
      },
    );

    // tyne-chat/tyne#689: Android's three-button navigation bar takes 48 dp at
    // the bottom of the screen, and Insert was drawn under it.
    testWidgets('keeps Insert above the system navigation bar', (tester) async {
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetPadding);
      await openPicker(tester);

      final Rect insert = tester.getRect(
        find.ancestor(
          of: find.text('Insert'),
          matching: find.byType(FluxerButton),
        ),
      );
      expect(insert.bottom, lessThanOrEqualTo(1600 - 48));
    });

    // tyne-chat/tyne#436: each keystroke rebuilds the sheet; the time zone
    // menu's some 300 items are built once.
    testWidgets('typing keeps the same time zone items', (tester) async {
      await openPicker(tester);
      List<FluxerSelectItem<String>> zoneItems() => tester
          .widgetList<FluxerSelect<String>>(find.byType(FluxerSelect<String>))
          .map((FluxerSelect<String> select) => select.items)
          .singleWhere(
            (List<FluxerSelectItem<String>> items) => items.length > 100,
          );
      final List<FluxerSelectItem<String>> before = zoneItems();

      await tester.enterText(find.byType(TextField).first, 'tomorrow');
      await tester.pumpAndSettle();

      expect(zoneItems(), same(before));
    });

    // tyne-chat/tyne#435: the composer's chips accept `s` and `S`, which the
    // format menu did not offer, so it opened blank.
    for (final String style in <String>['s', 'S']) {
      testWidgets('a chip written as $style opens on its own format', (
        tester,
      ) async {
        String? inserted;
        await openPicker(
          tester,
          initialEpoch: 1774008000,
          initialStyle: style,
          onInsert: (int epoch, String insertedStyle) =>
              inserted = insertedStyle,
        );
        final FluxerSelect<String> format = tester
            .widgetList<FluxerSelect<String>>(find.byType(FluxerSelect<String>))
            .singleWhere(
              (FluxerSelect<String> select) => select.items.any(
                (FluxerSelectItem<String> item) => item.value == 'combo',
              ),
            );

        expect(format.value, style);
        final FluxerSelectItem<String> item = format.items.singleWhere(
          (FluxerSelectItem<String> item) => item.value == style,
        );
        expect(item.label, isNotEmpty);
        expect(find.text(item.label), findsWidgets);

        await tester.ensureVisible(find.text('Insert'));
        await tester.tap(find.text('Insert'));
        await tester.pumpAndSettle();
        expect(inserted, style);
      });
    }

    testWidgets('offers the date-and-time formats together', (tester) async {
      await openPicker(tester, initialEpoch: 1774008000);
      final FluxerSelect<String> format = tester
          .widgetList<FluxerSelect<String>>(find.byType(FluxerSelect<String>))
          .singleWhere(
            (FluxerSelect<String> select) => select.items.any(
              (FluxerSelectItem<String> item) => item.value == 'combo',
            ),
          );

      expect(
        format.items.map((FluxerSelectItem<String> item) => item.value),
        <String>['combo', 'f', 'F', 's', 'S', 'R', 'd', 'D', 't', 'T'],
      );
    });
  });
}
