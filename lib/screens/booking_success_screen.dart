import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/dynamic_mesh_background.dart';

class BookingSuccessScreen extends StatefulWidget {
  final String spotId;
  final String locationName;
  final int durationHours;
  final double totalPrice;
  final String bookingRef;

  const BookingSuccessScreen({
    Key? key,
    required this.spotId,
    required this.locationName,
    required this.durationHours,
    required this.totalPrice,
    required this.bookingRef,
  }) : super(key: key);

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: AppTheme.appleSpring,
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
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
                      ),
                      child: const Icon(Icons.check_circle,
                          color: AppTheme.brandGreen, size: 64),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text('Booking Confirmed!',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: AppTheme.brandGreenDeep)),
                  const SizedBox(height: 24),

                  // Details card
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        _detailRow(context, 'Location', widget.locationName),
                        const SizedBox(height: 12),
                        _detailRow(context, 'Spot', widget.spotId),
                        const SizedBox(height: 12),
                        _detailRow(
                            context, 'Duration', '${widget.durationHours}h'),
                        const SizedBox(height: 12),
                        _detailRow(context, 'Total',
                            '₱${widget.totalPrice.toStringAsFixed(0)}'),
                        const Divider(height: 24),
                        _detailRow(context, 'Reference', widget.bookingRef),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Buttons
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
                  const SizedBox(height: 12),
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
