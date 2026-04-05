import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import 'glass_container.dart';

/// A reusable bottom sheet that displays the booking's QR code.
/// Show it with: showBookingQrSheet(context, bookingCode: '...', ...)
class BookingQrSheet extends StatelessWidget {
  final String bookingCode;
  final String spotLabel;
  final String locationName;
  final int durationHours;
  final DateTime? arrivalTime;

  const BookingQrSheet({
    Key? key,
    required this.bookingCode,
    required this.spotLabel,
    required this.locationName,
    required this.durationHours,
    this.arrivalTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arrivalStr = arrivalTime != null
        ? '${arrivalTime!.hour.toString().padLeft(2, '0')}:${arrivalTime!.minute.toString().padLeft(2, '0')}'
        : 'Flexible';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Your Entry Pass',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Show this QR code at the parking entrance',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
          const SizedBox(height: 24),

          // QR Code
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(
                    data: bookingCode,
                    version: QrVersions.auto,
                    size: 200,
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
                const SizedBox(height: 16),

                // Booking code text
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: bookingCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking code copied!'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.brandGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.brandGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bookingCode,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandGreen,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.copy_rounded,
                            size: 16, color: AppTheme.brandGreen.withOpacity(0.7)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap code to copy',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Booking details row
          Row(
            children: [
              _infoChip(Icons.location_on_outlined, locationName),
              const SizedBox(width: 8),
              _infoChip(Icons.local_parking, spotLabel),
              const SizedBox(width: 8),
              _infoChip(Icons.schedule, '$durationHours h • $arrivalStr'),
            ],
          ),
          const SizedBox(height: 20),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share QR Code',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              onPressed: () {
                Share.share(
                  'My ParkAlisto booking code: $bookingCode\n'
                  'Spot: $spotLabel at $locationName\n'
                  'Duration: ${durationHours}h | Arrival: $arrivalStr',
                  subject: 'ParkAlisto Booking — $bookingCode',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white.withOpacity(0.45)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.65),
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to show the QR sheet from anywhere
void showBookingQrSheet(
  BuildContext context, {
  required String bookingCode,
  required String spotLabel,
  required String locationName,
  required int durationHours,
  DateTime? arrivalTime,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BookingQrSheet(
      bookingCode: bookingCode,
      spotLabel: spotLabel,
      locationName: locationName,
      durationHours: durationHours,
      arrivalTime: arrivalTime,
    ),
  );
}
