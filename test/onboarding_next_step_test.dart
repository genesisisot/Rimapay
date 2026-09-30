import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/features/onboarding/data/onboarding_dtos.dart';

void main() {
  group('routing after OTP', () {
    OnboardingNextStep resolve(String? raw,
            [OnboardingStage stage = OnboardingStage.otpVerified]) =>
        OnboardingNextStep.resolve(raw: raw, stage: stage);

    test('the three values the backend documents', () {
      // Exactly as the guide writes it, parenthetical and all.
      expect(resolve('ValidateFaceWithId(bvn or nin)'),
          OnboardingNextStep.faceWithId);
      expect(resolve('ValidateFace'), OnboardingNextStep.face);
      expect(resolve('IdentityVerification'), OnboardingNextStep.identity);
    });

    test('the parenthetical is prose, so wording changes do not break it', () {
      expect(resolve('ValidateFaceWithId'), OnboardingNextStep.faceWithId);
      expect(resolve('ValidateFaceWithId (BVN or NIN)'),
          OnboardingNextStep.faceWithId);
      expect(resolve('validatefacewithid(bvn)'), OnboardingNextStep.faceWithId);
    });

    test('ValidateFaceWithId is not mistaken for ValidateFace', () {
      expect(resolve('ValidateFaceWithId(bvn or nin)'),
          isNot(OnboardingNextStep.face));
    });

    test('falls back to the stage when nextStep is absent', () {
      expect(resolve(null, OnboardingStage.validateFaceWithIdPending),
          OnboardingNextStep.faceWithId);
      expect(resolve(null, OnboardingStage.facialValidationPending),
          OnboardingNextStep.face);
      expect(resolve(null, OnboardingStage.otpVerified),
          OnboardingNextStep.identity);
      expect(resolve('  '), OnboardingNextStep.identity);
    });

    test('an unrecognised value keeps the new-customer path', () {
      expect(resolve('SomethingNewEntirely'), OnboardingNextStep.identity);
    });
  });

  group('verify-otp response', () {
    test('reads nextStep off the envelope data', () {
      final r = VerifyOnboardingOtpResponse.fromJson({
        'sessionId': 's1',
        'currentStage': 'ValidateFaceWithIdPending',
        'isVerified': true,
        'facialValidationHint': null,
        'nextStep': 'ValidateFaceWithId(bvn or nin)',
        'message': 'OTP verified.',
      });
      expect(r.isVerified, isTrue);
      expect(r.currentStage, OnboardingStage.validateFaceWithIdPending);
      expect(r.nextStep, OnboardingNextStep.faceWithId);
    });

    test('an older gateway with no nextStep still routes', () {
      final r = VerifyOnboardingOtpResponse.fromJson({
        'sessionId': 's1',
        'currentStage': 'FacialValidationPending',
        'isVerified': true,
      });
      expect(r.nextStep, OnboardingNextStep.face);
    });
  });

  group('OnboardingStage', () {
    test('knows the new stage by name and by number', () {
      expect(OnboardingStage.fromJson('ValidateFaceWithIdPending'),
          OnboardingStage.validateFaceWithIdPending);
      expect(OnboardingStage.fromJson(16),
          OnboardingStage.validateFaceWithIdPending);
    });

    test('numbers match the backend, not the declaration order', () {
      // Failed is 99 there; reading it positionally used to make it step one.
      expect(OnboardingStage.fromJson(99), OnboardingStage.failed);
      expect(OnboardingStage.failed.code, 99);
      expect(OnboardingStage.fromJson(1), OnboardingStage.initialDataEntry);
      expect(OnboardingStage.fromJson(5), OnboardingStage.otpVerified);
      expect(OnboardingStage.fromJson(6),
          OnboardingStage.facialValidationPending);
      expect(OnboardingStage.fromJson(8),
          OnboardingStage.passwordCreationPending);
    });

    test('a number sent as a string is still a number', () {
      expect(OnboardingStage.fromJson('16'),
          OnboardingStage.validateFaceWithIdPending);
    });

    test('anything unknown lands on the first stage', () {
      expect(OnboardingStage.fromJson(1234), OnboardingStage.initialDataEntry);
      expect(OnboardingStage.fromJson(null), OnboardingStage.initialDataEntry);
    });
  });

  group('validate-face request', () {
    test('omits the ID fields entirely when none was collected', () {
      final json = const FacialValidationRequest(
        sessionId: 's1',
        capturedImageBase64: 'abc',
        livenessCheckPassed: true,
      ).toJson();
      expect(json.containsKey('identityNumber'), isFalse);
      expect(json.containsKey('documentType'), isFalse);
    });

    test('sends the ID as a string enum, matching the live schema', () {
      final json = const FacialValidationRequest(
        sessionId: 's1',
        capturedImageBase64: 'abc',
        identityNumber: '22233344455',
        documentType: IdentityDocumentType.nin,
      ).toJson();
      expect(json['identityNumber'], '22233344455');
      expect(json['documentType'], 'NIN');
    });

    test('defaults to BVN when a number is given without a type', () {
      final json = const FacialValidationRequest(
        sessionId: 's1',
        capturedImageBase64: 'abc',
        identityNumber: '22233344455',
      ).toJson();
      expect(json['documentType'], 'BVN');
    });

    test('an empty number is treated as no number', () {
      final json = const FacialValidationRequest(
        sessionId: 's1',
        capturedImageBase64: 'abc',
        identityNumber: '',
      ).toJson();
      expect(json.containsKey('identityNumber'), isFalse);
    });
  });
}
