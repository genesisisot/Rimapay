// DTOs for the RIMA Profile-Transaction bills endpoints (`/api/v1/bills/*`).
//
// Shapes mirror https://api.rimabank.ng/profile-transaction/swagger. Every
// response is wrapped in the standard `ApiResponse<T>` envelope
// `{ isSuccess, errorCode, statusCode, message, devMessage, data }`.

import '../../../core/Utils/brand_names.dart';

double _toDouble(Object? v) => (v as num?)?.toDouble() ?? 0;
int _toInt(Object? v) => (v as num?)?.toInt() ?? 0;

// ── Data bundles ──────────────────────────────────────────────────────────────

/// GET /api/v1/bills/data/plans → `DataBundleDto`.
class DataBundleDto {
  final String id;
  final String? networkProvider;
  final int billerId;
  final int billerCategoryId;
  final String? billerItemId;
  final String? name;

  /// `Daily` | `Weekly` | `Monthly` | `Yearly`.
  final String? validityType;
  final int validityDays;
  final String? validityDescription;
  final String? dataAllowance;
  final double amount;
  final double itemFee;
  final bool isAmountFixed;
  final int sortOrder;

  const DataBundleDto({
    required this.id,
    this.networkProvider,
    this.billerId = 0,
    this.billerCategoryId = 0,
    this.billerItemId,
    this.name,
    this.validityType,
    this.validityDays = 0,
    this.validityDescription,
    this.dataAllowance,
    this.amount = 0,
    this.itemFee = 0,
    this.isAmountFixed = true,
    this.sortOrder = 0,
  });

  factory DataBundleDto.fromJson(Map<String, dynamic> json) => DataBundleDto(
        id: json['id']?.toString() ?? '',
        networkProvider: json['networkProvider'] as String?,
        billerId: _toInt(json['billerId']),
        billerCategoryId: _toInt(json['billerCategoryId']),
        billerItemId: json['billerItemId'] as String?,
        name: fixBrandSpellingOrNull(json['name'] as String?),
        validityType: json['validityType']?.toString(),
        validityDays: _toInt(json['validityDays']),
        validityDescription: json['validityDescription'] as String?,
        dataAllowance: json['dataAllowance'] as String?,
        amount: _toDouble(json['amount']),
        itemFee: _toDouble(json['itemFee']),
        isAmountFixed: json['isAmountFixed'] != false,
        sortOrder: _toInt(json['sortOrder']),
      );
}

// ── Billers ───────────────────────────────────────────────────────────────────

/// GET /api/v1/bills/categories → `BillerCategoryDto`.
class BillerCategoryDto {
  final int categoryId;
  final String? name;
  final String? description;
  final bool isActive;
  final int billerCount;

  const BillerCategoryDto({
    required this.categoryId,
    this.name,
    this.description,
    this.isActive = true,
    this.billerCount = 0,
  });

  factory BillerCategoryDto.fromJson(Map<String, dynamic> json) =>
      BillerCategoryDto(
        categoryId: _toInt(json['categoryId']),
        name: fixBrandSpellingOrNull(json['name'] as String?),
        description: json['description'] as String?,
        isActive: json['isActive'] != false,
        billerCount: _toInt(json['billerCount']),
      );
}

/// GET /api/v1/bills/categories/{categoryId}/billers → `BillerDto`.
class BillerDto {
  final int billerId;
  final int billerCategoryId;
  final String? categoryName;
  final String? name;
  final String? shortName;
  final String? narration;

  /// Label for the customer reference the biller expects (e.g. "Smart Card Number").
  final String? customerField1;
  final String? customerField2;
  final String? logoUrl;
  final double surcharge;
  final bool usesPaymentItems;
  final bool isActive;

  const BillerDto({
    required this.billerId,
    this.billerCategoryId = 0,
    this.categoryName,
    this.name,
    this.shortName,
    this.narration,
    this.customerField1,
    this.customerField2,
    this.logoUrl,
    this.surcharge = 0,
    this.usesPaymentItems = true,
    this.isActive = true,
  });

  /// Best display name: short name, else full name.
  String get displayName => (shortName?.trim().isNotEmpty ?? false)
      ? shortName!.trim()
      : (name ?? 'Biller');

  factory BillerDto.fromJson(Map<String, dynamic> json) => BillerDto(
        billerId: _toInt(json['billerId']),
        billerCategoryId: _toInt(json['billerCategoryId']),
        categoryName: json['categoryName'] as String?,
        name: fixBrandSpellingOrNull(json['name'] as String?),
        shortName: fixBrandSpellingOrNull(json['shortName'] as String?),
        narration: json['narration'] as String?,
        customerField1: json['customerField1'] as String?,
        customerField2: json['customerField2'] as String?,
        logoUrl: json['logoUrl'] as String?,
        surcharge: _toDouble(json['surcharge']),
        usesPaymentItems: json['usesPaymentItems'] != false,
        isActive: json['isActive'] != false,
      );
}

/// GET /api/v1/bills/billers/{billerId}/items → `BillerItemDto`.
class BillerItemDto {
  final int billerId;
  final String billerItemId;
  final String? name;
  final String? code;
  final String? consumerIdField;

  /// QuickTeller payment code; sent with customer validation.
  final String? paymentCode;
  final double itemFee;
  final double amount;
  final bool isAmountFixed;
  final int sortOrder;
  final bool isActive;

  const BillerItemDto({
    required this.billerId,
    required this.billerItemId,
    this.name,
    this.code,
    this.consumerIdField,
    this.paymentCode,
    this.itemFee = 0,
    this.amount = 0,
    this.isAmountFixed = false,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory BillerItemDto.fromJson(Map<String, dynamic> json) => BillerItemDto(
        billerId: _toInt(json['billerId']),
        billerItemId: json['billerItemId']?.toString() ?? '',
        name: fixBrandSpellingOrNull(json['name'] as String?),
        code: json['code'] as String?,
        consumerIdField: json['consumerIdField'] as String?,
        paymentCode: json['paymentCode']?.toString(),
        itemFee: _toDouble(json['itemFee']),
        amount: _toDouble(json['amount']),
        isAmountFixed: json['isAmountFixed'] == true,
        sortOrder: _toInt(json['sortOrder']),
        isActive: json['isActive'] != false,
      );
}

// ── Beneficiaries ─────────────────────────────────────────────────────────────

/// GET /api/v1/bills/beneficiaries → `BeneficiaryResponseDto`.
class BeneficiaryDto {
  final String id;
  final String alias;
  final String mobileNo;
  final String networkProvider;

  /// `AirtimeAndData` | `Airtime` | `Data`.
  final String category;
  final int usageCount;
  final DateTime? lastUsedOn;

  const BeneficiaryDto({
    required this.id,
    required this.alias,
    required this.mobileNo,
    this.networkProvider = '',
    this.category = 'AirtimeAndData',
    this.usageCount = 0,
    this.lastUsedOn,
  });

  /// First letter of the alias, for the avatar.
  String get initial =>
      alias.trim().isEmpty ? '#' : alias.trim()[0].toUpperCase();

  factory BeneficiaryDto.fromJson(Map<String, dynamic> json) => BeneficiaryDto(
        id: json['id']?.toString() ?? '',
        alias: (json['alias'] as String?)?.trim() ?? '',
        mobileNo: (json['mobileNo'] as String?)?.trim() ?? '',
        networkProvider: (json['networkProvider'] as String?)?.trim() ?? '',
        category: json['category']?.toString() ?? 'AirtimeAndData',
        usageCount: _toInt(json['usageCount']),
        lastUsedOn: DateTime.tryParse(json['lastUsedOn']?.toString() ?? ''),
      );
}

/// POST /api/v1/bills/beneficiaries
class CreateBeneficiaryRequest {
  final String alias;
  final String mobileNo;
  final String networkProvider;
  final String category;

  const CreateBeneficiaryRequest({
    required this.alias,
    required this.mobileNo,
    required this.networkProvider,
    this.category = 'AirtimeAndData',
  });

  Map<String, dynamic> toJson() => {
        'alias': alias,
        'mobileNo': mobileNo,
        'networkProvider': networkProvider,
        'category': category,
      };
}

/// PUT /api/v1/bills/beneficiaries/{id}
class UpdateBeneficiaryRequest {
  final String alias;
  final String networkProvider;

  const UpdateBeneficiaryRequest({
    required this.alias,
    required this.networkProvider,
  });

  Map<String, dynamic> toJson() => {
        'alias': alias,
        'networkProvider': networkProvider,
      };
}

// ── Limits ────────────────────────────────────────────────────────────────────

/// GET /api/v1/bills/airtime/limit and /api/v1/bills/limit → `UtilityLimitResponseDto`.
class UtilityLimitDto {
  final String? utilityType;
  final double dailyLimit;
  final double dailySpent;
  final double remainingLimit;

  const UtilityLimitDto({
    this.utilityType,
    this.dailyLimit = 0,
    this.dailySpent = 0,
    this.remainingLimit = 0,
  });

  factory UtilityLimitDto.fromJson(Map<String, dynamic> json) =>
      UtilityLimitDto(
        utilityType: json['utilityType']?.toString(),
        dailyLimit: _toDouble(json['dailyLimit']),
        dailySpent: _toDouble(json['dailySpent']),
        remainingLimit: _toDouble(json['remainingLimit']),
      );
}

// ── Purchase requests ─────────────────────────────────────────────────────────

/// POST /api/v1/bills/airtime/topup
class AirtimeTopUpRequest {
  final String sourceAccount;
  final String serviceProvider;
  final String mobileNo;
  final double amount;
  final String transactionPin;
  final String? vtuMode;

  const AirtimeTopUpRequest({
    required this.sourceAccount,
    required this.serviceProvider,
    required this.mobileNo,
    required this.amount,
    required this.transactionPin,
    this.vtuMode,
  });

  Map<String, dynamic> toJson() => {
        'sourceAccount': sourceAccount,
        'serviceProvider': serviceProvider,
        'mobileNo': mobileNo,
        'amount': amount,
        'transactionPin': transactionPin,
        if (vtuMode != null) 'vtuMode': vtuMode,
      };
}

/// POST /api/v1/bills/data/purchase
class DataPurchaseRequest {
  final String sourceAccount;
  final String dataBundleId;
  final String mobileNo;
  final String transactionPin;

  const DataPurchaseRequest({
    required this.sourceAccount,
    required this.dataBundleId,
    required this.mobileNo,
    required this.transactionPin,
  });

  Map<String, dynamic> toJson() => {
        'sourceAccount': sourceAccount,
        'dataBundleId': dataBundleId,
        'mobileNo': mobileNo,
        'transactionPin': transactionPin,
      };
}

/// POST /api/v1/bills/payment
class BillPaymentRequest {
  final String sourceAccount;
  final int billerId;
  final String billerItemId;
  final String customerId;

  /// Omit for fixed-price items; required for variable amounts (e.g. prepaid meters).
  final double? amount;
  final String transactionPin;

  const BillPaymentRequest({
    required this.sourceAccount,
    required this.billerId,
    required this.billerItemId,
    required this.customerId,
    this.amount,
    required this.transactionPin,
  });

  Map<String, dynamic> toJson() => {
        'sourceAccount': sourceAccount,
        'billerId': billerId,
        'billerItemId': billerItemId,
        'customerId': customerId,
        if (amount != null) 'amount': amount,
        'transactionPin': transactionPin,
      };
}

// ── Payment history ───────────────────────────────────────────────────────────

/// GET /api/v1/bills/history → `BillPaymentResponseDto`.
///
/// The backend has no dedicated token field: QuickTeller returns the prepaid
/// meter token inside its response text, so [token] digs it out of that.
class BillPaymentHistoryDto {
  final String id;
  final String? transactionReference;
  final String? gatewayTransactionRef;
  final String? sourceAccount;
  final int billerId;
  final String? billerName;
  final String? categoryName;

  /// `Electricity` | `CableTv` | `Airtime` | `Data`.
  final String? utilityType;
  final String? billerItemId;
  final String? itemName;

  /// Meter number for electricity, smartcard/IUC for cable.
  final String? customerId;
  final double amount;
  final String? status;
  final bool isReversed;
  final String? responseCode;
  final String? responseDesc;
  final String? reversalDescription;
  final DateTime? createdAt;

  const BillPaymentHistoryDto({
    required this.id,
    this.transactionReference,
    this.gatewayTransactionRef,
    this.sourceAccount,
    this.billerId = 0,
    this.billerName,
    this.categoryName,
    this.utilityType,
    this.billerItemId,
    this.itemName,
    this.customerId,
    this.amount = 0,
    this.status,
    this.isReversed = false,
    this.responseCode,
    this.responseDesc,
    this.reversalDescription,
    this.createdAt,
  });

  factory BillPaymentHistoryDto.fromJson(Map<String, dynamic> json) =>
      BillPaymentHistoryDto(
        id: json['id']?.toString() ?? '',
        transactionReference: json['transactionReference'] as String?,
        gatewayTransactionRef: json['gatewayTransactionRef'] as String?,
        sourceAccount: json['sourceAccount'] as String?,
        billerId: _toInt(json['billerId']),
        billerName: fixBrandSpellingOrNull(json['billerName'] as String?),
        categoryName: json['categoryName'] as String?,
        utilityType: json['utilityType']?.toString(),
        billerItemId: json['billerItemId']?.toString(),
        itemName: fixBrandSpellingOrNull(json['itemName'] as String?),
        customerId: json['customerId'] as String?,
        amount: _toDouble(json['amount']),
        status: json['status']?.toString(),
        isReversed: json['isReversed'] == true,
        responseCode: json['responseCode']?.toString(),
        responseDesc: json['responseDesc'] as String?,
        reversalDescription: json['reversalDescription'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
      );

  static const _digits = r'\d(?:[\s-]?\d){15,19}';
  static final _labelledToken =
      RegExp('(?:token|pin)\\D{0,12}($_digits)', caseSensitive: false);
  static final _anyToken = RegExp('($_digits)');

  /// Prepaid meter token (digits grouped in fours), or null when the backend
  /// didn't return one — postpaid payments never have a token.
  ///
  /// Only `responseDesc` is searched: gateway references are often long
  /// all-digit strings, and showing one as a token would be worse than none.
  String? get token {
    final text = responseDesc ?? '';
    final match = _labelledToken.firstMatch(text) ?? _anyToken.firstMatch(text);
    if (match == null) return null;
    final digits = match.group(1)!.replaceAll(RegExp(r'\D'), '');
    return [
      for (var i = 0; i < digits.length; i += 4)
        digits.substring(i, i + 4 > digits.length ? digits.length : i + 4),
    ].join('-');
  }

  /// Units of energy bought, when the response text mentions them (e.g. "45.3 kWh").
  String? get units {
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*kwh', caseSensitive: false)
        .firstMatch(responseDesc ?? '');
    return match == null ? null : '${match.group(1)} kWh';
  }

  bool get isPostpaid => (itemName ?? '').toLowerCase().contains('postpaid');

  bool get isFailed =>
      isReversed || (status ?? '').toLowerCase().contains('fail');

  bool get isPending {
    final s = (status ?? '').toLowerCase();
    return !isFailed && (s.contains('pend') || s.contains('process'));
  }
}

// ── Customer validation ───────────────────────────────────────────────────────

/// POST /api/v1/bills/validate
class ValidateCustomerRequest {
  final String customerId;
  final String? billerItemId;
  final String? paymentCode;

  const ValidateCustomerRequest({
    required this.customerId,
    this.billerItemId,
    this.paymentCode,
  });

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        if (billerItemId != null && billerItemId!.isNotEmpty)
          'billerItemId': billerItemId,
        if (paymentCode != null && paymentCode!.isNotEmpty)
          'paymentCode': paymentCode,
      };
}

/// POST /api/v1/bills/validate → `ValidateCustomerResponseDto`.
class ValidateCustomerDto {
  final String? customerId;
  final String? fullName;
  final String? paymentCode;

  /// Amount due / fixed amount, when the biller reports one.
  final double? amount;
  final int amountType;
  final String? amountTypeDescription;
  final double? surcharge;
  final int billerId;
  final String? responseCode;

  const ValidateCustomerDto({
    this.customerId,
    this.fullName,
    this.paymentCode,
    this.amount,
    this.amountType = 0,
    this.amountTypeDescription,
    this.surcharge,
    this.billerId = 0,
    this.responseCode,
  });

  /// QuickTeller marks a fixed amount in the description ("Fixed", "Exact").
  bool get isAmountFixed {
    final d = (amountTypeDescription ?? '').toLowerCase();
    return d.contains('fixed') || d.contains('exact');
  }

  factory ValidateCustomerDto.fromJson(Map<String, dynamic> json) =>
      ValidateCustomerDto(
        customerId: json['customerId']?.toString(),
        fullName: (json['fullName'] as String?)?.trim(),
        paymentCode: json['paymentCode']?.toString(),
        amount: (json['amount'] as num?)?.toDouble(),
        amountType: _toInt(json['amountType']),
        amountTypeDescription: json['amountTypeDescription']?.toString(),
        surcharge: (json['surcharge'] as num?)?.toDouble(),
        billerId: _toInt(json['billerId']),
        responseCode: json['responseCode']?.toString(),
      );
}

enum CustomerValidationOutcome { verified, invalid, unavailable }

/// Result of validating a meter / smartcard number.
///
/// [CustomerValidationOutcome.invalid] means the biller rejected the number;
/// [CustomerValidationOutcome.unavailable] means we couldn't get an answer
/// (network, timeout, 5xx) and the user should retry.
class CustomerValidationResult {
  final CustomerValidationOutcome outcome;
  final ValidateCustomerDto? customer;
  final String message;

  const CustomerValidationResult._(this.outcome, this.customer, this.message);

  factory CustomerValidationResult.verified(ValidateCustomerDto customer) =>
      CustomerValidationResult._(
          CustomerValidationOutcome.verified, customer, 'Verified');

  factory CustomerValidationResult.invalid(String message) =>
      CustomerValidationResult._(CustomerValidationOutcome.invalid, null,
          humanizeProviderMessage(message));

  factory CustomerValidationResult.unavailable(String message) =>
      CustomerValidationResult._(
          CustomerValidationOutcome.unavailable, null, message);

  bool get isVerified => outcome == CustomerValidationOutcome.verified;
}

// ── Purchase result ───────────────────────────────────────────────────────────

/// Normalised outcome of airtime top-up, data purchase and bill payment.
///
/// All three responses share `transactionReference`, `status`, `isReversed`
/// and `responseDesc`, so one result type covers them.
class BillPurchaseResult {
  final bool isSuccess;
  final String? transactionReference;
  final String? status;
  final String message;
  final String? errorCode;

  const BillPurchaseResult({
    required this.isSuccess,
    this.transactionReference,
    this.status,
    required this.message,
    this.errorCode,
  });

  factory BillPurchaseResult.failure(String message, {String? errorCode}) =>
      BillPurchaseResult(
          isSuccess: false, message: message, errorCode: errorCode);

  factory BillPurchaseResult.fromEnvelope(Map<String, dynamic> body,
      {int? httpStatus}) {
    final data = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final status = data['status']?.toString();
    final reversed = data['isReversed'] == true;
    final failedStatus =
        status != null && status.toLowerCase().contains('fail');
    final ok = body['isSuccess'] == true && !reversed && !failedStatus;

    String? pick(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final message = ok
        ? (pick(body['message']) ?? pick(data['responseDesc']) ?? 'Successful')
        : (pick(body['message']) ??
            pick(data['reversalDescription']) ??
            pick(data['responseDesc']) ??
            pick(body['devMessage']) ??
            (httpStatus == 401
                ? 'Your session has expired. Please log in again.'
                : 'Transaction failed. Please try again.'));

    return BillPurchaseResult(
      isSuccess: ok,
      transactionReference: pick(data['transactionReference']),
      status: status,
      message: ok ? message : humanizeProviderMessage(message),
      errorCode: pick(body['errorCode']),
    );
  }
}

/// The VTU provider answers with colon-separated codes such as
/// `99:Topup Service Failed:But Reversal Successfull:No Issue`. Testers saw
/// that verbatim, so turn it into a sentence while keeping the code for support.
String humanizeProviderMessage(String message) {
  final parts = message.split(':').map((p) => p.trim()).toList();
  if (parts.length < 2 || !RegExp(r'^\d{1,3}$').hasMatch(parts.first)) {
    return message;
  }
  final code = parts.first;
  final rest = parts.sublist(1).where((p) => p.isNotEmpty).toList();
  final reversed = rest.any((p) => p.toLowerCase().contains('reversal'));
  final detail = rest.isEmpty ? 'Transaction failed' : rest.first;
  return reversed
      ? '$detail. Your money has been reversed (code $code).'
      : '$detail (code $code).';
}
