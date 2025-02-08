// models/tailor.dart
class Tailor {
  final String id;
  final String name;
  final String location;
  final List<String> services;
  final double rating;

  Tailor({
    required this.id,
    required this.name,
    required this.location,
    required this.services,
    required this.rating,
  });

  factory Tailor.fromMap(String id, Map<String, dynamic> map) {
    return Tailor(
      id: id,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      services: List<String>.from(map['services'] ?? []),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'services': services,
      'rating': rating,
    };
  }
}