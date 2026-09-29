import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/Utils/password_policy.dart';

void main() {
  group('the passwords testers reported', () {
    test('Gengen@00 is accepted', () {
      expect(validateSignupPassword('Gengen@00'), isNull);
    });

    test('7890&^()AYo is rejected, naming the characters at fault', () {
      final err = validateSignupPassword(r'7890&^()AYo');
      expect(err, isNotNull);
      final blamed = err!.split(' cannot be used').first;
      expect(blamed, '^ ( )');
      // & is on the allowed list, so it must not be blamed.
      expect(blamed, isNot(contains('&')));
      expect(err, contains('Allowed symbols'));
      expect(disallowedCharsIn(r'7890&^()AYo'), ['^', '(', ')']);
    });
  });

  group('one message per reason', () {
    test('empty', () {
      expect(validateSignupPassword(''), 'Password is required');
      expect(validateSignupPassword(null), 'Password is required');
    });

    test('too short', () {
      expect(validateSignupPassword('Ab1@efg'), contains('at least 8'));
    });

    test('too long', () {
      expect(validateSignupPassword('Abcdefghij1@klmnopqrs'),
          contains('20 characters or fewer'));
    });

    test('missing each class', () {
      expect(validateSignupPassword('ABCDEF1@'), contains('lowercase'));
      expect(validateSignupPassword('abcdef1@'), contains('uppercase'));
      expect(validateSignupPassword('Abcdefg@'), contains('number'));
      expect(validateSignupPassword('Abcdefg1'), contains('symbols'));
    });

    test('a disallowed symbol is named before anything else is complained about',
        () {
      // Also missing an uppercase letter, but the unusable character is the
      // thing the person needs to know about.
      expect(validateSignupPassword('abcdef1#'), contains('#'));
    });
  });

  group('boundaries', () {
    test('exactly 8 and exactly 20 are fine', () {
      expect(validateSignupPassword('Abcdef1@'), isNull); // 8
      expect(validateSignupPassword('Abcdefghij1@klmnopqr'), isNull); // 20
    });
  });

  test('every allowed symbol really is allowed', () {
    for (final ch in kPasswordSpecials.split('')) {
      expect(validateSignupPassword('Abcdefg1$ch'), isNull,
          reason: '$ch should be accepted');
    }
  });

  test('agrees with the backend pattern on generated passwords', () {
    // The point of this one: if either side drifts, this fails.
    final rnd = Random(7);
    const alphabet = r'abcXYZ019@$!%*?&^()#-_. ';
    for (var i = 0; i < 2000; i++) {
      final len = 4 + rnd.nextInt(20);
      final pwd = List.generate(
          len, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();

      final backendAccepts =
          kSignupPasswordPattern.hasMatch(pwd) && pwd.length <= kPasswordMaxLength;

      expect(validateSignupPassword(pwd) == null, backendAccepts,
          reason: 'disagreed on "$pwd"');
    }
  });
}
