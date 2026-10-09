/// Official spellings for brands whose names reach us wrongly cased from the
/// billers API or the statement (e.g. `GOTV`, `Gotv` → `GOtv`). UAT flagged
/// "GOTV" as a spelling error.
const _brandSpellings = {
  'gotv': 'GOtv',
  'dstv': 'DStv',
};

final _brandPattern =
    RegExp(r'\b(' + _brandSpellings.keys.join('|') + r')\b', caseSensitive: false);

/// Replaces any wrongly cased brand name in [text] with its official spelling.
String fixBrandSpelling(String text) => text.replaceAllMapped(
    _brandPattern, (m) => _brandSpellings[m.group(1)!.toLowerCase()]!);

/// Null-safe [fixBrandSpelling] for DTO fields.
String? fixBrandSpellingOrNull(String? text) =>
    text == null ? null : fixBrandSpelling(text);
