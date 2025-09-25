class ProductoSeleccionado {
  int id;
  String nombre;
  double precio;
  double cantidad;
  String categoria;

  ProductoSeleccionado({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.categoria,
  });

  factory ProductoSeleccionado.fromJson(Map<String, dynamic> json) {
    return ProductoSeleccionado(
      id: json['id'],
      nombre: json['nombre'],
      precio: (json['precio'] as num).toDouble(),
      cantidad: (json['cantidad'] as num).toDouble(),
      categoria: json['categoria'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria,
    };
  }
}
