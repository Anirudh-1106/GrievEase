import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  static Future<Position?> getCurrentLocation() async {
    if (!await requestPermission()) return null;
    return await Geolocator.getCurrentPosition();
  }

  static Future<String?> getAddressFromCoordinates(
      double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      Placemark place = placemarks[0];
      return '${place.street}, ${place.locality}, ${place.administrativeArea}';
    } catch (e) {
      return null;
    }
  }
}
