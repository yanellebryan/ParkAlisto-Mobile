import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../models/booking.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/dynamic_mesh_background.dart';
import '../widgets/booking_qr_sheet.dart';
import 'active_parking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  Timer? _pollTimer;
  String? _autoNavigatedSessionId; // tracks which session we auto-navigated to

  @override
  void initState() {
    super.initState();
    // Poll every 10s so check-in is detected even without realtime
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) context.read<AppState>().loadBookings();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final activeSession = appState.activeCheckedInBooking;

    // Auto-navigate to ActiveParkingScreen when a new check-in is detected
    if (activeSession != null && _autoNavigatedSessionId != activeSession.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Only navigate if this session wasn't already navigated to
        if (_autoNavigatedSessionId != activeSession.id) {
          setState(() => _autoNavigatedSessionId = activeSession.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActiveParkingScreen(booking: activeSession),
            ),
          );
        }
      });
    } else if (activeSession == null) {
      // Reset when session ends so a future check-in triggers again
      _autoNavigatedSessionId = null;
    }

    // Filter out active+checked-in booking from the list (shown in ActiveParkingScreen instead)
    final bookings = appState.myBookings
        .where((b) => !(b.status == 'active' && b.checkedIn))
        .toList();

    return DynamicMeshBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Bookings', style: theme.textTheme.headlineMedium),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppTheme.textPrimary.withOpacity(0.5),
                    onPressed: () => appState.loadBookings(),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            // ── Active Session Banner ──────────────────────────────
            if (activeSession != null)
              _buildActiveSessionBanner(context, activeSession),

            // Content
            Expanded(
              child: bookings.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) =>
                          _buildBookingCard(context, bookings[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionBanner(BuildContext context, Booking booking) {
    final expiresAt = booking.expiresAt;
    final remaining = expiresAt != null && expiresAt.isAfter(DateTime.now())
        ? expiresAt.difference(DateTime.now())
        : Duration.zero;
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveParkingScreen(booking: booking),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.brandGreen.withOpacity(0.85),
              AppTheme.brandGreenDeep,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandGreen.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_parking, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "You're currently parked! 🚗",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remaining.inSeconds > 0
                        ? '$h:$m remaining • ${booking.spot.label}'
                        : 'Session expired • Please vacate',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined,
              size: 64, color: AppTheme.textPrimary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No bookings yet',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: AppTheme.textPrimary.withOpacity(0.5))),
          const SizedBox(height: 24),
          GlassButton(
            variant: GlassButtonVariant.primary,
            onPressed: () {
              context.read<AppState>().setBottomNavIndex(0);
            },
            child: const Text('Find Parking'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    switch (booking.status) {
      case 'active':
        statusColor = AppTheme.brandGreen;
        statusIcon = Icons.radio_button_checked;
        break;
      case 'completed':
        statusColor = AppTheme.textPrimary.withOpacity(0.4);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        statusColor = AppTheme.destructiveLight;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppTheme.textPrimary.withOpacity(0.4);
        statusIcon = Icons.help_outline;
    }

    final bool cancelledByAdmin =
        booking.status == 'cancelled' && booking.cancellationReason != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.location.name,
                    style: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        booking.status[0].toUpperCase() +
                            booking.status.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info rows
            _infoRow(Icons.local_parking, 'Spot ${booking.spot.label}'),
            const SizedBox(height: 4),
            _infoRow(Icons.calendar_today_outlined,
                '${booking.dateTime.day}/${booking.dateTime.month}/${booking.dateTime.year}  ${booking.dateTime.hour}:${booking.dateTime.minute.toString().padLeft(2, '0')}'),
            const SizedBox(height: 4),
            _infoRow(Icons.timer_outlined,
                '${booking.durationHours}h — ₱${booking.totalPrice.toStringAsFixed(0)}'),

            // Booking code row
            if (booking.bookingCode != null) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.qr_code_rounded, booking.bookingCode!,
                  color: AppTheme.brandGreen.withOpacity(0.7)),
            ],

            // Expiry info for active bookings
            if (booking.status == 'active' && booking.expiresAt != null) ...[
              const SizedBox(height: 4),
              _infoRow(
                Icons.hourglass_bottom_rounded,
                'Expires: ${_formatDateTime(booking.expiresAt!)}',
                color: booking.isExpired
                    ? AppTheme.destructiveLight
                    : AppTheme.textPrimary.withOpacity(0.5),
              ),
            ],

            // Admin cancellation notice
            if (cancelledByAdmin) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.destructiveLight.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.destructiveLight.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16,
                        color: AppTheme.destructiveLight.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancelled by admin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.destructiveLight,
                            ),
                          ),
                          if (booking.cancellationReason!.isNotEmpty)
                            Text(
                              booking.cancellationReason!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textPrimary.withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Bottom action buttons
            if (booking.status == 'active') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  // Show QR button
                  Expanded(
                    child: GlassButton(
                      variant: GlassButtonVariant.ghost,
                      onPressed: () => showBookingQrSheet(
                        context,
                        bookingCode: booking.bookingCode ?? booking.id,
                        spotLabel: booking.spot.label,
                        locationName: booking.location.name,
                        durationHours: booking.durationHours,
                        arrivalTime: booking.arrivalTime,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Show QR'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Cancel button
                  Expanded(
                    child: GlassButton(
                      variant: GlassButtonVariant.destructive,
                      onPressed: () => _showCancelDialog(context, booking.id),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} $hour:$min';
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: color ?? AppTheme.textPrimary.withOpacity(0.45)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color ?? AppTheme.textPrimary.withOpacity(0.65),
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cancel Booking?',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to cancel this booking? This action cannot be undone.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      variant: GlassButtonVariant.ghost,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Keep'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      variant: GlassButtonVariant.destructive,
                      onPressed: () {
                        context.read<AppState>().cancelBooking(bookingId);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
