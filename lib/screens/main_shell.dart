import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/glass_container.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'my_bookings_screen.dart';
import 'account_screen.dart';
import 'exit_success_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    // Start listening to AppState for global events like exit completion
    context.read<AppState>().addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    // Clean up listener
    // Note: In some provider setups, the notifier might be disposed before the listener
    // but usually this is safe if the notifier is provided at a higher level.
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    
    final appState = context.read<AppState>();
    
    // Check if there's a booking that just finished
    if (appState.lastCompletedBooking != null) {
      final booking = appState.lastCompletedBooking!;
      
      // Navigate to success screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExitSuccessScreen(booking: booking),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: IndexedStack(
        index: appState.bottomNavIndex,
        children: const [
          HomeScreen(),
          MapScreen(),
          MyBookingsScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: GlassContainer(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        padding: const EdgeInsets.symmetric(vertical: 8),
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          currentIndex: appState.bottomNavIndex,
          onTap: (index) {
            if (index == 2) {
              appState.loadBookings();
            }
            appState.setBottomNavIndex(index);
          },
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.brandGreen,
          unselectedItemColor: AppTheme.textPrimary.withOpacity(0.35),
          showUnselectedLabels: true,
          selectedLabelStyle: theme.textTheme.labelLarge
              ?.copyWith(fontSize: 12, color: AppTheme.brandGreen),
          unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              color: AppTheme.textPrimary.withOpacity(0.35)),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined), label: 'Maps'),
            BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined), label: 'My Booking'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
      ),
    );
  }
}
