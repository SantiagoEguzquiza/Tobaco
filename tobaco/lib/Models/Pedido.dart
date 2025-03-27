// ignore_for_file: file_names

import "package:tobaco/Models/Cliente.dart";
import "package:tobaco/Models/Producto.dart";



class Pedido {
  int? id;
  Cliente cliente;
  List<Producto> productos;
  int total;
  DateTime fecha;

  Pedido({
    this.id,
    required this.cliente,
    required this.productos,
    required this.total,
    required this.fecha,
  });
}



