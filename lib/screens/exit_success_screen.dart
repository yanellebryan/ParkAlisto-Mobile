import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../models/booking.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/dynamic_mesh_background.dart';

class ExitSuccessScreen extends StatefulWidget {
  final Booking booking;

  const ExitSuccessScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<ExitSuccessScreen> createState() => _ExitSuccessScreenState();
}

class _ExitSuccessScreenState extends State<ExitSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: AppTheme.appleSpring,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<AppState>().clearLastCompletedBooking();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = widget.booking;

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
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.brandGreen.withOpacity(0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brandGreen.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.brandGreen,
                        size: 72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(
                          'Session Completed!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppTheme.brandGreenDeep,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Thank you for parking with ParkAlisto!\nHave a safe drive home.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Session Summary ───────────────────────────
                        GlassContainer(
                          padding: const EdgeInsets.all(24),
                          borderRadius: BorderRadius.circular(28),
                          opacity: 0.6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.summarize_rounded, 
                                      size: 20, color: AppTheme.brandGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Session Summary',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(height: 1),
                              ),
                              _summaryRow('Location', booking.location.name),
                              const SizedBox(height: 14),
                              _summaryRow('Parking Spot', booking.spot.label),
                              const SizedBox(height: 14),
                              _summaryRow('Total Paid', '₱${booking.totalPrice.toStringAsFixed(0)}'),
                              const SizedBox(height: 14),
                              _summaryRow('Reference', booking.bookingCode ?? booking.id.substring(0, 8)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ── Action Buttons ──────────────────────────────
                        GlassButton(
                          isFullWidth: true,
                          variant: GlassButtonVariant.primary,
                          onPressed: _finish,
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

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
