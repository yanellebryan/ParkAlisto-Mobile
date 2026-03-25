import '../models/parking_location.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';

class MockData {
  // ── Helper: generate spots for a location ──────────────────
  static List<ParkingSpot> _generateSpots(int total, List<int> occupiedIndices) {
    final rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];
    final spots = <ParkingSpot>[];
    int idx = 0;
    for (int i = 0; i < total; i++) {
      final row = rows[i ~/ 6 % rows.length];
      final number = (i % 6) + 1;
      final floor = (i / 24).floor() + 1; // 24 spots per floor
      spots.add(ParkingSpot(
        id: '$row$number',
        row: row,
        number: number,
        floor: floor,
        status: occupiedIndices.contains(idx)
            ? SpotStatus.occupied
            : SpotStatus.available,
      ));
      idx++;
    }
    return spots;
  }

  // ── Parking Locations ──────────────────────────────────────
  static final List<ParkingLocation> parkingLocations = [
    ParkingLocation(
      id: 'loc_1',
      name: 'Ayala Mall Parking',
      address: 'Ayala North Point, Talisay',
      district: 'Ayala',
      pricePerHour: 40,
      totalSpots: 30,
      availableSpots: 12,
      category: 'car',
      rating: 4.8,
      logoPath: 'assets/images/Ayala_Malls_Logo.png',
      latitude: 10.676145,
      longitude: 122.948791,
      spots: _generateSpots(30, [0,1,2,4,5,6,8,9,11,13,14,16,17,19,20,22,24,26]),
    ),
    ParkingLocation(
      id: 'loc_2',
      name: 'SM City Bacolod Parking',
      address: 'Rizal Street, Bacolod City',
      district: 'SM City',
      pricePerHour: 60,
      totalSpots: 12,
      availableSpots: 5,
      category: 'car',
      rating: 4.0,
      logoPath: 'assets/images/SM Logo.png',
      latitude: 10.673079,
      longitude: 122.943373,
      spots: _generateSpots(12, [0,1,3,5,6,8,10]),
    ),
    ParkingLocation(
      id: 'loc_3',
      name: 'Robinsons Place Parking',
      address: 'Lacson Street, Bacolod City',
      district: 'Robinsons',
      pricePerHour: 50,
      totalSpots: 18,
      availableSpots: 7,
      category: 'car',
      rating: 4.6,
      logoPath: 'assets/images/Robinsons logo.png',
      latitude: 10.692225,
      longitude: 122.956981,
      spots: _generateSpots(18, [0,2,4,6,8,10,12]),
    ),
    ParkingLocation(
      id: 'loc_4',
      name: 'University of St. La Salle Parking',
      address: 'La Salle Avenue, Bacolod City',
      district: 'USLS',
      pricePerHour: 20,
      totalSpots: 72,
      availableSpots: 45,
      category: 'car',
      rating: 4.7,
      logoPath: 'assets/images/USLS_Logo.png',
      latitude: 10.680323,
      longitude: 122.962593,
      spots: _generateSpots(72, [1,4,5,8,10,12,15,18,20,22,25,28,30,32,35,38,40,43,46,48,50,53,56,58,60,63,66,68]),
    ),
  ];

  // ── Recent Places (pull from main list) ────────────────────
  static List<ParkingLocation> get recentPlaces =>
      [parkingLocations[1], parkingLocations[0]];

  // ── Recent Bookings ────────────────────────────────────────
  static List<Booking> get recentBookings => [
        Booking(
          id: 'PRK-001',
          location: parkingLocations[1], // SM City
          spot: parkingLocations[1].spots.firstWhere((s) => s.id == 'A3'),
          dateTime: DateTime.now().subtract(const Duration(hours: 3)),
          durationHours: 2,
          status: 'active',
        ),
        Booking(
          id: 'PRK-002',
          location: parkingLocations[0], // Ayala
          spot: parkingLocations[0].spots.firstWhere((s) => s.id == 'B2'),
          dateTime: DateTime.now().subtract(const Duration(days: 2)),
          durationHours: 4,
          status: 'completed',
        ),
      ];
}
