import 'package:flutter/material.dart';
import 'package:tobaco/Theme/app_theme.dart';

/// Footer fijo con el botón para confirmar la venta
/// Incluye SafeArea y manejo de teclado para evitar superposiciones
class ConfirmarVentaFooter extends StatelessWidget {
  final VoidCallback onConfirmar;
  final bool enabled;
  final double total;
  final int cantidadProductos;
  final double? descuento;

  const ConfirmarVentaFooter({
    super.key,
    required this.onConfirmar,
    required this.enabled,
    required this.total,
    required this.cantidadProductos,
    this.descuento,
  });

  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(2);
  }

  Widget _formatearPrecioConDecimales(
    double precio, {
    Color? color,
    double? fontSize,
  }) {
    final partes = precio.toStringAsFixed(2).split('.');
    final parteEntera = partes[0];
    final parteDecimal = partes[1];

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '\$$parteEntera',
            style: TextStyle(
              fontSize: fontSize ?? 20.0,
              fontWeight: FontWeight.bold,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
          TextSpan(
            text: ',$parteDecimal',
            style: TextStyle(
              fontSize: (fontSize ?? 20.0) * 0.7,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    if (!enabled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.only(
          bottom: isKeyboardVisible ? keyboardHeight : 0,
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Información del total
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtotal y descuento (si hay)
                    if (descuento != null && descuento! > 0) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.receipt,
                            size: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Subtotal: \$${_formatearPrecio(total + descuento!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Descuento: -\$${_formatearPrecio(descuento!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.red.shade400 : Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _formatearPrecioConDecimales(
                      total,
                      color: AppTheme.primaryColor,
                      fontSize: 22.0,
                    ),
                    Text(
                      '$cantidadProductos producto${cantidadProductos != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Botón confirmar
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Confirmar Venta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

