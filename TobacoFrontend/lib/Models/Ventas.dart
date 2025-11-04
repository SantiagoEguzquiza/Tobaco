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
  int? usuarioIdCreador;
  User? usuarioCreador;
  int? usuarioIdAsignado;
  User? usuarioAsignado;
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
    this.usuarioIdCreador,
    this.usuarioCreador,
    this.usuarioIdAsignado,
    this.usuarioAsignado,
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
        usuarioIdCreador: json['usuarioIdCreador'],
        usuarioCreador: json['usuarioCreador'] != null ? User.fromJson(json['usuarioCreador']) : null,
        usuarioIdAsignado: json['usuarioIdAsignado'],
        usuarioAsignado: json['usuarioAsignado'] != null ? User.fromJson(json['usuarioAsignado']) : null,
        estadoEntrega: json['estadoEntrega'] != null
            ? EstadoEntregaExtension.fromJson(json['estadoEntrega'])
            : EstadoEntrega.noEntregada,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'clienteId': clienteId,
        'cliente': cliente.toJson(),
        'ventaProductos': ventasProductos.map((e) => e.toJson()).toList(),
        'total': total,
        'fecha': fecha.toIso8601String(),
        'metodoPago': metodoPago?.index,
        'ventaPagos': pagos?.map((e) => e.toJson()).toList() ?? [],
        'usuarioIdCreador': usuarioIdCreador,
        'usuarioCreador': usuarioCreador?.toJson(),
        'usuarioIdAsignado': usuarioIdAsignado,
        'usuarioAsignado': usuarioAsignado?.toJson(),
        'estadoEntrega': estadoEntrega.toJson(),
      };    
}
