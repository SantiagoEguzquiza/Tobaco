enum EstadoEntrega {
  noEntregada,  // 0
  parcial,      // 1
  entregada,    // 2
}

// Helper para convertir desde/hacia JSON (valor int del backend)
extension EstadoEntregaExtension on EstadoEntrega {
  int toJson() => index;

  static EstadoEntrega fromJson(int value) {
    switch (value) {
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

