import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tobaco/Models/Abono.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/ProductoAFavor.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Models/cuenta_corriente_movimiento.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';

/// Servicio de caché para la cuenta corriente (deudas, abonos, notas de crédito y productos a favor)
/// Permite operar en modo offline con datos persistentes en SQLite
class CuentaCorrienteCacheService {
  static final CuentaCorrienteCacheService _instance = CuentaCorrienteCacheService._internal();
  factory CuentaCorrienteCacheService() => _instance;
  CuentaCorrienteCacheService._internal();

  static Database? _database;
  static const String _dbName = 'cuenta_corriente_cache.db';
  static const int _dbVersion = 1;

  static const String _movimientosTable = 'cuenta_corriente_movimientos';
  static const String _clientesTable = 'cuenta_corriente_clientes';

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_movimientosTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movimiento_id INTEGER,
        local_id TEXT UNIQUE NOT NULL,
        cliente_id INTEGER NOT NULL,
        cliente_nombre TEXT,
        cliente_json TEXT,
        venta_id INTEGER,
        venta_local_id TEXT,
        monto_total REAL NOT NULL DEFAULT 0,
        monto_adeudado REAL NOT NULL DEFAULT 0,
        saldo_delta REAL NOT NULL DEFAULT 0,
        fecha TEXT NOT NULL,
        tipo TEXT NOT NULL,
        detalle TEXT,
        observacion TEXT,
        metadata_json TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_clientesTable (
        cliente_id INTEGER PRIMARY KEY,
        cliente_nombre TEXT NOT NULL,
        cliente_json TEXT,
        saldo_actual REAL NOT NULL DEFAULT 0,
        total_ventas INTEGER NOT NULL DEFAULT 0,
        total_abonos INTEGER NOT NULL DEFAULT 0,
        total_notas_credito INTEGER NOT NULL DEFAULT 0,
        total_productos_favor INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_cc_mov_cliente ON $_movimientosTable(cliente_id)');
    await db.execute('CREATE INDEX idx_cc_mov_tipo ON $_movimientosTable(tipo)');
    await db.execute('CREATE INDEX idx_cc_mov_sync ON $_movimientosTable(sync_status)');
  }

  double _parseDeuda(String? deuda) {
    if (deuda == null || deuda.isEmpty) return 0;
    final normalized = deuda.replaceAll(',', '.');
    return double.tryParse(normalized) ?? double.tryParse(deuda) ?? 0;
  }

  Future<void> cacheClientesResumen(List<Cliente> clientes) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    batch.delete(_clientesTable);

    if (clientes.isNotEmpty) {
      for (final cliente in clientes) {
        final deuda = _parseDeuda(cliente.deuda);
        final resumen = CuentaCorrienteClienteResumen(
          clienteId: cliente.id ?? 0,
          clienteNombre: cliente.nombre,
          saldoActual: deuda,
          cliente: cliente,
        );
        batch.insert(
          _clientesTable,
          resumen.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    try {
      await batch.commit(noResult: true);
      debugPrint('💾 CuentaCorrienteCacheService: ${clientes.length} clientes de CC cacheados ($now)');
    } catch (e) {
      debugPrint('❌ CuentaCorrienteCacheService: Error guardando resumen de clientes: $e');
    }
  }

  Future<Map<String, dynamic>> obtenerClientesConSaldoPaginados({
    required int page,
    required int pageSize,
  }) async {
    final db = await database;
    final offset = (page - 1) * pageSize;

    final rows = await db.query(
      _clientesTable,
      orderBy: 'cliente_nombre COLLATE NOCASE ASC',
      limit: pageSize,
      offset: offset,
    );

    final total = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_clientesTable'),
        ) ??
        0;

    final clientes = rows.map((row) {
      final resumen = CuentaCorrienteClienteResumen.fromMap(row);
      if (resumen.cliente != null) {
        final cliente = resumen.cliente!;
        cliente.deuda = resumen.saldoActual.toStringAsFixed(2);
        return cliente;
      }
      return Cliente(
        id: resumen.clienteId,
        nombre: resumen.clienteNombre,
        direccion: null,
        deuda: resumen.saldoActual.toStringAsFixed(2),
      );
    }).toList();

    return {
      'clientes': clientes,
      'totalItems': total,
      'currentPage': page,
      'pageSize': pageSize,
      'totalPages': (total / pageSize).ceil(),
      'hasNextPage': offset + clientes.length < total,
      'hasPreviousPage': page > 1,
    };
  }

  Future<void> replaceMovimientosDelCliente({
    required int clienteId,
    required TipoMovimientoCuentaCorriente tipo,
    required List<CuentaCorrienteMovimiento> movimientos,
  }) async {
    final db = await database;
    final tipoDb = tipoMovimientoToDb(tipo);
    await db.transaction((txn) async {
      await txn.delete(
        _movimientosTable,
        where: 'cliente_id = ? AND tipo = ? AND sync_status = ?',
        whereArgs: [clienteId, tipoDb, 'synced'],
      );
      for (final movimiento in movimientos) {
        await txn.insert(
          _movimientosTable,
          movimiento.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> cacheVentasCuentaCorriente(int clienteId, List<Ventas> ventas) async {
    final movimientos = ventas.map((venta) {
      final deuda = _calcularDeudaDesdeVenta(venta);
      return CuentaCorrienteMovimiento(
        movimientoId: venta.id,
        localId: 'venta_${venta.id}',
        clienteId: clienteId,
        clienteNombre: venta.cliente.nombre,
        ventaId: venta.id,
        montoTotal: venta.total,
        montoAdeudado: deuda,
        saldoDelta: deuda,
        fecha: venta.fecha,
        tipo: TipoMovimientoCuentaCorriente.venta,
        detalle: 'Venta #${venta.id ?? ''}',
        metadataJson: jsonEncode(venta.toJson()),
      );
    }).toList();

    await replaceMovimientosDelCliente(
      clienteId: clienteId,
      tipo: TipoMovimientoCuentaCorriente.venta,
      movimientos: movimientos,
    );
  }

  Future<void> cacheAbonos(int clienteId, List<Abono> abonos) async {
    final movimientos = abonos.map((abono) {
      final monto = _parseDeuda(abono.monto);
      return CuentaCorrienteMovimiento(
        movimientoId: abono.id,
        localId: 'abono_${abono.id ?? abono.fecha.millisecondsSinceEpoch}',
        clienteId: clienteId,
        clienteNombre: abono.clienteNombre,
        montoTotal: monto,
        montoAdeudado: 0,
        saldoDelta: -monto,
        fecha: abono.fecha,
        tipo: TipoMovimientoCuentaCorriente.abono,
        detalle: 'Abono registrado',
        observacion: abono.nota,
        metadataJson: jsonEncode(abono.toJson()),
      );
    }).toList();

    await replaceMovimientosDelCliente(
      clienteId: clienteId,
      tipo: TipoMovimientoCuentaCorriente.abono,
      movimientos: movimientos,
    );
  }

  Future<void> cacheProductosAFavor(int clienteId, List<ProductoAFavor> productos) async {
    final movimientos = productos.map((producto) {
      return CuentaCorrienteMovimiento(
        movimientoId: producto.id,
        localId: 'producto_${producto.id ?? producto.fechaRegistro.millisecondsSinceEpoch}',
        clienteId: clienteId,
        clienteNombre: producto.cliente?.nombre,
        ventaId: producto.ventaId,
        montoTotal: 0,
        montoAdeudado: 0,
        saldoDelta: 0,
        fecha: producto.fechaRegistro,
        tipo: TipoMovimientoCuentaCorriente.productoAFavor,
        detalle: producto.producto?.nombre ?? 'Producto a favor',
        observacion: producto.nota,
        metadataJson: jsonEncode(producto.toJson()),
      );
    }).toList();

    await replaceMovimientosDelCliente(
      clienteId: clienteId,
      tipo: TipoMovimientoCuentaCorriente.productoAFavor,
      movimientos: movimientos,
    );
  }

  Future<List<Ventas>> obtenerVentasOffline(int clienteId) async {
    final rows = await _queryMovimientos(
      clienteId: clienteId,
      tipo: TipoMovimientoCuentaCorriente.venta,
    );

    return rows.map((mov) {
      final metadata = mov.metadataJson;
      if (metadata != null) {
        try {
          return Ventas.fromJson(jsonDecode(metadata) as Map<String, dynamic>);
        } catch (e) {
          debugPrint('⚠️ CuentaCorrienteCacheService: Error parseando venta offline: $e');
        }
      }
      return Ventas(
        id: mov.movimientoId,
        clienteId: mov.clienteId,
        cliente: Cliente(id: mov.clienteId, nombre: mov.clienteNombre ?? 'Cliente', direccion: null),
        ventasProductos: <VentasProductos>[],
        total: mov.montoTotal,
        fecha: mov.fecha,
        estadoEntrega: EstadoEntrega.noEntregada,
      );
    }).toList();
  }

  Future<List<Abono>> obtenerAbonosOffline(int clienteId) async {
    final rows = await _queryMovimientos(
      clienteId: clienteId,
      tipo: TipoMovimientoCuentaCorriente.abono,
    );

    return rows.map((mov) {
      try {
        if (mov.metadataJson != null) {
          return Abono.fromJson(jsonDecode(mov.metadataJson!) as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('⚠️ CuentaCorrienteCacheService: Error parseando abono offline: $e');
      }
      return Abono(
        id: mov.movimientoId,
        clienteId: mov.clienteId,
        clienteNombre: mov.clienteNombre ?? 'Cliente',
        monto: mov.montoTotal.toStringAsFixed(2),
        fecha: mov.fecha,
        nota: mov.observacion ?? '',
      );
    }).toList();
  }

  Future<List<ProductoAFavor>> obtenerProductosAFavorOffline(int clienteId) async {
    final rows = await _queryMovimientos(
      clienteId: clienteId,
      tipo: TipoMovimientoCuentaCorriente.productoAFavor,
    );

    return rows.map((mov) {
      try {
        if (mov.metadataJson != null) {
          return ProductoAFavor.fromJson(jsonDecode(mov.metadataJson!) as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('⚠️ CuentaCorrienteCacheService: Error parseando producto a favor: $e');
      }
      return ProductoAFavor(
        id: mov.movimientoId,
        clienteId: mov.clienteId,
        productoId: 0,
        cantidad: 0,
        fechaRegistro: mov.fecha,
        motivo: mov.detalle ?? 'Producto a favor',
        nota: mov.observacion,
        ventaId: mov.ventaId ?? 0,
        ventaProductoId: 0,
      );
    }).toList();
  }

  Future<List<CuentaCorrienteMovimiento>> _queryMovimientos({
    required int clienteId,
    TipoMovimientoCuentaCorriente? tipo,
    String? syncStatus,
  }) async {
    final db = await database;
    final where = <String>['cliente_id = ?'];
    final args = <dynamic>[clienteId];

    if (tipo != null) {
      where.add('tipo = ?');
      args.add(tipoMovimientoToDb(tipo));
    }
    if (syncStatus != null) {
      where.add('sync_status = ?');
      args.add(syncStatus);
    }

    final rows = await db.query(
      _movimientosTable,
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'fecha DESC',
    );

    return rows.map(CuentaCorrienteMovimiento.fromMap).toList();
  }

  Future<List<CuentaCorrienteMovimiento>> obtenerMovimientosPorTipo({
    required int clienteId,
    required TipoMovimientoCuentaCorriente tipo,
  }) async {
    return _queryMovimientos(
      clienteId: clienteId,
      tipo: tipo,
    );
  }

  Future<List<CuentaCorrienteMovimiento>> obtenerMovimientosPendientes() async {
    final db = await database;
    final rows = await db.query(
      _movimientosTable,
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
    return rows.map(CuentaCorrienteMovimiento.fromMap).toList();
  }

  Future<void> registrarVentaOffline({
    required int clienteId,
    required String clienteNombre,
    required String ventaLocalId,
    required double deudaGenerada,
    required Ventas venta,
  }) async {
    if (deudaGenerada <= 0) return;
    final cliente = venta.cliente;
    final movimiento = CuentaCorrienteMovimiento(
      movimientoId: null,
      localId: 'venta_local_$ventaLocalId',
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      ventaLocalId: ventaLocalId,
      montoTotal: venta.total,
      montoAdeudado: deudaGenerada,
      saldoDelta: deudaGenerada,
      fecha: DateTime.now(),
      tipo: TipoMovimientoCuentaCorriente.venta,
      detalle: 'Venta offline pendiente',
      metadataJson: jsonEncode(venta.toJson()),
      syncStatus: EstadoMovimientoSincronizacion.pendiente,
    );
    final db = await database;
    await db.insert(
      _movimientosTable,
      movimiento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _ajustarSaldoCliente(
      clienteId,
      deudaGenerada,
      clienteNombre: clienteNombre,
      cliente: cliente,
    );
  }

  Future<Abono> registrarAbonoOffline({
    required int clienteId,
    required String clienteNombre,
    required double monto,
    String? nota,
  }) async {
    final fecha = DateTime.now();
    final localId = 'abono_local_${fecha.millisecondsSinceEpoch}';
    final abono = Abono(
      id: null,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      monto: monto.toStringAsFixed(2),
      fecha: fecha,
      nota: nota ?? '',
    );
    final movimiento = CuentaCorrienteMovimiento(
      localId: localId,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      montoTotal: monto,
      montoAdeudado: 0,
      saldoDelta: -monto,
      fecha: fecha,
      tipo: TipoMovimientoCuentaCorriente.abono,
      observacion: nota,
      metadataJson: jsonEncode(abono.toJson()),
      syncStatus: EstadoMovimientoSincronizacion.pendiente,
    );

    final db = await database;
    await db.insert(
      _movimientosTable,
      movimiento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _ajustarSaldoCliente(
      clienteId,
      -monto,
      clienteNombre: clienteNombre,
    );
    return abono;
  }

  Future<void> marcarMovimientoSincronizado(
    String localId, {
    int? movimientoId,
  }) async {
    final db = await database;
    await db.update(
      _movimientosTable,
      {
        'movimiento_id': movimientoId,
        'sync_status': 'synced',
        'last_error': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> marcarMovimientoError(String localId, String error) async {
    final db = await database;
    await db.update(
      _movimientosTable,
      {
        'sync_status': 'error',
        'last_error': error,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> marcarMovimientosDeVentaComoSincronizados({
    required String ventaLocalId,
    required int? ventaServerId,
  }) async {
    final db = await database;
    await db.update(
      _movimientosTable,
      {
        'venta_id': ventaServerId,
        'sync_status': 'synced',
        'last_error': null,
        'updated_at': DateTime.now().toIso8601String(),
        'local_id': 'venta_${ventaServerId ?? ventaLocalId}',
      },
      where: 'venta_local_id = ?',
      whereArgs: [ventaLocalId],
    );
  }

  Future<void> _ajustarSaldoCliente(
    int clienteId,
    double delta, {
    String? clienteNombre,
    Cliente? cliente,
  }) async {
    final db = await database;
    final existing = await db.query(
      _clientesTable,
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert(
        _clientesTable,
        {
          'cliente_id': clienteId,
          'cliente_nombre': clienteNombre ?? 'Cliente #$clienteId',
          'cliente_json': cliente != null ? jsonEncode(cliente.toJsonId()) : null,
          'saldo_actual': delta.clamp(0, double.infinity),
          'total_ventas': delta > 0 ? 1 : 0,
          'total_abonos': delta < 0 ? 1 : 0,
          'total_notas_credito': 0,
          'total_productos_favor': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return;
    }

    final row = existing.first;
    final resumen = CuentaCorrienteClienteResumen.fromMap(row);
    final nuevoSaldo = (resumen.saldoActual + delta).clamp(0, double.infinity);
    await db.update(
      _clientesTable,
      {
        'saldo_actual': nuevoSaldo,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
    );
  }

  double _calcularDeudaDesdeVenta(Ventas venta) {
    if (venta.pagos == null || venta.pagos!.isEmpty) {
      return venta.metodoPago == MetodoPago.cuentaCorriente ? venta.total : 0;
    }
    final deuda = venta.pagos!
        .where((p) => p.metodo == MetodoPago.cuentaCorriente)
        .fold<double>(0, (acc, pago) => acc + pago.monto);
    return deuda;
  }

  Future<CuentaCorrienteClienteResumen?> obtenerResumenCliente(int clienteId) async {
    final db = await database;
    final rows = await db.query(
      _clientesTable,
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CuentaCorrienteClienteResumen.fromMap(rows.first);
  }

  Future<Map<String, dynamic>?> obtenerDetalleDeudaOffline(int clienteId) async {
    final resumen = await obtenerResumenCliente(clienteId);
    if (resumen == null) return null;
    return {
      'clienteId': resumen.clienteId,
      'clienteNombre': resumen.clienteNombre,
      'deudaActual': resumen.saldoActual,
      'deudaFormateada': resumen.saldoActual.toStringAsFixed(2),
      'fechaConsulta': DateTime.now().toIso8601String(),
    };
  }
}

