import 'package:flutter/material.dart';
import '../models/parking_location.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';
import '../models/payment_method.dart';
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

  // ── Payment Methods ────────────────────────────────────────
  List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: 'pm_1',
      type: PaymentMethodType.gcash,
      name: 'GCash',
      lastFour: '8812',
      isDefault: true,
    ),
    PaymentMethod(
      id: 'pm_2',
      type: PaymentMethodType.card,
      name: 'Visa',
      lastFour: '4242',
      expiry: '12/25',
    ),
  ];

  bool autoSelectLastUsed = true;
  bool requireConfirmation = false;

  // ── Data loaded from Supabase ─────────────────────────────
  List<ParkingLocation> _locations = [];
  List<ParkingSpot> _spots = [];
  bool isLoading = false;
  String? errorMessage;

  // ── User Info ─────────────────────────────────────────────
  String get userName => _supabase.userName;
  String get userEmail => _supabase.userEmail;

  // ── Filtered locations by category ────────────────────────
  List<ParkingLocation> get filteredLocations {
    final mockMatches = MockData.parkingLocations
        .where((loc) => loc.category == selectedCategory)
        .toList();

    // Aggressive deduplication by normalized name
    String normalize(String name) {
      final n = name.toLowerCase();
      if (n.contains('ayala')) return 'ayala';
      if (n.contains('sm city') || n.contains('sm mall')) return 'sm';
      if (n.contains('robinson')) return 'robinsons';
      if (n.contains('la salle') || n.contains('usls')) return 'usls';
      return n;
    }

    // Start with mock data (the "new versions" the user wants)
    final Map<String, ParkingLocation> uniqueByNormalizedName = {};
    for (var loc in mockMatches) {
      uniqueByNormalizedName[normalize(loc.name)] = loc;
    }

    // Add Supabase data ONLY if we don't already have a mock equivalent
    if (_locations.isNotEmpty) {
      for (var loc in _locations) {
        final norm = normalize(loc.name);
        if (!uniqueByNormalizedName.containsKey(norm)) {
          uniqueByNormalizedName[norm] = loc;
        }
      }
    }

    return uniqueByNormalizedName.values.toList();
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
    if (locationId.startsWith('loc_')) {
      _spots = []; // Use local mock spots from the location object
      notifyListeners();
      return;
    }
    try {
      _spots = await _supabase.getSpotsForLocation(locationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading spots: $e');
      _spots = [];
      notifyListeners();
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

  // ── Payment Actions ────────────────────────────────────────
  void addPaymentMethod(PaymentMethod method) {
    paymentMethods.add(method);
    if (method.isDefault) {
      setDefaultPaymentMethod(method.id);
    } else {
      notifyListeners();
    }
  }

  void removePaymentMethod(String id) {
    paymentMethods.removeWhere((m) => m.id == id);
    if (paymentMethods.isNotEmpty && !paymentMethods.any((m) => m.isDefault)) {
      setDefaultPaymentMethod(paymentMethods.first.id);
    } else {
      notifyListeners();
    }
  }

  void setDefaultPaymentMethod(String id) {
    for (int i = 0; i < paymentMethods.length; i++) {
      final m = paymentMethods[i];
      paymentMethods[i] = PaymentMethod(
        id: m.id,
        type: m.type,
        name: m.name,
        lastFour: m.lastFour,
        isDefault: m.id == id,
        expiry: m.expiry,
      );
    }
    notifyListeners();
  }

  void toggleAutoSelect(bool value) {
    autoSelectLastUsed = value;
    notifyListeners();
  }

  void toggleRequireConfirmation(bool value) {
    requireConfirmation = value;
    notifyListeners();
  }
}
