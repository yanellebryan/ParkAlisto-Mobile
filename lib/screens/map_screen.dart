import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../services/mock_data.dart';
import '../widgets/dynamic_mesh_background.dart';
import '../models/parking_location.dart';
import 'choose_spot_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  double _currentZoom = 16.0;
  bool _iconsLoaded = false;

  // Cache for pre-rendered icons
  final Map<String, BitmapDescriptor> _fullMarkers = {};
  BitmapDescriptor? _pinOnlyMarker;

  @override
  void initState() {
    super.initState();
    _loadAllIcons();
  }

  Future<void> _loadAllIcons() async {
    try {
      // 1. Generate the simple pin icon once
      _pinOnlyMarker = await _generateMarkerIcon(null);

      // 2. Generate full aesthetic labels for each location
      for (var loc in MockData.parkingLocations) {
        _fullMarkers[loc.id] = await _generateMarkerIcon(loc);
      }

      if (mounted) {
        setState(() {
          _iconsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading icons: $e');
    }
  }

  // Generates a single bitmap descriptor containing BOTH the pin and the label
  Future<BitmapDescriptor> _generateMarkerIcon(ParkingLocation? loc) async {
    const double width = 360.0;
    const double height = 180.0;
    const double pinPadding = 10.0;
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    if (loc != null) {
      // --- TEXT RENDERING (MEASURE FIRST) ---
      final namePainter = TextPainter(
        text: TextSpan(
          text: loc.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24, // High res
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: width - 40); // Allow more width

      final pricePainter = TextPainter(
        text: TextSpan(
          text: '₱${loc.pricePerHour.toStringAsFixed(0)}/hr',
          style: const TextStyle(
            color: AppTheme.brandGreen,
            fontSize: 26, // High res
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Dynamic label styling
      final double labelWidth = (namePainter.width > pricePainter.width 
          ? namePainter.width 
          : pricePainter.width) + 30.0; // Adding horizontal padding
      const double labelHeight = 70.0;
      const double centerX = width / 2;
      const double labelTop = 30.0;
      
      // --- DRAW LABEL CARD ---
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.95)
        ..style = PaintingStyle.fill;

      // Shadow for label
      final shadowPath = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(centerX, labelTop + labelHeight / 2), width: labelWidth, height: labelHeight),
          const Radius.circular(16),
        ));
      canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.3), 4.0, true);
      
      // Label Background
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(centerX, labelTop + labelHeight / 2), width: labelWidth, height: labelHeight),
          const Radius.circular(16),
        ),
        paint,
      );
      
      // Border for label
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(centerX, labelTop + labelHeight / 2), width: labelWidth, height: labelHeight),
          const Radius.circular(16),
        ),
        Paint()
          ..color = AppTheme.brandGreen.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Paint text centered in the now-dynamic box
      namePainter.paint(canvas, Offset(centerX - namePainter.width / 2, labelTop + 12));
      pricePainter.paint(canvas, Offset(centerX - pricePainter.width / 2, labelTop + 42));
    }

    // --- DRAW PIN ---
    const double pinSize = 40.0;
    const double pinCenterY = 140.0;
    const double centerX = width / 2;

    // Pin Shadow
    final pinShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(const Offset(centerX, pinCenterY + 2), pinSize/2, pinShadowPaint);

    // Pin Outer Border (Green)
    canvas.drawCircle(const Offset(centerX, pinCenterY), pinSize/2, Paint()..color = AppTheme.brandGreen);
    
    // Pin Inner White
    canvas.drawCircle(const Offset(centerX, pinCenterY), pinSize/2 - 4, Paint()..color = Colors.white);
    
    // Pin Center Dot (Green)
    canvas.drawCircle(const Offset(centerX, pinCenterY), pinSize/2 - 10, Paint()..color = AppTheme.brandGreen);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController!.setMapStyle(_mapStyle);
  }

  void _onCameraMove(CameraPosition position) {
    if ((position.zoom >= 15.5 && _currentZoom < 15.5) ||
        (position.zoom < 15.5 && _currentZoom >= 15.5)) {
      setState(() {
        _currentZoom = position.zoom;
      });
    } else {
      _currentZoom = position.zoom;
    }
  }

  Set<Marker> _buildMarkers(List<ParkingLocation> locations) {
    if (!_iconsLoaded) return {};

    final appState = context.read<AppState>();
    final showLabels = _currentZoom >= 15.5;

    return locations
        .where((loc) => loc.latitude != null && loc.longitude != null)
        .map((loc) {
      return Marker(
        markerId: MarkerId(loc.id),
        position: LatLng(loc.latitude!, loc.longitude!),
        icon: showLabels 
            ? (_fullMarkers[loc.id] ?? BitmapDescriptor.defaultMarker)
            : (_pinOnlyMarker ?? BitmapDescriptor.defaultMarker),
        // Anchoring at the center horizontal and bottom (pin tip)
        anchor: const Offset(0.5, 0.78), 
        onTap: () => _navigateToDetails(context, appState, loc),
      );
    }).toSet();
  }

  void _navigateToDetails(BuildContext context, AppState appState, ParkingLocation loc) {
    appState.setLocation(loc);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChooseSpotScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locations = MockData.parkingLocations;

    return DynamicMeshBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Text('Explore Map', style: theme.textTheme.headlineMedium),
            ),

            // Map area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.brandGreen.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(10.6676405, 122.9455627),
                          zoom: 16.0,
                        ),
                        markers: _buildMarkers(locations),
                        onCameraMove: _onCameraMove,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: true,
                        compassEnabled: true,
                      ),
                      if (!_iconsLoaded)
                        Container(
                          color: Colors.white.withOpacity(0.5),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.brandGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// Custom map style to hide POIs and clutter
const String _mapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "poi.business",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels.icon",
    "stylers": [
      { "visibility": "off" }
    ]
  }
]
''';
