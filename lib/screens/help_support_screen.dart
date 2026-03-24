import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/dynamic_mesh_background.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

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
          title: const Text('Help & Support'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'QUICK HELP'),
                const SizedBox(height: 12),
                _buildQuickHelpList(context),
                const SizedBox(height: 32),
                _buildSectionTitle(context, 'FAQS'),
                const SizedBox(height: 12),
                _buildFAQList(context),
                const SizedBox(height: 32),
                _buildContactButton(context),
                const SizedBox(height: 32),
                _buildFooterLinks(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary.withOpacity(0.5),
          ),
    );
  }

  Widget _buildQuickHelpList(BuildContext context) {
    final categories = [
      {'title': 'Booking & Parking', 'icon': Icons.local_parking},
      {'title': 'Payments & Billing', 'icon': Icons.payment},
      {'title': 'Account Issues', 'icon': Icons.person_outline},
      {'title': 'App Problems', 'icon': Icons.phonelink_setup},
    ];

    return Column(
      children: categories
          .map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _showCategoryFAQs(context, cat['title'] as String),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData,
                            color: AppTheme.brandGreenDeep, size: 22),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            cat['title'] as String,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: AppTheme.textPrimary.withOpacity(0.35), size: 20),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildFAQList(BuildContext context) {
    final faqs = [
      {
        'q': 'How do I book a parking slot?',
        'a': 'Simply find a location on the map, select your preferred spot, choose the duration, and confirm your booking.'
      },
      {
        'q': 'How do I pay for parking?',
        'a': 'You can pay using GCash, Maya, or any registered Credit/Debit card in the Payment Methods section.'
      },
      {
        'q': 'What happens if I exceed my time?',
        'a': 'An overtime fee will be automatically calculated and charged to your default payment method.'
      },
      {
        'q': 'Why was I charged extra?',
        'a': 'Extra charges may occur due to overtime or peak hour pricing adjustments. Check your receipt for details.'
      },
    ];

    return Column(
      children: faqs
          .map((faq) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(16),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(
                        faq['q']!,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            faq['a']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary.withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildContactButton(BuildContext context) {
    return GlassButton(
      isFullWidth: true,
      onPressed: () => _showContactForm(context),
      child: const Text('Contact Support'),
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Column(
      children: [
        Center(
          child: TextButton(
            onPressed: () {},
            child: Text(
              'View Terms & Conditions',
              style: TextStyle(color: AppTheme.textPrimary.withOpacity(0.5)),
            ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Privacy Policy',
              style: TextStyle(color: AppTheme.textPrimary.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }

  void _showCategoryFAQs(BuildContext context, String category) {
    // For MVP, just show a message or different content
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $category FAQs...')),
    );
  }

  void _showContactForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Contact Support',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              _buildDropdownField(ctx),
              const SizedBox(height: 20),
              _buildTextInputField(ctx),
              const SizedBox(height: 20),
              _buildUploadPlaceholder(ctx),
              const SizedBox(height: 32),
              GlassButton(
                isFullWidth: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  _showSuccessDialog(context);
                },
                child: const Text('Submit Request'),
              ),
              const SizedBox(height: 12),
              GlassButton(
                isFullWidth: true,
                variant: GlassButtonVariant.ghost,
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Issue Type',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: 'Booking Issue',
              items: ['Booking Issue', 'Payment Issue', 'App Error', 'Other']
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell us what happened...',
            filled: true,
            fillColor: Colors.white.withOpacity(0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4), style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: AppTheme.brandGreen, size: 20),
          const SizedBox(width: 8),
          const Text('Upload Screenshot (Optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: AppTheme.brandGreen, size: 64),
              const SizedBox(height: 16),
              const Text('Request Sent',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Our support team will get back to you shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              GlassButton(
                isFullWidth: true,
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
