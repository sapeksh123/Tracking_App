import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class LocationService {
  final ApiService api;
  LocationService({required this.api});

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<Map<String, dynamic>> sendPing(String userId) async {
    final pos = await getCurrentLocation();
    final apiRes = await api.postPing(userId, pos.latitude, pos.longitude, accuracy: pos.accuracy);
    return apiRes;
  }
}
