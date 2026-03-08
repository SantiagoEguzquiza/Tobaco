import 'package:flutter/material.dart';
import 'package:tobaco/Theme/app_theme.dart';

/// Widget que muestra el estado vacío cuando no hay productos seleccionados
class EmptyStateVenta extends StatelessWidget {
  const EmptyStateVenta({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.grey.shade800
                  : AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 40,
              color: isDark 
                  ? Colors.grey.shade600
                  : AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No hay productos seleccionados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Presiona "Agregar Productos" para comenzar',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

