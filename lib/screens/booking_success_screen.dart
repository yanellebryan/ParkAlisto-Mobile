import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/dynamic_mesh_background.dart';
import '../widgets/booking_qr_sheet.dart';

class BookingSuccessScreen extends StatefulWidget {
  final String spotLabel;
  final String locationName;
  final int durationHours;
  final double totalPrice;
  final String bookingRef;
  final String? bookingCode; // Short QR code e.g. "PRK-4F2A8B"
  final DateTime? arrivalTime;

  const BookingSuccessScreen({
    Key? key,
    required this.spotLabel,
    required this.locationName,
    required this.durationHours,
    required this.totalPrice,
    required this.bookingRef,
    this.bookingCode,
    this.arrivalTime,
  }) : super(key: key);

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  Timer? _redirectTimer;
  int _countdown = 5;

  String get _displayCode => widget.bookingCode ?? widget.bookingRef;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: AppTheme.appleSpring,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _animController.forward();

    // Auto-redirect to My Bookings after 5 seconds
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _goToMyBookings();
      }
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _goToMyBookings() {
    if (!mounted) return;
    _redirectTimer?.cancel();
    final appState = context.read<AppState>();
    appState.setBottomNavIndex(2);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DynamicMeshBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated checkmark
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.brandGreen.withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandGreen.withOpacity(0.25),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_circle,
                          color: AppTheme.brandGreen, size: 64),
                    ),
                  ),
                  const SizedBox(height: 20),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(
                          'Booking Confirmed!',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(color: AppTheme.brandGreenDeep),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Show the QR code below at the parking entrance',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary.withOpacity(0.55),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Auto-redirect countdown ──────────────────────
                        GestureDetector(
                          onTap: _goToMyBookings,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.brandGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.brandGreen.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined,
                                        size: 16, color: AppTheme.brandGreen),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Going to My Bookings in ${_countdown}s  •  Tap to go now',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.brandGreenDeep,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        size: 12, color: AppTheme.brandGreen),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: 1.0 - (_countdown / 5.0),
                                    minHeight: 4,
                                    backgroundColor: AppTheme.brandGreen.withOpacity(0.15),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppTheme.brandGreen),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── QR Code Card ────────────────────────────────
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              // QR image
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 12,
                                    )
                                  ],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: QrImageView(
                                  data: _displayCode,
                                  version: QrVersions.auto,
                                  size: 180,
                                  gapless: true,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Code label
                              Text(
                                _displayCode,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.brandGreen,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Entry Pass Code',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textPrimary.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Booking Details ─────────────────────────────
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            children: [
                              _detailRow(context, 'Location', widget.locationName),
                              const SizedBox(height: 12),
                              _detailRow(context, 'Spot', widget.spotLabel),
                              const SizedBox(height: 12),
                              _detailRow(context, 'Duration', '${widget.durationHours}h'),
                              const SizedBox(height: 12),
                              _detailRow(context, 'Total',
                                  '₱${widget.totalPrice.toStringAsFixed(0)}'),
                              const Divider(height: 24),
                              _detailRow(context, 'Reference', widget.bookingRef.length > 16
                                  ? '...${widget.bookingRef.substring(widget.bookingRef.length - 12)}'
                                  : widget.bookingRef),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Action Buttons ──────────────────────────────
                        GlassButton(
                          isFullWidth: true,
                          variant: GlassButtonVariant.primary,
                          onPressed: _goToMyBookings,
                          child: const Text('Go to My Bookings →'),
                        ),
                        const SizedBox(height: 10),
                        GlassButton(
                          isFullWidth: true,
                          variant: GlassButtonVariant.ghost,
                          onPressed: () {
                            _redirectTimer?.cancel();
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          child: const Text('Back to Home'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 14)),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontSize: 14),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
