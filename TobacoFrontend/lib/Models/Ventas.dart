import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Models/metodoPago.dart';

import 'package:tobaco/Models/ventasPago.dart';

class Ventas {
  int? id;
  int clienteId;
  Cliente cliente;
  List<VentasProductos> ventasProductos;
  double total;
  DateTime fecha;
  List<VentaPago>? pagos;
  MetodoPago? metodoPago;

  Ventas({
    this.id,
    required this.clienteId,
    required this.cliente,
    required this.ventasProductos,
    required this.total,
    required this.fecha,
    this.metodoPago,
    this.pagos,
  });

  factory Ventas.fromJson(Map<String, dynamic> json) => Ventas(
        id: json['id'],
        clienteId: json['clienteId'],
        cliente: Cliente.fromJson(json['cliente']),
        ventasProductos: (json['pedidoProductos'] as List)
            .map((e) => VentasProductos.fromJson(e))
            .toList(),
        total: (json['total'] as num).toDouble(),
        fecha: DateTime.parse(json['fecha']),
        metodoPago: json['metodoPago'] != null
            ? MetodoPago.values[json['metodoPago'] as int]
            : null,
        pagos: json['VentaPagos'] != null
            ? (json['VentaPagos'] as List)
                .map((e) => VentaPago.fromJson(e))
                .toList()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'clienteId': clienteId,
        'cliente': cliente.toJson(),
        'pedidoProductos': ventasProductos.map((e) => e.toJson()).toList(),
        'total': total,
        'fecha': fecha.toIso8601String(),
        'metodoPago': metodoPago?.index,
        'VentaPagos': pagos?.map((e) => e.toJson()).toList(),
      };    
}
