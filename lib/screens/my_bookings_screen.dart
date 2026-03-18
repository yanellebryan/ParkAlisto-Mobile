import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../models/booking.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/dynamic_mesh_background.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final bookings = appState.myBookings;

    return DynamicMeshBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Text('My Bookings',
                  style: theme.textTheme.headlineMedium),
            ),

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
    switch (booking.status) {
      case 'active':
        statusColor = AppTheme.brandGreen;
        break;
      case 'completed':
        statusColor = AppTheme.textPrimary.withOpacity(0.4);
        break;
      case 'cancelled':
        statusColor = AppTheme.destructiveLight;
        break;
      default:
        statusColor = AppTheme.textPrimary.withOpacity(0.4);
    }

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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status[0].toUpperCase() +
                        booking.status.substring(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info rows
            _infoRow(Icons.local_parking, 'Spot ${booking.spot.id}'),
            const SizedBox(height: 4),
            _infoRow(Icons.calendar_today_outlined,
                '${booking.dateTime.day}/${booking.dateTime.month}/${booking.dateTime.year}  ${booking.dateTime.hour}:${booking.dateTime.minute.toString().padLeft(2, '0')}'),
            const SizedBox(height: 4),
            _infoRow(Icons.timer_outlined,
                '${booking.durationHours}h — ₱${booking.totalPrice.toStringAsFixed(0)}'),

            // Cancel button for active bookings
            if (booking.status == 'active') ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GlassButton(
                  variant: GlassButtonVariant.destructive,
                  onPressed: () => _showCancelDialog(context, booking.id),
                  child: const Text('Cancel Booking'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textPrimary.withOpacity(0.45)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textPrimary.withOpacity(0.65),
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
