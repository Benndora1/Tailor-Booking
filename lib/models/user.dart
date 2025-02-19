// models/user.dart
class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'user', 'tailor', or 'admin'
  final String status; // 'approved', 'pending', 'rejected' (optional for tailors)

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.status = '', // Default to empty string for normal users
  });

  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'user',
      status: map['status'] ?? '', // Default to empty string
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'status': status,
    };
  }
}