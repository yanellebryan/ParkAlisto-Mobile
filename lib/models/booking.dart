import 'parking_location.dart';
import 'parking_spot.dart';

class Booking {
  final String id;
  final ParkingLocation location;
  final ParkingSpot spot;
  final DateTime dateTime;
  final int durationHours;
  final DateTime? arrivalTime;
  String status; // 'active', 'completed', 'cancelled'
  final String? paymentMethod;

  double get totalPrice => location.pricePerHour * durationHours;

  Booking({
    required this.id,
    required this.location,
    required this.spot,
    required this.dateTime,
    this.arrivalTime,
    required this.durationHours,
    this.status = 'active',
    this.paymentMethod,
  });

  /// Create a Booking from a Supabase JSON row (with joined location & spot)
  factory Booking.fromJson(Map<String, dynamic> json) {
    final locationJson = json['parking_locations'];
    final spotJson = json['parking_spots'];

    return Booking(
      id: json['id'] as String,
      location: locationJson != null
          ? ParkingLocation.fromJson(locationJson as Map<String, dynamic>)
          : ParkingLocation(
              id: json['location_id'] ?? '',
              name: 'Branded Mall Parking',
              address: 'Bacolod City',
              district: 'Downtown',
              pricePerHour: 50,
              totalSpots: 0,
              availableSpots: 0,
              category: 'car',
              rating: 4.5,
            ),
      spot: spotJson != null
          ? ParkingSpot.fromJson(spotJson as Map<String, dynamic>)
          : ParkingSpot(
              id: json['spot_id'] ?? '',
              row: '?',
              number: 0,
              status: SpotStatus.occupied,
            ),
      dateTime: DateTime.parse(json['booking_date'] as String),
      arrivalTime: json['arrival_time'] != null 
          ? DateTime.parse(json['arrival_time'] as String)
          : null,
      durationHours: json['duration_hours'] as int,
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String?,
    );
  }

  /// Convert to JSON for Supabase insert (references only IDs)
  Map<String, dynamic> toJson(String userId) {
    String toIso(DateTime? dt) {
      if (dt == null) return '';
      final s = dt.toIso8601String();
      if (s.contains('Z') || s.contains('+')) return s;
      return '$s+08:00';
    }

    return {
      'user_id': userId,
      'location_id': location.id,
      'spot_id': spot.id,
      'booking_date': toIso(dateTime),
      'arrival_time': toIso(arrivalTime),
      'duration_hours': durationHours,
      'total_price': totalPrice,
      'status': status,
      'payment_method': paymentMethod,
    };
  }
}
