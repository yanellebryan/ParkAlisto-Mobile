import 'package:flutter/material.dart';
import '../models/parking_location.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';
import 'supabase_service.dart';
import 'mock_data.dart';

class AppState extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  String selectedCity = 'Bacolod City';
  String selectedCategory = 'car';
  ParkingLocation? selectedLocation;
  ParkingSpot? selectedSpot;
  List<Booking> myBookings = [];
  int bottomNavIndex = 0;

  // ── Data loaded from Supabase ─────────────────────────────
  List<ParkingLocation> _locations = [];
  List<ParkingSpot> _spots = [];
  bool isLoading = false;
  String? errorMessage;

  // ── Filtered locations by category ────────────────────────
  List<ParkingLocation> get filteredLocations {
    if (_locations.isEmpty) {
      // Fallback to mock data while Supabase loads or if offline
      return MockData.parkingLocations
          .where((loc) => loc.category == selectedCategory)
          .toList();
    }
    return _locations;
  }

  // ── Spots for the selected location ───────────────────────
  List<ParkingSpot> get currentSpots => _spots;

  // ── Load locations from Supabase ──────────────────────────
  Future<void> loadLocations() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _locations =
          await _supabase.getLocations(category: selectedCategory);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Could not load parking locations';
      debugPrint('Error loading locations: $e');
      notifyListeners();
    }
  }

  // ── Load spots for a location ─────────────────────────────
  Future<void> loadSpots(String locationId) async {
    try {
      _spots = await _supabase.getSpotsForLocation(locationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading spots: $e');
    }
  }

  // ── Load user bookings ────────────────────────────────────
  Future<void> loadBookings() async {
    try {
      myBookings = await _supabase.getMyBookings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    }
  }

  // ── Actions ───────────────────────────────────────────────
  void setCity(String city) {
    selectedCity = city;
    notifyListeners();
  }

  void setCategory(String category) {
    selectedCategory = category;
    loadLocations(); // Re-fetch for the new category
    notifyListeners();
  }

  void setLocation(ParkingLocation loc) {
    selectedLocation = loc;
    selectedSpot = null;
    loadSpots(loc.id); // Fetch spots from Supabase
    notifyListeners();
  }

  void setSpot(ParkingSpot spot) {
    selectedSpot = spot;
    notifyListeners();
  }

  /// Confirm a booking — saves to Supabase if logged in,
  /// otherwise falls back to local-only.
  Future<void> confirmBooking(int durationHours) async {
    if (selectedLocation == null || selectedSpot == null) return;

    if (_supabase.isLoggedIn) {
      try {
        await _supabase.createBooking(
          locationId: selectedLocation!.id,
          spotId: selectedSpot!.id,
          durationHours: durationHours,
          totalPrice: selectedLocation!.pricePerHour * durationHours,
        );
        await loadBookings(); // Refresh from DB
      } catch (e) {
        debugPrint('Error creating booking: $e');
      }
    } else {
      // Local fallback (no auth yet)
      final booking = Booking(
        id: 'PRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        location: selectedLocation!,
        spot: selectedSpot!,
        dateTime: DateTime.now(),
        durationHours: durationHours,
        status: 'active',
      );
      myBookings.insert(0, booking);
    }

    // Mark spot as occupied locally
    selectedSpot!.status = SpotStatus.occupied;
    selectedSpot = null;
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    bottomNavIndex = index;
    notifyListeners();
  }

  Future<void> cancelBooking(String bookingId) async {
    final idx = myBookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) return;

    if (_supabase.isLoggedIn) {
      try {
        await _supabase.cancelBooking(
          bookingId,
          myBookings[idx].spot.id,
        );
        await loadBookings();
      } catch (e) {
        debugPrint('Error cancelling booking: $e');
      }
    } else {
      myBookings[idx].status = 'cancelled';
    }
    notifyListeners();
  }
}
