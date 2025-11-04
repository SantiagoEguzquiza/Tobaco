import 'package:tobaco/Models/DiaSemana.dart';

class RecorridoProgramado {
  final int id;
  final int vendedorId;
  final String? vendedorNombre;
  final int clienteId;
  final String? clienteNombre;
  final String? clienteDireccion;
  final double? clienteLatitud;
  final double? clienteLongitud;
  final DiaSemana diaSemana;
  final int orden;
  final bool activo;

  RecorridoProgramado({
    required this.id,
    required this.vendedorId,
    this.vendedorNombre,
    required this.clienteId,
    this.clienteNombre,
    this.clienteDireccion,
    this.clienteLatitud,
    this.clienteLongitud,
    required this.diaSemana,
    required this.orden,
    required this.activo,
  });

  factory RecorridoProgramado.fromJson(Map<String, dynamic> json) {
    return RecorridoProgramado(
      id: json['id'] as int,
      vendedorId: json['vendedorId'] as int,
      vendedorNombre: json['vendedorNombre'] as String?,
      clienteId: json['clienteId'] as int,
      clienteNombre: json['clienteNombre'] as String?,
      clienteDireccion: json['clienteDireccion'] as String?,
      clienteLatitud: json['clienteLatitud'] != null ? (json['clienteLatitud'] as num).toDouble() : null,
      clienteLongitud: json['clienteLongitud'] != null ? (json['clienteLongitud'] as num).toDouble() : null,
      diaSemana: DiaSemana.fromJson(json['diaSemana']),
      orden: json['orden'] as int,
      activo: json['activo'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendedorId': vendedorId,
      'vendedorNombre': vendedorNombre,
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'clienteDireccion': clienteDireccion,
      'clienteLatitud': clienteLatitud,
      'clienteLongitud': clienteLongitud,
      'diaSemana': diaSemana.toJson(),
      'orden': orden,
      'activo': activo,
    };
  }

  RecorridoProgramado copyWith({
    int? id,
    int? vendedorId,
    String? vendedorNombre,
    int? clienteId,
    String? clienteNombre,
    String? clienteDireccion,
    double? clienteLatitud,
    double? clienteLongitud,
    DiaSemana? diaSemana,
    int? orden,
    bool? activo,
  }) {
    return RecorridoProgramado(
      id: id ?? this.id,
      vendedorId: vendedorId ?? this.vendedorId,
      vendedorNombre: vendedorNombre ?? this.vendedorNombre,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteDireccion: clienteDireccion ?? this.clienteDireccion,
      clienteLatitud: clienteLatitud ?? this.clienteLatitud,
      clienteLongitud: clienteLongitud ?? this.clienteLongitud,
      diaSemana: diaSemana ?? this.diaSemana,
      orden: orden ?? this.orden,
      activo: activo ?? this.activo,
    );
  }
}

