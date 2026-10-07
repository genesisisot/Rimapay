import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/features/onboarding/data/onboarding_dtos.dart';

/// A resumed link never calls verify-otp, so there is no `nextStep` to read and
/// the stage alone decides which screen comes next. That path had no coverage,
/// which is how it shipped popping the wrong type and stranding anyone whose
/// session already existed.
void main() {
  OnboardingNextStep fromStage(OnboardingStage stage) =>
      OnboardingNextStep.resolve(raw: null, stage: stage);

  group('resuming a link decides the screen from the stage', () {
    test('an account with no photo and no ID on file wants both', () {
      expect(fromStage(OnboardingStage.validateFaceWithIdPending),
          OnboardingNextStep.faceWithId);
    });

    test('an account the backend can already compare against wants a selfie',
        () {
      expect(fromStage(OnboardingStage.facialValidationPending),
          OnboardingNextStep.face);
    });

    test('anything earlier keeps the new-customer path', () {
      expect(fromStage(OnboardingStage.otpVerified),
          OnboardingNextStep.identity);
      expect(fromStage(OnboardingStage.otpPending),
          OnboardingNextStep.identity);
    });
  });

  group('"has this session passed OTP" is a question about codes', () {
    bool pastOtp(OnboardingStage s) =>
        s.code >= OnboardingStage.otpVerified.code &&
        s != OnboardingStage.failed;

    test('stages after OTP count, including the new one', () {
      expect(pastOtp(OnboardingStage.otpVerified), isTrue);
      expect(pastOtp(OnboardingStage.facialValidationPending), isTrue);
      expect(pastOtp(OnboardingStage.validateFaceWithIdPending), isTrue);
      expect(pastOtp(OnboardingStage.pinCreationPending), isTrue);
    });

    test('stages before it do not', () {
      expect(pastOtp(OnboardingStage.initialDataEntry), isFalse);
      expect(pastOtp(OnboardingStage.otpPending), isFalse);
    });

    test('failed is 99 and must not read as "further along"', () {
      // By declaration order `failed` sits past every real stage, so an index
      // comparison would wave a failed session through to the next screen.
      expect(pastOtp(OnboardingStage.failed), isFalse);
      expect(OnboardingStage.failed.code, 99);
    });

    test('the new stage is 16, wherever it sits in the enum', () {
      expect(OnboardingStage.validateFaceWithIdPending.code, 16);
      expect(OnboardingStage.fromJson(16),
          OnboardingStage.validateFaceWithIdPending);
    });
  });

  group('resending a code', () {
    test('only while one is actually outstanding', () {
      expect(OnboardingStage.otpPending.canResendOtp, isTrue);
    });

    test('never at IdentityVerification — the stage that broke linking', () {
      // resume returned this with requiresOtpResend: true, and resend-otp
      // answered INVALID_STAGE. The flag alone is not a reason to call it.
      expect(OnboardingStage.identityVerification.canResendOtp, isFalse);
    });

    test('nor anywhere else', () {
      for (final s in OnboardingStage.values) {
        if (s == OnboardingStage.otpPending) continue;
        expect(s.canResendOtp, isFalse, reason: s.name);
      }
    });
  });
}
