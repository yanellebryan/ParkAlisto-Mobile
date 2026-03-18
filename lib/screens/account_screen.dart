import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/dynamic_mesh_background.dart';
import 'onboarding_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DynamicMeshBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brandGreen,
                ),
                child: const Center(
                  child: Text(
                    'JD',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Juan dela Cruz',
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22)),
              const SizedBox(height: 4),
              Text('juan@parkalisto.com',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 32),

              // Menu tiles
              _buildTile(context, Icons.assignment_outlined, 'My Bookings',
                  onTap: () {
                context.read<AppState>().setBottomNavIndex(2);
              }),
              _buildTile(
                  context, Icons.notifications_outlined, 'Notifications'),
              _buildTile(
                  context, Icons.payment_outlined, 'Payment Methods'),
              _buildTile(
                  context, Icons.help_outline, 'Help & Support'),
              _buildTile(context, Icons.info_outline, 'About'),

              const SizedBox(height: 32),
              // Log Out
              GlassButton(
                isFullWidth: true,
                variant: GlassButtonVariant.destructive,
                onPressed: () => _showLogOutDialog(context),
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.brandGreenDeep, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontSize: 15),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppTheme.textPrimary.withOpacity(0.35), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogOutDialog(BuildContext context) {
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
            children: [
              Text(
                'Log Out?',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to log out?',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      variant: GlassButtonVariant.ghost,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      variant: GlassButtonVariant.destructive,
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OnboardingScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('Log Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
