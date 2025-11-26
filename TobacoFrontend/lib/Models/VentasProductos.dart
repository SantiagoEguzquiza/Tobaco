class VentasProductos {
  int productoId;
  String nombre;
  String? marca;
  double precio;
  double cantidad;
  String categoria;
  int categoriaId; // Agregar el ID de la categoría
  double precioFinalCalculado; // Precio final después de todos los descuentos
  bool entregado; // Indica si este item fue entregado
  String? motivo; // Motivo cuando no se entrega
  String? nota; // Nota opcional sobre la entrega
  DateTime? fechaChequeo; // Fecha de chequeo
  int? usuarioChequeoId; // ID del usuario que hizo el chequeo
  // Campos de descuento del producto (en el momento de la venta)
  double descuento; // Porcentaje de descuento del producto
  DateTime? fechaExpiracionDescuento; // Fecha de expiración del descuento
  bool descuentoIndefinido; // Si el descuento es indefinido

  VentasProductos({
    required this.productoId,
    required this.nombre,
    this.marca,
    required this.precio,
    required this.cantidad,
    required this.categoria,
    required this.categoriaId,
    required this.precioFinalCalculado,
    this.entregado = false,
    this.motivo,
    this.nota,
    this.fechaChequeo,
    this.usuarioChequeoId,
    this.descuento = 0.0,
    this.fechaExpiracionDescuento,
    this.descuentoIndefinido = false,
  });

  factory VentasProductos.fromJson(Map<String, dynamic> json) {
    // El backend envía la estructura del modelo PedidoProducto
    // que tiene ProductoId, Producto (objeto completo), y Cantidad
    final producto = json['producto'] as Map<String, dynamic>? ?? {};
    
    // Parsear fecha de expiración de descuento si existe
    DateTime? parseFechaExpiracion;
    if (producto['fechaExpiracionDescuento'] != null) {
      try {
        parseFechaExpiracion = DateTime.parse(producto['fechaExpiracionDescuento'] as String);
      } catch (e) {
        parseFechaExpiracion = null;
      }
    }
    
    return VentasProductos(
      productoId: json['productoId'] ?? producto['id'] ?? 0,
      nombre: producto['nombre'] ?? '',
      marca: producto['marca'],
      precio: (producto['precio'] as num?)?.toDouble() ?? 0.0,
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      categoria: producto['categoriaNombre'] ?? '',
      categoriaId: producto['categoriaId'] ?? 0,
      precioFinalCalculado: (json['precioFinalCalculado'] as num?)?.toDouble() ?? 0.0,
      entregado: json['entregado'] ?? false,
      motivo: json['motivo'],
      nota: json['nota'],
      fechaChequeo: json['fechaChequeo'] != null ? DateTime.parse(json['fechaChequeo']) : null,
      usuarioChequeoId: json['usuarioChequeoId'],
      descuento: producto['descuento'] != null
          ? double.tryParse(producto['descuento'].toString()) ?? 0.0
          : 0.0,
      fechaExpiracionDescuento: parseFechaExpiracion,
      descuentoIndefinido: producto['descuentoIndefinido'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'productoId': productoId,
        'producto': {
          'id': productoId,
          'nombre': nombre,
          'marca': marca,
          'precio': precio,
          'stock': 0, // Este campo es para el stock del producto, no la cantidad vendida
          'categoriaId': categoriaId, // Usar el ID de la categoría
          'categoriaNombre': categoria,
          'half': false,
        },
        'cantidad': cantidad,
        'precioFinalCalculado': precioFinalCalculado,
        'entregado': entregado,
        'motivo': motivo,
        'nota': nota,
        'fechaChequeo': fechaChequeo?.toIso8601String(),
        'usuarioChequeoId': usuarioChequeoId,
      };
}