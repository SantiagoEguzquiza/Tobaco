class PrecioEspecial {
  int? id;
  int clienteId;
  int productoId;
  double precio;
  DateTime fechaCreacion;
  DateTime? fechaActualizacion;
  
  // Propiedades adicionales para mostrar información
  String? clienteNombre;
  String? productoNombre;
  double? precioEstandar;

  PrecioEspecial({
    this.id,
    required this.clienteId,
    required this.productoId,
    required this.precio,
    required this.fechaCreacion,
    this.fechaActualizacion,
    this.clienteNombre,
    this.productoNombre,
    this.precioEstandar,
  });

  factory PrecioEspecial.fromJson(Map<String, dynamic> json) {
    return PrecioEspecial(
      id: json['id'],
      clienteId: json['clienteId'],
      productoId: json['productoId'],
      precio: (json['precio'] as num).toDouble(),
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaActualizacion: json['fechaActualizacion'] != null 
          ? DateTime.parse(json['fechaActualizacion']) 
          : null,
      clienteNombre: json['clienteNombre'],
      productoNombre: json['productoNombre'],
      precioEstandar: json['precioEstandar'] != null 
          ? (json['precioEstandar'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clienteId': clienteId,
      'productoId': productoId,
      'precio': precio,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
      'clienteNombre': clienteNombre,
      'productoNombre': productoNombre,
      'precioEstandar': precioEstandar,
    };
  }

  PrecioEspecial copyWith({
    int? id,
    int? clienteId,
    int? productoId,
    double? precio,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? clienteNombre,
    String? productoNombre,
    double? precioEstandar,
  }) {
    return PrecioEspecial(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      productoId: productoId ?? this.productoId,
      precio: precio ?? this.precio,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      productoNombre: productoNombre ?? this.productoNombre,
      precioEstandar: precioEstandar ?? this.precioEstandar,
    );
  }

  @override
  String toString() {
    return 'PrecioEspecial(id: $id, clienteId: $clienteId, productoId: $productoId, precio: $precio, clienteNombre: $clienteNombre, productoNombre: $productoNombre)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrecioEspecial &&
        other.id == id &&
        other.clienteId == clienteId &&
        other.productoId == productoId &&
        other.precio == precio;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        clienteId.hashCode ^
        productoId.hashCode ^
        precio.hashCode;
  }
}
