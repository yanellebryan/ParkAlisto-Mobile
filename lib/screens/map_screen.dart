import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../services/mock_data.dart';
import '../models/parking_location.dart';
import '../widgets/glass_container.dart';
import '../widgets/dynamic_mesh_background.dart';
import 'choose_spot_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

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
              child: Text('Explore Map',
                  style: theme.textTheme.headlineMedium),
            ),

            // Map area
            Expanded(
              child: Stack(
                children: [
                  // Mock map background
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: AppTheme.brandGreenLight.withOpacity(0.3),
                      border: Border.all(
                        color: AppTheme.brandGreen.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Grid lines to simulate a map
                        ...List.generate(5, (i) {
                          return Positioned(
                            top: 0,
                            bottom: 0,
                            left: (i + 1) * 70.0,
                            child: Container(
                              width: 0.5,
                              color: AppTheme.textPrimary.withOpacity(0.06),
                            ),
                          );
                        }),
                        ...List.generate(8, (i) {
                          return Positioned(
                            left: 0,
                            right: 0,
                            top: (i + 1) * 60.0,
                            child: Container(
                              height: 0.5,
                              color: AppTheme.textPrimary.withOpacity(0.06),
                            ),
                          );
                        }),

                        // Pin cards
                        _buildPinCard(context, locations[0], 0.15, 0.2),
                        _buildPinCard(context, locations[1], 0.55, 0.15),
                        _buildPinCard(context, locations[2], 0.3, 0.55),
                        _buildPinCard(context, locations[3], 0.65, 0.7),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPinCard(BuildContext context, ParkingLocation location,
      double leftFraction, double topFraction) {
    return Positioned(
      left: MediaQuery.of(context).size.width * leftFraction,
      top: MediaQuery.of(context).size.height * topFraction * 0.5,
      child: GestureDetector(
        onTap: () {
          final appState = context.read<AppState>();
          appState.setLocation(location);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChooseSpotScreen(),
            ),
          );
        },
        child: Column(
          children: [
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${location.pricePerHour.toStringAsFixed(0)}/hr',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brandGreen,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.location_on, color: AppTheme.brandGreen, size: 24),
          ],
        ),
      ),
    );
  }
}
