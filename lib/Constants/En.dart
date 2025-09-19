import 'package:rimapay/Utils/MyFlavorsConfig.dart';

String BASE_URL = MyAppConfig.getIsLive() == true ? "https://rimamfb.com/apiv1.0" : "https://rimamfb.com/apiv1.0";
const String ERROR_TEXT = "Ops, an error occured";
const String SUCCESS = "Success";
const String NETWORK_ERROR = "Network error. Please check your internet connection.";
const String TIME_OUT_ERROR = "Request timed out. Please try again.";
const String AN_ERROR_OCCURED_WHILE_PROCESSING_YOUR_REQUEST_PLEASE_TRY_AGAIN = "An error occured while processing your request please try again later";
String REQUEST_TYPE = MyAppConfig.getIsLive() == true ? "testDeployment" : "testDeployment";
