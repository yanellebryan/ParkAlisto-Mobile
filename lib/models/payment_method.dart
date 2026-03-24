enum PaymentMethodType { gcash, maya, card }

class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String name;
  final String lastFour;
  final bool isDefault;
  final String? expiry; // Only for cards

  PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    required this.lastFour,
    this.isDefault = false,
    this.expiry,
  });

  String get maskedDetails {
    switch (type) {
      case PaymentMethodType.gcash:
      case PaymentMethodType.maya:
        return '•••• $lastFour';
      case PaymentMethodType.card:
        return 'Visa •••• $lastFour';
    }
  }
}
