import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/User.dart';

class ProductoAFavor {
  int? id;
  int clienteId;
  Cliente? cliente;
  int productoId;
  Producto? producto;
  double cantidad;
  DateTime fechaRegistro;
  String motivo;
  String? nota;
  int ventaId;
  int ventaProductoId;
  int? usuarioRegistroId;
  User? usuarioRegistro;
  bool entregado;
  DateTime? fechaEntrega;
  int? usuarioEntregaId;
  User? usuarioEntrega;

  ProductoAFavor({
    this.id,
    required this.clienteId,
    this.cliente,
    required this.productoId,
    this.producto,
    required this.cantidad,
    required this.fechaRegistro,
    required this.motivo,
    this.nota,
    required this.ventaId,
    required this.ventaProductoId,
    this.usuarioRegistroId,
    this.usuarioRegistro,
    this.entregado = false,
    this.fechaEntrega,
    this.usuarioEntregaId,
    this.usuarioEntrega,
  });

  factory ProductoAFavor.fromJson(Map<String, dynamic> json) {
    return ProductoAFavor(
      id: json['id'],
      clienteId: json['clienteId'] ?? 0,
      cliente: json['cliente'] != null ? Cliente.fromJson(json['cliente']) : null,
      productoId: json['productoId'] ?? 0,
      producto: json['producto'] != null ? Producto.fromJson(json['producto']) : null,
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      fechaRegistro: json['fechaRegistro'] != null 
          ? DateTime.parse(json['fechaRegistro']) 
          : DateTime.now(),
      motivo: json['motivo'] ?? '',
      nota: json['nota'],
      ventaId: json['ventaId'] ?? 0,
      ventaProductoId: json['ventaProductoId'] ?? 0,
      usuarioRegistroId: json['usuarioRegistroId'],
      usuarioRegistro: json['usuarioRegistro'] != null 
          ? User.fromJson(json['usuarioRegistro']) 
          : null,
      entregado: json['entregado'] ?? false,
      fechaEntrega: json['fechaEntrega'] != null 
          ? DateTime.parse(json['fechaEntrega']) 
          : null,
      usuarioEntregaId: json['usuarioEntregaId'],
      usuarioEntrega: json['usuarioEntrega'] != null 
          ? User.fromJson(json['usuarioEntrega']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'clienteId': clienteId,
        if (cliente != null) 'cliente': cliente!.toJson(),
        'productoId': productoId,
        if (producto != null) 'producto': producto!.toJson(),
        'cantidad': cantidad,
        'fechaRegistro': fechaRegistro.toIso8601String(),
        'motivo': motivo,
        if (nota != null) 'nota': nota,
        'ventaId': ventaId,
        'ventaProductoId': ventaProductoId,
        if (usuarioRegistroId != null) 'usuarioRegistroId': usuarioRegistroId,
        if (usuarioRegistro != null) 'usuarioRegistro': usuarioRegistro!.toJson(),
        'entregado': entregado,
        if (fechaEntrega != null) 'fechaEntrega': fechaEntrega!.toIso8601String(),
        if (usuarioEntregaId != null) 'usuarioEntregaId': usuarioEntregaId,
        if (usuarioEntrega != null) 'usuarioEntrega': usuarioEntrega!.toJson(),
      };
}

