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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
                        const SizedBox(height: 24),

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
                          variant: GlassButtonVariant.ghost,
                          onPressed: () => showBookingQrSheet(
                            context,
                            bookingCode: _displayCode,
                            spotLabel: widget.spotLabel,
                            locationName: widget.locationName,
                            durationHours: widget.durationHours,
                            arrivalTime: widget.arrivalTime,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('View Full QR'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassButton(
                          isFullWidth: true,
                          variant: GlassButtonVariant.primary,
                          onPressed: () {
                            final appState = context.read<AppState>();
                            appState.setBottomNavIndex(2);
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          child: const Text('View My Bookings'),
                        ),
                        const SizedBox(height: 10),
                        GlassButton(
                          isFullWidth: true,
                          variant: GlassButtonVariant.ghost,
                          onPressed: () {
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
