import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/VentasProductos.dart';


class Ventas {
  int? id;
  int clienteId;
  Cliente cliente;
  List<VentasProductos> ventasProductos;
  double total;
  DateTime fecha;

  Ventas({
    this.id,
    required this.clienteId,
    required this.cliente,
    required this.ventasProductos,
    required this.total,
    required this.fecha,
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
      );

  Map<String, dynamic> toJson() => {
        'clienteId': clienteId,
        'cliente': cliente.toJson(),
        'pedidoProductos':
            ventasProductos.map((e) => e.toJson()).toList(),
        'total': total,
        'fecha': fecha.toIso8601String(),
      };
}

