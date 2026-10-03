/// Bank marks bundled under `assets/images/banks/`, named by CBN institution
/// code. `/payment/getbanks` returns no artwork, so the app carries its own.
///
/// Matching is by code first, since that is exact. Names are a fallback,
/// because the fallback bank list seeded in the transfer screen carries a few
/// codes that differ from the ones the marks are filed under.
library;

/// Institution codes with a bundled logo.
const _codes = <String>{
  '011', '023', '032', '033', '035', '035A', '044', '050', '057', '058',
  '063', '068', '070', '076', '082', '100', '101', '120001', '214', '215',
  '221', '232', '301', '50211', '50515', '999991', '999992',
};

/// Names, normalised, for banks whose code may arrive in another form.
const _byName = <String, String>{
  'access': '044',
  'accessdiamond': '063',
  'citi': '023',
  'ecobank': '050',
  'fcmb': '214',
  'firstcitymonument': '214',
  'fidelity': '070',
  'first': '011',
  'firstnigeria': '011',
  'gtbank': '058',
  'gtb': '058',
  'guarantytrust': '058',
  'jaiz': '301',
  'keystone': '082',
  'kuda': '50211',
  'moniepoint': '50515',
  'opay': '999992',
  'opaydigitalservices': '999992',
  'paycom': '999992',
  'palmpay': '999991',
  'polaris': '076',
  'providus': '101',
  'stanbicibtc': '221',
  'stanbic': '221',
  'standardchartered': '068',
  'sterling': '232',
  'suntrust': '100',
  'union': '032',
  'unionnigeria': '032',
  'uba': '033',
  'unitedafrica': '033',
  'unity': '215',
  'wema': '035',
  'alatbywema': '035A',
  'alat': '035A',
  '9psb': '120001',
  '9paymentservice': '120001',
  'zenith': '057',
};

/// Strips the words every bank name shares, so "Access Bank Plc" and
/// "ACCESS BANK" both land on the same key.
String _normalise(String name) {
  var s = name.toLowerCase();
  for (final w in [
    'bank',
    'plc',
    'limited',
    'ltd',
    'nigeria',
    'nig',
    'microfinance',
    'mfb',
    'digital',
    'services',
    'company',
    'of',
    'for',
  ]) {
    s = s.replaceAll(w, '');
  }
  return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// The asset for a bank, or null when none is bundled — callers fall back to
/// the lettered badge.
String? bankLogoAsset({String? code, String? name}) {
  final c = (code ?? '').trim();
  if (c.isNotEmpty) {
    if (_codes.contains(c)) return 'assets/images/banks/$c.png';
    if (_codes.contains(c.toUpperCase())) {
      return 'assets/images/banks/${c.toUpperCase()}.png';
    }
    // Some sources pad shorter codes with leading zeros, others don't.
    final trimmed = c.replaceFirst(RegExp(r'^0+'), '');
    for (final known in _codes) {
      if (known.replaceFirst(RegExp(r'^0+'), '') == trimmed) {
        return 'assets/images/banks/$known.png';
      }
    }
  }

  final n = _normalise(name ?? '');
  if (n.isEmpty) return null;
  final mapped = _byName[n];
  if (mapped != null) return 'assets/images/banks/$mapped.png';

  // Last resort: a name that starts with a known key, e.g. "zenithplc".
  for (final entry in _byName.entries) {
    if (n.startsWith(entry.key)) {
      return 'assets/images/banks/${entry.value}.png';
    }
  }
  return null;
}
