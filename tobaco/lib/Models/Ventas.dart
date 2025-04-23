import 'package:tobaco/Models/itemVenta.dart';

class Ventas {
  int? id;
  int clienteId;
  int total;
  DateTime fecha;
  List<ItemVenta> ventasProductos;

  Ventas({
    this.id,
    required this.clienteId,
    required this.total,
    required this.fecha,
    required this.ventasProductos,
  });

  factory Ventas.fromJson(Map<String, dynamic> json) {
    return Ventas(
      id: json['id'],
      clienteId: json['clienteId'],
      total: json['total'],
      fecha: DateTime.parse(json['fecha']),
      ventasProductos: (json['pedidoProductos'] as List)
          .map((item) => ItemVenta.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clienteId': clienteId,
      'total': total,
      'fecha': fecha.toIso8601String(),
      'pedidoProductos': ventasProductos.map((e) => e.toJson()).toList(),
    };
  }
}
