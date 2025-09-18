import 'package:geolocator/geolocator.dart';
import 'package:rimapay/Services/SessionServices/SessionProvider.dart';
import 'package:rimapay/main.dart';

String addLeadingZero(String input) {
  if (input.startsWith('0') && input.length > 1) {
    return input;
  } else if (input.length > 1) {
    return "0$input";
  }
  return input;
}

Future<Map<String, double>> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied, we cannot request permissions.');
  }

  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

  return {
    'lat': position.latitude,
    'lng': position.longitude,
  };
}

String? getSessionId() {
  final sessionId = RimaPayApp.globalRef.watch(sessionProvider);
  return sessionId;
}
