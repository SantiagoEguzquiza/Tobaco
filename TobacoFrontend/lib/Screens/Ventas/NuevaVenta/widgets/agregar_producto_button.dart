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
          icon: const Icon(Icons.add_shopping_cart, size: 20),
          label: const Text(
            'Agregar Productos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade400,
            disabledForegroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: enabled ? 2 : 0,
          ),
        ),
      ),
    );
  }
}

