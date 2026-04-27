// ignore_for_file: file_names

/// Define cómo se resuelve el control de stock para un producto puntual.
///
/// Se combina con la configuración global del tenant
/// (`stockControlEnabledByDefault`) para determinar el comportamiento efectivo:
/// - `inheritTenant` toma la configuración general del tenant.
/// - `forceEnabled` controla stock siempre, sin importar la configuración global.
/// - `forceDisabled` ignora el stock, sin importar la configuración global.
enum StockControlMode {
  inheritTenant(0),
  forceEnabled(1),
  forceDisabled(2);

  final int value;
  const StockControlMode(this.value);

  static StockControlMode fromJson(dynamic value) {
    int intValue;
    if (value is int) {
      intValue = value;
    } else if (value is String) {
      intValue = int.tryParse(value) ?? 0;
    } else {
      intValue = 0;
    }

    return StockControlMode.values.firstWhere(
      (e) => e.value == intValue,
      orElse: () => StockControlMode.inheritTenant,
    );
  }

  int toJson() => value;

  String get displayName {
    switch (this) {
      case StockControlMode.inheritTenant:
        return 'Heredar configuración general';
      case StockControlMode.forceEnabled:
        return 'Controlar stock';
      case StockControlMode.forceDisabled:
        return 'No controlar stock';
    }
  }

  String get description {
    switch (this) {
      case StockControlMode.inheritTenant:
        return 'Usa la configuración global del tenant.';
      case StockControlMode.forceEnabled:
        return 'Siempre controla stock para este producto.';
      case StockControlMode.forceDisabled:
        return 'Nunca controla stock para este producto.';
    }
  }
}
