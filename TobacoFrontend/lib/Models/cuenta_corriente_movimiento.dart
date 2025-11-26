import 'dart:convert';

import 'package:tobaco/Models/Cliente.dart';

enum TipoMovimientoCuentaCorriente {
  venta,
  abono,
  notaCredito,
  productoAFavor,
}

enum EstadoMovimientoSincronizacion {
  pendiente,
  sincronizado,
  error,
}

TipoMovimientoCuentaCorriente tipoMovimientoFromDb(String value) {
  switch (value) {
    case 'venta':
      return TipoMovimientoCuentaCorriente.venta;
    case 'abono':
      return TipoMovimientoCuentaCorriente.abono;
    case 'nota_credito':
      return TipoMovimientoCuentaCorriente.notaCredito;
    case 'producto_a_favor':
      return TipoMovimientoCuentaCorriente.productoAFavor;
    default:
      return TipoMovimientoCuentaCorriente.venta;
  }
}

String tipoMovimientoToDb(TipoMovimientoCuentaCorriente value) {
  switch (value) {
    case TipoMovimientoCuentaCorriente.venta:
      return 'venta';
    case TipoMovimientoCuentaCorriente.abono:
      return 'abono';
    case TipoMovimientoCuentaCorriente.notaCredito:
      return 'nota_credito';
    case TipoMovimientoCuentaCorriente.productoAFavor:
      return 'producto_a_favor';
  }
}

EstadoMovimientoSincronizacion estadoMovimientoFromDb(String value) {
  switch (value) {
    case 'pending':
      return EstadoMovimientoSincronizacion.pendiente;
    case 'error':
      return EstadoMovimientoSincronizacion.error;
    default:
      return EstadoMovimientoSincronizacion.sincronizado;
  }
}

String estadoMovimientoToDb(EstadoMovimientoSincronizacion value) {
  switch (value) {
    case EstadoMovimientoSincronizacion.pendiente:
      return 'pending';
    case EstadoMovimientoSincronizacion.error:
      return 'error';
    case EstadoMovimientoSincronizacion.sincronizado:
      return 'synced';
  }
}

class CuentaCorrienteMovimiento {
  final int? id;
  final int? movimientoId;
  final String localId;
  final int clienteId;
  final String? clienteNombre;
  final int? ventaId;
  final String? ventaLocalId;
  final double montoTotal;
  final double montoAdeudado;
  final double saldoDelta;
  final DateTime fecha;
  final TipoMovimientoCuentaCorriente tipo;
  final String? detalle;
  final String? observacion;
  final String? metadataJson;
  final EstadoMovimientoSincronizacion syncStatus;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  CuentaCorrienteMovimiento({
    this.id,
    this.movimientoId,
    required this.localId,
    required this.clienteId,
    this.clienteNombre,
    this.ventaId,
    this.ventaLocalId,
    required this.montoTotal,
    required this.montoAdeudado,
    required this.saldoDelta,
    required this.fecha,
    required this.tipo,
    this.detalle,
    this.observacion,
    this.metadataJson,
    this.syncStatus = EstadoMovimientoSincronizacion.sincronizado,
    this.lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'movimiento_id': movimientoId,
      'local_id': localId,
      'cliente_id': clienteId,
      'cliente_nombre': clienteNombre,
      'venta_id': ventaId,
      'venta_local_id': ventaLocalId,
      'monto_total': montoTotal,
      'monto_adeudado': montoAdeudado,
      'saldo_delta': saldoDelta,
      'fecha': fecha.toIso8601String(),
      'tipo': tipoMovimientoToDb(tipo),
      'detalle': detalle,
      'observacion': observacion,
      'metadata_json': metadataJson,
      'sync_status': estadoMovimientoToDb(syncStatus),
      'last_error': lastError,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CuentaCorrienteMovimiento.fromMap(Map<String, dynamic> map) {
    return CuentaCorrienteMovimiento(
      id: map['id'] as int?,
      movimientoId: map['movimiento_id'] as int?,
      localId: map['local_id'] as String,
      clienteId: map['cliente_id'] as int,
      clienteNombre: map['cliente_nombre'] as String?,
      ventaId: map['venta_id'] as int?,
      ventaLocalId: map['venta_local_id'] as String?,
      montoTotal: (map['monto_total'] as num?)?.toDouble() ?? 0,
      montoAdeudado: (map['monto_adeudado'] as num?)?.toDouble() ?? 0,
      saldoDelta: (map['saldo_delta'] as num?)?.toDouble() ?? 0,
      fecha: DateTime.parse(map['fecha'] as String),
      tipo: tipoMovimientoFromDb(map['tipo'] as String),
      detalle: map['detalle'] as String?,
      observacion: map['observacion'] as String?,
      metadataJson: map['metadata_json'] as String?,
      syncStatus: estadoMovimientoFromDb(map['sync_status'] as String? ?? 'synced'),
      lastError: map['last_error'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  CuentaCorrienteMovimiento copyWith({
    int? id,
    int? movimientoId,
    String? localId,
    int? clienteId,
    String? clienteNombre,
    int? ventaId,
    String? ventaLocalId,
    double? montoTotal,
    double? montoAdeudado,
    double? saldoDelta,
    DateTime? fecha,
    TipoMovimientoCuentaCorriente? tipo,
    String? detalle,
    String? observacion,
    String? metadataJson,
    EstadoMovimientoSincronizacion? syncStatus,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CuentaCorrienteMovimiento(
      id: id ?? this.id,
      movimientoId: movimientoId ?? this.movimientoId,
      localId: localId ?? this.localId,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      ventaId: ventaId ?? this.ventaId,
      ventaLocalId: ventaLocalId ?? this.ventaLocalId,
      montoTotal: montoTotal ?? this.montoTotal,
      montoAdeudado: montoAdeudado ?? this.montoAdeudado,
      saldoDelta: saldoDelta ?? this.saldoDelta,
      fecha: fecha ?? this.fecha,
      tipo: tipo ?? this.tipo,
      detalle: detalle ?? this.detalle,
      observacion: observacion ?? this.observacion,
      metadataJson: metadataJson ?? this.metadataJson,
      syncStatus: syncStatus ?? this.syncStatus,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic>? decodeMetadata() {
    if (metadataJson == null || metadataJson!.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(metadataJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

class CuentaCorrienteClienteResumen {
  final int clienteId;
  final String clienteNombre;
  final double saldoActual;
  final int totalVentas;
  final int totalAbonos;
  final int totalNotasCredito;
  final int totalProductosFavor;
  final DateTime updatedAt;
  final Cliente? cliente;

  CuentaCorrienteClienteResumen({
    required this.clienteId,
    required this.clienteNombre,
    required this.saldoActual,
    this.totalVentas = 0,
    this.totalAbonos = 0,
    this.totalNotasCredito = 0,
    this.totalProductosFavor = 0,
    DateTime? updatedAt,
    this.cliente,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'cliente_id': clienteId,
      'cliente_nombre': clienteNombre,
      'saldo_actual': saldoActual,
      'total_ventas': totalVentas,
      'total_abonos': totalAbonos,
      'total_notas_credito': totalNotasCredito,
      'total_productos_favor': totalProductosFavor,
      'cliente_json': cliente != null ? jsonEncode(cliente!.toJsonId()) : null,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CuentaCorrienteClienteResumen.fromMap(Map<String, dynamic> map) {
    Cliente? cliente;
    if (map['cliente_json'] != null) {
      try {
        final json = jsonDecode(map['cliente_json'] as String);
        cliente = Cliente.fromJson(json as Map<String, dynamic>);
      } catch (_) {}
    }

    return CuentaCorrienteClienteResumen(
      clienteId: map['cliente_id'] as int,
      clienteNombre: map['cliente_nombre'] as String? ?? '',
      saldoActual: (map['saldo_actual'] as num?)?.toDouble() ?? 0,
      totalVentas: map['total_ventas'] as int? ?? 0,
      totalAbonos: map['total_abonos'] as int? ?? 0,
      totalNotasCredito: map['total_notas_credito'] as int? ?? 0,
      totalProductosFavor: map['total_productos_favor'] as int? ?? 0,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      cliente: cliente,
    );
  }
}

