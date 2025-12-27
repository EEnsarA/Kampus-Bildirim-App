/// =============================================================================
/// KAMPÜS BİLDİRİM - Kullanıcı Modeli (app_user.dart)
/// =============================================================================
/// Bu dosya uygulamanın kullanıcı veri modelini içerir.
/// Firebase Auth ile doğrulanan kullanıcıların profillerini temsil eder.
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

/// =============================================================================
/// AppUser Sınıfı
/// =============================================================================
/// Kullanıcı profillerinin ana veri modelidir.
/// Firestore'daki 'users' collection'undaki verileri temsil eder.
/// =============================================================================
class AppUser {
  // -------------------------------------------------------------------------
  // Kimlik Bilgileri
  // -------------------------------------------------------------------------
  final String uid; // Firebase Auth kullanıcı ID'si (benzersiz)
  final String email; // E-posta adresi

  // -------------------------------------------------------------------------
  // Kişisel Bilgiler
  // -------------------------------------------------------------------------
  final String name; // Ad
  final String surname; // Soyad
  final String department; // Birim/Bölüm (orn: Bilgisayar Mühendisliği)

  // -------------------------------------------------------------------------
  // Yetki ve Profil
  // -------------------------------------------------------------------------
  final String role; // Rol: 'user' veya 'admin'
  final String? avatarUrl; // Profil fotoğrafı URL'si (opsiyonel)

  // -------------------------------------------------------------------------
  // Constructor (Yapıcı Metod)
  // -------------------------------------------------------------------------
  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.surname,
    required this.role,
    required this.department,
    this.avatarUrl,
  });

  // -------------------------------------------------------------------------
  // Tam Ad Getter'ı
  // -------------------------------------------------------------------------
  /// Ad ve soyadı birleştirerek tam ismi döndürür.
  String get fullName => '$name $surname';

  // =========================================================================
  // Firestore Dönüşüm Metodları
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// fromMap - Firestore'dan Nesneye Dönüşüm (Factory Constructor)
  /// ---------------------------------------------------------------------------
  /// Firestore dokümanından (Map) AppUser nesnesine dönüştürür.
  ///
  /// Parametreler:
  /// - data: Firestore'dan gelen key-value veri (Map<String, dynamic>)
  /// - uid: Firebase Auth'dan gelen kullanıcı ID'si
  /// ---------------------------------------------------------------------------
  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? 'İsimsiz',
      surname: data['surname'] ?? '',
      role: data['role'] ?? 'user', // Varsayılan: normal kullanıcı
      department: data['department'] ?? '',
      avatarUrl: data['avatarUrl'],
    );
  }

  /// ---------------------------------------------------------------------------
  /// toMap - Nesneden Firestore'a Dönüşüm
  /// ---------------------------------------------------------------------------
  /// AppUser nesnesini Firestore'a yazılabilir Map formatına dönüştürür.
  /// Kayıt veya profil güncelleme işlemlerinde kullanılır.
  /// ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'surname': surname,
      'role': role,
      'department': department,
      'avatarUrl': avatarUrl,
    };
  }
}
