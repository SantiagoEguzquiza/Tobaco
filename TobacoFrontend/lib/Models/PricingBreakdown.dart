class PricingBreakdown {
  int quantity;
  double unitPrice;
  double totalPrice;
  int count;

  PricingBreakdown({
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.count,
  });

  factory PricingBreakdown.fromJson(Map<String, dynamic> json) {
    return PricingBreakdown(
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'count': count,
    };
  }

  String get description {
    if (quantity == 1) {
      return '$count × Unidad';
    } else {
      return '$count × Pack x$quantity';
    }
  }

  @override
  String toString() {
    return 'PricingBreakdown(quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice, count: $count)';
  }
}
