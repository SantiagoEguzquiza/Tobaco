// ignore_for_file: file_names

/// Define los tipos de vendedores/distribuidores
enum TipoVendedor {
  /// Vendedor: visita sucursales, revisa inventario y asigna entregas a repartidores
  vendedor(0),
  
  /// Repartidor: solo realiza entregas, no genera ventas
  repartidor(1),
  
  /// Repartidor-Vendedor: visita sucursales, genera ventas y entrega en el mismo acto
  repartidorVendedor(2);

  final int value;
  const TipoVendedor(this.value);

  static TipoVendedor fromJson(dynamic value) {
    // Handle both int and String values
    int intValue;
    if (value is int) {
      intValue = value;
    } else if (value is String) {
      intValue = int.tryParse(value) ?? 1; // Default to repartidor if parsing fails
    } else {
      intValue = 1; // Default to repartidor
    }
    
    return TipoVendedor.values.firstWhere(
      (e) => e.value == intValue,
      orElse: () => TipoVendedor.repartidor, // Valor por defecto
    );
  }

  int toJson() => value;

  String get displayName {
    switch (this) {
      case TipoVendedor.vendedor:
        return 'Vendedor';
      case TipoVendedor.repartidor:
        return 'Repartidor';
      case TipoVendedor.repartidorVendedor:
        return 'Repartidor-Vendedor';
    }
  }

  String get description {
    switch (this) {
      case TipoVendedor.vendedor:
        return 'Visita sucursales, revisa inventario y asigna entregas a repartidores';
      case TipoVendedor.repartidor:
        return 'Solo realiza entregas, no genera ventas';
      case TipoVendedor.repartidorVendedor:
        return 'Visita sucursales, genera ventas y entrega en el mismo acto';
    }
  }
}

