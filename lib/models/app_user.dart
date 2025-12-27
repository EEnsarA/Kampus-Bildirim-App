// app_user.dart
// kullanıcı modeli - firebase auth ile eşleştiriliyor

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String surname;
  final String department;
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
