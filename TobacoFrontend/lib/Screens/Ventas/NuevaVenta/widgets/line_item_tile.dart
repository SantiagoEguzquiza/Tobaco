import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Theme/app_theme.dart';

/// Widget que representa un item de producto en la lista de la venta
/// Muestra: nombre, precio, cantidad, subtotal y botón eliminar
/// Tap en el producto navega a SeleccionarProductosScreen para editar
class LineItemTile extends StatelessWidget {
  final ProductoSeleccionado producto;
  final VoidCallback onEliminar;
  final VoidCallback onTap;
  final double? precioEspecial;
  final double? descuentoGlobal;

  const LineItemTile({
    super.key,
    required this.producto,
    required this.onEliminar,
    required this.onTap,
    this.precioEspecial,
    this.descuentoGlobal,
  });

  double _calcularPrecioFinal() {
    double precio = precioEspecial ?? producto.precio;

    // Aplicar descuento global si existe
    if (descuentoGlobal != null && descuentoGlobal! > 0) {
      precio = precio - (precio * (descuentoGlobal! / 100));
    }

    return precio;
  }

  bool _tienePrecioEspecial() {
    return precioEspecial != null && precioEspecial != producto.precio;
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
    final precioFinal = _calcularPrecioFinal();
    final subtotal = precioFinal * producto.cantidad;

    return Slidable(
      key: ValueKey(producto.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onEliminar(),
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Eliminar',
            borderRadius: BorderRadius.circular(8),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? const Color(0xFF404040)
                : AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Nombre del producto
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _formatearPrecioConDecimales(
                            precioFinal,
                            fontSize: 14.0,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'c/u',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cantidad
                Container(
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      producto.cantidad % 1 == 0
                          ? producto.cantidad.toInt().toString()
                          : producto.cantidad.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Subtotal
                Expanded(
                  flex: 3,
                  child: _formatearPrecioConDecimales(
                    subtotal,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
