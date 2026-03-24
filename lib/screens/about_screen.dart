import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/dynamic_mesh_background.dart';
import 'help_support_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DynamicMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('About'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // App Overview
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/icons/Logo_For_WhiteBG_PA.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Parkalisto',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Parkalisto is a smart parking app that lets you find, reserve, and pay for parking spaces cashlessly.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                height: 1.5,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Version Info
                _buildSectionTitle(context, 'APP INFO'),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      _buildInfoRow('Version', '1.0.0'),
                      Divider(height: 24, color: Colors.black.withOpacity(0.05)),
                      _buildInfoRow('Build', '1.0'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Mission
                _buildSectionTitle(context, 'OUR MISSION'),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(16),
                  child: Text(
                    'Parkalisto aims to make parking faster, easier, and fully digital by removing the need for cash and manual processes.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textPrimary.withOpacity(0.7),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Links
                _buildSectionTitle(context, 'LEGAL'),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      _buildLinkTile(context, 'Terms & Conditions'),
                      _buildLinkTile(context, 'Privacy Policy'),
                      _buildLinkTile(context, 'Licenses', isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Support Shortcut
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Need help?',
                          style: TextStyle(color: AppTheme.textPrimary.withOpacity(0.5)),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Visit Help & Support',
                          style: TextStyle(
                            color: AppTheme.brandGreenDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Footer
                Text(
                  '© 2026 Parkalisto. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary.withOpacity(0.4),
              ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textPrimary.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkTile(BuildContext context, String title, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          trailing: Icon(
            Icons.chevron_right,
            size: 20,
            color: AppTheme.textPrimary.withOpacity(0.3),
          ),
          onTap: () {},
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.black.withOpacity(0.05),
          ),
      ],
    );
  }
}
