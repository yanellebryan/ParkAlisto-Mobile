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
