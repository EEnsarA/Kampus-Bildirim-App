/// =============================================================================
/// KAMPÜS BİLDİRİM - Konum Servisi (location_service.dart)
/// =============================================================================
/// Bu dosya GPS konum işlemlerini yönetir.
/// Geolocator ve Geocoding paketlerini kullanır.
///
/// İçerdiği İşlemler:
/// - Mevcut konumu alma
/// - Koordinatları adrese çevirme (Reverse Geocoding)
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:geocoding/geocoding.dart'; // Adres çevirme için
import 'package:geolocator/geolocator.dart'; // GPS konum için

// =============================================================================
// LocationService Sınıfı
// =============================================================================
/// Konum işlemlerini yöneten statik servis sınıfı.
/// Static metodlar kullanıldığı için instance oluşturmaya gerek yoktur.
class LocationService {
  // -------------------------------------------------------------------------
  // Mevcut Konumu Al
  // -------------------------------------------------------------------------
  /// Cihazın GPS konumunu alır.
  ///
  /// İşlem Adımları:
  /// 1. Konum servisi açık mı kontrol et
  /// 2. Konum izni var mı kontrol et (yoksa iste)
  /// 3. Yüksek hassasiyetle konum al
  ///
  /// Hatalar:
  /// - Konum servisi kapalıysa hata fırlatır
  /// - İzin reddedilirse hata fırlatır
  // -------------------------------------------------------------------------
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Konum servisi açık mı?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Konum servisi kapalı. Lütfen açınız.');
    }

    // 2. İzin kontrolü
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // İzin iste
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Konum izni reddedildi.');
      }
    }

    // Kalıcı olarak engellenmişse
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Konum izinleri kalıcı olarak engellendi. Ayarlardan açmanız gerek.',
      );
    }

    // 3. Yüksek hassasiyetle konum al
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // -------------------------------------------------------------------------
  // Koordinatlardan Adres Al (Reverse Geocoding)
  // -------------------------------------------------------------------------
  /// Enlem ve boylamdan okunabilir adres döndürür.
  /// Format: "İl, İlçe" (orn: "Ankara, Çankaya")
  ///
  /// Başarısız olursa null döner.
  // -------------------------------------------------------------------------
  static Future<String?> getAddressFromCoordinates(
    double lat,
    double long,
  ) async {
    try {
      // Koordinatlardan adres listesi al
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
