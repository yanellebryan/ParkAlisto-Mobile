import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/glass_container.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'my_bookings_screen.dart';
import 'account_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({Key? key}) : super(key: key);

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
