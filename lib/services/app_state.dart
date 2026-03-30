import 'dart:async';
import 'package:flutter/material.dart';
import '../models/parking_location.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';
import '../models/payment_method.dart';
import 'logger.dart';
import 'supabase_service.dart';
import 'mock_data.dart';

class AppState extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  StreamSubscription? _spotSubscription;

  String selectedCity = 'Bacolod City';
  String selectedCategory = 'car';
  ParkingLocation? selectedLocation;
  ParkingSpot? selectedSpot;
  List<Booking> myBookings = [];
  int bottomNavIndex = 0;
  PaymentMethod? selectedPaymentMethod;

  List<PaymentMethod> paymentMethods = [];
  bool autoSelectLastUsed = true;
  bool requireConfirmation = false;

  // ── Data loaded from Supabase ─────────────────────────────
  List<ParkingLocation> _locations = [];
  List<ParkingSpot> _spots = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    _spotSubscription?.cancel();
    super.dispose();
  }

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

    // Add Supabase data. If we match a mock, ADOPT the Supabase ID.
    if (_locations.isNotEmpty) {
      for (var loc in _locations) {
        final norm = normalize(loc.name);
        if (uniqueByNormalizedName.containsKey(norm)) {
          // Adopt the real UUID from Supabase for this mock
          final mock = uniqueByNormalizedName[norm]!;
          uniqueByNormalizedName[norm] = mock.copyWith(id: loc.id);
        } else {
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
      loadPaymentMethods(); // Load payments too
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Could not load parking locations';
      AppLogger.error('Error loading locations', e);
      notifyListeners();
    }
  }

  // ── Load spots for a location ─────────────────────────────
  Future<void> loadSpots(String locationId) async {
    _spotSubscription?.cancel();
    
    if (locationId.startsWith('loc_')) {
      _spots = []; // Use local mock spots from the location object
      notifyListeners();
      return;
    }
    
    try {
      _spotSubscription = _supabase.getSpotsStream(locationId).listen((spots) {
        _spots = spots;
        notifyListeners();
      });
    } catch (e) {
      AppLogger.error('Error loading spots stream', e);
      _spots = [];
      notifyListeners();
    }
  }

  // ── Load user bookings ────────────────────────────────────
  Future<void> loadBookings() async {
    if (!_supabase.isLoggedIn) return; // Don't overwrite local list if not logged in

    try {
      myBookings = await _supabase.getMyBookings();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading bookings', e);
    }
  }

  // ── Load payment methods ──────────────────────────────────
  Future<void> loadPaymentMethods() async {
    if (!_supabase.isLoggedIn) {
      paymentMethods = [];
      notifyListeners();
      return;
    }
    try {
      paymentMethods = await _supabase.getPaymentMethods();
      if (paymentMethods.isNotEmpty && selectedPaymentMethod == null) {
        selectedPaymentMethod = paymentMethods.firstWhere(
          (m) => m.isDefault,
          orElse: () => paymentMethods.first,
        );
      }
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading payment methods', e);
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
  Future<void> confirmBooking(int durationHours, {DateTime? startTime}) async {
    if (selectedLocation == null || selectedSpot == null) return;

    final start = startTime ?? DateTime.now();

    final bookingId = 'PRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final newBooking = Booking(
      id: bookingId,
      location: selectedLocation!,
      spot: selectedSpot!,
      dateTime: start,
      durationHours: durationHours,
      status: 'active',
      paymentMethod: selectedPaymentMethod?.name ?? 'Cash',
    );

    if (_supabase.isLoggedIn) {
      try {
        // Robust UUID check: Mock IDs like "A1", "B4" are NOT UUIDs.
        // Mapped locations use UUIDs for locationId, but if spots are missing,
        // we'll have a mock spot ID.
        final bool isUuidSpot = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        ).hasMatch(selectedSpot!.id);

        if (!isUuidSpot) {
          myBookings.insert(0, newBooking);
          AppLogger.info('Booking mock spot locally: ${selectedSpot!.id}');
        } else {
          await _supabase.createBooking(
            locationId: selectedLocation!.id,
            spotId: selectedSpot!.id,
            startTime: start,
            durationHours: durationHours,
            totalPrice: selectedLocation!.pricePerHour * durationHours,
            paymentMethod: selectedPaymentMethod?.name ?? 'Cash',
          );
          // The real-time stream in loadSpots() will automatically
          // pick up the 'occupied' status change. No need to loadSpots() again.
          await loadBookings();
        }
      } catch (e) {
        AppLogger.error('Error creating booking', e);
        // Final fallback: showing at least locally
        myBookings.insert(0, newBooking);
      }
    } else {
      myBookings.insert(0, newBooking);
    }

    // Clear selection. The status change will be handled by the Realtime stream.
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
        AppLogger.error('Error cancelling booking', e);
      }
    } else {
      myBookings[idx].status = 'cancelled';
    }
    notifyListeners();
  }

  // ── Payment Actions ────────────────────────────────────────
  Future<void> addPaymentMethod(PaymentMethod method) async {
    if (_supabase.isLoggedIn) {
      try {
        await _supabase.createPaymentMethod(method);
        await loadPaymentMethods();
      } catch (e) {
        AppLogger.error('Error adding payment method', e);
      }
    } else {
      paymentMethods.add(method);
      if (method.isDefault) {
        setDefaultPaymentMethod(method.id);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> removePaymentMethod(String id) async {
    if (_supabase.isLoggedIn) {
      try {
        await _supabase.deletePaymentMethod(id);
        await loadPaymentMethods();
      } catch (e) {
        AppLogger.error('Error removing payment method', e);
      }
    } else {
      paymentMethods.removeWhere((m) => m.id == id);
      if (paymentMethods.isNotEmpty && !paymentMethods.any((m) => m.isDefault)) {
        setDefaultPaymentMethod(paymentMethods.first.id);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    if (_supabase.isLoggedIn) {
      try {
        await _supabase.setDefaultPaymentMethod(id);
        await loadPaymentMethods();
      } catch (e) {
        AppLogger.error('Error setting default payment method', e);
      }
    } else {
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
  }

  void toggleAutoSelect(bool value) {
    autoSelectLastUsed = value;
    notifyListeners();
  }

  void toggleRequireConfirmation(bool value) {
    requireConfirmation = value;
    notifyListeners();
  }

  void setSelectedPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod = method;
    notifyListeners();
  }
}
