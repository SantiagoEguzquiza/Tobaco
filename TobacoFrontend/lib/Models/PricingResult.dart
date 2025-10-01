import 'PricingBreakdown.dart';

class PricingResult {
  double totalPrice;
  List<PricingBreakdown> breakdown;
  double? specialPrice;
  double? globalDiscount;
  double finalPrice;

  PricingResult({
    required this.totalPrice,
    required this.breakdown,
    this.specialPrice,
    this.globalDiscount,
    required this.finalPrice,
  });

  factory PricingResult.fromJson(Map<String, dynamic> json) {
    return PricingResult(
      totalPrice: (json['totalPrice'] as num).toDouble(),
      breakdown: (json['breakdown'] as List)
          .map((e) => PricingBreakdown.fromJson(e))
          .toList(),
      specialPrice: json['specialPrice'] != null 
          ? (json['specialPrice'] as num).toDouble() 
          : null,
      globalDiscount: json['globalDiscount'] != null 
          ? (json['globalDiscount'] as num).toDouble() 
          : null,
      finalPrice: (json['finalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPrice': totalPrice,
      'breakdown': breakdown.map((e) => e.toJson()).toList(),
      'specialPrice': specialPrice,
      'globalDiscount': globalDiscount,
      'finalPrice': finalPrice,
    };
  }

  String get breakdownDescription {
    return breakdown.map((b) => b.description).join(' + ');
  }

  bool get hasSpecialPrice => specialPrice != null;
  bool get hasGlobalDiscount => globalDiscount != null && globalDiscount! > 0;

  @override
  String toString() {
    return 'PricingResult(totalPrice: $totalPrice, finalPrice: $finalPrice, breakdown: $breakdown)';
  }
}
