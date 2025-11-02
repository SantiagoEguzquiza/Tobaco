enum EstadoEntrega {
  noEntregada,  // 0
  parcial,      // 1
  entregada,    // 2
}

// Helper para convertir desde/hacia JSON (valor int del backend)
extension EstadoEntregaExtension on EstadoEntrega {
  int toJson() => index;

  static EstadoEntrega fromJson(dynamic value) {
    // Handle both int and String values
    int intValue;
    if (value is int) {
      intValue = value;
    } else if (value is String) {
      intValue = int.tryParse(value) ?? 0; // Default to noEntregada if parsing fails
    } else {
      intValue = 0; // Default to noEntregada
    }
    
    switch (intValue) {
      case 0:
        return EstadoEntrega.noEntregada;
      case 1:
        return EstadoEntrega.parcial;
      case 2:
        return EstadoEntrega.entregada;
      default:
        return EstadoEntrega.noEntregada;
    }
  }

  String get displayName {
    switch (this) {
      case EstadoEntrega.noEntregada:
        return 'No Entregada';
      case EstadoEntrega.parcial:
        return 'Parcial';
      case EstadoEntrega.entregada:
        return 'Entregada';
    }
  }
}

