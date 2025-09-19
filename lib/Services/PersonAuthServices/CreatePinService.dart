// ignore_for_file: deprecated_member_use

import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:rimapay/Constants/En.dart';
import 'package:rimapay/Models/UserDataModel.dart';
import 'package:rimapay/Services/UserDataProvider.dart';

class CreatePinParams {
  final String? sessionId;
  final String? requestType;
  final String? method;
  final String? sentPIN;
  final String? sentConfirmPIN;

  CreatePinParams({
    this.sessionId,
    this.requestType,
    this.method,
    this.sentPIN,
    this.sentConfirmPIN,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (sessionId != null) json["sessionId"] = sessionId;
    if (requestType != null) json["requestType"] = requestType;
    if (method != null) json["method"] = method;
    if (sentPIN != null) json["sentPIN"] = sentPIN;
    if (sentConfirmPIN != null) json["sentConfirmPIN"] = sentConfirmPIN;

    return json;
  }
}

class CreatePinService {
  final ProviderRef ref;

  CreatePinService(this.ref);

  Future<CreatePinResponse> createPin(CreatePinParams params) async {
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

      log("CREATE PIN RESPONSE -------> ${response.body.toString()}");

      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        CreatePinData resBody = CreatePinData.fromJson(json);

        if (resBody.status == 200 && resBody.message == SUCCESS) {
          return CreatePinResponse(
            errmessage: resBody.message ?? "PIN Created Successfully",
            status: "success",
            model: resBody,
          );
        } else {
          return CreatePinResponse(
            errmessage: resBody.message ?? ERROR_TEXT,
            status: "failed",
            model: null,
          );
        }
      } else {
        Map<String, dynamic> res = jsonDecode(response.body);
        CreatePinData resbody = CreatePinData.fromJson(res);
        return CreatePinResponse(
          errmessage: resbody.message ?? ERROR_TEXT,
          status: "failed",
          model: null,
        );
      }
    } on SocketException catch (_) {
      log('Network error: no internet connection.');
      return CreatePinResponse(
        errmessage: NETWORK_ERROR,
        status: "failed",
        model: null,
      );
    } on TimeoutException catch (_) {
      log('Network error: request timed out.');
      return CreatePinResponse(
        errmessage: TIME_OUT_ERROR,
        status: "failed",
        model: null,
      );
    } catch (e) {
      log("An error occurred: $e");
      return CreatePinResponse(
        errmessage: AN_ERROR_OCCURED_WHILE_PROCESSING_YOUR_REQUEST_PLEASE_TRY_AGAIN,
        status: "failed",
        model: null,
      );
    }
  }
}

// Providers
final createPinServiceProvider = Provider.autoDispose<CreatePinService>(
  (ref) => CreatePinService(ref),
);

final createPinResponseStateProvider = StateProvider.autoDispose<CreatePinResponse?>((ref) => null);

final createPinProvider = FutureProvider.autoDispose.family<bool, CreatePinParams>(
  (ref, params) async {
    final createPinResponse = await ref.watch(createPinServiceProvider).createPin(params);
    
    final isPinCreated = createPinResponse.model != null && createPinResponse.status == SUCCESS;
    
    ref.read(createPinResponseStateProvider.notifier).state = createPinResponse;
    if(isPinCreated){
      ref.read(userDataProvider.notifier).updateUserData("pin", params.sentPIN);
    }
    return isPinCreated;
  },
);

// Response classes
class CreatePinResponse {
  final String? errmessage;
  final String? status;
  final CreatePinData? model;

  CreatePinResponse({
    required this.errmessage,
    required this.status,
    required this.model,
  });
}

class CreatePinData {
  CreatePinData({
    required this.status,
    required this.message,
    required this.data,
  });

  final num? status;
  final String? message;
  final UserData? data;

  CreatePinData copyWith({
    num? status,
    String? message,
    UserData? data,
  }) {
    return CreatePinData(
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  factory CreatePinData.fromJson(Map<String, dynamic> json) {
    return CreatePinData(
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