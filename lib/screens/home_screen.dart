import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../services/mock_data.dart';
import '../models/parking_location.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/dynamic_mesh_background.dart';
import 'choose_spot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _sortMode = 'none'; // 'price', 'rating', 'availability'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();

    // Filter locations by category + search
    List<ParkingLocation> locations = appState.filteredLocations
        .where((loc) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return loc.name.toLowerCase().contains(q) ||
          loc.district.toLowerCase().contains(q);
    }).toList();

    // Sort
    if (_sortMode == 'price') {
      locations.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
    } else if (_sortMode == 'rating') {
      locations.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortMode == 'availability') {
      locations.sort((a, b) => b.availableSpots.compareTo(a.availableSpots));
    }

    return DynamicMeshBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Location dropdown
                  GestureDetector(
                    onTap: () => _showCityPicker(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Location', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              appState.selectedCity,
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down,
                                size: 20,
                                color:
                                    AppTheme.textPrimary.withOpacity(0.6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/Logo_For_WhiteBG_PA.png',
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 16),
                      // Notification bell
                      GestureDetector(
                        onTap: () => _showNotifications(context),
                        child: GlassContainer(
                          width: 48,
                          height: 48,
                          borderRadius: BorderRadius.circular(24),
                          child: Center(
                            child: Icon(Icons.notifications_none,
                                color:
                                    AppTheme.textPrimary.withOpacity(0.7)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Greeting
              Text('Hello, ${appState.userName}! 👋',
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Let\'s find the best parking space',
                style:
                    theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 24),

              // ── Search Bar ───────────────────────────────────
              GlassContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        color: AppTheme.textPrimary.withOpacity(0.45)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: theme.textTheme.bodyMedium,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterSheet(context),
                      child: Icon(Icons.tune,
                          color: AppTheme.textPrimary.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Categories ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: _buildCategoryCard(
                          context,
                          Icons.directions_car,
                          'Car',
                          '${appState.filteredLocations.length} places',
                          appState.selectedCategory == 'car',
                          'car')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildCategoryCard(
                          context,
                          Icons.two_wheeler,
                          'Motorcycle',
                          '${appState.filteredLocations.length} places',
                          appState.selectedCategory == 'motorcycle',
                          'motorcycle')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildCategoryCard(
                          context,
                          Icons.local_shipping,
                          'Truck',
                          '${appState.filteredLocations.length} places',
                          appState.selectedCategory == 'truck',
                          'truck')),
                ],
              ),
              const SizedBox(height: 32),

              // ── Parking Location Cards ─────────────────────
              if (locations.isNotEmpty) ...[
                Text('Available Parking',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontSize: 18)),
                const SizedBox(height: 16),
                ...locations
                    .map((loc) => _buildLocationCard(context, loc))
                    .toList(),
                const SizedBox(height: 32),
              ],

              // ── Recent Places ──────────────────────────────
              Text('Recent Place',
                  style:
                      theme.textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: appState.filteredLocations.take(3)
                      .map((loc) => _buildRecentPlaceCard(context, loc))
                      .toList(),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  Widget _buildCategoryCard(BuildContext context, IconData icon, String title,
      String subtitle, bool isSelected, String category) {
    return GestureDetector(
      onTap: () => context.read<AppState>().setCategory(category),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 20),
        borderRadius: BorderRadius.circular(16),
        opacity: isSelected ? 0.65 : 0.45,
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(
                    color: AppTheme.brandGreen.withOpacity(0.8), width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 32,
                  color: isSelected
                      ? AppTheme.brandGreen
                      : AppTheme.textPrimary.withOpacity(0.6)),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: isSelected
                          ? AppTheme.brandGreen.withOpacity(0.8)
                          : AppTheme.textPrimary.withOpacity(0.4),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, ParkingLocation loc) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          context.read<AppState>().setLocation(loc);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChooseSpotScreen()));
        },
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              // Map icon placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.brandGreenLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_parking,
                    color: AppTheme.brandGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.name,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(loc.address,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '₱${loc.pricePerHour.toStringAsFixed(0)}/hr',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.brandGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.event_seat,
                            size: 14,
                            color:
                                AppTheme.textPrimary.withOpacity(0.45)),
                        const SizedBox(width: 4),
                        Text('${loc.availableSpots} spots',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary
                                    .withOpacity(0.55))),
                        const SizedBox(width: 12),
                        Icon(Icons.star,
                            size: 14, color: AppTheme.warningLight),
                        const SizedBox(width: 2),
                        Text(loc.rating.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary
                                    .withOpacity(0.7))),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppTheme.textPrimary.withOpacity(0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPlaceCard(
      BuildContext context, ParkingLocation loc) {
    return GestureDetector(
      onTap: () {
        context.read<AppState>().setLocation(loc);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ChooseSpotScreen()));
      },
      child: GlassContainer(
        width: MediaQuery.of(context).size.width * 0.75,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    loc.name,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: AppTheme.textPrimary.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${loc.address} | ₱${loc.pricePerHour.toStringAsFixed(0)}/hr',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontSize: 14, color: AppTheme.brandGreen),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.brandGreenLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(Icons.map_outlined,
                      color: AppTheme.brandGreen.withOpacity(0.3), size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Sheets & Dialogs ────────────────────────────────

  void _showCityPicker(BuildContext context) {
    final cities = ['Bacolod City', 'Iloilo City', 'Cebu City', 'Manila'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.textPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Select City',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 20)),
            const SizedBox(height: 16),
            ...cities.map((city) {
              final isSelected =
                  context.read<AppState>().selectedCity == city;
              return ListTile(
                onTap: () {
                  context.read<AppState>().setCity(city);
                  Navigator.pop(ctx);
                },
                title: Text(city,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.brandGreen
                          : AppTheme.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    )),
                trailing: isSelected
                    ? const Icon(Icons.check_circle,
                        color: AppTheme.brandGreen, size: 20)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final notifications = [
      'Your booking at Sudirman District Parking is confirmed',
      'Special offer: 20% off at Ayala Mall Parking today!',
      'Reminder: Your booking expires in 30 minutes',
    ];

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifications',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 20)),
              const SizedBox(height: 16),
              ...notifications.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle,
                            size: 8, color: AppTheme.brandGreen),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(n,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 14))),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GlassButton(
                  variant: GlassButtonVariant.ghost,
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.textPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Sort By',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 20)),
            const SizedBox(height: 16),
            _filterOption(ctx, 'Price (Low → High)', 'price'),
            _filterOption(ctx, 'Rating', 'rating'),
            _filterOption(ctx, 'Availability', 'availability'),
            const SizedBox(height: 8),
            GlassButton(
              isFullWidth: true,
              variant: GlassButtonVariant.ghost,
              onPressed: () {
                setState(() => _sortMode = 'none');
                Navigator.pop(ctx);
              },
              child: const Text('Clear Filter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(BuildContext ctx, String label, String mode) {
    final isActive = _sortMode == mode;
    return ListTile(
      onTap: () {
        setState(() => _sortMode = mode);
        Navigator.pop(ctx);
      },
      title: Text(label,
          style: TextStyle(
            color: isActive ? AppTheme.brandGreen : AppTheme.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          )),
      trailing: isActive
          ? const Icon(Icons.check_circle,
              color: AppTheme.brandGreen, size: 20)
          : null,
    );
  }
}
