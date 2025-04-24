import 'package:tobaco/Models/Producto.dart';

class VentasProductos {
  int productoId;
  Producto producto;
  double cantidad;

  VentasProductos({
    required this.productoId,
    required this.producto,
    required this.cantidad,
  });

  factory VentasProductos.fromJson(Map<String, dynamic> json) => VentasProductos(
        productoId: json['productoId'],
        producto: Producto.fromJson(json['producto']),
        cantidad: json['cantidad'].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'productoId': productoId,
        'producto': producto.toJson(),
        'cantidad': cantidad,
      };
}