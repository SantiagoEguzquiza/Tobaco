import 'package:flutter/material.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'line_item_tile.dart';

/// Widget que muestra la lista de productos agregados a la venta
class LineItemsList extends StatelessWidget {
  final List<ProductoSeleccionado> productos;
  final Function(int index) onEliminar;
  final Function(int index) onTap;
  final Map<int, double> preciosEspeciales;
  final double? descuentoGlobal;

  const LineItemsList({
    super.key,
    required this.productos,
    required this.onEliminar,
    required this.onTap,
    required this.preciosEspeciales,
    this.descuentoGlobal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: productos.asMap().entries.map((entry) {
          final index = entry.key;
          final producto = entry.value;
          
          return LineItemTile(
            key: ValueKey(producto.id),
            producto: producto,
            onEliminar: () => onEliminar(index),
            onTap: () => onTap(index),
            precioEspecial: preciosEspeciales[producto.id],
            descuentoGlobal: descuentoGlobal,
          );
        }).toList(),
      ),
    );
  }
}

