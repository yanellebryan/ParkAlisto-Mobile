import 'parking_spot.dart';

class ParkingLocation {
  final String id;
  final String name;
  final String address;
  final String district;
  final double pricePerHour;
  final int totalSpots;
  final int availableSpots;
  final String category; // 'car', 'motorcycle', 'truck'
  final double rating;
  final List<ParkingSpot> spots;

  const ParkingLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.pricePerHour,
    required this.totalSpots,
    required this.availableSpots,
    required this.category,
    required this.rating,
    this.spots = const [],
  });

  /// Create a ParkingLocation from a Supabase JSON row
  factory ParkingLocation.fromJson(Map<String, dynamic> json) {
    return ParkingLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      district: json['district'] as String,
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      totalSpots: json['total_spots'] as int,
      availableSpots: json['available_spots'] as int,
      category: json['category'] as String,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'district': district,
      'price_per_hour': pricePerHour,
      'total_spots': totalSpots,
      'available_spots': availableSpots,
      'category': category,
      'rating': rating,
    };
  }

  ParkingLocation copyWith({
    String? id,
    String? name,
    String? address,
    String? district,
    double? pricePerHour,
    int? totalSpots,
    int? availableSpots,
    String? category,
    double? rating,
    List<ParkingSpot>? spots,
  }) {
    return ParkingLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      district: district ?? this.district,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      totalSpots: totalSpots ?? this.totalSpots,
      availableSpots: availableSpots ?? this.availableSpots,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      spots: spots ?? this.spots,
    );
  }
}
