import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/app_state.dart';
import '../models/payment_method.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/dynamic_mesh_background.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final methods = appState.paymentMethods;
    final defaultMethod = methods.cast<PaymentMethod?>().firstWhere(
          (m) => m?.isDefault ?? false,
          orElse: () => null,
        );
    final otherMethods = methods.where((m) => !m.isDefault).toList();

    return DynamicMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Payment Methods'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, size: 24),
              onPressed: () => _showAddPaymentOptions(context),
            ),
          ],
        ),
        body: SafeArea(
          child: methods.isEmpty
              ? _buildEmptyState(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (defaultMethod != null) ...[
                        _buildSectionTitle(context, 'DEFAULT PAYMENT'),
                        const SizedBox(height: 12),
                        _buildDefaultCard(context, defaultMethod),
                        const SizedBox(height: 32),
                      ],
                      if (otherMethods.isNotEmpty) ...[
                        _buildSectionTitle(context, 'SAVED METHODS'),
                        const SizedBox(height: 12),
                        ...otherMethods.map((m) => _buildMethodTile(context, m)),
                        const SizedBox(height: 32),
                      ],
                      _buildAddButton(context),
                      const SizedBox(height: 32),
                      _buildSectionTitle(context, 'SETTINGS'),
                      const SizedBox(height: 12),
                      _buildSettingsSection(context, appState),
                      const SizedBox(height: 32),
                      _buildHistoryRow(context),
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

  Widget _buildDefaultCard(BuildContext context, PaymentMethod method) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      opacity: 0.7,
      child: Row(
        children: [
          _buildMethodIcon(method.type, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DEFAULT',
                        style: TextStyle(
                          color: AppTheme.brandGreenDeep,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  method.maskedDetails,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppTheme.brandGreen, size: 24),
        ],
      ),
    );
  }

  Widget _buildMethodTile(BuildContext context, PaymentMethod method) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showActionSheet(context, method),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              _buildMethodIcon(method.type, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      method.maskedDetails,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary.withOpacity(0.5),
                      ),
                    ),
                  ],
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

  Widget _buildMethodIcon(PaymentMethodType type, {double size = 32}) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case PaymentMethodType.gcash:
        iconData = Icons.account_balance_wallet;
        iconColor = Colors.blue;
        break;
      case PaymentMethodType.maya:
        iconData = Icons.wallet;
        iconColor = Colors.green;
        break;
      case PaymentMethodType.card:
        iconData = Icons.credit_card;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.payments_outlined;
        iconColor = AppTheme.brandGreen;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(iconData, color: iconColor, size: size * 0.6),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GlassButton(
      isFullWidth: true,
      onPressed: () => _showAddPaymentOptions(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add, size: 20),
          SizedBox(width: 8),
          Text('Add Payment Method'),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, AppState appState) {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          _buildToggleTile(
            context,
            'Auto-select last used',
            appState.autoSelectLastUsed,
            (val) => appState.toggleAutoSelect(val),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.2)),
          _buildToggleTile(
            context,
            'Require confirmation',
            appState.requireConfirmation,
            (val) => appState.toggleRequireConfirmation(val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(
      BuildContext context, String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.brandGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to history
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            const Text(
              'Payment History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: AppTheme.textPrimary.withOpacity(0.35), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: AppTheme.brandGreen.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No payment methods yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a payment method to start booking parking spots easily.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            _buildAddButton(context),
          ],
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context, PaymentMethod method) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              method.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(method.maskedDetails),
            const SizedBox(height: 32),
            GlassButton(
              isFullWidth: true,
              onPressed: () {
                context.read<AppState>().setDefaultPaymentMethod(method.id);
                Navigator.pop(ctx);
              },
              child: const Text('Set as Default'),
            ),
            const SizedBox(height: 12),
            GlassButton(
              isFullWidth: true,
              variant: GlassButtonVariant.destructive,
              onPressed: () {
                context.read<AppState>().removePaymentMethod(method.id);
                Navigator.pop(ctx);
              },
              child: const Text('Remove Payment Method'),
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
    );
  }

  void _showAddPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add Payment Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 32),
            _buildAddOptionTile(context, 'GCash', Icons.account_balance_wallet, Colors.blue, () {
              Navigator.pop(ctx);
              _showAddPaymentForm(context, PaymentMethodType.gcash);
            }),
            _buildAddOptionTile(context, 'Maya', Icons.wallet, Colors.green, () {
              Navigator.pop(ctx);
              _showAddPaymentForm(context, PaymentMethodType.maya);
            }),
            _buildAddOptionTile(context, 'Credit/Debit Card', Icons.credit_card, Colors.orange, () {
              Navigator.pop(ctx);
              _showAddPaymentForm(context, PaymentMethodType.card);
            }),
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
    );
  }

  Widget _buildAddOptionTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Icon(Icons.add_circle_outline, color: AppTheme.brandGreen, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPaymentForm(BuildContext context, PaymentMethodType type) {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final expiryController = TextEditingController();

    final title = type == PaymentMethodType.card ? 'Add Card' : 'Add ${type.name.toUpperCase()}';
    final numberLabel = type == PaymentMethodType.card ? 'Card Number' : 'Mobile Number';

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
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              _buildTextField(nameController, 'Name (e.g. My Account)', Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(numberController, numberLabel, Icons.phone_android),
              if (type == PaymentMethodType.card) ...[
                const SizedBox(height: 16),
                _buildTextField(expiryController, 'Expiry (MM/YY)', Icons.calendar_today_outlined),
              ],
              const SizedBox(height: 32),
              GlassButton(
                isFullWidth: true,
                onPressed: () {
                  final number = numberController.text.trim();
                  if (number.length < 4) return;
                  
                  final lastFour = number.substring(number.length - 4);
                  final name = nameController.text.trim();

                  context.read<AppState>().addPaymentMethod(PaymentMethod(
                        id: DateTime.now().toString(),
                        type: type,
                        name: name.isEmpty ? type.name.toUpperCase() : name,
                        lastFour: lastFour,
                        expiry: type == PaymentMethodType.card ? expiryController.text : null,
                      ));
                  Navigator.pop(ctx);
                },
                child: const Text('Save Payment Method'),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white70, size: 20),
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
