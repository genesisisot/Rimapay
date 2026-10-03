/// Bank marks bundled under `assets/images/banks/`, named by CBN institution
/// code. `/payment/getbanks` returns no artwork, so the app carries its own.
///
/// Matching is by code first, since that is exact. Names are a fallback,
/// because the fallback bank list seeded in the transfer screen carries a few
/// codes that differ from the ones the marks are filed under.
library;

/// Institution codes with a bundled logo.
const _codes = <String>{
  '000304', '00103', '00305', '00716', '00zap', '011', '023', '031', '032',
  '033', '035', '035A', '044', '050', '050002', '050020', '050021',
  '050023', '050032', '057', '058', '063', '068', '070', '070016', '070022',
  '070027', '076', '082', '090162', '090164', '090171', '090190', '090420',
  '090478', '090560', '090561', '090567', '090574', '090629', '090664',
  '090678', '090680', '090708', '090759', '091003', '098', '100', '100002',
  '100022', '100025', '100036', '100039', '100040', '100052', '101', '102',
  '104', '105', '106', '107', '108', '109', '11072', '120001', '120002',
  '120003', '120004', '125', '214', '215', '221', '232', '268', '301',
  '302', '303', '311', '312', '401', '40119', '40165', '40195', '402',
  '402001', '404', '413', '415', '50036', '50055', '50059', '50072',
  '50083', '50092', '501', '50117', '50122', '50123', '50126', '50130',
  '50162', '50171', '50186', '502', '50200', '50204', '50211', '50216',
  '50263', '50280', '50298', '50304', '50315', '50368', '50383', '50439',
  '50442', '50453', '50457', '50491', '50502', '50515', '50549', '50563',
  '50570', '50572', '50582', '50622', '50629', '50645', '50689', '50697',
  '50725', '50743', '50746', '50756', '50761', '50767', '50800', '50809',
  '50823', '50840', '50864', '50870', '50871', '50875', '50880', '50894',
  '50910', '50922', '50926', '50931', '50934', '50968', '50994', '51056',
  '51062', '51074', '51080', '51085', '51097', '51100', '51108', '51110',
  '51113', '51142', '51146', '51204', '51212', '51226', '51229', '51241',
  '51244', '51251', '51253', '51261', '51267', '51269', '51276', '51279',
  '51286', '5129', '51293', '51297', '51304', '51308', '51310', '51312',
  '51314', '51316', '51318', '51322', '51333', '51334', '51336', '51337',
  '51341', '51351', '51353', '51355', '51361', '51364', '51368', '51371',
  '51373', '51375', '51386', '51396', '51403', '51411', '51429', '51437',
  '51444', '51447', '51449', '51450', '51455', '51457', '51458', '51462',
  '51474', '51475', '51477', '559', '561', '562', '565', '566', '594',
  '602', '650', '677', '812', '865', '899', '90003', '90012', '90028',
  '90052', '90065', '90067', '90070', '90077', '90089', '90102', '90278',
  '90287', '90317', '90335', '90367', '90451', '90586', '90641', '90667',
  '90774', '90787', '90801', '90825', '946', '999991', '999992', 'D53',
  'FC40128', 'FC40163', 'MFB50094', 'MFB50992', 'MFB51116M', 'MFB51452',
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
