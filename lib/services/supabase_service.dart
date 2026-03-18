import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parking_location.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';

/// Service that handles all Supabase database operations.
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── Parking Locations ───────────────────────────────────

  /// Fetch all parking locations, optionally filtered by category
  Future<List<ParkingLocation>> getLocations({String? category}) async {
    var query = _client.from('parking_locations').select();
    if (category != null) {
      query = query.eq('category', category);
    }
    final data = await query.order('name');
    return (data as List).map((json) => ParkingLocation.fromJson(json)).toList();
  }

  /// Fetch a single location by ID
  Future<ParkingLocation?> getLocationById(String id) async {
    final data =
        await _client.from('parking_locations').select().eq('id', id).single();
    return ParkingLocation.fromJson(data);
  }

  // ─── Parking Spots ──────────────────────────────────────

  /// Fetch all spots for a given location
  Future<List<ParkingSpot>> getSpotsForLocation(String locationId) async {
    final data = await _client
        .from('parking_spots')
        .select()
        .eq('location_id', locationId)
        .order('row_letter')
        .order('spot_number');
    return (data as List).map((json) => ParkingSpot.fromJson(json)).toList();
  }

  /// Update spot status (available / occupied)
  Future<void> updateSpotStatus(String spotId, String status) async {
    await _client
        .from('parking_spots')
        .update({'status': status})
        .eq('id', spotId);
  }

  // ─── Bookings ───────────────────────────────────────────

  /// Fetch all bookings for the current user (with joined location & spot)
  Future<List<Booking>> getMyBookings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('bookings')
        .select('*, parking_locations(*), parking_spots(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((json) => Booking.fromJson(json)).toList();
  }

  /// Create a new booking
  Future<void> createBooking({
    required String locationId,
    required String spotId,
    required int durationHours,
    required double totalPrice,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('bookings').insert({
      'user_id': userId,
      'location_id': locationId,
      'spot_id': spotId,
      'duration_hours': durationHours,
      'total_price': totalPrice,
      'status': 'active',
    });

    // Mark the spot as occupied
    await updateSpotStatus(spotId, 'occupied');
  }

  /// Cancel an existing booking
  Future<void> cancelBooking(String bookingId, String spotId) async {
    await _client
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);

    // Free up the spot
    await updateSpotStatus(spotId, 'available');
  }

  // ─── Auth Helpers ───────────────────────────────────────

  /// Check if user is currently logged in
  bool get isLoggedIn => _client.auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;
}
