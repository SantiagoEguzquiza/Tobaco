class ProductoSeleccionado {
  int id;
  String nombre;
  double precio;
  double cantidad;
  String categoria;
  int categoriaId; // Agregar el ID de la categoría

  ProductoSeleccionado({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.categoria,
    required this.categoriaId,
  });

  factory ProductoSeleccionado.fromJson(Map<String, dynamic> json) {
    return ProductoSeleccionado(
      id: json['id'],
      nombre: json['nombre'],
      precio: (json['precio'] as num).toDouble(),
      cantidad: (json['cantidad'] as num).toDouble(),
      categoria: json['categoria'] ?? '',
      categoriaId: json['categoriaId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria,
      'categoriaId': categoriaId,
    };
  }
}
