import 'package:tobaco/Models/Proveedor.dart';

class CompraItem {
  final int id;
  final int productoId;
  final String? productoNombre;
  final double cantidad;
  final double costoUnitario;
  final double subtotal;

  CompraItem({
    required this.id,
    required this.productoId,
    this.productoNombre,
    required this.cantidad,
    required this.costoUnitario,
    required this.subtotal,
  });

  factory CompraItem.fromJson(Map<String, dynamic> json) {
    double v(dynamic a) => (a is int ? a.toDouble() : (a as num).toDouble());
    return CompraItem(
      id: (json['id'] ?? json['Id']) as int,
      productoId: (json['productoId'] ?? json['ProductoId']) as int,
      productoNombre: (json['productoNombre'] ?? json['ProductoNombre']) as String?,
      cantidad: v(json['cantidad'] ?? json['Cantidad']),
      costoUnitario: v(json['costoUnitario'] ?? json['CostoUnitario']),
      subtotal: v(json['subtotal'] ?? json['Subtotal']),
    );
  }
}

class Compra {
  final int id;
  final int proveedorId;
  final Proveedor? proveedor;
  final DateTime fecha;
  final String? numeroComprobante;
  final String? observaciones;
  final double total;
  final DateTime createdAt;
  final List<CompraItem> items;

  Compra({
    required this.id,
    required this.proveedorId,
    this.proveedor,
    required this.fecha,
    this.numeroComprobante,
    this.observaciones,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  factory Compra.fromJson(Map<String, dynamic> json) {
    List<CompraItem> itemsList = [];
    final itemsRaw = json['items'] ?? json['Items'];
    if (itemsRaw != null) {
      for (var e in itemsRaw as List) {
        itemsList.add(CompraItem.fromJson(e as Map<String, dynamic>));
      }
    }
    final prov = json['proveedor'] ?? json['Proveedor'];
    return Compra(
      id: (json['id'] ?? json['Id']) as int,
      proveedorId: (json['proveedorId'] ?? json['ProveedorId']) as int,
      proveedor: prov != null ? Proveedor.fromJson(prov as Map<String, dynamic>) : null,
      fecha: DateTime.parse((json['fecha'] ?? json['Fecha']).toString()),
      numeroComprobante: (json['numeroComprobante'] ?? json['NumeroComprobante']) as String?,
      observaciones: (json['observaciones'] ?? json['Observaciones']) as String?,
      total: (json['total'] ?? json['Total']) is int ? ((json['total'] ?? json['Total']) as int).toDouble() : ((json['total'] ?? json['Total']) as num).toDouble(),
      createdAt: DateTime.parse((json['createdAt'] ?? json['CreatedAt']).toString()),
      items: itemsList,
    );
  }
}
