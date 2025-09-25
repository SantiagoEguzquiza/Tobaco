class VentasProductos {
  int productoId;
  String nombre;
  double precio;
  double cantidad;
  String categoria;

  VentasProductos({
    required this.productoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.categoria,
  });

  factory VentasProductos.fromJson(Map<String, dynamic> json) => VentasProductos(
        productoId: json['productoId'],
        nombre: json['nombre'] ?? '',
        precio: (json['precio'] as num).toDouble(),
        cantidad: (json['cantidad'] as num).toDouble(),
        categoria: json['categoria'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'productoId': productoId,
        'nombre': nombre,
        'precio': precio,
        'cantidad': cantidad,
        'categoria': categoria,
      };
}