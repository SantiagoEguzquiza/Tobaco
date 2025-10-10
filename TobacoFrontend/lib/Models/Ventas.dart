import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Models/User.dart';
import 'package:tobaco/Models/ventasPago.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';

class Ventas {
  int? id;
  int clienteId;
  Cliente cliente;
  List<VentasProductos> ventasProductos;
  double total;
  DateTime fecha;
  List<VentaPago>? pagos;
  MetodoPago? metodoPago;
  int? usuarioId;
  User? usuario;
  EstadoEntrega estadoEntrega;

  Ventas({
    this.id,
    required this.clienteId,
    required this.cliente,
    required this.ventasProductos,
    required this.total,
    required this.fecha,
    this.metodoPago,
    this.pagos,
    this.usuarioId,
    this.usuario,
    this.estadoEntrega = EstadoEntrega.noEntregada,
  });

  factory Ventas.fromJson(Map<String, dynamic> json) => Ventas(
        id: json['id'],
        clienteId: json['clienteId'] ?? 0,
        cliente: Cliente.fromJson(json['cliente']),
        ventasProductos: (json['ventaProductos'] as List?)
            ?.map((e) => VentasProductos.fromJson(e))
            .toList() ?? [],
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        fecha: DateTime.parse(json['fecha']),
        metodoPago: json['metodoPago'] != null
            ? MetodoPago.values[json['metodoPago'] as int]
            : null,
        pagos: json['ventaPagos'] != null
            ? (json['ventaPagos'] as List)
                .map((e) => VentaPago.fromJson(e))
                .toList()
            : null,
        usuarioId: json['usuarioId'],
        usuario: json['usuario'] != null ? User.fromJson(json['usuario']) : null,
        estadoEntrega: json['estadoEntrega'] != null
            ? EstadoEntregaExtension.fromJson(json['estadoEntrega'] as int)
            : EstadoEntrega.noEntregada,
      );

  Map<String, dynamic> toJson() => {
        'clienteId': clienteId,
        'cliente': cliente.toJson(),
        'ventaProductos': ventasProductos.map((e) => e.toJson()).toList(),
        'total': total,
        'fecha': fecha.toIso8601String(),
        'metodoPago': metodoPago?.index,
        'ventaPagos': pagos?.map((e) => e.toJson()).toList() ?? [],
        'usuarioId': usuarioId,
        'usuario': usuario?.toJson(),
        'estadoEntrega': estadoEntrega.toJson(),
      };    
}
