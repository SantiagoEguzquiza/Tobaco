class VentasProductos {
  int productoId;
  String nombre;
  double precio;
  double cantidad;
  String categoria;
  int categoriaId; // Agregar el ID de la categoría

  VentasProductos({
    required this.productoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.categoria,
    required this.categoriaId,
  });

  factory VentasProductos.fromJson(Map<String, dynamic> json) {
    // El backend envía la estructura del modelo PedidoProducto
    // que tiene ProductoId, Producto (objeto completo), y Cantidad
    final producto = json['producto'] as Map<String, dynamic>? ?? {};
    
    return VentasProductos(
      productoId: json['productoId'] ?? producto['id'] ?? 0,
      nombre: producto['nombre'] ?? '',
      precio: (producto['precio'] as num?)?.toDouble() ?? 0.0,
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      categoria: producto['categoriaNombre'] ?? '',
      categoriaId: producto['categoriaId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'productoId': productoId,
        'producto': {
          'id': productoId,
          'nombre': nombre,
          'precio': precio,
          'cantidad': 0, // Este campo es para el stock del producto, no la cantidad vendida
          'categoriaId': categoriaId, // Usar el ID de la categoría
          'categoriaNombre': categoria,
          'half': false,
        },
        'cantidad': cantidad,
      };
}