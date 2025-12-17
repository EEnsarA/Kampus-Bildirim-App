import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Konum servisi kapalı. Lütfen açınız.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Konum izni reddedildi.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Konum izinleri kalıcı olarak engellendi. Ayarlardan açmanız gerek.',
      );
    }

    // 3. Konumu Getir
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  static Future<String?> getAddressFromCoordinates(
    double lat,
    double long,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        String city = place.administrativeArea ?? ''; // İl
        String district = place.subAdministrativeArea ?? ''; // İlçe

        return "$city, $district".trim();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
