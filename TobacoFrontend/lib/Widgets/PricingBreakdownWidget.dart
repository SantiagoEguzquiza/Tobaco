import 'package:flutter/material.dart';
import 'package:tobaco/Models/PricingResult.dart';

class PricingBreakdownWidget extends StatelessWidget {
  final PricingResult pricingResult;
  final String productName;
  final int quantity;

  const PricingBreakdownWidget({
    super.key,
    required this.pricingResult,
    required this.productName,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1A1A1A)
          : Colors.blue.shade50,
        border: Border.all(
          color: isDark 
            ? const Color(0xFF404040)
            : Colors.blue.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Desglose de Precio - $productName',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                'Cantidad: $quantity',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pricingResult.breakdown.map((breakdown) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      breakdown.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    Text(
                      '\$${breakdown.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                '\$${pricingResult.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          if (pricingResult.hasSpecialPrice) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Precio especial aplicado:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  '\$${pricingResult.specialPrice!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (pricingResult.hasGlobalDiscount) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Descuento global (${pricingResult.globalDiscount!.toStringAsFixed(1)}%):',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  '-\$${(pricingResult.totalPrice - pricingResult.finalPrice).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
              Text(
                '\$${pricingResult.finalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
