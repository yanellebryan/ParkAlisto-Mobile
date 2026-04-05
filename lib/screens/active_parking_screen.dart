import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/booking_qr_sheet.dart';

class ActiveParkingScreen extends StatefulWidget {
  final Booking booking;

  const ActiveParkingScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<ActiveParkingScreen> createState() => _ActiveParkingScreenState();
}

class _ActiveParkingScreenState extends State<ActiveParkingScreen>
    with TickerProviderStateMixin {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  Duration _total = Duration.zero;
  bool _isExpired = false;

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the "LIVE" indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _initTimer();
    _progressController.forward();
  }

  void _initTimer() {
    final expiresAt = widget.booking.expiresAt;
    final checkedInAt = widget.booking.checkedInAt ?? widget.booking.arrivalTime;

    if (expiresAt != null && checkedInAt != null) {
      _total = expiresAt.difference(checkedInAt);
    } else if (expiresAt != null) {
      _total = Duration(hours: widget.booking.durationHours);
    }

    _updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final expiresAt = widget.booking.expiresAt;
    if (expiresAt == null) {
      setState(() => _isExpired = true);
      _countdownTimer?.cancel();
      return;
    }

    final now = DateTime.now();
    if (expiresAt.isAfter(now)) {
      setState(() {
        _remaining = expiresAt.difference(now);
        _isExpired = false;
      });
    } else {
      setState(() {
        _remaining = Duration.zero;
        _isExpired = true;
      });
      _countdownTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────
  String _formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, $h:$m $period';
  }

  double get _progressValue {
    if (_total.inSeconds == 0) return 0;
    final elapsed = _total.inSeconds - _remaining.inSeconds;
    return (elapsed / _total.inSeconds).clamp(0.0, 1.0);
  }

  Color get _progressColor {
    final p = _progressValue;
    if (p < 0.6) return AppTheme.brandGreen;
    if (p < 0.85) return const Color(0xFFFF9500);
    return Colors.red;
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final expiresAt = booking.expiresAt;
    final checkedInTime = booking.checkedInAt ?? booking.arrivalTime;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F0),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── Header row ─────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                    ),
                    const Spacer(),
                    // LIVE badge
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.brandGreen.withOpacity(0.1 + _pulseController.value * 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.brandGreen.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.brandGreen.withOpacity(0.5 + _pulseController.value * 0.5),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('LIVE', style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.brandGreenDeep,
                              letterSpacing: 1,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Hero section ───────────────────────────
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: BorderRadius.circular(28),
                  opacity: 0.65,
                  child: Column(
                    children: [
                      // Icon + status
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isExpired
                                ? [Colors.red.shade300, Colors.red.shade600]
                                : [AppTheme.brandGreenLight, AppTheme.brandGreen],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isExpired ? Colors.red : AppTheme.brandGreen).withOpacity(0.3),
                              blurRadius: 20, offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isExpired ? Icons.timer_off_rounded : Icons.local_parking,
                          color: Colors.white, size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        _isExpired ? 'Session Expired' : "You're Parked! 🚗",
                        style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      Text(
                        booking.location.name,
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary.withOpacity(0.55),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Countdown timer ────────────────────────
                GlassContainer(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  borderRadius: BorderRadius.circular(24),
                  opacity: 0.65,
                  child: Column(
                    children: [
                      Text(
                        _isExpired ? 'Time Expired' : 'Time Remaining',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary.withOpacity(0.5),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Main countdown display
                      Text(
                        _isExpired ? '00:00:00' : _formatCountdown(_remaining),
                        style: TextStyle(
                          fontSize: 52, fontWeight: FontWeight.w900,
                          color: _isExpired ? Colors.red : _progressColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        _isExpired
                            ? 'Please vacate the parking spot'
                            : 'out of ${widget.booking.durationHours}h booked',
                        style: TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary.withOpacity(0.45),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Progress bar
                      AnimatedBuilder(
                        animation: _progressAnim,
                        builder: (_, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progressValue * _progressAnim.value,
                            minHeight: 8,
                            backgroundColor: Colors.black.withOpacity(0.06),
                            valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Time labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Check-in: ${_formatTime(checkedInTime)}',
                            style: TextStyle(fontSize: 11, color: AppTheme.textPrimary.withOpacity(0.4)),
                          ),
                          Text(
                            'Exit: ${_formatTime(expiresAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _progressColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Booking details card ───────────────────
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(24),
                  opacity: 0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking Details', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      )),
                      const SizedBox(height: 16),

                      _detailRow(Icons.local_parking, 'Parking Spot',
                          booking.spot.label),
                      _divider(),
                      _detailRow(Icons.layers_outlined, 'Floor',
                          booking.spot.floor != null ? 'Floor ${booking.spot.floor}' : '—'),
                      _divider(),
                      _detailRow(Icons.access_time_rounded, 'Arrival Time',
                          _formatTime(booking.arrivalTime)),
                      _divider(),
                      _detailRow(Icons.timer_outlined, 'Duration',
                          '${booking.durationHours} hour${booking.durationHours > 1 ? 's' : ''}'),
                      _divider(),
                      _detailRow(Icons.exit_to_app_rounded, 'Exit By',
                          _formatTime(expiresAt)),
                      _divider(),
                      _detailRow(Icons.payments_outlined, 'Amount Paid',
                          '₱${booking.totalPrice.toStringAsFixed(0)}'),

                      // Booking code chip
                      if (booking.bookingCode != null) ...[
                        _divider(),
                        Row(
                          children: [
                            Icon(Icons.qr_code_2_rounded,
                                size: 18, color: AppTheme.textPrimary.withOpacity(0.45)),
                            const SizedBox(width: 10),
                            Text('Booking Code',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary.withOpacity(0.55))),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.brandGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.brandGreen.withOpacity(0.25), width: 1),
                              ),
                              child: Text(
                                booking.bookingCode!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.brandGreenDeep,
                                  letterSpacing: 1,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Action buttons ─────────────────────────
                if (booking.bookingCode != null || booking.id.isNotEmpty) ...[
                  GlassButton(
                    isFullWidth: true,
                    variant: GlassButtonVariant.primary,
                    onPressed: () {
                      showBookingQrSheet(
                        context,
                        bookingCode: booking.bookingCode ?? booking.id,
                        spotLabel: booking.spot.label,
                        locationName: booking.location.name,
                        durationHours: booking.durationHours,
                        arrivalTime: booking.arrivalTime,
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_rounded, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Show QR Code'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // My Bookings button
                GlassButton(
                  isFullWidth: true,
                  variant: GlassButtonVariant.ghost,
                  onPressed: () {
                    context.read<AppState>().setBottomNavIndex(2);
                    Navigator.popUntil(context, (r) => r.isFirst);
                  },
                  child: const Text('View My Bookings'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textPrimary.withOpacity(0.45)),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            fontSize: 13, color: AppTheme.textPrimary.withOpacity(0.55),
          )),
          const Spacer(),
          Text(value, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          )),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1, color: AppTheme.textPrimary.withOpacity(0.06),
  );
}
