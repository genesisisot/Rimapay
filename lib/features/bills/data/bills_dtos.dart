// DTOs for the RIMA Profile-Transaction bills endpoints (`/api/v1/bills/*`).
//
// Shapes mirror https://api.rimabank.ng/profile-transaction/swagger. Every
// response is wrapped in the standard `ApiResponse<T>` envelope
// `{ isSuccess, errorCode, statusCode, message, devMessage, data }`.

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
        name: json['name'] as String?,
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
        name: json['name'] as String?,
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
  String get displayName =>
      (shortName?.trim().isNotEmpty ?? false) ? shortName!.trim() : (name ?? 'Biller');

  factory BillerDto.fromJson(Map<String, dynamic> json) => BillerDto(
        billerId: _toInt(json['billerId']),
        billerCategoryId: _toInt(json['billerCategoryId']),
        categoryName: json['categoryName'] as String?,
        name: json['name'] as String?,
        shortName: json['shortName'] as String?,
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
    this.itemFee = 0,
    this.amount = 0,
    this.isAmountFixed = false,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory BillerItemDto.fromJson(Map<String, dynamic> json) => BillerItemDto(
        billerId: _toInt(json['billerId']),
        billerItemId: json['billerItemId']?.toString() ?? '',
        name: json['name'] as String?,
        code: json['code'] as String?,
        consumerIdField: json['consumerIdField'] as String?,
        itemFee: _toDouble(json['itemFee']),
        amount: _toDouble(json['amount']),
        isAmountFixed: json['isAmountFixed'] == true,
        sortOrder: _toInt(json['sortOrder']),
        isActive: json['isActive'] != false,
      );
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

  factory UtilityLimitDto.fromJson(Map<String, dynamic> json) => UtilityLimitDto(
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
      BillPurchaseResult(isSuccess: false, message: message, errorCode: errorCode);

  factory BillPurchaseResult.fromEnvelope(Map<String, dynamic> body, {int? httpStatus}) {
    final data = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final status = data['status']?.toString();
    final reversed = data['isReversed'] == true;
    final failedStatus = status != null && status.toLowerCase().contains('fail');
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
      message: message,
      errorCode: pick(body['errorCode']),
    );
  }
}
