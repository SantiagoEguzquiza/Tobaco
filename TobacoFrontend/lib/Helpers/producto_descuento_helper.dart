import 'package:tobaco/Models/Producto.dart';

class ProductoDescuentoHelper {
  /// Calcula el precio con descuento aplicado
  /// Retorna el precio original si el descuento venció o no existe
  static double calcularPrecioConDescuento(Producto producto) {
    // Verificar si hay descuento activo
    if (!_tieneDescuentoActivo(producto)) {
      return producto.precio;
    }

    // Calcular precio con descuento
    final descuento = producto.descuento;
    final precioConDescuento = producto.precio * (1 - descuento / 100);
    return precioConDescuento;
  }

  /// Verifica si el producto tiene un descuento activo (no vencido)
  static bool _tieneDescuentoActivo(Producto producto) {
    // Si no hay descuento, retornar false
    if (producto.descuento <= 0) {
      return false;
    }

    // Si el descuento es indefinido, está activo
    if (producto.descuentoIndefinido) {
      return true;
    }

    // Si tiene fecha de expiración, verificar si no venció
    if (producto.fechaExpiracionDescuento != null) {
      final ahora = DateTime.now();
      final fechaExpiracion = producto.fechaExpiracionDescuento!;
      return fechaExpiracion.isAfter(ahora);
    }

    // Si tiene descuento pero no es indefinido y no tiene fecha, considerar activo
    // (aunque esto no debería pasar según la lógica del backend)
    return true;
  }

  /// Verifica si el producto tiene descuento (activo o no)
  static bool tieneDescuento(Producto producto) {
    return producto.descuento > 0;
  }

  /// Verifica si el descuento está activo (no vencido)
  static bool tieneDescuentoActivo(Producto producto) {
    return _tieneDescuentoActivo(producto);
  }

  /// Obtiene el porcentaje de descuento activo
  static double obtenerPorcentajeDescuento(Producto producto) {
    if (!_tieneDescuentoActivo(producto)) {
      return 0.0;
    }
    return producto.descuento;
  }

  /// Obtiene la fecha de expiración formateada
  static String? obtenerFechaExpiracionFormateada(Producto producto) {
    if (producto.fechaExpiracionDescuento == null) {
      return null;
    }
    final fecha = producto.fechaExpiracionDescuento!;
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}

