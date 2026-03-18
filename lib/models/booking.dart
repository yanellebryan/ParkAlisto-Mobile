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
}
