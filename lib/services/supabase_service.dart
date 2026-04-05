import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parking_location.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';
import '../models/payment_method.dart';
import 'logger.dart';

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
        .order('floor')
        .order('row_letter')
        .order('spot_number');
    return (data as List).map((json) => ParkingSpot.fromJson(json)).toList();
  }

  /// Get a real-time stream of spots for a location
  Stream<List<ParkingSpot>> getSpotsStream(String locationId) {
    return _client
        .from('parking_spots')
        .stream(primaryKey: ['id'])
        .eq('location_id', locationId)
        .order('floor')
        .order('row_letter')
        .order('spot_number')
        .map((data) {
          print('Supabase Realtime: Received ${data.length} spots for $locationId');
          return data.map((json) => ParkingSpot.fromJson(json)).toList();
        });
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

  /// Generate a short, unique booking code like "PRK-4F2A8B"
  String _generateBookingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no confusing chars
    final random = Random.secure();
    final code = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    return 'PRK-$code';
  }

  /// Helper to ensure timestamps are sent with the Asia/Manila (+08:00) offset
  String? _toPstIsoString(DateTime? dt) {
    if (dt == null) return null;
    final iso = dt.toIso8601String();
    if (iso.contains('Z') || iso.contains(RegExp(r'[+-]\d{2}:\d{2}'))) {
      return iso;
    }
    return '$iso+08:00';
  }

  /// Create a new booking.
  /// Returns the created [Booking] object (with Supabase UUID and booking_code).
  Future<Booking> createBooking({
    required String locationId,
    required String spotId,
    required DateTime startTime,
    DateTime? arrivalTime,
    required int durationHours,
    required double totalPrice,
    String? paymentMethod,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final bookingCode = _generateBookingCode();

    AppLogger.info('Supabase: Creating booking with code $bookingCode, arrival_time: ${_toPstIsoString(arrivalTime)}');

    final inserted = await _client.from('bookings').insert({
      'user_id': userId,
      'location_id': locationId,
      'spot_id': spotId,
      'booking_date': _toPstIsoString(startTime),
      'arrival_time': _toPstIsoString(arrivalTime),
      'duration_hours': durationHours,
      'total_price': totalPrice,
      'status': 'active',
      'payment_method': paymentMethod,
      'booking_code': bookingCode,
    }).select('*, parking_locations(*), parking_spots(*)').single();

    // Mark the spot as occupied
    await updateSpotStatus(spotId, 'occupied');

    AppLogger.info('Supabase: Booking created — ID: ${inserted['id']}, code: $bookingCode');
    return Booking.fromJson(inserted);
  }

  /// Cancel an existing booking (user-initiated)
  Future<void> cancelBooking(String bookingId, String spotId) async {
    await _client
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);

    // Free up the spot
    await updateSpotStatus(spotId, 'available');
  }

  /// Watch for real-time changes to the current user's bookings.
  /// Calls [onUpdate] whenever any booking row changes (e.g., checked_in → true).
  RealtimeChannel watchBookingCheckins(void Function() onUpdate) {
    final userId = _client.auth.currentUser?.id;
    final channelName = 'user_booking_watch_${userId ?? 'anon'}';

    return _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }

  /// Lookup a booking by its short booking_code (for QR scan at entrance)
  Future<Map<String, dynamic>?> getBookingByCode(String bookingCode) async {
    final data = await _client
        .from('bookings')
        .select('*, parking_locations(*), parking_spots(*)')
        .eq('booking_code', bookingCode.toUpperCase())
        .maybeSingle();
    return data;
  }

  // ─── Push Tokens ────────────────────────────────────────

  /// Save or update the device's push token in Supabase
  Future<void> saveDevicePushToken(String token, {String platform = 'unknown'}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('user_push_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': platform,
    }, onConflict: 'user_id, token');

    AppLogger.info('Push token saved for user $userId');
  }

  // ─── Auth Helpers ───────────────────────────────────────

  /// Sign up a new user
  Future<void> signUp({required String email, required String password, required String fullName}) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    if (response.user == null) {
      throw Exception('Sign up failed');
    }
  }

  /// Sign in an existing user
  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Sign in failed');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Check if user is currently logged in
  bool get isLoggedIn => _client.auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Get current user's full name from metadata
  String get userName {
    final user = _client.auth.currentUser;
    if (user == null) return 'Guest';
    return user.userMetadata?['full_name'] ?? 'Guest';
  }

  /// Get current user's email
  String get userEmail {
    final user = _client.auth.currentUser;
    if (user == null) return '';
    return user.email ?? '';
  }

  // ─── Payment Methods ──────────────────────────────────────

  /// Fetch all payment methods for the current user
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('payment_methods')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    return (data as List).map((json) => PaymentMethod.fromJson(json)).toList();
  }

  /// Create a new payment method
  Future<PaymentMethod> createPaymentMethod(PaymentMethod method) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final data = await _client.from('payment_methods').insert({
      ...method.toJson(),
      'user_id': userId,
    }).select().single();

    return PaymentMethod.fromJson(data);
  }

  /// Delete a payment method
  Future<void> deletePaymentMethod(String id) async {
    await _client.from('payment_methods').delete().eq('id', id);
  }

  /// Update payment method (e.g. set as default)
  Future<void> updatePaymentMethod(String id, Map<String, dynamic> updates) async {
    await _client.from('payment_methods').update(updates).eq('id', id);
  }

  /// Set a specific payment method as default and unset others
  Future<void> setDefaultPaymentMethod(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('payment_methods')
        .update({'is_default': false})
        .eq('user_id', userId);

    await _client
        .from('payment_methods')
        .update({'is_default': true})
        .eq('id', id);
  }
}
