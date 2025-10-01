import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/ProductQuantityPrice.dart';
import 'package:tobaco/Models/PricingResult.dart';
import 'package:tobaco/Models/PricingBreakdown.dart';

class PricingService {
  /// Calculates the optimal pricing for a given quantity of a product
  static PricingResult calculateOptimalPricing(
    Producto product,
    int requestedQuantity, {
    double? specialPrice,
    double? globalDiscount,
  }) {
    // Use the product's base price as unit price
    var unitPrice = ProductQuantityPrice(
      productId: product.id ?? 0,
      quantity: 1,
      totalPrice: specialPrice ?? product.precio,
    );

    // Get all available quantity prices (only packs, quantity > 1)
    var availablePrices = product.quantityPrices
        .where((qp) => qp.quantity > 1)
        .toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));

    // Add the unit price first
    availablePrices.insert(0, unitPrice);

    // If no packs are configured, just use unit pricing
    if (availablePrices.length == 1) {
      return PricingResult(
        totalPrice: unitPrice.totalPrice * requestedQuantity,
        breakdown: [
          PricingBreakdown(
            quantity: 1,
            unitPrice: unitPrice.totalPrice,
            totalPrice: unitPrice.totalPrice * requestedQuantity,
            count: requestedQuantity,
          )
        ],
        specialPrice: specialPrice,
        finalPrice: unitPrice.totalPrice * requestedQuantity,
      );
    }

    // Calculate optimal combination using dynamic programming
    var result = _calculateOptimalCombination(availablePrices, requestedQuantity);
    result.specialPrice = specialPrice;

    // Apply global discount if provided
    if (globalDiscount != null && globalDiscount > 0) {
      result.globalDiscount = globalDiscount;
      result.finalPrice = result.totalPrice * (1 - globalDiscount / 100);
    } else {
      result.finalPrice = result.totalPrice;
    }

    return result;
  }

  static PricingResult _calculateOptimalCombination(
    List<ProductQuantityPrice> availablePrices,
    int requestedQuantity,
  ) {
    // Create a map for quick lookup
    final priceMap = {for (var qp in availablePrices) qp.quantity: qp.totalPrice};

    // Dynamic programming approach
    final dp = List<double>.filled(requestedQuantity + 1, double.infinity);
    final parent = List<int>.filled(requestedQuantity + 1, 0);
    final usedQuantities = <int, int>{};

    // Initialize DP array
    dp[0] = 0;

    // Fill DP array
    for (int i = 1; i <= requestedQuantity; i++) {
      for (var qp in availablePrices) {
        if (qp.quantity <= i) {
          final cost = dp[i - qp.quantity] + qp.totalPrice;
          if (cost < dp[i]) {
            dp[i] = cost;
            parent[i] = qp.quantity;
          }
        }
      }
    }

    // If we can't find a solution, fall back to unit prices
    if (dp[requestedQuantity] == double.infinity) {
      final unitPrice = availablePrices.firstWhere((qp) => qp.quantity == 1);
      return PricingResult(
        totalPrice: unitPrice.totalPrice * requestedQuantity,
        breakdown: [
          PricingBreakdown(
            quantity: 1,
            unitPrice: unitPrice.totalPrice,
            totalPrice: unitPrice.totalPrice * requestedQuantity,
            count: requestedQuantity,
          )
        ],
        finalPrice: unitPrice.totalPrice * requestedQuantity,
      );
    }

    // Reconstruct the solution
    final breakdown = <int, int>{};
    int remaining = requestedQuantity;
    while (remaining > 0) {
      final quantity = parent[remaining];
      breakdown[quantity] = (breakdown[quantity] ?? 0) + 1;
      remaining -= quantity;
    }

    // Create breakdown list
    final breakdownList = <PricingBreakdown>[];
    for (final entry in breakdown.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      final unitPrice = priceMap[entry.key]! / entry.key;
      breakdownList.add(PricingBreakdown(
        quantity: entry.key,
        unitPrice: unitPrice,
        totalPrice: priceMap[entry.key]! * entry.value,
        count: entry.value,
      ));
    }

    return PricingResult(
      totalPrice: dp[requestedQuantity],
      breakdown: breakdownList,
      finalPrice: dp[requestedQuantity],
    );
  }

  /// Validates that a product has valid quantity prices
  static bool validateQuantityPrices(List<ProductQuantityPrice> quantityPrices) {
    if (quantityPrices.isEmpty) return true; // Empty list is valid (no packs configured)

    // Check for duplicate quantities
    final quantities = quantityPrices.map((qp) => qp.quantity).toList();
    if (quantities.length != quantities.toSet().length) return false;

    // Check for valid quantities and prices
    for (var qp in quantityPrices) {
      if (qp.quantity < 2 || qp.totalPrice <= 0) return false; // Only allow packs (quantity >= 2)
    }

    return true;
  }
}
