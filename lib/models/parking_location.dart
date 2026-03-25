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
  final String? logoPath;
  final double? latitude;
  final double? longitude;
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
    this.logoPath,
    this.latitude,
    this.longitude,
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
      logoPath: json['logo_path'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
      'logo_path': logoPath,
      'latitude': latitude,
      'longitude': longitude,
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
    String? logoPath,
    double? latitude,
    double? longitude,
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
      logoPath: logoPath ?? this.logoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      spots: spots ?? this.spots,
    );
  }
}

extension ParkingLocationLogo on ParkingLocation {
  String? get effectiveLogoPath {
    if (logoPath != null && logoPath!.isNotEmpty) return logoPath;
    
    final lowerName = name.toLowerCase();
    if (lowerName.contains('ayala')) {
      return 'assets/images/Ayala_Malls_Logo.png';
    } else if (lowerName.contains('sm city') || lowerName.contains('sm mall')) {
      return 'assets/images/SM Logo.png';
    } else if (lowerName.contains('robinsons')) {
      return 'assets/images/Robinsons logo.png';
    } else if (lowerName.contains('la salle')) {
      return 'assets/images/USLS_Logo.png';
    }
    return null;
  }
}
