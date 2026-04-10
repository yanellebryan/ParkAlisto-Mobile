import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  RealtimeChannel? _bookingChannel;

  String selectedCity = 'Bacolod City';
  String selectedCategory = 'car';
  ParkingLocation? selectedLocation;
  ParkingSpot? selectedSpot;
  List<Booking> myBookings = [];
  int bottomNavIndex = 0;
  PaymentMethod? selectedPaymentMethod;
  Booking? lastCompletedBooking; // Tracks the booking that just finished

  List<PaymentMethod> paymentMethods = [];
  bool autoSelectLastUsed = true;
  bool requireConfirmation = false;

  // ── Data loaded from Supabase ─────────────────────────────
  // ── Data loaded from Supabase (by category) ──────────────
  final Map<String, List<ParkingLocation>> _categoryLocations = {};
  List<ParkingSpot> _spots = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    _spotSubscription?.cancel();
    stopBookingRealtimeListener();
    super.dispose();
  }

  // ── Active parking session ────────────────────────────────
  /// Returns the booking that has been checked in by admin and is still active.
  Booking? get activeCheckedInBooking {
    try {
      return myBookings.firstWhere(
        (b) => b.status == 'active' && b.checkedIn,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Realtime booking listener ─────────────────────────────
  /// Start listening for check-in updates from Supabase.
  /// Call this after the user logs in.
  void startBookingRealtimeListener() {
    if (!_supabase.isLoggedIn) return;
    stopBookingRealtimeListener();
    _bookingChannel = _supabase.watchBookingCheckins(() {
      AppLogger.info('Realtime: booking update detected, reloading bookings');
      loadBookings();
    });
  }

  void stopBookingRealtimeListener() {
    _bookingChannel?.unsubscribe();
    _bookingChannel = null;
  }

  // ── User Info ─────────────────────────────────────────────
  String get userName => _supabase.userName;
  String get userEmail => _supabase.userEmail;

  // ── Filtered locations by category ────────────────────────
  List<ParkingLocation> get filteredLocations => _getFilteredLocationsFor(selectedCategory);

  /// Get count of locations for a specific category, independent of current selection.
  int getCategoryCount(String category) {
    if (category == 'motorcycle' || category == 'truck') return 0;
    return _getFilteredLocationsFor(category).length;
  }

  List<ParkingLocation> _getFilteredLocationsFor(String category) {
    final mockMatches = MockData.parkingLocations
        .where((loc) => loc.category == category)
        .toList();

    String normalize(String name) {
      final n = name.toLowerCase();
      if (n.contains('ayala')) return 'ayala';
      if (n.contains('sm city') || n.contains('sm mall')) return 'sm';
      if (n.contains('robinson')) return 'robinsons';
      if (n.contains('la salle') || n.contains('usls')) return 'usls';
      return n;
    }

    final Map<String, ParkingLocation> uniqueByNormalizedName = {};
    for (var loc in mockMatches) {
      uniqueByNormalizedName[normalize(loc.name)] = loc;
    }

    final supabaseMatches = _categoryLocations[category] ?? [];
    if (supabaseMatches.isNotEmpty) {
      for (var loc in supabaseMatches) {
        final norm = normalize(loc.name);
        if (uniqueByNormalizedName.containsKey(norm)) {
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
  Future<void> loadLocations({String? category}) async {
    final cat = category ?? selectedCategory;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await _supabase.getLocations(category: cat);
      _categoryLocations[cat] = results;
      
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
    if (!_supabase.isLoggedIn) return;

    try {
      // Remember the ID of the currently active/parked booking to detect transition
      final activeId = activeCheckedInBooking?.id;

      myBookings = await _supabase.getMyBookings();

      // If we had an active booking, check if it just became 'completed'
      if (activeId != null) {
        try {
          final updated = myBookings.firstWhere((b) => b.id == activeId);
          if (updated.status == 'completed') {
            lastCompletedBooking = updated;
            AppLogger.info('AppState: Detected exit completion for $activeId');
          }
        } catch (_) {
          // Not found or filtered out
        }
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading bookings', e);
    }
  }

  void clearLastCompletedBooking() {
    lastCompletedBooking = null;
    notifyListeners();
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
  /// Returns the created [Booking] (with real Supabase UUID + booking_code).
  Future<Booking?> confirmBooking(int durationHours, {DateTime? startTime}) async {
    if (selectedLocation == null || selectedSpot == null) return null;

    final start = startTime ?? DateTime.now();

    // Local fallback booking (used if offline or mock spot)
    final fallbackBooking = Booking(
      id: 'PRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      location: selectedLocation!,
      spot: selectedSpot!,
      dateTime: start,
      durationHours: durationHours,
      status: 'active',
      paymentMethod: selectedPaymentMethod?.name ?? 'Cash',
      bookingCode: 'PRK-OFFLINE',
    );

    Booking? createdBooking;

    if (_supabase.isLoggedIn) {
      try {
        // Only attempt Supabase if the spot ID is a real UUID
        final bool isUuidSpot = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        ).hasMatch(selectedSpot!.id);

        if (!isUuidSpot) {
          myBookings.insert(0, fallbackBooking);
          AppLogger.info('Booking mock spot locally: ${selectedSpot!.id}');
          createdBooking = fallbackBooking;
        } else {
          // createBooking now returns the full Booking with real UUID + booking_code
          createdBooking = await _supabase.createBooking(
            locationId: selectedLocation!.id,
            spotId: selectedSpot!.id,
            startTime: start,
            durationHours: durationHours,
            totalPrice: selectedLocation!.pricePerHour * durationHours,
            paymentMethod: selectedPaymentMethod?.name ?? 'Cash',
          );
          // Reload to get fresh list from DB (with location & spot joins)
          await loadBookings();
        }
      } catch (e) {
        AppLogger.error('Error creating booking', e);
        myBookings.insert(0, fallbackBooking);
        createdBooking = fallbackBooking;
      }
    } else {
      myBookings.insert(0, fallbackBooking);
      createdBooking = fallbackBooking;
    }

    // Clear selection. The status change will be handled by the Realtime stream.
    selectedSpot = null;
    notifyListeners();
    return createdBooking;
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
