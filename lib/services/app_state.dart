import 'package:flutter/material.dart';
import '../models/parking_location.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';
import 'mock_data.dart';

class AppState extends ChangeNotifier {
  String selectedCity = 'Bacolod City';
  String selectedCategory = 'car';
  ParkingLocation? selectedLocation;
  ParkingSpot? selectedSpot;
  List<Booking> myBookings = [...MockData.recentBookings];
  int bottomNavIndex = 0;

  // ── Filtered locations by category ─────────────────────────
  List<ParkingLocation> get filteredLocations =>
      MockData.parkingLocations
          .where((loc) => loc.category == selectedCategory)
          .toList();

  // ── Actions ────────────────────────────────────────────────
  void setCity(String city) {
    selectedCity = city;
    notifyListeners();
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setLocation(ParkingLocation loc) {
    selectedLocation = loc;
    selectedSpot = null;
    notifyListeners();
  }

  void setSpot(ParkingSpot spot) {
    selectedSpot = spot;
    notifyListeners();
  }

  void confirmBooking(int durationHours) {
    if (selectedLocation == null || selectedSpot == null) return;

    final booking = Booking(
      id:
          'PRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      location: selectedLocation!,
      spot: selectedSpot!,
      dateTime: DateTime.now(),
      durationHours: durationHours,
      status: 'active',
    );
    myBookings.insert(0, booking);

    // Mark spot as occupied
    selectedSpot!.status = SpotStatus.occupied;
    selectedSpot = null;
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    bottomNavIndex = index;
    notifyListeners();
  }

  void cancelBooking(String bookingId) {
    final idx = myBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      myBookings[idx].status = 'cancelled';
      notifyListeners();
    }
  }
}
