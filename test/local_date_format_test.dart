import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:snippet/core/local_date_format.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('the full date follows the phone language and region', () {
    final day = DateTime(2026, 10, 21);
    expect(
      localFullDate(day, locale: const Locale('en', 'US')),
      'Wednesday, October 21, 2026',
    );
    expect(
      localFullDate(day, locale: const Locale('en', 'GB')),
      'Wednesday, 21 October 2026',
    );
    expect(
      localFullDate(day, locale: const Locale('de', 'DE')),
      'Mittwoch, 21. Oktober 2026',
    );
    expect(
      localFullDate(day, locale: const Locale('fr', 'FR')),
      'mercredi 21 octobre 2026',
    );
  });

  test('an unknown locale falls back to US English', () {
    expect(
      localFullDate(DateTime(2026, 10, 21), locale: const Locale('xx', 'YY')),
      'Wednesday, October 21, 2026',
    );
  });
}
