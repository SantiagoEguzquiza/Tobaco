// ignore_for_file: file_names

import 'PrecioEspecial.dart';

class Cliente {
  int? id;
  String nombre;
  String? direccion;
  int? telefono;
  String? deuda;
  List<PrecioEspecial> preciosEspeciales;


  Cliente(
      {required this.id,
      required this.nombre,
      required this.direccion,
      this.telefono,
      this.deuda,
      this.preciosEspeciales = const [],
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
      preciosEspeciales: precios,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono?.toString(),
      'deuda': deuda,
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
      
    };
  }
}
