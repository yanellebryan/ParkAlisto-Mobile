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
  final String? bookingCode;         // Short human-readable code e.g. "PRK-4F2A8B"
  final String? cancellationReason;  // Reason if cancelled by admin
  final bool checkedIn;              // Whether user has scanned in at entrance
  final DateTime? checkedInAt;

  double get totalPrice => location.pricePerHour * durationHours;

  /// The booking window end time (arrival_time + duration) or null if not set
  DateTime? get expiresAt {
    if (arrivalTime != null) {
      return arrivalTime!.add(Duration(hours: durationHours));
    }
    return dateTime.add(Duration(hours: durationHours + 2));
  }

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  Booking({
    required this.id,
    required this.location,
    required this.spot,
    required this.dateTime,
    this.arrivalTime,
    required this.durationHours,
    this.status = 'active',
    this.paymentMethod,
    this.bookingCode,
    this.cancellationReason,
    this.checkedIn = false,
    this.checkedInAt,
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
      bookingCode: json['booking_code'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      checkedIn: (json['checked_in'] as bool?) ?? false,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
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
      if (bookingCode != null) 'booking_code': bookingCode,
    };
  }
}
