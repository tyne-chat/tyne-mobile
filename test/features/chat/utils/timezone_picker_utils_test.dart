import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/timezone_data.dart';
import 'package:fluxer_app/features/chat/utils/timezone_menu_data.dart';
import 'package:fluxer_app/features/chat/utils/timezone_picker_utils.dart';
import 'package:fluxer_app/features/profile/utils/timezone_catalog.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('kTimezoneOptions', () {
    test('is non-empty and contains UTC', () {
      expect(kTimezoneOptions, isNotEmpty);
      final utc = kTimezoneOptions.where((o) => o.value == 'UTC');
      expect(utc, hasLength(1));
      expect(utc.first.label, contains('UTC'));
      expect(utc.first.offsetMinutes, 0);
    });

    test('contains well-known timezones', () {
      final values = kTimezoneOptions.map((o) => o.value).toSet();
      expect(values, contains('America/Los_Angeles'));
      expect(values, contains('America/New_York'));
      expect(values, contains('Europe/London'));
      expect(values, contains('Asia/Tokyo'));
      expect(values, contains('Australia/Sydney'));
    });

    test('excludes Etc/ entries and Factory', () {
      for (final option in kTimezoneOptions) {
        expect(
          option.value.startsWith('Etc/'),
          isFalse,
          reason: '${option.value} should be filtered out',
        );
        expect(option.value, isNot('Factory'));
      }
    });

    test('is sorted by offset ascending', () {
      for (int i = 1; i < kTimezoneOptions.length; i++) {
        expect(
          kTimezoneOptions[i].offsetMinutes,
          greaterThanOrEqualTo(kTimezoneOptions[i - 1].offsetMinutes),
          reason:
              '${kTimezoneOptions[i].value} should come after ${kTimezoneOptions[i - 1].value}',
        );
      }
    });

    test('every entry has a non-empty label and searchText', () {
      for (final option in kTimezoneOptions) {
        expect(
          option.label,
          isNotEmpty,
          reason: '${option.value} has empty label',
        );
        expect(
          option.searchText,
          isNotEmpty,
          reason: '${option.value} has empty searchText',
        );
      }
    });

    test('every non-UTC entry resolves via safeGetLocation', () {
      for (final option in kTimezoneOptions) {
        final loc = safeGetLocation(option.value);
        expect(
          loc,
          isNotNull,
          reason: '${option.value} should resolve to a tz.Location',
        );
      }
    });
  });

  group('findTimezoneOption', () {
    test('finds exact match by ianaName', () {
      final opt = findTimezoneOption('America/Los_Angeles');
      expect(opt.value, 'America/Los_Angeles');
      expect(opt.label, contains('Pacific Time'));
      expect(opt.label, contains('Los Angeles'));
    });

    test('normalizes Etc/UTC to UTC', () {
      final opt = findTimezoneOption('Etc/UTC');
      expect(opt.value, 'UTC');
    });

    test('normalizes GMT to UTC', () {
      final opt = findTimezoneOption('GMT');
      expect(opt.value, 'UTC');
    });

    test('finds deviceIanaName when ianaName is null', () {
      final opt = findTimezoneOption(null, null, 'America/Los_Angeles');
      expect(opt.value, 'America/Los_Angeles');
    });

    test('falls back to closest offset match for unknown IANA name', () {
      // Pass an IANA name that doesn't exist in our list, with offset 0
      final opt = findTimezoneOption('Fake/Timezone', 0);
      expect(opt.value, 'UTC');
    });
  });

  group('safeGetLocation', () {
    test('resolves UTC and aliases to tz.UTC', () {
      expect(safeGetLocation('UTC'), tz.UTC);
      expect(safeGetLocation('Etc/UTC'), tz.UTC);
      expect(safeGetLocation('GMT'), tz.UTC);
    });

    test('resolves standard IANA timezone', () {
      expect(
        safeGetLocation('America/Los_Angeles')?.name,
        'America/Los_Angeles',
      );
    });

    test('returns null gracefully for non-existent timezone', () {
      expect(safeGetLocation('NonExistent/Zone'), isNull);
    });

    test('returns null for null or empty input', () {
      expect(safeGetLocation(null), isNull);
      expect(safeGetLocation(''), isNull);
    });
  });

  group('getCurrentWallClockTime', () {
    test('computes wall clock for UTC without throwing', () {
      final opt = findTimezoneOption('UTC');
      final wallClock = getCurrentWallClockTime(opt);
      final nowUtc = DateTime.now().toUtc();
      expect(wallClock.year, nowUtc.year);
      expect(wallClock.month, nowUtc.month);
      expect(wallClock.day, nowUtc.day);
      expect(wallClock.hour, nowUtc.hour);
    });

    test('computes wall clock for Los Angeles without throwing', () {
      final opt = findTimezoneOption('America/Los_Angeles');
      final wallClock = getCurrentWallClockTime(opt);
      // Just verify it doesn't throw and returns reasonable values
      expect(wallClock.year, greaterThanOrEqualTo(2024));
      expect(wallClock.hour, inInclusiveRange(0, 23));
    });
  });

  group('adjustToViewerTimezone', () {
    test('returns original datetime when timezone is null or empty', () {
      final dt = DateTime.utc(2026, 4, 20, 15, 30);
      expect(adjustToViewerTimezone(dt, null), dt);
      expect(adjustToViewerTimezone(dt, ''), dt);
    });

    test('handles UTC timezone explicitly without throwing', () {
      final dt = DateTime.utc(2026, 4, 20, 15, 30);
      final adjusted = adjustToViewerTimezone(dt, 'UTC');
      expect(adjusted.year, 2026);
      expect(adjusted.month, 4);
      expect(adjusted.day, 20);
      expect(adjusted.hour, 15);
      expect(adjusted.minute, 30);
    });

    test('adjusts UTC instant to Tokyo wall-clock (UTC+9)', () {
      // 2026-04-20 12:00 UTC -> 2026-04-20 21:00 Tokyo
      final dt = DateTime.utc(2026, 4, 20, 12);
      final adjusted = adjustToViewerTimezone(dt, 'Asia/Tokyo');
      expect(adjusted.year, 2026);
      expect(adjusted.month, 4);
      expect(adjusted.day, 20);
      expect(adjusted.hour, 21);
      expect(adjusted.minute, 0);
    });

    test('adjusts UTC instant to New York wall-clock (EDT, UTC-4)', () {
      // 2026-04-20 12:00 UTC -> 2026-04-20 08:00 New York
      final dt = DateTime.utc(2026, 4, 20, 12);
      final adjusted = adjustToViewerTimezone(dt, 'America/New_York');
      expect(adjusted.year, 2026);
      expect(adjusted.month, 4);
      expect(adjusted.day, 20);
      expect(adjusted.hour, 8);
      expect(adjusted.minute, 0);
    });
  });

  group('calculateEpochFromWallClock', () {
    test('calculates correct epoch for wall clock in timezone', () {
      final date = DateTime(2026, 4, 20);
      final epoch = calculateEpochFromWallClock(
        wallClockDate: date,
        hour: 21,
        minute: 0,
        timezoneIana: 'Asia/Tokyo',
      );
      // 21:00 Tokyo = 12:00 UTC on 2026-04-20
      final utc = DateTime.utc(2026, 4, 20, 12);
      expect(epoch, utc.millisecondsSinceEpoch ~/ 1000);
    });

    test('calculates correct epoch for UTC without throwing', () {
      final date = DateTime(2026, 4, 20);
      final epoch = calculateEpochFromWallClock(
        wallClockDate: date,
        hour: 15,
        minute: 30,
        timezoneIana: 'UTC',
      );
      final utc = DateTime.utc(2026, 4, 20, 15, 30);
      expect(epoch, utc.millisecondsSinceEpoch ~/ 1000);
    });

    test('handles DST transition correctly for US timezones', () {
      // 2026-03-08 02:30 America/New_York is during spring-forward
      // The tz package handles this by pushing to 03:30
      final date = DateTime(2026, 3, 8);
      final epoch = calculateEpochFromWallClock(
        wallClockDate: date,
        hour: 3,
        minute: 30,
        timezoneIana: 'America/New_York',
      );
      // 03:30 EDT (UTC-4) = 07:30 UTC
      final utc = DateTime.utc(2026, 3, 8, 7, 30);
      expect(epoch, utc.millisecondsSinceEpoch ~/ 1000);
    });
  });

  group('names it does not know', () {
    const String unknown = 'Mars/Olympus_Mons';

    test('picks the option whose offset is closest to the one given', () {
      final TimezoneOption kolkata = findTimezoneOption('Asia/Kolkata');
      expect(
        findTimezoneOption(unknown, kolkata.offsetMinutes).offsetMinutes,
        kolkata.offsetMinutes,
      );
      expect(
        findTimezoneOption(unknown, kolkata.offsetMinutes + 1).offsetMinutes,
        kolkata.offsetMinutes,
      );
    });

    test('prefers the device zone over the offset', () {
      expect(findTimezoneOption(unknown, 0, 'Asia/Tokyo').value, 'Asia/Tokyo');
      expect(findTimezoneOption(unknown, 0, 'Etc/UTC').value, 'UTC');
    });

    test("shift a time by the fallback option's offset", () {
      final DateTime instant = DateTime.utc(2026, 1, 15, 12);
      final int offset = findTimezoneOption(unknown).offsetMinutes;

      expect(
        adjustToViewerTimezone(instant, unknown),
        DateTime(2026, 1, 15, 12).add(Duration(minutes: offset)),
      );
    });

    test('turn a wall-clock time into an epoch with the fallback offset', () {
      final int offset = findTimezoneOption(unknown).offsetMinutes;

      expect(
        calculateEpochFromWallClock(
          wallClockDate: DateTime(2026, 1, 15),
          hour: 12,
          minute: 30,
          timezoneIana: unknown,
        ),
        DateTime.utc(2026, 1, 15, 12, 30).millisecondsSinceEpoch ~/ 1000 -
            offset * 60,
      );
    });

    test("give the wall clock at the option's offset", () {
      const TimezoneOption option = TimezoneOption(
        value: unknown,
        label: 'Mars',
        searchText: 'mars',
        offsetMinutes: 90,
      );
      final DateTime expected = DateTime.now().toUtc().add(
        const Duration(minutes: 90),
      );

      final DateTime wallClock = getCurrentWallClockTime(option);

      final DateTime asNaive = DateTime(
        expected.year,
        expected.month,
        expected.day,
        expected.hour,
        expected.minute,
        expected.second,
      );
      expect(wallClock.difference(asNaive).inSeconds.abs(), lessThan(5));
    });
  });

  test(
    'reports no zone when the platform cannot say which one the device is in',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      expect(await getDeviceIanaTimezone(), isNull);
    },
  );

  test('an unknown device zone falls back to the offset, not UTC', () {
    final TimezoneOption kolkata = findTimezoneOption('Asia/Kolkata');

    expect(
      findTimezoneOption(null, kolkata.offsetMinutes).offsetMinutes,
      kolkata.offsetMinutes,
    );
  });

  group('the menu and the database (tyne-chat/tyne#429)', () {
    TimezoneOption option(String name) =>
        kTimezoneOptions.firstWhere((o) => o.value == name);

    test('offers every official name and UTC, and nothing else', () {
      expect(kTimezoneOptions.map((o) => o.value).toSet(), <String>{
        'UTC',
        ...kOfficialTimezoneNames,
      });
    });

    test('every official name and every older one resolves', () {
      for (final String name in <String>[
        ...kOfficialTimezoneNames,
        ...kTimezoneAliases.keys,
      ]) {
        expect(safeGetLocation(name), isNotNull, reason: name);
      }
    });

    test('every older name leads to an entry in the menu', () {
      final Set<String> entries = kTimezoneOptions.map((o) => o.value).toSet();
      expect(entries.containsAll(kTimezoneAliases.values), isTrue);
    });

    test('a place the short database lacks keeps its own clock changes', () {
      final tz.Location stockholm = safeGetLocation('Europe/Stockholm')!;
      Duration offsetIn(int month) => stockholm
          .timeZone(DateTime.utc(2026, month).millisecondsSinceEpoch)
          .offset;

      expect(offsetIn(1), const Duration(hours: 1));
      expect(offsetIn(7), const Duration(hours: 2));
    });

    test('a later load by the profile catalog keeps the whole database', () {
      expect(safeGetLocation('Europe/Stockholm'), isNotNull);

      ensureTimezoneDatabaseInitialized();

      expect(safeGetLocation('Europe/Stockholm'), isNotNull);
    });

    test('new places get a readable label', () {
      expect(
        option('Europe/Stockholm').label,
        endsWith('Central European Time - Stockholm, Sweden'),
      );
    });

    test('an older name selects its current entry', () {
      expect(findTimezoneOption('Europe/Kiev').value, 'Europe/Kyiv');
      expect(findTimezoneOption('Asia/Calcutta').value, 'Asia/Kolkata');
      expect(findTimezoneOption('US/Eastern').value, 'America/New_York');
      expect(
        findTimezoneOption(null, 0, 'Asia/Saigon').value,
        'Asia/Ho_Chi_Minh',
      );
    });

    test('the UTC family selects UTC', () {
      for (final String name in <String>[
        'Zulu',
        'Universal',
        'Etc/Zulu',
        'UCT',
      ]) {
        expect(findTimezoneOption(name).value, 'UTC', reason: name);
      }
    });

    test('search finds an entry by an older name', () {
      expect(option('Asia/Ho_Chi_Minh').searchText, contains('Saigon'));
      expect(option('Europe/Kyiv').searchText, contains('Kiev'));
    });

    test('the profile catalog offers the same places', () {
      final Set<String> ids = buildTimezoneCatalogOptions()
          .map((o) => o.id)
          .toSet();

      expect(ids, <String>{'UTC', ...kOfficialTimezoneNames});
    });

    test('the profile catalog searches older names too', () {
      final TimezoneCatalogOption saigon = buildTimezoneCatalogOptions()
          .firstWhere((o) => o.id == 'Asia/Ho_Chi_Minh');

      expect(saigon.searchText, contains('Saigon'));
    });
  });

  group('timestamps near the last date', () {
    test('the composer takes only what can be converted', () {
      expect(isComposableTimestampEpoch(0), isFalse);
      expect(isComposableTimestampEpoch(1), isTrue);
      expect(isComposableTimestampEpoch(kLastConvertibleEpochSeconds), isTrue);
      expect(
        isComposableTimestampEpoch(kLastConvertibleEpochSeconds + 1),
        isFalse,
      );
      expect(isComposableTimestampEpoch(99999999999999), isFalse);
    });

    test('the last chip converts in the zones furthest from UTC', () {
      final DateTime last = DateTime.fromMillisecondsSinceEpoch(
        kLastConvertibleEpochSeconds * 1000,
      );

      for (final String zone in <String>[
        'Pacific/Kiritimati',
        'Pacific/Pago_Pago',
      ]) {
        expect(() => adjustToViewerTimezone(last, zone), returnsNormally);
      }
    });

    test('a later date than that is left as it is, in any zone', () {
      final DateTime end = DateTime.fromMillisecondsSinceEpoch(
        8640000000000 * 1000,
      );

      expect(adjustToViewerTimezone(end, 'Asia/Tokyo'), end);
    });
  });
}
