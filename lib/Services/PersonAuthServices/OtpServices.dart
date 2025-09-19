// ignore_for_file: deprecated_member_use

import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:rimapay/Constants/En.dart';
import 'package:rimapay/Models/UserDataModel.dart';

class OtpParams {

  final String? otpCode;

  final String? sessionId;
  final String? requestType;
  final String? method;

  OtpParams({

    this.otpCode,
 
    this.sessionId,
    this.requestType,
    this.method,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (sessionId != null) json["sessionId"] = sessionId;
    if (requestType != null) json["requestType"] = requestType;
    if (method != null) json["method"] = method;
   
    if (otpCode != null) json["sentOTP"] = otpCode;


    return json;
  }
}

class OtpService {
  final ProviderRef ref;

  OtpService(this.ref);

  Future<OtpResponse> resendOtp(OtpParams params) async {
    try {
  
      
      final url = Uri.parse('$BASE_URL/processes');
      log(params.toJson().toString());
      
      final response = await post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(params.toJson()),
      );

      log("OTP RESEND RESPONSE -------> ${response.body.toString()}");

      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        OtpData resBody = OtpData.fromJson(json);

        if (resBody.status == 200 && resBody.message == SUCCESS) {
          return OtpResponse(
            errmessage: resBody.message ?? "OTP Resent Successfully",
            status: "success",
            model: resBody,
          );
        } else {
          return OtpResponse(
            errmessage: resBody.message ?? ERROR_TEXT,
            status: "failed",
            model: null,
          );
        }
      } else {
        Map<String, dynamic> res = jsonDecode(response.body);
        OtpData resbody = OtpData.fromJson(res);
        return OtpResponse(
          errmessage: resbody.message ?? ERROR_TEXT,
          status: "failed",
          model: null,
        );
      }
    } on SocketException catch (_) {
      log('Network error: no internet connection.');
      return OtpResponse(
        errmessage: NETWORK_ERROR,
        status: "failed",
        model: null,
      );
    } on TimeoutException catch (_) {
      log('Network error: request timed out.');
      return OtpResponse(
        errmessage: TIME_OUT_ERROR,
        status: "failed",
        model: null,
      );
    } catch (e) {
      log("An error occurred: $e");
      return OtpResponse(
        errmessage: AN_ERROR_OCCURED_WHILE_PROCESSING_YOUR_REQUEST_PLEASE_TRY_AGAIN,
        status: "failed",
        model: null,
      );
    }
  }

  Future<OtpResponse> verifyOtp(OtpParams params) async {
    try {
    
      log("OTP_CODE: ${params.otpCode}");
      
      final url = Uri.parse('$BASE_URL/processes');
      log(params.toJson().toString());
      
      final response = await post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(params.toJson()),
      );

      log("OTP VERIFY RESPONSE -------> ${response.body.toString()}");

      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        OtpData resBody = OtpData.fromJson(json);

        if (resBody.status == 200 && resBody.message == SUCCESS) {
          return OtpResponse(
            errmessage: resBody.message ?? "OTP Verified Successfully",
            status: "success",
            model: resBody,
          );
        } else {
          return OtpResponse(
            errmessage: resBody.message ?? ERROR_TEXT,
            status: "failed",
            model: null,
          );
        }
      } else {
        Map<String, dynamic> res = jsonDecode(response.body);
        OtpData resbody = OtpData.fromJson(res);
        return OtpResponse(
          errmessage: resbody.message ?? ERROR_TEXT,
          status: "failed",
          model: null,
        );
      }
    } on SocketException catch (_) {
      log('Network error: no internet connection.');
      return OtpResponse(
        errmessage: NETWORK_ERROR,
        status: "failed",
        model: null,
      );
    } on TimeoutException catch (_) {
      log('Network error: request timed out.');
      return OtpResponse(
        errmessage: TIME_OUT_ERROR,
        status: "failed",
        model: null,
      );
    } catch (e) {
      log("An error occurred: $e");
      return OtpResponse(
        errmessage: AN_ERROR_OCCURED_WHILE_PROCESSING_YOUR_REQUEST_PLEASE_TRY_AGAIN,
        status: "failed",
        model: null,
      );
    }
  }
}

// Providers
final otpServiceProvider = Provider.autoDispose<OtpService>(
  (ref) => OtpService(ref),
);

final resendOtpResponseStateProvider = StateProvider.autoDispose<OtpResponse?>((ref) => null);
final verifyOtpResponseStateProvider = StateProvider.autoDispose<OtpResponse?>((ref) => null);

final resendOtpProvider = FutureProvider.autoDispose.family<bool, OtpParams>(
  (ref, params) async {
    final otpResponse = await ref.watch(otpServiceProvider).resendOtp(params);
    
    final isOtpSent = otpResponse.model != null && otpResponse.status == SUCCESS;
    
    ref.read(resendOtpResponseStateProvider.notifier).state = otpResponse;
    
    return isOtpSent;
  },
);

final verifyOtpProvider = FutureProvider.autoDispose.family<bool, OtpParams>(
  (ref, params) async {
    final otpResponse = await ref.watch(otpServiceProvider).verifyOtp(params);
    
    final isOtpVerified = otpResponse.model != null && otpResponse.status == SUCCESS;
    
    ref.read(verifyOtpResponseStateProvider.notifier).state = otpResponse;
    
    return isOtpVerified;
  },
);

// Response classes
class OtpResponse {
  final String? errmessage;
  final String? status;
  final OtpData? model;

  OtpResponse({
    required this.errmessage,
    required this.status,
    required this.model,
  });
}

class OtpData {
  OtpData({
    required this.status,
    required this.message,
    required this.data,
  });

  final num? status;
  final String? message;
  final UserData? data;

  OtpData copyWith({
    num? status,
    String? message,
    UserData? data,
  }) {
    return OtpData(
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  factory OtpData.fromJson(Map<String, dynamic> json) {
    return OtpData(
      status: json["status"],
      message: json["message"],
      data: json["data"] == null ? null : UserData.fromJson(json["data"]),
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