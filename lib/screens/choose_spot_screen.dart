import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../models/parking_location.dart';
import '../models/parking_spot.dart';
import '../models/payment_method.dart';
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
  final TransformationController _transformationController = TransformationController();
  bool _isZoomedIn = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _isZoomedIn = false);
  }

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
    final isUSLS = location.name.contains('University of St. La Salle') || location.id == 'loc_6';

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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

              // Legend row – outside scrollable area
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendItem('Available', AppTheme.brandGreen, AppTheme.brandGreen),
                    const SizedBox(width: 20),
                    _legendItem('Occupied', Colors.red, Colors.red),
                    const SizedBox(width: 20),
                    _legendItem('Selected', AppTheme.brandGreen, AppTheme.brandGreen),
                  ],
                ),
              ),

              // Spot grid / Map
              Expanded(
                child: Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.3,
                      maxScale: 3.5,
                      constrained: false,   // lets child be its natural size – no squishing
                      boundaryMargin: const EdgeInsets.fromLTRB(40, 20, 40, 100),
                      onInteractionEnd: (_) {
                        setState(() {
                          _isZoomedIn = _transformationController.value.getMaxScaleOnAxis() > 1.1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        child: isUSLS
                            ? _buildUSLSLayout(currentSpots, selectedSpot, appState)
                            : _buildSpotGrid(currentSpots, selectedSpot, appState),
                      ),
                    ),
                    // Reset zoom button
                    if (_isZoomedIn)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          heroTag: 'resetZoom',
                          onPressed: _resetZoom,
                          backgroundColor: AppTheme.brandGreen,
                          child: const Icon(Icons.zoom_out_map, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (selectedSpot != null) {
              _showBookingSheet(context, appState);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: selectedSpot != null ? AppTheme.brandGreen : AppTheme.brandGreen.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              selectedSpot != null
                  ? 'Choose Spot (${selectedSpot.label})'
                  : 'Select a spot',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
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
            .expand<Widget>((s) => [
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

  Widget _buildUSLSLayout(List<ParkingSpot> spots, ParkingSpot? selectedSpot, AppState appState) {
    // Spot dimensions – bigger landscape cards
    const double spotW = 88;
    const double spotH = 64;
    const double rowGap = 8.0;
    const double colGap = 10.0;
    const double aisleW = 96.0;  // wide driving aisle

    Widget makeSpot(int index) {
      if (index < spots.length) {
        return _buildSpot(spots[index], selectedSpot, appState,
            width: spotW, height: spotH, isUSLS: true);
      }
      // Empty placeholder
      return SizedBox(width: spotW + 8, height: spotH + 8);
    }

    // ─── TOP: 3 spots centred ─────────────────────────────────
    // Sketch shows 3 spots near top-centre (spots 0-2)
    final topSpots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        makeSpot(0),
        SizedBox(width: rowGap),
        makeSpot(1),
        SizedBox(width: rowGap),
        makeSpot(2),
      ],
    );

    // ─── MAIN BODY ────────────────────────────────────────────
    // Left block: 2 columns × 8 rows  → spots 3-18
    // Right block: 1 column × 8 rows  → spots 19-26
    List<Widget> bodyRows = [];
    for (int r = 0; r < 8; r++) {
      final leftA = makeSpot(3 + r * 2);      // col 1
      final leftB = makeSpot(3 + r * 2 + 1);  // col 2
      final right  = makeSpot(19 + r);         // single right col

      bodyRows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left 2-col group
            leftA,
            SizedBox(width: rowGap),
            leftB,
            // Wide aisle (driving lane)
            SizedBox(width: aisleW),
            // Right 1-col group
            right,
          ],
        ),
      );
      if (r < 7) bodyRows.add(SizedBox(height: colGap));
    }

    // ─── BADGE helper ─────────────────────────────────────────
    Widget badge(String text, Color color, IconData icon) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 5),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

    // ─── ROW label ────────────────────────────────────────────
    Widget rowLabel(String left, String right) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left 2 cols width = 2 * (spotW+8) + rowGap
              SizedBox(
                width: (spotW + 8) * 2 + rowGap,
                child: Center(
                  child: Text(left,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppTheme.textPrimary.withValues(alpha: 0.35))),
                ),
              ),
              SizedBox(width: aisleW),
              // Right col width = spotW+8
              SizedBox(
                width: spotW + 8,
                child: Center(
                  child: Text(right,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppTheme.textPrimary.withValues(alpha: 0.35))),
                ),
              ),
            ],
          ),
        );

    // Full lot width (for aisle label)
    final double totalWidth = (spotW + 8) * 2 + rowGap + aisleW + (spotW + 8);

    Widget drivewayDivider(String label) => SizedBox(
          width: totalWidth,
          height: 36,
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.compare_arrows, size: 13,
                          color: AppTheme.textPrimary.withValues(alpha: 0.28)),
                      const SizedBox(width: 4),
                      Text(label,
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppTheme.textPrimary.withValues(alpha: 0.28))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textPrimary.withValues(alpha: 0.07), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ENTRANCE badge (top-left like sketch) ──────────
          badge('ENTRANCE', AppTheme.brandGreen, Icons.arrow_upward),
          const SizedBox(height: 12),

          // ── 3 top spots (centred) ──────────────────────────
          Center(child: topSpots),

          drivewayDivider('DRIVEWAY'),

          // ── Left/Right column headers ──────────────────────
          rowLabel('SECTION A', 'SECTION B'),

          // ── Main body rows ──────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bodyRows,
          ),

          const SizedBox(height: 16),

          // ── EXIT badge (bottom-left like sketch) ────────────
          badge('EXIT', Colors.red, Icons.arrow_downward),
        ],
      ),
    );
  }

  Widget _buildSpot(
      ParkingSpot spot, ParkingSpot? selectedSpot, AppState appState, 
      {bool isVertical = false, double? width, double? height, bool isUSLS = false}) {
    final bool isOccupied = spot.status == SpotStatus.occupied;
    final bool isSelected = selectedSpot?.id == spot.id;

    final occupiedColor = isUSLS ? Colors.red : AppTheme.textPrimary.withOpacity(0.04);
    final availableBorderColor = isUSLS ? AppTheme.brandGreen : AppTheme.brandGreen.withOpacity(0.3);

    return GestureDetector(
      onTap: () {
        if (!isOccupied) {
          appState.setSpot(spot);
        }
      },
      child: GlassContainer(
        height: height ?? 145,
        width: width,
        opacity: isSelected ? 0.70 : (isOccupied ? 0.35 : 0.45),
        borderRadius: BorderRadius.circular(12),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                      color: occupiedColor.withOpacity(0.15),
                      border: isUSLS ? Border.all(color: Colors.red, width: 1.5) : null,
                    )
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: availableBorderColor,
                          width: 1),
                    ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _spotNameChip(spot, isSelected),
                const SizedBox(height: 4),
                Expanded(
                  child: Center(
                    child: isOccupied
                        ? const CarTopView(width: 25, height: 40)
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isSelected ? 'Selected' : 'Available',
                                style: TextStyle(
                                  color: isSelected ? AppTheme.brandGreenDeep : AppTheme.textPrimary.withValues(alpha: 0.45),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                if (isSelected) ...[
                   const SizedBox(height: 4),
                   _checkIcon(),
                ],
                const SizedBox(height: 4),
              ],
            ),
        ),
      ),
    );
  }

  Widget _checkIcon() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.brandGreen,
      ),
      child: const Icon(Icons.check, size: 16, color: Colors.white),
    );
  }

  Widget _spotNameChip(ParkingSpot spot, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.brandGreen.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(spot.label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppTheme.textPrimary.withValues(alpha: 0.7))),
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
                _sheetRow(context, 'Location', loc.name),
                const SizedBox(height: 8),
                _sheetRow(context, 'Spot', spot.label),
                const SizedBox(height: 8),
                _sheetRow(context, 'Price',
                    '₱${loc.pricePerHour.toStringAsFixed(0)}/hr'),
                const SizedBox(height: 16),

                // Payment Method
                Text('Payment Method',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showPaymentSelectionSheet(context, appState, setSheetState),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        _buildPaymentIcon(appState.selectedPaymentMethod?.type ?? PaymentMethodType.cash),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.selectedPaymentMethod?.name ?? 'Cash',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            Text(
                              appState.selectedPaymentMethod?.maskedDetails ?? 'Pay upon arrival',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Change',
                          style: TextStyle(
                            color: AppTheme.brandGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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

  void _showPaymentSelectionSheet(BuildContext context, AppState appState, StateSetter parentSetState) {
    // Manual/Default options
    final manualOptions = [
      PaymentMethod(id: 'cash', type: PaymentMethodType.cash, name: 'Cash', lastFour: ''),
      PaymentMethod(id: 'qrph', type: PaymentMethodType.qrph, name: 'QrPh', lastFour: ''),
      PaymentMethod(id: 'otc', type: PaymentMethodType.overTheCounter, name: 'Over the Counter', lastFour: ''),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (appState.paymentMethods.isNotEmpty) ...[
                      _sheetSectionHeader('SAVED METHODS'),
                      ...appState.paymentMethods.map((pm) => _buildPaymentOption(pm, appState, parentSetState, ctx)),
                      const SizedBox(height: 16),
                    ],
                    _sheetSectionHeader('OTHER OPTIONS'),
                    ...manualOptions.map((pm) => _buildPaymentOption(pm, appState, parentSetState, ctx)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary.withOpacity(0.4),
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(PaymentMethod pm, AppState appState, StateSetter parentSetState, BuildContext sheetCtx) {
    final isSelected = appState.selectedPaymentMethod?.id == pm.id;
    return GestureDetector(
      onTap: () {
        appState.setSelectedPaymentMethod(pm);
        parentSetState(() {});
        Navigator.pop(sheetCtx);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandGreen.withOpacity(0.1) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.brandGreen, width: 1.5) : null,
        ),
        child: Row(
          children: [
            _buildPaymentIcon(pm.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pm.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(pm.maskedDetails, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary.withOpacity(0.5))),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.brandGreen, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentIcon(PaymentMethodType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case PaymentMethodType.gcash:
        iconData = Icons.account_balance_wallet;
        color = Colors.blue;
        break;
      case PaymentMethodType.maya:
        iconData = Icons.wallet;
        color = Colors.green;
        break;
      case PaymentMethodType.card:
        iconData = Icons.credit_card;
        color = Colors.orange;
        break;
      case PaymentMethodType.cash:
        iconData = Icons.payments_outlined;
        color = Colors.teal;
        break;
      case PaymentMethodType.qrph:
        iconData = Icons.qr_code_scanner;
        color = Colors.purple;
        break;
      case PaymentMethodType.overTheCounter:
        iconData = Icons.storefront_outlined;
        color = Colors.brown;
        break;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color, size: 18),
    );
  }

  Widget _sheetRow(BuildContext context, String label, String value) {
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
