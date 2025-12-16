class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String department;

  //ctor
  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.department,
  });

  // Map (key-value) :
  // key => String
  // value => dynamic (her şey olabilir int,float,bool,string)
  // firestore map => AppUser Çevirme
  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? 'İsimsiz',
      role: data['role'] ?? 'user',
      department: data['department'] ?? '',
    );
  }

  // AppUser => Firestore map çevirme
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'department': department,
    };
  }
}
