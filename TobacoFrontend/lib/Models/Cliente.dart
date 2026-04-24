// ignore_for_file: file_names

import 'PrecioEspecial.dart';

class Cliente {
  int? id;
  String nombre;
  String? direccion;
  int? telefono;
  String? deuda;
  double descuentoGlobal;
  List<PrecioEspecial> preciosEspeciales;
  double? latitud;
  double? longitud;
  bool visible;
  /// Indica si el cliente puede operar con cuenta corriente.
  bool hasCCTE;

  Cliente(
      {required this.id,
      required this.nombre,
      required this.direccion,
      this.telefono,
      this.deuda,
      this.descuentoGlobal = 0.0,
      this.preciosEspeciales = const [],
      this.latitud,
      this.longitud,
      this.visible = true,
      this.hasCCTE = false,
      });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    List<PrecioEspecial> precios = [];
    if (json['preciosEspeciales'] != null) {
      precios = (json['preciosEspeciales'] as List)
          .map((precio) => PrecioEspecial.fromJson(precio))
          .toList();
    }

    return Cliente(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] != null
          ? int.tryParse(json['telefono'].toString())
          : null,
      deuda: json['deuda'] as String?,
      descuentoGlobal: (json['descuentoGlobal'] as num?)?.toDouble() ?? 0.0,
      preciosEspeciales: precios,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      visible: json['visible'] as bool? ?? true,
      hasCCTE: json['hasCCTE'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    // Normalizar deuda: si es null, vacío o solo espacios, usar "0"
    String deudaNormalizada = '0';
    final deudaValue = deuda;
    if (deudaValue != null && deudaValue.trim().isNotEmpty) {
      // Remover espacios y reemplazar comas por puntos
      deudaNormalizada = deudaValue.trim().replaceAll(',', '.');
      // Si después de normalizar está vacío, usar "0"
      if (deudaNormalizada.isEmpty) {
        deudaNormalizada = '0';
      }
    }
    
    Map<String, dynamic> json = {
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono?.toString(),
      'deuda': deudaNormalizada,
      'descuentoGlobal': descuentoGlobal,
      'latitud': latitud,
      'longitud': longitud,
      'visible': visible,
      'hasCCTE': hasCCTE,
    };
    
    // Solo incluir el id si no es null (para actualizaciones)
    if (id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  Map<String, dynamic> toJsonId() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono?.toString(),
      'deuda': deuda,
      'descuentoGlobal': descuentoGlobal,
      'latitud': latitud,
      'longitud': longitud,
      'visible': visible,
      'hasCCTE': hasCCTE,
    };
  }
}
