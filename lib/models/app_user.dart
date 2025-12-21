class AppUser {
  final String uid;
  final String email;
  final String name;
  final String surname;
  final String role;
  final String department;
  final String? avatarUrl;

  //ctor
  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.surname,
    required this.role,
    required this.department,
    this.avatarUrl,
  });

  // Tam ad getter'ı
  String get fullName => '$name $surname';

  // Map (key-value) :
  // key => String
  // value => dynamic (her şey olabilir int,float,bool,string)
  // firestore map => AppUser Çevirme
  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? 'İsimsiz',
      surname: data['surname'] ?? '',
      role: data['role'] ?? 'user',
      department: data['department'] ?? '',
      avatarUrl: data['avatarUrl'],
    );
  }

  // AppUser => Firestore map çevirme
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
