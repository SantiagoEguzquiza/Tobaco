// ignore_for_file: file_names

enum Origen {
  nacional,
  importado,
  analgesico,
  otros 
}

class Producto {
  int id;
  String nombre;
  int cantidad;
  int precio;
  Origen origen;

  Producto({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.precio,
    required this.origen,
  });
}