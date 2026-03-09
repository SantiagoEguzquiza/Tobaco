import 'package:flutter/material.dart';
import 'package:tobaco/Theme/app_theme.dart';

/// Botón grande para agregar productos a la venta
class AgregarProductoButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;
  /// Si true, el botón ocupa todo el ancho del padre (sin padding horizontal extra).
  final bool fullWidth;

  const AgregarProductoButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = AppTheme.isCompactVentasButton(context);

    return Padding(
      padding: fullWidth ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: isCompact ? 48 : null,
        child: ElevatedButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: Icon(
            Icons.add_shopping_cart,
            size: AppTheme.ventasButtonIconSize(context),
          ),
          label: Text(
            'Agregar Productos',
            style: TextStyle(
              fontSize: AppTheme.ventasButtonFontSize(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade400,
            disabledForegroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: AppTheme.ventasButtonPadding(context),
            elevation: enabled ? 2 : 0,
          ),
        ),
      ),
    );
  }
}

