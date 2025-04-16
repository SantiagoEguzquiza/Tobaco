// ignore_for_file: file_names

enum Categoria {
  nacional,
  importado,
  analgesico,
  otro,
}

class Producto {
  int? id;
  String nombre;
  double? cantidad;
  double precio;
  Categoria categoria;

  Producto({
    required this.id,
    required this.nombre,
    this.cantidad,
    required this.precio,
    required this.categoria,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      cantidad: json['cantidad'] != null
          ? double.tryParse(json['cantidad'].toString())
          : null,
      precio: json['precio'] as double,
      categoria: Categoria.values.firstWhere(
          (e) => e.toString().split('.').last == json['categoria']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'cantidad': cantidad?.toString(),
      'precio': precio,
      'categoria': categoria.index,
    };
  }
}