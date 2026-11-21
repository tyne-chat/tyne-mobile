// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:fluxer_app/features/dm/data/dm_repository.dart';
import 'package:fluxer_app/features/dm/providers/dm_providers.dart';
import 'package:fluxer_app/features/quick_switcher/utils/quick_switcher_navigation.dart';
import 'package:fluxer_app/features/ui/toast/toast_provider.dart';
import 'package:fluxer_app/material_ui.dart';

import '../../../helpers/pump_fluxer_app.dart';
import '../../../helpers/test_l10n.dart';

/// Records what the switcher asks for; every call fails while [failure] is
/// set.
class _FakeDmRepository implements DmRepository {
  final List<String> calls = <String>[];
  Exception? failure;

  @override
  Future<String> ensureDmChannel(String userId) async {
    calls.add('dm $userId');
    if (failure case final Exception error) {
      throw error;
    }
    return 'dm-$userId';
  }

  @override
  Future<void> ensurePersonalNotesChannel(String userId) async {
    calls.add('notes $userId');
    if (failure case final Exception error) {
      throw error;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const InstanceRuntimeConfig _dmsDisabled = InstanceRuntimeConfig(
  productName: 'Tyne',
  selfHosted: false,
  stripeEnabled: false,
  emailsEnabled: true,
  voiceEnabled: true,
  presignedAttachmentUploads: true,
  gifEnabled: true,
  blueskyEnabled: false,
  gifAttributionRequired: false,
  singleCommunity: false,
  directMessagesDisabled: true,
  registrationClosed: false,
  adminRegistrationUrlsEnabled: false,
  collectDateOfBirth: true,
);

void main() {
  late _FakeDmRepository repository;
  late int closes;
  late WidgetRef capturedRef;
  late BuildContext capturedContext;

  setUp(() {
    repository = _FakeDmRepository();
    closes = 0;
  });

  Future<void> pump(WidgetTester tester, {bool dmsDisabled = false}) async {
    await tester.pumpWidget(
      pumpFluxerApp(
        overrides: [
          dmRepositoryProvider.overrideWithValue(repository),
          if (dmsDisabled)
            instanceRuntimeConfigProvider.overrideWithValue(_dmsDisabled),
        ],
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            capturedRef = ref;
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
  }

  /// Opens [userId]'s DM (or personal notes) from the switcher, and answers
  /// whether it showed the error dialog for opening a DM.
  Future<bool> open(
    WidgetTester tester, {
    required String userId,
    bool isPersonalNotes = false,
  }) async {
    final Future<void> opening = openDmWithUserFromQuickSwitcher(
      context: capturedContext,
      ref: capturedRef,
      userId: userId,
      onClose: () => closes++,
      isPersonalNotes: isPersonalNotes,
    );
    await tester.pumpAndSettle();
    final bool sawError = find
        .text(testL10n.dmErrorStartConversationTitle)
        .evaluate()
        .isNotEmpty;
    // The error dialog holds the call open until it is dismissed.
    if (sawError) {
      await tester.tap(find.text(testL10n.uiUnderstood));
      await tester.pumpAndSettle();
    }
    await opening;
    return sawError;
  }

  // tyne-chat/tyne#441: with direct messages off on the instance, a tap on a
  // user did nothing at all.
  group('direct messages disabled on the instance', () {
    for (final bool isPersonalNotes in <bool>[false, true]) {
      testWidgets(
        '${isPersonalNotes ? 'personal notes' : 'a user'}: says so and closes '
        'the switcher without a request',
        (tester) async {
          await pump(tester, dmsDisabled: true);

          await open(tester, userId: '200', isPersonalNotes: isPersonalNotes);

          expect(
            capturedRef.read(toastProvider).single.toast.message,
            testL10n.assistantDmsDisabled,
          );
          expect(closes, 1);
          expect(repository.calls, isEmpty);
          await tester.pump(const Duration(seconds: 5));
        },
      );
    }
  });

  group('a failed request', () {
    for (final bool isPersonalNotes in <bool>[false, true]) {
      testWidgets(
        '${isPersonalNotes ? 'opening personal notes' : 'opening a DM'}: '
        'shows the error and keeps the switcher open',
        (tester) async {
          repository.failure = Exception('offline');
          await pump(tester);

          final bool sawError = await open(
            tester,
            userId: '200',
            isPersonalNotes: isPersonalNotes,
          );

          expect(sawError, isTrue);
          expect(repository.calls, <String>[
            '${isPersonalNotes ? 'notes' : 'dm'} 200',
          ]);
          expect(closes, 0);
        },
      );
    }
  });
}
