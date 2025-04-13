// ignore_for_file: file_names

class Cliente {
  int? id;
  String nombre;
  String? direccion;
  int? telefono;
  int? deuda;

  Cliente(
      {required this.id,
      required this.nombre,
      required this.direccion,
      this.telefono,
      this.deuda});

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] != null
          ? int.tryParse(json['telefono'].toString())
          : null,
      deuda:
          json['deuda'] != null ? int.tryParse(json['deuda'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono.toString(),
      'deuda': deuda.toString(),
    };
  }
}
