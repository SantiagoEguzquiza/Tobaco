import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/VentasProductos.dart';


enum MetodoPago {
  efectivo,
  transferencia,
  tarjeta,
  cuentaCorriente,
}

class Ventas {
  int? id;
  int clienteId;
  Cliente cliente;
  List<VentasProductos> ventasProductos;
  double total;
  DateTime fecha;
  MetodoPago? metodoPago;

  Ventas({
    this.id,
    required this.clienteId,
    required this.cliente,
    required this.ventasProductos,
    required this.total,
    required this.fecha,
    this.metodoPago,
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
       metodoPago: MetodoPago.values[json['metodoPago'] as int],
      );

  Map<String, dynamic> toJson() => {
        'clienteId': clienteId,
        'cliente': cliente.toJson(),
        'pedidoProductos':
            ventasProductos.map((e) => e.toJson()).toList(),
        'total': total,
        'fecha': fecha.toIso8601String(),
        'metodoPago': metodoPago?.index,
      };
}

