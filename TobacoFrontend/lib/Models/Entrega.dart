// ignore_for_file: file_names

import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Models/Ventas.dart';

/// Modelo para representar una entrega en el mapa
class Entrega {
  int? id;
  int ventaId;
  Ventas? venta;
  int clienteId;
  Cliente cliente;
  double? latitud;
  double? longitud;
  EstadoEntrega estado;
  DateTime fechaAsignacion;
  DateTime? fechaEntrega;
  int? repartidorId;
  int orden; // Orden de entrega en la ruta
  String? notas;
  double? distanciaDesdeUbicacionActual; // En kilómetros

  Entrega({
    this.id,
    required this.ventaId,
    this.venta,
    required this.clienteId,
    required this.cliente,
    this.latitud,
    this.longitud,
    this.estado = EstadoEntrega.noEntregada,
    required this.fechaAsignacion,
    this.fechaEntrega,
    this.repartidorId,
    this.orden = 0,
    this.notas,
    this.distanciaDesdeUbicacionActual,
  });

  /// Indica si la entrega tiene coordenadas válidas
  bool get tieneCoordenadasValidas => 
      latitud != null && 
      longitud != null && 
      latitud != 0 && 
      longitud != 0;

  /// Obtiene el nombre del cliente
  String get nombreCliente => cliente.nombre;

  /// Obtiene la dirección del cliente
  String get direccion => cliente.direccion ?? 'Sin dirección';

  /// Indica si la entrega ya fue completada
  bool get estaCompletada => estado == EstadoEntrega.entregada;

  /// Indica si la entrega está pendiente
  bool get estaPendiente => estado == EstadoEntrega.noEntregada;

  factory Entrega.fromJson(Map<String, dynamic> json) {
    // Backend puede enviar 'cliente' anidado o campos planos 'clienteNombre'/'clienteDireccion'
    final Map<String, dynamic>? clienteJson = json['cliente'] as Map<String, dynamic>?;
    final String clienteNombre = (clienteJson != null
            ? clienteJson['nombre']
            : json['clienteNombre']) as String? ?? 'Cliente';
    final String? clienteDireccion = (clienteJson != null
            ? clienteJson['direccion']
            : json['clienteDireccion']) as String?;

    return Entrega(
      id: json['id'] as int?,
      ventaId: json['ventaId'] as int,
      venta: json['venta'] != null ? Ventas.fromJson(json['venta']) : null,
      clienteId: json['clienteId'] as int,
      cliente: clienteJson != null
          ? Cliente.fromJson(clienteJson)
          : Cliente(id: json['clienteId'] as int, nombre: clienteNombre, direccion: clienteDireccion),
      latitud: json['latitud'] != null
          ? (json['latitud'] as num).toDouble()
          : null,
      longitud: json['longitud'] != null
          ? (json['longitud'] as num).toDouble()
          : null,
      estado: json['estado'] != null
          ? EstadoEntregaExtension.fromJson(json['estado'])
          : EstadoEntrega.noEntregada,
      fechaAsignacion: DateTime.parse(json['fechaAsignacion'] as String),
      fechaEntrega: json['fechaEntrega'] != null
          ? DateTime.parse(json['fechaEntrega'] as String)
          : null,
      repartidorId: json['repartidorId'] as int?,
      orden: (json['orden'] as int?) ?? 0,
      notas: json['notas'] as String?,
      distanciaDesdeUbicacionActual: json['distanciaDesdeUbicacionActual'] != null
          ? (json['distanciaDesdeUbicacionActual'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ventaId': ventaId,
      'venta': venta?.toJson(),
      'clienteId': clienteId,
      'cliente': cliente.toJson(),
      'latitud': latitud,
      'longitud': longitud,
      'estado': estado.toJson(),
      'fechaAsignacion': fechaAsignacion.toIso8601String(),
      'fechaEntrega': fechaEntrega?.toIso8601String(),
      'repartidorId': repartidorId,
      'orden': orden,
      'notas': notas,
      'distanciaDesdeUbicacionActual': distanciaDesdeUbicacionActual,
    };
  }

  /// Convierte a Map para SQLite (sin objetos anidados complejos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ventaId': ventaId,
      'clienteId': clienteId,
      'latitud': latitud,
      'longitud': longitud,
      'estado': estado.toJson(),
      'fechaAsignacion': fechaAsignacion.toIso8601String(),
      'fechaEntrega': fechaEntrega?.toIso8601String(),
      'repartidorId': repartidorId,
      'orden': orden,
      'notas': notas,
      'distanciaDesdeUbicacionActual': distanciaDesdeUbicacionActual,
      // Guardamos algunos datos del cliente directamente
      'clienteNombre': cliente.nombre,
      'clienteDireccion': cliente.direccion,
    };
  }

  /// Crea desde Map de SQLite
  factory Entrega.fromMap(Map<String, dynamic> map, {Cliente? clienteData, Ventas? ventaData}) {
    return Entrega(
      id: map['id'] as int?,
      // admitir snake_case de SQLite y camelCase
      ventaId: (map['ventaId'] ?? map['venta_id']) as int,
      venta: ventaData,
      clienteId: (map['clienteId'] ?? map['cliente_id']) as int,
      cliente: clienteData ?? Cliente(
        id: (map['clienteId'] ?? map['cliente_id']) as int,
        nombre: (map['clienteNombre'] ?? map['cliente_nombre'] ?? 'Cliente') as String,
        direccion: (map['clienteDireccion'] ?? map['cliente_direccion']) as String?,
      ),
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      estado: EstadoEntregaExtension.fromJson(map['estado'] ?? map['estado_entrega']),
      fechaAsignacion: DateTime.parse((map['fechaAsignacion'] ?? map['fecha_asignacion']) as String),
      fechaEntrega: (map['fechaEntrega'] ?? map['fecha_entrega']) != null
          ? DateTime.parse((map['fechaEntrega'] ?? map['fecha_entrega']) as String)
          : null,
      repartidorId: (map['repartidorId'] ?? map['repartidor_id']) as int?,
      orden: (map['orden'] as int?) ?? 0,
      notas: map['notas'] as String?,
      distanciaDesdeUbicacionActual: (map['distanciaDesdeUbicacionActual'] ?? map['distancia_desde_ubicacion_actual']) as double?,
    );
  }

  /// Crea una copia con campos actualizados
  Entrega copyWith({
    int? id,
    int? ventaId,
    Ventas? venta,
    int? clienteId,
    Cliente? cliente,
    double? latitud,
    double? longitud,
    EstadoEntrega? estado,
    DateTime? fechaAsignacion,
    DateTime? fechaEntrega,
    int? repartidorId,
    int? orden,
    String? notas,
    double? distanciaDesdeUbicacionActual,
  }) {
    return Entrega(
      id: id ?? this.id,
      ventaId: ventaId ?? this.ventaId,
      venta: venta ?? this.venta,
      clienteId: clienteId ?? this.clienteId,
      cliente: cliente ?? this.cliente,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      estado: estado ?? this.estado,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      repartidorId: repartidorId ?? this.repartidorId,
      orden: orden ?? this.orden,
      notas: notas ?? this.notas,
      distanciaDesdeUbicacionActual: distanciaDesdeUbicacionActual ?? this.distanciaDesdeUbicacionActual,
    );
  }
}

