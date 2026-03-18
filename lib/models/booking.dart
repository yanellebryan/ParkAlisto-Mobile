import 'parking_location.dart';
import 'parking_spot.dart';

class Booking {
  final String id;
  final ParkingLocation location;
  final ParkingSpot spot;
  final DateTime dateTime;
  final int durationHours;
  String status; // 'active', 'completed', 'cancelled'

  double get totalPrice => location.pricePerHour * durationHours;

  Booking({
    required this.id,
    required this.location,
    required this.spot,
    required this.dateTime,
    required this.durationHours,
    this.status = 'active',
  });

  /// Create a Booking from a Supabase JSON row (with joined location & spot)
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      location: ParkingLocation.fromJson(
        json['parking_locations'] as Map<String, dynamic>,
      ),
      spot: ParkingSpot.fromJson(
        json['parking_spots'] as Map<String, dynamic>,
      ),
      dateTime: DateTime.parse(json['booking_date'] as String),
      durationHours: json['duration_hours'] as int,
      status: json['status'] as String,
    );
  }

  /// Convert to JSON for Supabase insert (references only IDs)
  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'location_id': location.id,
      'spot_id': spot.id,
      'booking_date': dateTime.toIso8601String(),
      'duration_hours': durationHours,
      'total_price': totalPrice,
      'status': status,
    };
  }
}
