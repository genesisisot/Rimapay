import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import 'bills_dtos.dart';

/// Dio client for the RIMA Profile-Transaction bills API (`/api/v1/bills/*`):
/// airtime top-up, data bundles, biller categories/billers/items and bill payment.
///
/// List endpoints return an empty list on any failure; purchases never throw and
/// report failures through [BillPurchaseResult].
class BillsApiService {
  BillsApiService({Dio? dio})
      : _dio = dio ?? DioClient.instance.forBaseUrl(ApiConfig.profileBaseUrl);

  final Dio _dio;

  // ── Airtime ───────────────────────────────────────────────────────────────

  /// POST /api/v1/bills/airtime/topup
  Future<BillPurchaseResult> airtimeTopUp(AirtimeTopUpRequest request) =>
      _purchase('/api/v1/bills/airtime/topup', request.toJson());

  /// GET /api/v1/bills/airtime/limit
  Future<UtilityLimitDto?> getAirtimeLimit() =>
      _getObject('/api/v1/bills/airtime/limit', UtilityLimitDto.fromJson);

  // ── Data bundles ──────────────────────────────────────────────────────────

  /// GET /api/v1/bills/data/networks
  Future<List<String>> getDataNetworks() async {
    try {
      final res = await _dio.get('/api/v1/bills/data/networks');
      final body = res.data;
      if (body is Map<String, dynamic> && body['data'] is List) {
        return (body['data'] as List).map((e) => e.toString()).toList();
      }
      debugPrint('GET bills/data/networks → ${res.statusCode}');
      return const [];
    } catch (e) {
      debugPrint('GET bills/data/networks failed: $e');
      return const [];
    }
  }

  /// GET /api/v1/bills/data/plans?network=&validityType=
  Future<List<DataBundleDto>> getDataPlans({
    required String network,
    String? validityType,
  }) =>
      _getList(
        '/api/v1/bills/data/plans',
        DataBundleDto.fromJson,
        query: {
          'network': network,
          if (validityType != null) 'validityType': validityType,
        },
      );

  /// POST /api/v1/bills/data/purchase
  Future<BillPurchaseResult> purchaseData(DataPurchaseRequest request) =>
      _purchase('/api/v1/bills/data/purchase', request.toJson());

  // ── Billers ───────────────────────────────────────────────────────────────

  /// GET /api/v1/bills/categories
  Future<List<BillerCategoryDto>> getCategories() =>
      _getList('/api/v1/bills/categories', BillerCategoryDto.fromJson);

  /// GET /api/v1/bills/categories/{categoryId}/billers
  Future<List<BillerDto>> getBillers(int categoryId) =>
      _getList('/api/v1/bills/categories/$categoryId/billers', BillerDto.fromJson);

  /// GET /api/v1/bills/billers/{billerId}/items
  Future<List<BillerItemDto>> getBillerItems(int billerId) =>
      _getList('/api/v1/bills/billers/$billerId/items', BillerItemDto.fromJson);

  /// POST /api/v1/bills/payment
  Future<BillPurchaseResult> payBill(BillPaymentRequest request) =>
      _purchase('/api/v1/bills/payment', request.toJson());

  /// GET /api/v1/bills/limit?categoryId=
  Future<UtilityLimitDto?> getBillLimit(int categoryId) => _getObject(
        '/api/v1/bills/limit',
        UtilityLimitDto.fromJson,
        query: {'categoryId': categoryId},
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      final body = res.data;
      if (body is Map<String, dynamic> && body['data'] is List) {
        return (body['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(fromJson)
            .toList();
      }
      debugPrint('GET $path → ${res.statusCode}');
      return <T>[];
    } catch (e) {
      debugPrint('GET $path failed: $e');
      return <T>[];
    }
  }

  Future<T?> _getObject<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      final body = res.data;
      if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
        return fromJson(body['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('GET $path failed: $e');
      return null;
    }
  }

  Future<BillPurchaseResult> _purchase(
      String path, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post(path, data: payload);
      final body = res.data;
      if (body is Map<String, dynamic>) {
        return BillPurchaseResult.fromEnvelope(body, httpStatus: res.statusCode);
      }
      return BillPurchaseResult.failure(res.statusCode == 401
          ? 'Your session has expired. Please log in again.'
          : 'Unexpected response (${res.statusCode}).');
    } on DioException catch (e) {
      return BillPurchaseResult.failure(_dioMessage(e));
    } catch (e) {
      return BillPurchaseResult.failure('Unexpected error: $e');
    }
  }

  String _dioMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Network error. Please check your internet connection.';
    }
    return e.message ?? 'Network request failed.';
  }
}
