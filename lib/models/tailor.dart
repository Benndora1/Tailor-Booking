// models/tailor.dart
class Tailor {
  final String id;
  final String userId; // Reference to the user document
  final String name;
  final String location;
  final List<String> services;
  final double rating;
  final String status; // 'approved', 'pending', 'rejected'

  Tailor({
    required this.id,
    required this.userId,
    required this.name,
    required this.location,
    required this.services,
    required this.rating,
    required this.status,
  });

  factory Tailor.fromMap(String id, Map<String, dynamic> map) {
    return Tailor(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      services: List<String>.from(map['services'] ?? []),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'location': location,
      'services': services,
      'rating': rating,
      'status': status,
    };
  }
}