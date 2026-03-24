import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../models/parking_location.dart';
import '../models/parking_spot.dart';
import '../widgets/car_placeholder.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/dynamic_mesh_background.dart';
import 'booking_success_screen.dart';

class ChooseSpotScreen extends StatefulWidget {
  const ChooseSpotScreen({Key? key}) : super(key: key);

  @override
  State<ChooseSpotScreen> createState() => _ChooseSpotScreenState();
}

class _ChooseSpotScreenState extends State<ChooseSpotScreen> {
  int _currentFloorIndex = 0;
  final List<String> _floors = ['Floor 1', 'Floor 2', 'Floor 3'];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final location = appState.selectedLocation;

    if (location == null) {
      return const Scaffold(
        body: Center(child: Text('No location selected')),
      );
    }

    // Split spots into 3 "floors"
    final allSpots = appState.currentSpots.isNotEmpty ? appState.currentSpots : location.spots;
    final spotsPerFloor = (allSpots.length / 3).ceil();
    final floorSpots = <List<ParkingSpot>>[];
    for (int i = 0; i < 3; i++) {
      final start = i * spotsPerFloor;
      final end = (start + spotsPerFloor).clamp(0, allSpots.length);
      if (start < allSpots.length) {
        floorSpots.add(allSpots.sublist(start, end));
      } else {
        floorSpots.add([]);
      }
    }

    final currentSpots = floorSpots[_currentFloorIndex];
    final selectedSpot = appState.selectedSpot;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Choose Spot'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/icons/Logo_For_WhiteBG_PA.png',
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: DynamicMeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Location info
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  children: [
                    if (location.effectiveLogoPath != null)
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Image.asset(location.effectiveLogoPath!, fit: BoxFit.contain),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(location.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(location.address,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Floor selector
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentFloorIndex =
                        (_currentFloorIndex + 1) % _floors.length;
                  });
                },
                child: GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_floors[_currentFloorIndex],
                          style: TextStyle(color: AppTheme.textPrimary)),
                      const SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppTheme.textPrimary.withOpacity(0.6)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Spot grid
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildSpotGrid(currentSpots, selectedSpot, appState),
                        const SizedBox(height: 24),

                        // Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legendItem('Available', Colors.white,
                                AppTheme.brandGreen),
                            const SizedBox(width: 20),
                            _legendItem(
                                'Occupied',
                                AppTheme.textPrimary.withOpacity(0.15),
                                AppTheme.textPrimary.withOpacity(0.3)),
                            const SizedBox(width: 20),
                            _legendItem('Selected', AppTheme.brandGreen,
                                AppTheme.brandGreen),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: GlassButton(
          isFullWidth: true,
          variant: selectedSpot != null
              ? GlassButtonVariant.primary
              : GlassButtonVariant.ghost,
          onPressed: () {
            if (selectedSpot != null) {
              _showBookingSheet(context, appState);
            }
          },
          child: Text(selectedSpot != null
              ? 'Choose Spot (${selectedSpot.label})'
              : 'Select a spot'),
        ),
      ),
    );
  }

  Widget _buildSpotGrid(List<ParkingSpot> spots, ParkingSpot? selectedSpot,
      AppState appState) {
    // Arrange in rows of 4
    final List<Widget> rows = [];
    for (int i = 0; i < spots.length; i += 4) {
      final rowSpots = spots.sublist(i, (i + 4).clamp(0, spots.length));
      rows.add(Row(
        children: rowSpots
            .expand((s) => [
                  Expanded(child: _buildSpot(s, selectedSpot, appState)),
                  if (rowSpots.indexOf(s) < rowSpots.length - 1)
                    _buildVerticalDivider(),
                ])
            .toList(),
      ));
      if (i + 4 < spots.length) {
        rows.add(const SizedBox(height: 16));
      }
    }
    return Column(children: rows);
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 110,
      color: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildSpot(
      ParkingSpot spot, ParkingSpot? selectedSpot, AppState appState) {
    final bool isOccupied = spot.status == SpotStatus.occupied;
    final bool isSelected = selectedSpot?.id == spot.id;

    return GestureDetector(
      onTap: () {
        if (!isOccupied) {
          appState.setSpot(spot);
        }
      },
      child: GlassContainer(
        height: 145,
        opacity: isSelected ? 0.70 : (isOccupied ? 0.35 : 0.45),
        borderRadius: BorderRadius.circular(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.brandGreen, width: 2),
                  color: AppTheme.brandGreen.withOpacity(0.08),
                )
              : isOccupied
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.textPrimary.withOpacity(0.04),
                    )
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.brandGreen.withOpacity(0.3),
                          width: 1),
                    ),
          child: Column(
            children: [
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.brandGreen,
                  ),
                  child:
                      const Icon(Icons.check, size: 16, color: Colors.white),
                )
              else
                const SizedBox(height: 16),

              // Spot Name Chip
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.brandGreen.withOpacity(0.15)
                      : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(spot.label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textPrimary.withOpacity(0.7))),
              ),

              Expanded(
                child: Center(
                  child: isOccupied
                      ? const CarTopView(
                          width: 40,
                          height: 55,
                        )
                      : isSelected
                          ? Text('Selected',
                              style: TextStyle(
                                  color: AppTheme.brandGreenDeep,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600))
                          : Text('Available',
                              style: TextStyle(
                                  color:
                                      AppTheme.textPrimary.withOpacity(0.45),
                                  fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color fill, Color borderColor) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: fill.withOpacity(0.7),
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: AppTheme.textPrimary.withOpacity(0.55))),
      ],
    );
  }

  // ── Booking Sheet ──────────────────────────────────────────

  void _showBookingSheet(BuildContext context, AppState appState) {
    int selectedDuration = 1;
    final durations = [1, 2, 3, 4, 6, 8];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final loc = appState.selectedLocation!;
          final spot = appState.selectedSpot!;
          final totalPrice = loc.pricePerHour * selectedDuration;

          return GlassContainer(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.textPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Confirm Booking',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 20)),
                const SizedBox(height: 16),

                // Details
                _sheetRow('Location', loc.name),
                const SizedBox(height: 8),
                _sheetRow('Spot', spot.label),
                const SizedBox(height: 8),
                _sheetRow('Price',
                    '₱${loc.pricePerHour.toStringAsFixed(0)}/hr'),
                const SizedBox(height: 16),

                // Duration chips
                Text('Duration',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: durations.map((d) {
                    final isActive = selectedDuration == d;
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedDuration = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.brandGreen
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${d}h',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : AppTheme.textPrimary.withOpacity(0.7),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Total
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontSize: 16)),
                      Text(
                        '₱${totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.brandGreenDeep,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                GlassButton(
                  isFullWidth: true,
                  variant: GlassButtonVariant.primary,
                  onPressed: () {
                    final ref =
                        'PRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                    final spotLabel = spot.label;
                    final locName = loc.name;
                    final price = totalPrice;
                    final dur = selectedDuration;

                    appState.confirmBooking(selectedDuration);
                    Navigator.pop(ctx); // close sheet
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingSuccessScreen(
                          spotLabel: spotLabel,
                          locationName: locName,
                          durationHours: dur,
                          totalPrice: price,
                          bookingRef: ref,
                        ),
                      ),
                    );
                  },
                  child: const Text('Confirm Booking'),
                ),
                const SizedBox(height: 8),
                GlassButton(
                  isFullWidth: true,
                  variant: GlassButtonVariant.ghost,
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sheetRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary.withOpacity(0.55))),
        Flexible(
          child: Text(value,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontSize: 14),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
