// ignore_for_file: file_names

enum Categoria {
  nacional,
  importado,
  analgesico,
  otro,
}

extension CategoriaExtension on Categoria {
  String get nombre {
    switch (this) {
      case Categoria.nacional:
        return "Nacional";
      case Categoria.importado:
        return "Importado";
      case Categoria.analgesico:
        return "Analgésico";
      case Categoria.otro:
        return "Otro";
    }
  }
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
    precio: json['precio'] != null
        ? double.tryParse(json['precio'].toString()) ?? 0.0
        : 0.0,
    categoria: Categoria.values[json['categoria'] as int],
  );
}


  Map<String, dynamic> toJson() {
    return {      
      'nombre': nombre,
      'cantidad': cantidad?.toString(),
      'precio': precio,
      'categoria': categoria.index,
    };
  }
}