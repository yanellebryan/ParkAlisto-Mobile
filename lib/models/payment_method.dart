enum PaymentMethodType { gcash, maya, card, cash, qrph, overTheCounter }

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

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      type: PaymentMethodType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PaymentMethodType.card,
      ),
      name: json['name'] as String,
      lastFour: json['last_four'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      expiry: json['expiry'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'name': name,
      'last_four': lastFour,
      'is_default': isDefault,
      'expiry': expiry,
    };
  }

  PaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? name,
    String? lastFour,
    bool? isDefault,
    String? expiry,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      lastFour: lastFour ?? this.lastFour,
      isDefault: isDefault ?? this.isDefault,
      expiry: expiry ?? this.expiry,
    );
  }

  String get maskedDetails {
    switch (type) {
      case PaymentMethodType.gcash:
      case PaymentMethodType.maya:
        return '•••• $lastFour';
      case PaymentMethodType.card:
        return 'Visa •••• $lastFour';
      case PaymentMethodType.cash:
        return 'Pay upon arrival';
      case PaymentMethodType.qrph:
        return 'Scan to pay';
      case PaymentMethodType.overTheCounter:
        return 'Payment at kiosk';
    }
  }
}
