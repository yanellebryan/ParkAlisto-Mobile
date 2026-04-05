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

    // Split spots into floors based on the 'floor' property from the database
    final allSpots = appState.currentSpots.isNotEmpty ? appState.currentSpots : location.spots;
    final selectedSpot = appState.selectedSpot;
    
    // Determine spots for the current floor
    // If spots have a floor property (Supabase), filter by it. 
    // Otherwise (Mock), fall back to slicing 24 per floor.
    final List<ParkingSpot> currentSpots;
    if (allSpots.any((s) => s.floor != null)) {
      currentSpots = allSpots.where((s) => s.floor == (_currentFloorIndex + 1)).toList();
    } else {
      final spotsPerFloor = (allSpots.length / 3).ceil();
      final start = _currentFloorIndex * spotsPerFloor;
      final end = (start + spotsPerFloor).clamp(0, allSpots.length);
      currentSpots = (start < allSpots.length) ? allSpots.sublist(start, end) : [];
    }
    final isUSLS = location.name.contains('University of St. La Salle') || location.id == 'loc_4';

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

              // Floor selector — opens picker showing all floors
              GestureDetector(
                onTap: () => _showFloorPicker(context),
                child: GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_floors[_currentFloorIndex],
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
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

  Widget _buildSpotGrid(List<ParkingSpot> spots, ParkingSpot? selectedSpot, AppState appState) {
    const double spotW = 92.0;
    const double spotH = 75.0; 
    const double colGap = 12.0;
    final double gridWidth = (spotW * 3) + (colGap * 2);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.textPrimary.withValues(alpha: 0.07), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _badge('ENTRANCE', AppTheme.brandGreen, Icons.arrow_upward),
            const SizedBox(height: 16),
            SizedBox(
              width: gridWidth,
              child: GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: spotW / spotH,
                  crossAxisSpacing: colGap,
                  mainAxisSpacing: colGap,
                ),
                itemCount: spots.length,
                itemBuilder: (ctx, idx) => _buildSpot(spots[idx], selectedSpot, appState, 
                    width: spotW, height: spotH, noMargin: true),
              ),
            ),
            const SizedBox(height: 20),
            _badge('EXIT', Colors.red, Icons.arrow_downward),
          ],
        ),
      ),
    );
  }

  Widget _buildUSLSLayout(List<ParkingSpot> spots, ParkingSpot? selectedSpot, AppState appState) {
    // Robust mapping: Create a map of spots by their label (e.g., 'A1', 'B3')
    // This prevents naming mismatches if the DB order changes.
    final Map<String, ParkingSpot> spotMap = {
      for (var s in spots) s.label: s
    };

    // Helper to get spot by row and number
    ParkingSpot? getSpot(String row, int num) => spotMap['$row$num'];

    // Fixed spot dimensions
    const double spotW = 82.0;
    const double spotH = 68.0;
    const double colGap = 8.0;
    const double aisleW = 64.0;
    const double rowGap = 6.0;

    // Section sizes
    final double sectionAW = spotW * 2 + colGap;
    final double sectionBW = spotW;
    final double totalW = sectionAW + aisleW + sectionBW;

    Widget makeTile(ParkingSpot? spot) {
      if (spot != null) {
        return _buildSpot(spot, selectedSpot, appState,
            width: spotW, height: spotH, noMargin: true);
      }
      return SizedBox(width: spotW, height: spotH);
    }

    // Determine which rows are on this floor
    // Floor 1: A, B, C, D
    // Floor 2: E, F, G, H
    // Floor 3: I, J, K, L
    final List<String> floorRows;
    if (_currentFloorIndex == 0) floorRows = ['A', 'B', 'C', 'D'];
    else if (_currentFloorIndex == 1) floorRows = ['E', 'F', 'G', 'H'];
    else floorRows = ['I', 'J', 'K', 'L'];

    final r1 = floorRows[0];
    final r2 = floorRows[1];
    final r3 = floorRows[2];
    final r4 = floorRows[3];

    // Top Row: Row 1, Spots 1-3
    final topRow = SizedBox(
      width: totalW,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          makeTile(getSpot(r1, 1)),
          const SizedBox(width: colGap),
          makeTile(getSpot(r1, 2)),
          const SizedBox(width: colGap),
          makeTile(getSpot(r1, 3)),
        ],
      ),
    );

    // Section A (Left): 2 columns
    // Row 1 (4-6), Row 2 (1-6), Row 3 (1-5) -> 3+6+5 = 14 spots = 7 rows of 2
    List<ParkingSpot?> sectionASpots = [
      getSpot(r1, 4), getSpot(r1, 5),
      getSpot(r1, 6), getSpot(r2, 1),
      getSpot(r2, 2), getSpot(r2, 3),
      getSpot(r2, 4), getSpot(r2, 5),
      getSpot(r2, 6), getSpot(r3, 1),
      getSpot(r3, 2), getSpot(r3, 3),
      getSpot(r3, 4), getSpot(r3, 5),
    ];

    // Section B (Right): 1 column
    // Row 3 (6), Row 4 (1-6) -> 1+6 = 7 spots = 7 rows of 1
    List<ParkingSpot?> sectionBSpots = [
      getSpot(r3, 6),
      getSpot(r4, 1),
      getSpot(r4, 2),
      getSpot(r4, 3),
      getSpot(r4, 4),
      getSpot(r4, 5),
      getSpot(r4, 6),
    ];

    List<Widget> sectionARows = [];
    List<Widget> sectionBRows = [];

    for (int r = 0; r < 7; r++) {
      sectionARows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            makeTile(sectionASpots[r * 2]),
            const SizedBox(width: colGap),
            makeTile(sectionASpots[r * 2 + 1]),
          ],
        ),
      );
      sectionBRows.add(makeTile(sectionBSpots[r]));
      if (r < 6) {
        sectionARows.add(const SizedBox(height: rowGap));
        sectionBRows.add(const SizedBox(height: rowGap));
      }
    }

    final bodyContent = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(mainAxisSize: MainAxisSize.min, children: sectionARows),
        SizedBox(width: aisleW),
        Column(mainAxisSize: MainAxisSize.min, children: sectionBRows),
      ],
    );

    Widget sectionHeaders() => SizedBox(
          width: totalW,
          child: Row(
            children: [
              SizedBox(width: sectionAW, child: Center(child: Text('SECTION A', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textPrimary.withValues(alpha: 0.35))))),
              SizedBox(width: aisleW),
              SizedBox(width: sectionBW, child: Center(child: Text('SECTION B', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textPrimary.withValues(alpha: 0.35))))),
            ],
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textPrimary.withValues(alpha: 0.07), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _badge('ENTRANCE', AppTheme.brandGreen, Icons.arrow_upward),
            const SizedBox(height: 10),
            topRow,
            _drivewayDivider('DRIVEWAY', totalW),
            Padding(padding: const EdgeInsets.only(bottom: 6), child: sectionHeaders()),
            bodyContent,
            const SizedBox(height: 16),
            _badge('EXIT', Colors.red, Icons.arrow_downward),
          ],
        ),
      ),
    );
  }


  // ── Shared High-Fidelity UL Elements ────────────────────────

  Widget _badge(String text, Color color, IconData icon) => Container(
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
            Text(text,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 1.3)),
          ],
        ),
      );

  Widget _drivewayDivider(String label, double width) => SizedBox(
        width: width,
        height: 32,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.compare_arrows,
                  size: 13, color: AppTheme.textPrimary.withValues(alpha: 0.28)),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary.withValues(alpha: 0.28))),
            ],
          ),
        ),
      );

  Widget _buildSpot(
      ParkingSpot spot, ParkingSpot? selectedSpot, AppState appState, 
      {double? width, double? height, bool noMargin = false}) {
    final bool isOccupied = spot.status == SpotStatus.occupied;
    final bool isSelected = selectedSpot?.id == spot.id;

    final occupiedColor = Colors.red;
    final availableBorderColor = AppTheme.brandGreen;

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
        margin: noMargin ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                      border: Border.all(color: Colors.red, width: 1.5),
                    )
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: availableBorderColor,
                          width: 1),
                    ),
          child: ClipRect(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _spotNameChip(spot, isSelected),
                  const SizedBox(height: 2),
                  if (isOccupied)
                    const CarTopView(width: 20, height: 28)
                  else if (isSelected)
                    _checkIcon()
                  else
                    Text(
                      'Available',
                      style: TextStyle(
                        color: AppTheme.brandGreenDeep,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
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

  // ── Floor Picker ───────────────────────────────────────────

  void _showFloorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.textPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Floor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            ..._floors.asMap().entries.map((entry) {
              final index = entry.key;
              final floor = entry.value;
              final isActive = _currentFloorIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _currentFloorIndex = index);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.brandGreen.withOpacity(0.12)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: isActive
                        ? Border.all(color: AppTheme.brandGreen, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 20,
                        color: isActive ? AppTheme.brandGreen : AppTheme.textPrimary.withOpacity(0.5),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        floor,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? AppTheme.brandGreen : AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (isActive)
                        const Icon(Icons.check_circle, color: AppTheme.brandGreen, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Booking Sheet ──────────────────────────────────────────

  void _showBookingSheet(BuildContext context, AppState appState) {
    int selectedDuration = 1;
    final durations = [1, 2, 3, 4, 6, 8];
    DateTime selectedTime = DateTime.now();

    String formatTime(DateTime t) {
      final now = DateTime.now();
      final isToday = t.day == now.day && t.month == now.month && t.year == now.year;
      final isTomorrow = t.day == now.add(const Duration(days: 1)).day && t.month == now.add(const Duration(days: 1)).month;
      
      String dayPrefix = isToday ? 'Today' : (isTomorrow ? 'Tomorrow' : '${t.month}/${t.day}');
      
      int h = t.hour;
      String period = h >= 12 ? 'PM' : 'AM';
      if (h == 0) {
        h = 12;
      } else if (h > 12) {
        h -= 12;
      }
      
      String m = t.minute.toString().padLeft(2, '0');
      
      return '$dayPrefix, $h:$m $period';
    }

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

                // Arrival Time
                Text('Arrival Time',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedTime),
                    );
                    if (picked != null) {
                      final now = DateTime.now();
                      setSheetState(() {
                        selectedTime = DateTime(
                          now.year, now.month, now.day,
                          picked.hour, picked.minute,
                        );
                        // If picked time is strictly earlier than now (within margin), assume tomorrow
                        if (selectedTime.isBefore(now.subtract(const Duration(minutes: 5)))) {
                          selectedTime = selectedTime.add(const Duration(days: 1));
                        }
                      });
                    }
                  },
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.brandGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.access_time, color: AppTheme.brandGreen, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatTime(selectedTime),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            Text(
                              'Tap to change arrival time',
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
                  onPressed: () async {
                    final spotLabel = spot.label;
                    final locName = loc.name;
                    final price = totalPrice;
                    final dur = selectedDuration;
                    final capturedTime = selectedTime;

                    Navigator.pop(ctx); // close sheet first

                    // confirmBooking now returns the real Booking with UUID + bookingCode
                    final createdBooking = await appState.confirmBooking(
                      dur,
                      startTime: capturedTime,
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingSuccessScreen(
                          spotLabel: spotLabel,
                          locationName: locName,
                          durationHours: dur,
                          totalPrice: price,
                          bookingRef: createdBooking?.id ?? 'N/A',
                          bookingCode: createdBooking?.bookingCode,
                          arrivalTime: capturedTime,
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
