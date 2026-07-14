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

// ── Daily Limit DTOs ──────────────────────────────────────────────────────────

class UpdateDailyLimitRequest {
  final double dailyLimit;

  const UpdateDailyLimitRequest({required this.dailyLimit});

  Map<String, dynamic> toJson() => {'dailyLimit': dailyLimit};
}

class DailyLimitResponse {
  final double dailyLimit;
  final int tier;
  final double effectiveDailyLimit;

  const DailyLimitResponse({
    required this.dailyLimit,
    required this.tier,
    required this.effectiveDailyLimit,
  });

  factory DailyLimitResponse.fromJson(Map<String, dynamic> json) =>
      DailyLimitResponse(
        dailyLimit: (json['dailyLimit'] as num?)?.toDouble() ?? 0,
        tier: (json['tier'] as num?)?.toInt() ?? 0,
        effectiveDailyLimit: (json['effectiveDailyLimit'] as num?)?.toDouble() ?? 0,
      );
}

class DailyLimitBalanceResponse {
  final double dailyLimit;
  final int tier;
  final double effectiveDailyLimit;
  final double totalSpentToday;
  final double remainingBalance;

  const DailyLimitBalanceResponse({
    required this.dailyLimit,
    required this.tier,
    required this.effectiveDailyLimit,
    required this.totalSpentToday,
    required this.remainingBalance,
  });

  factory DailyLimitBalanceResponse.fromJson(Map<String, dynamic> json) =>
      DailyLimitBalanceResponse(
        dailyLimit: (json['dailyLimit'] as num?)?.toDouble() ?? 0,
        tier: (json['tier'] as num?)?.toInt() ?? 0,
        effectiveDailyLimit: (json['effectiveDailyLimit'] as num?)?.toDouble() ?? 0,
        totalSpentToday: (json['totalSpentToday'] as num?)?.toDouble() ?? 0,
        remainingBalance: (json['remainingBalance'] as num?)?.toDouble() ?? 0,
      );
}

// ── Payment / Transfer DTOs ───────────────────────────────────────────────────

class TransferRequest {
  final String senderAccountNumber;
  final String recipientAccountNumber;
  final String recipientBankCode;
  final String recipientBankName;
  final double amount;
  final String? narration;
  final String? transactionReference;
  final String pin;
  final String? otpCode;
  final String? otpReference;

  const TransferRequest({
    required this.senderAccountNumber,
    required this.recipientAccountNumber,
    required this.recipientBankCode,
    required this.recipientBankName,
    required this.amount,
    this.narration,
    this.transactionReference,
    required this.pin,
    this.otpCode,
    this.otpReference,
  });

  Map<String, dynamic> toJson() => {
        'senderAccountNumber': senderAccountNumber,
        'recipientAccountNumber': recipientAccountNumber,
        'recipientBankCode': recipientBankCode,
        'recipientBankName': recipientBankName,
        'amount': amount,
        if (narration != null) 'narration': narration,
        if (transactionReference != null) 'transactionReference': transactionReference,
        'pin': pin,
        if (otpCode != null) 'otpCode': otpCode,
        if (otpReference != null) 'otpReference': otpReference,
      };
}

class TransferResponse {
  final bool isSuccess;
  final String? transactionReference;
  final String? batchReference;
  final String? status;
  final String? errorMessage;
  final String? errorCode;

  const TransferResponse({
    required this.isSuccess,
    this.transactionReference,
    this.batchReference,
    this.status,
    this.errorMessage,
    this.errorCode,
  });

  factory TransferResponse.fromJson(Map<String, dynamic> json) =>
      TransferResponse(
        isSuccess: json['isSuccess'] == true,
        transactionReference: json['transactionReference'] as String?,
        batchReference: json['batchReference'] as String?,
        status: json['status'] as String?,
        errorMessage: json['errorMessage'] as String?,
        errorCode: json['errorCode'] as String?,
      );
}

// ── Account Details (Name Enquiry) DTO ─────────────────────────────────────────

class AccountDetailsResponse {
  final String? accountTitle;
  final String? accountNo;
  final String? accountStatus;
  final String? mobilePhone;
  final String? emailAddress;

  const AccountDetailsResponse({
    this.accountTitle,
    this.accountNo,
    this.accountStatus,
    this.mobilePhone,
    this.emailAddress,
  });

  factory AccountDetailsResponse.fromJson(Map<String, dynamic> json) =>
      AccountDetailsResponse(
        accountTitle: json['accountTitle'] as String?,
        accountNo: json['accountNo'] as String?,
        accountStatus: json['accountStatus'] as String?,
        mobilePhone: json['mobilePhone'] as String?,
        emailAddress: json['emailAddress'] as String?,
      );
}

// ── Bank List DTO (getbanks) ───────────────────────────────────────────────────

class BankDto {
  final String? bankName;
  final String? institutionCode;
  final String? channelCode;

  const BankDto({
    this.bankName,
    this.institutionCode,
    this.channelCode,
  });

  factory BankDto.fromJson(Map<String, dynamic> json) => BankDto(
        bankName: json['bankName'] as String?,
        institutionCode: json['institutionCode'] as String?,
        channelCode: json['channelCode'] as String?,
      );
}

// ── Inter-bank Name Enquiry DTO ────────────────────────────────────────────────

/// Response for GET /api/v1/payment/name-enquiry/inter.
///
/// The gateway wraps a thin NIBSS-style payload: [responseCode] `"00"` means
/// success and [responseDesc] carries the resolved account holder name.
class InterNameEnquiryResponse {
  final String? responseCode;
  final String? responseDesc;

  const InterNameEnquiryResponse({
    this.responseCode,
    this.responseDesc,
  });

  /// True when the enquiry resolved an account.
  bool get isResolved => responseCode == '00' && (responseDesc?.isNotEmpty ?? false);

  /// The resolved account holder name (only meaningful when [isResolved]).
  String get accountName => responseDesc?.trim() ?? '';

  factory InterNameEnquiryResponse.fromJson(Map<String, dynamic> json) =>
      InterNameEnquiryResponse(
        responseCode: json['responseCode'] as String?,
        responseDesc: json['responseDesc'] as String?,
      );
}

// ── Accounts DTOs ─────────────────────────────────────────────────────────────

class AccountSummaryDto {
  final String? identityUserId;
  final String? profileId;
  final String? accountNumber;
  final String? customerId;
  final double balance;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? phoneNumber;
  final String? email;

  const AccountSummaryDto({
    this.identityUserId,
    this.profileId,
    this.accountNumber,
    this.customerId,
    this.balance = 0,
    this.firstName,
    this.lastName,
    this.middleName,
    this.phoneNumber,
    this.email,
  });

  factory AccountSummaryDto.fromJson(Map<String, dynamic> json) =>
      AccountSummaryDto(
        identityUserId: json['identityUserId'] as String?,
        profileId: json['profileId'] as String?,
        accountNumber: json['accountNumber'] as String?,
        customerId: json['customerId'] as String?,
        balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        middleName: json['middleName'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        email: json['email'] as String?,
      );
}

// ── File DTOs ────────────────────────────────────────────────────────────────

class Base64FileUploadRequest {
  final String? key;
  final String? base64File;
  final String? contentType;

  const Base64FileUploadRequest({
    this.key,
    this.base64File,
    this.contentType,
  });

  Map<String, dynamic> toJson() => {
        if (key != null) 'key': key,
        if (base64File != null) 'base64File': base64File,
        if (contentType != null) 'contentType': contentType,
      };
}

class FileUploadResponse {
  final String? key;
  final String? bucketName;
  final int size;
  final String? contentType;

  const FileUploadResponse({
    this.key,
    this.bucketName,
    this.size = 0,
    this.contentType,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) =>
      FileUploadResponse(
        key: json['key'] as String?,
        bucketName: json['bucketName'] as String?,
        size: (json['size'] as num?)?.toInt() ?? 0,
        contentType: json['contentType'] as String?,
      );
}

class PresignedUrlResponse {
  final String? key;
  final String? url;
  final int expiresInSeconds;

  const PresignedUrlResponse({
    this.key,
    this.url,
    this.expiresInSeconds = 0,
  });

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) =>
      PresignedUrlResponse(
        key: json['key'] as String?,
        url: json['url'] as String?,
        expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 0,
      );
}

// ── Profile DTOs ──────────────────────────────────────────────────────────────

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
