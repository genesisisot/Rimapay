// ignore_for_file: deprecated_member_use
import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:rimapay/Constants/En.dart';
import 'package:rimapay/Models/UserDataModel.dart';

class PersonalSignupParams {
  final String? sessionId;
  final String? requestType;
  final String? method;
  final String? acceptOurTerms;
  final String? customerTitle;
  final String? customerFirstName;
  final String? customerSurnameName;
  final String? customerMiddleName;
  final String? emailAddress;
  final String? dateOfBirth;
  final String? gender;
  final String? mobilePhoneNo;
  final String? password;
  final String? confirmPassword;
  final String? nationality;
  final String? residentState;
  final String? residentCity;
  final String? residentLga;
  final String? addressLine1;
  final String? addressLine2;
  final String? accountType;
  final String? customerBVN;
  final String? customerNIN;
  final String? latitude;
  final String? longitude;

  PersonalSignupParams({
    this.sessionId,
    this.requestType,
    this.method,
    this.acceptOurTerms,
    this.customerTitle,
    this.customerFirstName,
    this.customerSurnameName,
    this.customerMiddleName,
    this.emailAddress,
    this.dateOfBirth,
    this.gender,
    this.mobilePhoneNo,
    this.password,
    this.confirmPassword,
    this.nationality,
    this.residentState,
    this.residentCity,
    this.residentLga,
    this.addressLine1,
    this.addressLine2,
    this.accountType,
    this.customerBVN,
    this.customerNIN,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (sessionId != null) json["sessionId"] = sessionId;
    if (requestType != null) json["requestType"] = requestType;
    if (method != null) json["method"] = method;
    if (acceptOurTerms != null) json["acceptOurTerms"] = acceptOurTerms;
    if (customerTitle != null) json["CustomerTitle"] = customerTitle;
    if (customerFirstName != null) json["CustomerFirstName"] = customerFirstName;
    if (customerSurnameName != null) json["CustomerSurnameName"] = customerSurnameName;
    if (customerMiddleName != null) json["CustomerMiddleName"] = customerMiddleName;
    if (emailAddress != null) json["EmailAddress"] = emailAddress;
    if (dateOfBirth != null) json["DateOfBirth"] = dateOfBirth;
    if (gender != null) json["Gender"] = gender;
    if (mobilePhoneNo != null) json["MobilePhoneNo"] = mobilePhoneNo;
    if (password != null) json["password"] = password;
    if (confirmPassword != null) json["confirmPassword"] = confirmPassword;
    if (nationality != null) json["Nationality"] = nationality;
    if (residentState != null) json["residentState"] = residentState;
    if (residentCity != null) json["residentCity"] = residentCity;
    if (residentLga != null) json["residentLga"] = residentLga;
    if (addressLine1 != null) json["AddressLine1"] = addressLine1;
    if (addressLine2 != null) json["AddressLine2"] = addressLine2;
    if (accountType != null) json["accountType"] = accountType;
    if (customerBVN != null) json["customerBVN"] = customerBVN;
    if (customerNIN != null) json["customerNIN"] = customerNIN;
    if (latitude != null) json["latitude"] = latitude;
    if (longitude != null) json["longitude"] = longitude;

    return json;
  }
}

class PersonalSignupService {
  final ProviderRef ref;

  PersonalSignupService(this.ref);

  Future<PersonalSignupResponse> signupPersonal(PersonalSignupParams params) async {
    try {
      final url = Uri.parse('$BASE_URL/processes');

      final response = await post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(params.toJson()),
      );

      log(response.body.toString());

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        SignUpData resBody = SignUpData.fromJson(json);

        if (resBody.status == 200 && resBody.message == SUCCESS) {
          return PersonalSignupResponse(
            errmessage: resBody.message ?? SUCCESS,
            status: "success",
            model: resBody,
          );
        } else {
          return PersonalSignupResponse(
            errmessage: resBody.message ?? ERROR_TEXT,
            status: "failed",
            model: null,
          );
        }
      } else {
        Map<String, dynamic> res = jsonDecode(response.body);
        SignUpData resbody = SignUpData.fromJson(res);
        return PersonalSignupResponse(
          errmessage: resbody.message ?? ERROR_TEXT,
          status: "failed",
          model: null,
        );
      }
    } on SocketException catch (_) {
      log('Network error: no internet connection.');

      return PersonalSignupResponse(
        errmessage: NETWORK_ERROR,
        status: "failed",
        model: null,
      );
    } on TimeoutException catch (_) {
      log('Network error: request timed out.');

      return PersonalSignupResponse(
        errmessage: TIME_OUT_ERROR,
        status: "failed",
        model: null,
      );
    } catch (e) {
      log("An error occurred: $e");

      return PersonalSignupResponse(
        errmessage: AN_ERROR_OCCURED_WHILE_PROCESSING_YOUR_REQUEST_PLEASE_TRY_AGAIN,
        status: "failed",
        model: null,
      );
    }
  }
}

final signupServiceProvider = Provider.autoDispose<PersonalSignupService>(
  (ref) => PersonalSignupService(ref),
);

final signupResponseStateProvider = StateProvider.autoDispose<PersonalSignupResponse?>((ref) => null);

final signupProvider = FutureProvider.autoDispose.family<bool, PersonalSignupParams>(
  (ref, params) async {
    final signupResponse = await ref.watch(signupServiceProvider).signupPersonal(params);

    final isSignupSuccessful = signupResponse.model != null && signupResponse.status == "success";

    ref.read(signupResponseStateProvider.notifier).state = signupResponse;

    return isSignupSuccessful;
  },
);

class PersonalSignupResponse {
  final String? errmessage;
  final String? status;
  final SignUpData? model;

  PersonalSignupResponse({
    required this.errmessage,
    required this.status,
    required this.model,
  });
}

class SignUpData {
  SignUpData({
    required this.status,
    required this.message,
    required this.data,
  });

  final num? status;
  final String? message;
  final UserData? data;

  SignUpData copyWith({
    num? status,
    String? message,
    UserData? data,
  }) {
    return SignUpData(
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  factory SignUpData.fromJson(Map<String, dynamic> json) {
    return SignUpData(
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
