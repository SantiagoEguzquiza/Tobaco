class ProductoSeleccionado {
  int id;
  String nombre;
  String? marca;
  double precio;
  double cantidad;
  String categoria;
  int categoriaId; // Agregar el ID de la categoría
  double descuento;
  DateTime? fechaExpiracionDescuento;
  bool descuentoIndefinido;

  ProductoSeleccionado({
    required this.id,
    required this.nombre,
    this.marca,
    required this.precio,
    required this.cantidad,
    required this.categoria,
    required this.categoriaId,
    this.descuento = 0.0,
    this.fechaExpiracionDescuento,
    this.descuentoIndefinido = false,
  });

  factory ProductoSeleccionado.fromJson(Map<String, dynamic> json) {
    DateTime? parseFecha;
    if (json['fechaExpiracionDescuento'] != null) {
      try {
        parseFecha = DateTime.parse(json['fechaExpiracionDescuento'] as String);
      } catch (_) {
        parseFecha = null;
      }
    }

    return ProductoSeleccionado(
      id: json['id'],
      nombre: json['nombre'],
      marca: json['marca'],
      precio: (json['precio'] as num).toDouble(),
      cantidad: (json['cantidad'] as num).toDouble(),
      categoria: json['categoria'] ?? '',
      categoriaId: json['categoriaId'] ?? 0,
      descuento: json['descuento'] != null
          ? double.tryParse(json['descuento'].toString()) ?? 0.0
          : 0.0,
      fechaExpiracionDescuento: parseFecha,
      descuentoIndefinido: json['descuentoIndefinido'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'marca': marca,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria,
      'categoriaId': categoriaId,
      'descuento': descuento,
      'fechaExpiracionDescuento': fechaExpiracionDescuento?.toIso8601String(),
      'descuentoIndefinido': descuentoIndefinido,
    };
  }
}
