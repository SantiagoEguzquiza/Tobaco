import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';

/// Modelo para representar una venta en estado borrador
/// Permite guardar el progreso de una venta antes de confirmarla
class VentaBorrador {
  Cliente? cliente;
  List<ProductoSeleccionado> productosSeleccionados;
  Map<int, double> preciosEspeciales;
  DateTime fechaCreacion;
  DateTime fechaUltimaModificacion;

  VentaBorrador({
    this.cliente,
    required this.productosSeleccionados,
    required this.preciosEspeciales,
    required this.fechaCreacion,
    required this.fechaUltimaModificacion,
  });

  /// Convierte el borrador a JSON para persistencia
  Map<String, dynamic> toJson() {
    return {
      'cliente': cliente?.toJson(),
      'productosSeleccionados': productosSeleccionados.map((p) => p.toJson()).toList(),
      'preciosEspeciales': preciosEspeciales.map((key, value) => MapEntry(key.toString(), value)),
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaUltimaModificacion': fechaUltimaModificacion.toIso8601String(),
    };
  }

  /// Crea un borrador desde JSON
  factory VentaBorrador.fromJson(Map<String, dynamic> json) {
    return VentaBorrador(
      cliente: json['cliente'] != null ? Cliente.fromJson(json['cliente']) : null,
      productosSeleccionados: (json['productosSeleccionados'] as List?)
          ?.map((e) => ProductoSeleccionado.fromJson(e))
          .toList() ?? [],
      preciosEspeciales: (json['preciosEspeciales'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(int.parse(key), (value as num).toDouble())) ?? {},
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaUltimaModificacion: DateTime.parse(json['fechaUltimaModificacion']),
    );
  }

  /// Verifica si el borrador tiene contenido
  bool get tieneContenido {
    return cliente != null || productosSeleccionados.isNotEmpty;
  }

  /// Crea una copia del borrador con campos actualizados
  VentaBorrador copyWith({
    Cliente? cliente,
    List<ProductoSeleccionado>? productosSeleccionados,
    Map<int, double>? preciosEspeciales,
    DateTime? fechaCreacion,
    DateTime? fechaUltimaModificacion,
  }) {
    return VentaBorrador(
      cliente: cliente ?? this.cliente,
      productosSeleccionados: productosSeleccionados ?? this.productosSeleccionados,
      preciosEspeciales: preciosEspeciales ?? this.preciosEspeciales,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaUltimaModificacion: fechaUltimaModificacion ?? this.fechaUltimaModificacion,
    );
  }

  /// Limpia el borrador
  void limpiar() {
    cliente = null;
    productosSeleccionados.clear();
    preciosEspeciales.clear();
  }
}

