import 'package:flutter/material.dart';
import 'package:tobaco/Theme/app_theme.dart';

/// Botón grande para agregar productos a la venta
class AgregarProductoButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const AgregarProductoButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: const Icon(Icons.add_shopping_cart, size: 24),
          label: const Text(
            'Agregar Productos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.addGreenColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade400,
            disabledForegroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: enabled ? 3 : 0,
          ),
        ),
      ),
    );
  }
}

