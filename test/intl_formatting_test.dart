import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:rimapay/core/localization/l10n.dart';

/// Regression cover for the Hausa blank-screen bug.
///
/// `intl` ships date symbols for Hausa but no *number* symbols, so setting
/// `Intl.defaultLocale = 'ha'` makes every `NumberFormat` throw. On the
/// dashboard that killed the balance card and, with it, the whole page body —
/// which rendered as a blank grey area in release.
void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  tearDown(() {
    Intl.defaultLocale = null;
  });

  test('intl has no Hausa number symbols (the cause)', () {
    Intl.defaultLocale = 'ha';
    expect(
      () => NumberFormat('#,##0.00').format(1234.5),
      throwsA(isA<ArgumentError>()),
      reason: 'If this ever stops throwing, intl gained ha number data and '
          'the workaround below can be revisited.',
    );
  });

  test('money formats correctly while the UI is Hausa', () {
    // The app must not put 'ha' into Intl.defaultLocale; Nigerian money is
    // written with Western digits and #,##0.00 grouping in both languages.
    Intl.defaultLocale = null;
    expect('₦${NumberFormat('#,##0.00').format(1234.5)}', '₦1,234.50');
  });

  test('intl has no usable Hausa date locale either', () {
    // A ha.json exists in intl's symbol data but 'ha' is not a registered
    // locale, so this throws too. Dates therefore stay on the default locale
    // in both languages — do not "fix" this by passing 'ha'.
    expect(
      () => DateFormat('d MMM yyyy', 'ha').format(DateTime(2026, 1, 15)),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('dates format normally on the default locale', () {
    Intl.defaultLocale = null;
    expect(
      DateFormat('d MMM yyyy').format(DateTime(2026, 1, 15)),
      '15 Jan 2026',
    );
  });

  test('Hausa plural strings resolve without throwing', () async {
    // The generated Hausa class calls Intl.pluralLogic(locale: 'ha'). If that
    // threw the way NumberFormat does, every screen using a plural string
    // would blank in exactly the same way.
    final ha = await AppL10n.delegate.load(const Locale('ha'));
    expect(ha.ticketCount(1), isNotEmpty);
    expect(ha.ticketCount(5), isNotEmpty);
    expect(ha.seatCount(2), isNotEmpty);
  });

  test('every Hausa string with an argument resolves', () async {
    // Spot-checks the placeholder-bearing messages that appear on the screens
    // the user reported blank.
    final ha = await AppL10n.delegate.load(const Locale('ha'));
    expect(ha.accountNoPrefix('123'), contains('123'));
    expect(ha.dailyLimit('₦50,000'), contains('₦50,000'));
    expect(ha.comingSoonFeature('Cards'), contains('Cards'));
    expect(ha.loanPitch('₦500,000'), contains('₦500,000'));
  });
}
