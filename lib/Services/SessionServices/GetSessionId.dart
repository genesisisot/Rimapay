// ignore_for_file: deprecated_member_use
import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:rimapay/Constants/En.dart';
import 'package:rimapay/Services/SessionServices/SessionProvider.dart';
import 'package:rimapay/Utils/Logics.dart';

class GetSessionService {
  final ProviderRef ref;

  GetSessionService(this.ref);

  Future<AuthResponse> authenticate() async {
    try {
      final url = Uri.parse('$BASE_URL/authorization');

      final location = await getCurrentLocation();
      final body = {
        "method": "authorization",
        "username": "admin",
        "password": "1aa373",
        "latitude": "${location["lat"]}",
        "longitude": "${location["lng"]}",
      };

      final response = await post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer 10266560e8cc88866889421da7212a20",
        },
        body: jsonEncode(body),
      );

      log(response.body.toString());

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        SessionResModel resBody = SessionResModel.fromJson(json);

        if (resBody.status == 200 && resBody.message == SUCCESS) {
          return AuthResponse(
            errmessage: resBody.message ?? ERROR_TEXT,
            status: "failed",
            model: resBody,
          );
        } else {
          return AuthResponse(
            errmessage: resBody.message ?? ERROR_TEXT,
            status: "failed",
            model: null,
          );
        }
      } else {
        Map<String, dynamic> res = jsonDecode(response.body);
        SessionResModel resbody = SessionResModel.fromJson(res);
        return AuthResponse(
          errmessage: resbody.message ?? ERROR_TEXT,
          status: "failed",
          model: null,
        );
      }
    } on SocketException catch (_) {
      log('Network error: no internet connection.');

      return AuthResponse(
        errmessage: NETWORK_ERROR,
        status: "failed",
        model: null,
      );
    } on TimeoutException catch (_) {
      log('Network error: request timed out.');

      return AuthResponse(
        errmessage: TIME_OUT_ERROR,
        status: "failed",
        model: null,
      );
    } catch (e) {
      log("An error occurred: $e");

      return AuthResponse(
        errmessage: AN_ERROR_OCCURED_WHILE_PROCESSING_YOUR_REQUEST_PLEASE_TRY_AGAIN,
        status: "failed",
        model: null,
      );
    }
  }
}

final authServiceProvider = Provider.autoDispose<GetSessionService>(
  (ref) => GetSessionService(ref),
);

final authResponseStateProvider = StateProvider.autoDispose<AuthResponse?>((ref) => null);

final authenticateProvider = FutureProvider.autoDispose<AuthResponse?>(
  (ref) async {
    final authResponse = await ref.watch(authServiceProvider).authenticate();

    final isAuthenticated = authResponse.model != null;

    ref.read(authResponseStateProvider.notifier).state = authResponse;
    if (isAuthenticated) {
      ref.read(sessionProvider.notifier).saveSessionId(authResponse.model?.data?.sessionId ?? "");
    }
    return authResponse;
  },
);

class AuthResponse {
  final String? errmessage;
  final String? status;
  final SessionResModel? model;

  AuthResponse({
    required this.errmessage,
    required this.status,
    required this.model,
  });
}

class SessionResModel {
  SessionResModel({
    required this.status,
    required this.message,
    required this.data,
  });

  final num? status;
  final String? message;
  final SessionData? data;

  SessionResModel copyWith({
    num? status,
    String? message,
    SessionData? data,
  }) {
    return SessionResModel(
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  factory SessionResModel.fromJson(Map<String, dynamic> json) {
    return SessionResModel(
      status: json["status"],
      message: json["message"],
      data: json["data"] == null ? null : SessionData.fromJson(json["data"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data?.toJson(),
      };

  @override
  String toString() {
    return "$status, $message, $data, ";
  }
}

class SessionData {
  SessionData({
    required this.businessName,
    required this.requestType,
    required this.sessionId,
    required this.expireTime,
    required this.deviceIp,
    required this.deviceLatitude,
    required this.deviceLongitude,
    required this.timeStamp,
  });

  final String? businessName;
  final String? requestType;
  final String? sessionId;
  final DateTime? expireTime;
  final String? deviceIp;
  final String? deviceLatitude;
  final String? deviceLongitude;
  final DateTime? timeStamp;

  SessionData copyWith({
    String? businessName,
    String? requestType,
    String? sessionId,
    DateTime? expireTime,
    String? deviceIp,
    String? deviceLatitude,
    String? deviceLongitude,
    DateTime? timeStamp,
  }) {
    return SessionData(
      businessName: businessName ?? this.businessName,
      requestType: requestType ?? this.requestType,
      sessionId: sessionId ?? this.sessionId,
      expireTime: expireTime ?? this.expireTime,
      deviceIp: deviceIp ?? this.deviceIp,
      deviceLatitude: deviceLatitude ?? this.deviceLatitude,
      deviceLongitude: deviceLongitude ?? this.deviceLongitude,
      timeStamp: timeStamp ?? this.timeStamp,
    );
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      businessName: json["businessName"],
      requestType: json["requestType"],
      sessionId: json["sessionId"],
      expireTime: DateTime.tryParse(json["expireTime"] ?? ""),
      deviceIp: json["deviceIp"],
      deviceLatitude: json["deviceLatitude"],
      deviceLongitude: json["deviceLongitude"],
      timeStamp: DateTime.tryParse(json["timeStamp"] ?? ""),
    );
  }

  Map<String, dynamic> toJson() => {
        "businessName": businessName,
        "requestType": requestType,
        "sessionId": sessionId,
        "expireTime": expireTime?.toIso8601String(),
        "deviceIp": deviceIp,
        "deviceLatitude": deviceLatitude,
        "deviceLongitude": deviceLongitude,
        "timeStamp": timeStamp?.toIso8601String(),
      };

  @override
  String toString() {
    return "$businessName, $requestType, $sessionId, $expireTime, $deviceIp, $deviceLatitude, $deviceLongitude, $timeStamp, ";
  }
}
