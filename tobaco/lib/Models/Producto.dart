// ignore_for_file: file_names

enum Categoria {
  nacional,
  importado,
  analgesico,
  otro,
}

class Producto {
  int id;
  String nombre;
  int? cantidad;
  int precio;
  Categoria categoria;

  Producto({
    required this.id,
    required this.nombre,
    this.cantidad,
    required this.precio,
    required this.categoria,
  });
}