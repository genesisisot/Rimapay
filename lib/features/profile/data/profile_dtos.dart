// Request/response models for the RIMA Profile API (`/api/v1/profile/*`).

class CreateProfileRequest {
  final String identityUserId;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? email;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? profilePictureUrl;
  final String? identityNumber;
  final String? documentType;

  const CreateProfileRequest({
    required this.identityUserId,
    this.firstName,
    this.lastName,
    this.middleName,
    this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.profilePictureUrl,
    this.identityNumber,
    this.documentType,
  });

  Map<String, dynamic> toJson() => {
        'identityUserId': identityUserId,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (middleName != null) 'middleName': middleName,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (gender != null) 'gender': gender,
        if (address != null) 'address': address,
        if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
        if (identityNumber != null) 'identityNumber': identityNumber,
        if (documentType != null) 'documentType': documentType,
      };
}

class CreateProfileResponse {
  final bool isSuccess;
  final String? profileId;
  final String? errorMessage;
  final String? errorCode;

  const CreateProfileResponse({
    required this.isSuccess,
    this.profileId,
    this.errorMessage,
    this.errorCode,
  });

  factory CreateProfileResponse.fromJson(Map<String, dynamic> json) =>
      CreateProfileResponse(
        isSuccess: json['isSuccess'] == true,
        profileId: json['profileId'] as String?,
        errorMessage: json['errorMessage'] as String?,
        errorCode: json['errorCode'] as String?,
      );
}

// ── Profile Completion DTOs ─────────────────────────────────────────────

class AddressCompletionRequest {
  final String addressLine;
  final String? houseNumber;
  final String? areaLandmark;
  final String state;
  final String lga;

  const AddressCompletionRequest({
    required this.addressLine,
    this.houseNumber,
    this.areaLandmark,
    required this.state,
    required this.lga,
  });

  Map<String, dynamic> toJson() => {
        'addressLine': addressLine,
        if (houseNumber != null) 'houseNumber': houseNumber,
        if (areaLandmark != null) 'areaLandmark': areaLandmark,
        'state': state,
        'lga': lga,
      };
}

class PepCompletionRequest {
  final bool isPep;

  const PepCompletionRequest({required this.isPep});

  Map<String, dynamic> toJson() => {'isPep': isPep};
}

class SourceOfIncomeRequest {
  final String occupation;
  final String annualIncome;

  const SourceOfIncomeRequest({
    required this.occupation,
    required this.annualIncome,
  });

  Map<String, dynamic> toJson() => {
        'occupation': occupation,
        'annualIncome': annualIncome,
      };
}

class CompletionResponse {
  final bool isSuccess;
  final String? errorMessage;
  final String? errorCode;

  const CompletionResponse({
    required this.isSuccess,
    this.errorMessage,
    this.errorCode,
  });

  factory CompletionResponse.fromJson(Map<String, dynamic> json) =>
      CompletionResponse(
        isSuccess: json['isSuccess'] == true,
        errorMessage: json['errorMessage'] as String?,
        errorCode: json['errorCode'] as String?,
      );
}

class ProfileCompletionStatusDto {
  final String? identityUserId;
  final String? profileId;
  final bool residentialAddressProvided;
  final String? addressLine;
  final String? houseNumber;
  final String? areaLandmark;
  final String? state;
  final String? lga;
  final bool? isPepDeclared;
  final bool sourceOfIncomeProvided;
  final String? occupation;
  final String? annualIncome;
  final bool pinCreated;

  const ProfileCompletionStatusDto({
    this.identityUserId,
    this.profileId,
    required this.residentialAddressProvided,
    this.addressLine,
    this.houseNumber,
    this.areaLandmark,
    this.state,
    this.lga,
    this.isPepDeclared,
    required this.sourceOfIncomeProvided,
    this.occupation,
    this.annualIncome,
    required this.pinCreated,
  });

  factory ProfileCompletionStatusDto.fromJson(Map<String, dynamic> json) =>
      ProfileCompletionStatusDto(
        identityUserId: json['identityUserId'] as String?,
        profileId: json['profileId'] as String?,
        residentialAddressProvided:
            json['residentialAddressProvided'] == true,
        addressLine: json['addressLine'] as String?,
        houseNumber: json['houseNumber'] as String?,
        areaLandmark: json['areaLandmark'] as String?,
        state: json['state'] as String?,
        lga: json['lga'] as String?,
        isPepDeclared: json['isPepDeclared'] as bool?,
        sourceOfIncomeProvided: json['sourceOfIncomeProvided'] == true,
        occupation: json['occupation'] as String?,
        annualIncome: json['annualIncome'] as String?,
        pinCreated: json['pinCreated'] == true,
      );
}

class UserProfileDetails {
  final String profileId;
  final String identityUserId;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? email;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? profilePictureUrl;
  final String? identityNumber;
  final String? documentType;
  final DateTime createdOn;
  final DateTime? modifiedOn;

  const UserProfileDetails({
    required this.profileId,
    required this.identityUserId,
    this.firstName,
    this.lastName,
    this.middleName,
    this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.profilePictureUrl,
    this.identityNumber,
    this.documentType,
    required this.createdOn,
    this.modifiedOn,
  });

  factory UserProfileDetails.fromJson(Map<String, dynamic> json) =>
      UserProfileDetails(
        profileId: json['profileId'] as String,
        identityUserId: json['identityUserId'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        middleName: json['middleName'] as String?,
        email: json['email'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        dateOfBirth: json['dateOfBirth'] as String?,
        gender: json['gender'] as String?,
        address: json['address'] as String?,
        profilePictureUrl: json['profilePictureUrl'] as String?,
        identityNumber: json['identityNumber'] as String?,
        documentType: json['documentType'] as String?,
        createdOn: DateTime.parse(json['createdOn'] as String),
        modifiedOn: json['modifiedOn'] != null
            ? DateTime.parse(json['modifiedOn'] as String)
            : null,
      );
}
