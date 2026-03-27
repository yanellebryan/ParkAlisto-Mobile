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

  // Cache for pre-rendered icons and their specific anchors
  final Map<String, ({BitmapDescriptor icon, Offset anchor})> _markerData = {};
  ({BitmapDescriptor icon, Offset anchor})? _pinOnlyData;

  @override
  void initState() {
    super.initState();
    _loadAllIcons();
  }

  Future<void> _loadAllIcons() async {
    try {
      // 1. Generate the simple pin icon once
      _pinOnlyData = await _generateMarkerIconData(null);

      // 2. Generate full aesthetic labels for each location
      for (var loc in MockData.parkingLocations) {
        _markerData[loc.id] = await _generateMarkerIconData(loc);
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

  // Generates a bitmap descriptor AND the correct anchor for the pin tip
  Future<({BitmapDescriptor icon, Offset anchor})> _generateMarkerIconData(ParkingLocation? loc) async {
    // 1. MEASURE CONTENT
    double labelWidth = 0;
    const double labelHeight = 76.0;
    const double pinSize = 44.0;
    const double gap = 4.0;
    
    TextPainter? namePainter;
    TextPainter? pricePainter;

    if (loc != null) {
      namePainter = TextPainter(
        text: TextSpan(
          text: loc.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 300);

      pricePainter = TextPainter(
        text: TextSpan(
          text: '₱${loc.pricePerHour.toStringAsFixed(0)}/hr',
          style: const TextStyle(
            color: AppTheme.brandGreen,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelWidth = (namePainter.width > pricePainter.width 
          ? namePainter.width 
          : pricePainter.width) + 32.0;
    }

    // 2. CALCULATE CANVAS SIZE
    // We need enough room for the label, the gap, the pin, and shadows
    final double canvasWidth = (labelWidth > pinSize ? labelWidth : pinSize) + 20.0; // + shadow room
    final double canvasHeight = (loc != null ? labelHeight + gap : 0) + pinSize + 20.0;
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final centerX = canvasWidth / 2;
    
    if (loc != null && namePainter != null && pricePainter != null) {
      const double labelTop = 10.0;
      
      // Shadow for label
      final shadowPath = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(centerX, labelTop + labelHeight / 2), width: labelWidth, height: labelHeight),
          const Radius.circular(16),
        ));
      canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.25), 4.0, true);
      
      // Label Background
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(centerX, labelTop + labelHeight / 2), width: labelWidth, height: labelHeight),
          const Radius.circular(16),
        ),
        Paint()..color = Colors.white.withOpacity(0.98),
      );
      
      // Label Border
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(centerX, labelTop + labelHeight / 2), width: labelWidth, height: labelHeight),
          const Radius.circular(16),
        ),
        Paint()
          ..color = AppTheme.brandGreen.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      namePainter.paint(canvas, Offset(centerX - namePainter.width / 2, labelTop + 12));
      pricePainter.paint(canvas, Offset(centerX - pricePainter.width / 2, labelTop + 42));
    }

    // --- DRAW PIN ---
    final double pinCenterY = (loc != null ? labelHeight + gap : 0) + 10.0 + pinSize/2;

    // Pin Shadow
    canvas.drawCircle(Offset(centerX, pinCenterY + 2), pinSize/2, 
        Paint()..color = Colors.black.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0));

    // Pin Outer
    canvas.drawCircle(Offset(centerX, pinCenterY), pinSize/2, Paint()..color = AppTheme.brandGreen);
    // Pin Inner White
    canvas.drawCircle(Offset(centerX, pinCenterY), pinSize/2 - 4.0, Paint()..color = Colors.white);
    // Pin Center Dot
    canvas.drawCircle(Offset(centerX, pinCenterY), pinSize/2 - 10.0, Paint()..color = AppTheme.brandGreen);

    // 3. EXPORT IMAGE
    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    // 4. CALCULATE ANCHOR
    // The anchor should be at the very tip (bottom) of the pin
    final double tipY = pinCenterY + pinSize/2;
    final Offset anchor = Offset(0.5, tipY / canvasHeight);

    return (
      icon: BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List()),
      anchor: anchor,
    );
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
      final data = showLabels ? _markerData[loc.id] : _pinOnlyData;
      
      return Marker(
        markerId: MarkerId(loc.id),
        position: LatLng(loc.latitude!, loc.longitude!),
        icon: data?.icon ?? BitmapDescriptor.defaultMarker,
        anchor: data?.anchor ?? const Offset(0.5, 1.0),
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
