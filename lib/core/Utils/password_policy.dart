/// Signup password rules, mirroring the backend contract.
///
/// `CreatePasswordRequestDto` in the accounts service
/// (https://api.rimabank.ng/accounts/swagger/v1/swagger.json) declares:
///
/// ```
/// minLength 8, maxLength 20,
/// pattern ^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$
/// ```
///
/// The trailing character class is a whitelist: letters, digits and
/// `@ $ ! % * ? &` are the only characters accepted. Anything else — `^ ( ) # - _`
/// and friends — is refused by the API, so the app has to refuse it too, and say
/// which character was the problem.
library;

/// The only symbols the signup endpoint accepts.
const String kPasswordSpecials = r'@$!%*?&';

/// Same rule as the backend, for tests and for anything that needs the whole
/// check in one expression.
final RegExp kSignupPasswordPattern =
    RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

const int kPasswordMinLength = 8;
const int kPasswordMaxLength = 20;

bool hasLower(String v) => RegExp(r'[a-z]').hasMatch(v);
bool hasUpper(String v) => RegExp(r'[A-Z]').hasMatch(v);
bool hasDigit(String v) => RegExp(r'\d').hasMatch(v);

/// True when the password carries at least one of the allowed symbols.
bool hasAllowedSpecial(String v) => RegExp(r'[@$!%*?&]').hasMatch(v);

/// True when every character is one the backend accepts.
bool hasOnlyAllowedChars(String v) => disallowedCharsIn(v).isEmpty;

bool isLengthOk(String v) =>
    v.length >= kPasswordMinLength && v.length <= kPasswordMaxLength;

/// The characters the backend would reject, in the order they appear and
/// without repeats — so the message can name them.
List<String> disallowedCharsIn(String v) {
  final bad = <String>[];
  for (final ch in v.split('')) {
    if (RegExp(r'[A-Za-z\d@$!%*?&]').hasMatch(ch)) continue;
    if (!bad.contains(ch)) bad.add(ch);
  }
  return bad;
}

/// Readable form of the allowed symbol set, e.g. `@ $ ! % * ? &`.
String get allowedSymbolsLabel => kPasswordSpecials.split('').join(' ');

/// Validates a signup password, returning null when it is acceptable and a
/// message naming the single reason it is not otherwise.
String? validateSignupPassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < kPasswordMinLength) {
    return 'Password must be at least $kPasswordMinLength characters';
  }
  if (value.length > kPasswordMaxLength) {
    return 'Password must be $kPasswordMaxLength characters or fewer';
  }

  final bad = disallowedCharsIn(value);
  if (bad.isNotEmpty) {
    return '${bad.join(' ')} cannot be used. '
        'Allowed symbols: $allowedSymbolsLabel';
  }
  if (!hasLower(value)) return 'Add a lowercase letter (a-z)';
  if (!hasUpper(value)) return 'Add an uppercase letter (A-Z)';
  if (!hasDigit(value)) return 'Add a number (0-9)';
  if (!hasAllowedSpecial(value)) {
    return 'Add one of these symbols: $allowedSymbolsLabel';
  }
  return null;
}
