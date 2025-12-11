import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../Models/Ventas.dart';
import '../../Models/VentasProductos.dart';
import '../../Models/Cliente.dart';
import '../../Models/ventasPago.dart';
import '../../Models/metodoPago.dart';
import '../../Models/EstadoEntrega.dart';
import '../../Models/User.dart';
import '../../Models/Entrega.dart';

/// Helper para la base de datos SQLite local
/// Maneja el almacenamiento offline de ventas pendientes de sincronización
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _databaseName = 'tobaco_offline.db';
  static const int _databaseVersion = 4;

  // Nombres de tablas
  static const String _ventasTable = 'ventas_offline';
  static const String _productosTable = 'ventas_productos_offline';
  static const String _pagosTable = 'ventas_pagos_offline';
  static const String _entregasTable = 'entregas_offline';

  Future<Database> get database async {
    // Verificar si la base de datos está abierta y es válida
    if (_database != null) {
      try {
        // Intentar una operación simple para verificar que la BD esté abierta
        await _database!.rawQuery('SELECT 1');
        return _database!;
      } catch (e) {
        // Si la BD está cerrada, reinicializarla
        debugPrint('⚠️ DatabaseHelper: Base de datos cerrada, reinicializando...');
        _database = null;
      }
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// Formatea una fecha en hora local sin conversión a UTC
  /// Preserva la hora exacta de la fecha local
  static String formatDateTimeLocal(DateTime dateTime) {
    final local = dateTime.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    final millisecond = local.millisecond.toString().padLeft(3, '0');
    return '$year-$month-$day $hour:$minute:$second.$millisecond';
  }

  /// Parsea una fecha desde string, interpretándola siempre como hora local
  static DateTime parseDateTimeLocal(String dateTimeStr) {
    try {
      // Si tiene zona horaria (UTC), convertirla a local
      if (dateTimeStr.endsWith('Z') || dateTimeStr.contains('+') || 
          (dateTimeStr.contains('-') && dateTimeStr.length > 19 && 
           dateTimeStr.substring(19).contains('-'))) {
        return DateTime.parse(dateTimeStr).toLocal();
      }
      
      // Si es formato ISO sin zona horaria (YYYY-MM-DD HH:mm:ss.mmm), parsear como local
      if (dateTimeStr.contains(' ')) {
        // Formato: YYYY-MM-DD HH:mm:ss.mmm
        final parts = dateTimeStr.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('-');
          final timeParts = parts[1].split(':');
          if (dateParts.length == 3 && timeParts.length >= 2) {
            final year = int.parse(dateParts[0]);
            final month = int.parse(dateParts[1]);
            final day = int.parse(dateParts[2]);
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            final second = timeParts.length > 2 ? int.parse(timeParts[2].split('.')[0]) : 0;
            final millisecond = timeParts.length > 2 && timeParts[2].contains('.')
                ? int.parse(timeParts[2].split('.')[1].padRight(3, '0').substring(0, 3))
                : 0;
            return DateTime(year, month, day, hour, minute, second, millisecond);
          }
        }
      }
      
      // Fallback: usar DateTime.parse (puede interpretar como UTC si no tiene zona horaria)
      final parsed = DateTime.parse(dateTimeStr);
      // Si no tiene zona horaria, asumir que es local
      return parsed.isUtc ? parsed.toLocal() : parsed;
    } catch (e) {
      debugPrint('⚠️ DatabaseHelper: Error parseando fecha: $dateTimeStr, usando DateTime.now()');
      return DateTime.now();
    }
  }

  Future<Database> _initDatabase() async {
    
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    

    // Tabla de ventas offline
    await db.execute('''
      CREATE TABLE $_ventasTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_id TEXT UNIQUE NOT NULL,
        cliente_id INTEGER NOT NULL,
        cliente_json TEXT NOT NULL,
        total REAL NOT NULL,
        fecha TEXT NOT NULL,
        metodo_pago INTEGER,
        usuario_id_creador INTEGER,
        usuario_creador_json TEXT,
        usuario_id_asignado INTEGER,
        usuario_asignado_json TEXT,
        estado_entrega INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        sync_attempts INTEGER NOT NULL DEFAULT 0,
        last_sync_attempt TEXT,
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabla de productos de ventas offline
    await db.execute('''
      CREATE TABLE $_productosTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_local_id TEXT NOT NULL,
        producto_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        marca TEXT,
        precio REAL NOT NULL,
        cantidad REAL NOT NULL,
        categoria TEXT NOT NULL,
        categoria_id INTEGER NOT NULL,
        precio_final_calculado REAL NOT NULL,
        entregado INTEGER NOT NULL DEFAULT 0,
        motivo TEXT,
        nota TEXT,
        fecha_chequeo TEXT,
        usuario_chequeo_id INTEGER,
        FOREIGN KEY (venta_local_id) REFERENCES $_ventasTable (local_id) ON DELETE CASCADE
      )
    ''');

    // Tabla de pagos de ventas offline
    await db.execute('''
      CREATE TABLE $_pagosTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_local_id TEXT NOT NULL,
        metodo INTEGER NOT NULL,
        monto REAL NOT NULL,
        FOREIGN KEY (venta_local_id) REFERENCES $_ventasTable (local_id) ON DELETE CASCADE
      )
    ''');

    // Tabla de entregas
    await db.execute('''
      CREATE TABLE $_entregasTable (
        id INTEGER PRIMARY KEY,
        venta_id INTEGER NOT NULL,
        cliente_id INTEGER NOT NULL,
        cliente_nombre TEXT NOT NULL,
        cliente_direccion TEXT,
        latitud REAL,
        longitud REAL,
        estado INTEGER NOT NULL DEFAULT 0,
        fecha_asignacion TEXT NOT NULL,
        fecha_entrega TEXT,
        repartidor_id INTEGER,
        orden INTEGER NOT NULL DEFAULT 0,
        notas TEXT,
        distancia_desde_ubicacion_actual REAL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        pendiente_sincronizar INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Índices para mejorar el rendimiento
    await db.execute('CREATE INDEX idx_venta_sync_status ON $_ventasTable(sync_status)');
    await db.execute('CREATE INDEX idx_venta_created_at ON $_ventasTable(created_at)');
    await db.execute('CREATE INDEX idx_productos_venta ON $_productosTable(venta_local_id)');
    await db.execute('CREATE INDEX idx_pagos_venta ON $_pagosTable(venta_local_id)');
    await db.execute('CREATE INDEX idx_entregas_fecha ON $_entregasTable(fecha_asignacion)');
    await db.execute('CREATE INDEX idx_entregas_repartidor ON $_entregasTable(repartidor_id)');
    await db.execute('CREATE INDEX idx_entregas_estado ON $_entregasTable(estado)');
    await db.execute('CREATE INDEX idx_entregas_sync ON $_entregasTable(pendiente_sincronizar)');

    
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    
    
    // Migración de v1 a v2: agregar tabla de entregas
    if (oldVersion < 2) {
      
      await db.execute('''
        CREATE TABLE $_entregasTable (
          id INTEGER PRIMARY KEY,
          venta_id INTEGER NOT NULL,
          cliente_id INTEGER NOT NULL,
          cliente_nombre TEXT NOT NULL,
          cliente_direccion TEXT,
          latitud REAL,
          longitud REAL,
          estado INTEGER NOT NULL DEFAULT 0,
          fecha_asignacion TEXT NOT NULL,
          fecha_entrega TEXT,
          repartidor_id INTEGER,
          orden INTEGER NOT NULL DEFAULT 0,
          notas TEXT,
          distancia_desde_ubicacion_actual REAL,
          sync_status TEXT NOT NULL DEFAULT 'synced',
          pendiente_sincronizar INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      await db.execute('CREATE INDEX idx_entregas_fecha ON $_entregasTable(fecha_asignacion)');
      await db.execute('CREATE INDEX idx_entregas_repartidor ON $_entregasTable(repartidor_id)');
      await db.execute('CREATE INDEX idx_entregas_estado ON $_entregasTable(estado)');
      await db.execute('CREATE INDEX idx_entregas_sync ON $_entregasTable(pendiente_sincronizar)');
      
      
    }
    
    // Migración de v2 a v3: dividir usuario en creador y asignado
    if (oldVersion < 3) {
      // Agregar nuevos campos
      await db.execute('ALTER TABLE $_ventasTable ADD COLUMN usuario_id_creador INTEGER');
      await db.execute('ALTER TABLE $_ventasTable ADD COLUMN usuario_creador_json TEXT');
      await db.execute('ALTER TABLE $_ventasTable ADD COLUMN usuario_id_asignado INTEGER');
      await db.execute('ALTER TABLE $_ventasTable ADD COLUMN usuario_asignado_json TEXT');
      
      // Migrar datos existentes: mover usuario_id/usuario_json a usuario_id_creador/usuario_creador_json
      await db.execute('''
        UPDATE $_ventasTable 
        SET usuario_id_creador = usuario_id, 
            usuario_creador_json = usuario_json
        WHERE usuario_id IS NOT NULL
      ''');
      
      // Eliminar columnas antiguas
      // Nota: SQLite no soporta DROP COLUMN directamente, pero como estamos 
      // en la v3 nueva, esto solo afecta a usuarios que ya tenían v2
      // Las nuevas instalaciones usarán el esquema correcto de v3 desde el inicio
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE $_productosTable ADD COLUMN marca TEXT');
    }
  }

  /// Guarda una venta offline
  Future<String> saveVentaOffline(Ventas venta) async {
    
    
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await db.transaction((txn) async {
        // Insertar venta
        await txn.insert(_ventasTable, {
          'local_id': localId,
          'cliente_id': venta.clienteId,
          'cliente_json': jsonEncode(venta.cliente.toJson()),
          'total': venta.total,
          // Guardar fecha en hora local (formato ISO sin zona horaria para preservar hora exacta)
          'fecha': formatDateTimeLocal(venta.fecha),
          'metodo_pago': venta.metodoPago?.index,
          'usuario_id_creador': venta.usuarioIdCreador,
          'usuario_creador_json': venta.usuarioCreador != null ? jsonEncode(venta.usuarioCreador!.toJson()) : null,
          'usuario_id_asignado': venta.usuarioIdAsignado,
          'usuario_asignado_json': venta.usuarioAsignado != null ? jsonEncode(venta.usuarioAsignado!.toJson()) : null,
          'estado_entrega': venta.estadoEntrega.toJson(),
          'sync_status': 'pending',
          'sync_attempts': 0,
          'created_at': now,
          'updated_at': now,
        });

        // Insertar productos
        for (var producto in venta.ventasProductos) {
          await txn.insert(_productosTable, {
            'venta_local_id': localId,
            'producto_id': producto.productoId,
            'nombre': producto.nombre,
            'marca': producto.marca,
            'precio': producto.precio,
            'cantidad': producto.cantidad,
            'categoria': producto.categoria,
            'categoria_id': producto.categoriaId,
            'precio_final_calculado': producto.precioFinalCalculado,
            'entregado': producto.entregado ? 1 : 0,
            'motivo': producto.motivo,
            'nota': producto.nota,
            'fecha_chequeo': producto.fechaChequeo?.toIso8601String(),
            'usuario_chequeo_id': producto.usuarioChequeoId,
          });
        }

        // Insertar pagos si existen
        if (venta.pagos != null) {
          for (var pago in venta.pagos!) {
            await txn.insert(_pagosTable, {
              'venta_local_id': localId,
              'metodo': pago.metodo.index,
              'monto': pago.monto,
            });
          }
        }
      });

      
      return localId;
    } catch (e) {
      
      rethrow;
    }
  }

  /// Obtiene todas las ventas offline pendientes de sincronización
  Future<List<Map<String, dynamic>>> getPendingVentas() async {
    try {
      final db = await database;
      
      // Verificar que la base de datos esté abierta
      if (!db.isOpen) {
        debugPrint('⚠️ DatabaseHelper: Base de datos cerrada al obtener ventas pendientes');
        return [];
      }
      
      final ventas = await db.query(
        _ventasTable,
        where: 'sync_status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
      );

      List<Map<String, dynamic>> result = [];

      for (var ventaRow in ventas) {
        try {
          final localId = ventaRow['local_id'] as String;
          
          // Obtener productos
          final productos = await db.query(
            _productosTable,
            where: 'venta_local_id = ?',
            whereArgs: [localId],
          );

          // Obtener pagos
          final pagos = await db.query(
            _pagosTable,
            where: 'venta_local_id = ?',
            whereArgs: [localId],
          );

          result.add({
            'venta': ventaRow,
            'productos': productos,
            'pagos': pagos,
          });
        } catch (e) {
          debugPrint('⚠️ DatabaseHelper: Error procesando venta pendiente: $e');
          // Continuar con la siguiente venta
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ DatabaseHelper: Error al obtener ventas pendientes: $e');
      return [];
    }
  }

  /// Obtiene todas las ventas offline (incluidas las sincronizadas)
  Future<List<Ventas>> getAllOfflineVentas() async {
    final db = await database;
    
    final ventas = await db.query(
      _ventasTable,
      orderBy: 'created_at DESC',
    );

    List<Ventas> result = [];

    for (var ventaRow in ventas) {
      final venta = await _buildVentaFromRow(ventaRow);
      result.add(venta);
    }

    return result;
  }

  /// Construye un objeto Ventas desde una fila de base de datos
  Future<Ventas> _buildVentaFromRow(Map<String, dynamic> ventaRow) async {
    final db = await database;
    final localId = ventaRow['local_id'] as String;

    // Obtener productos
    final productosRows = await db.query(
      _productosTable,
      where: 'venta_local_id = ?',
      whereArgs: [localId],
    );

    List<VentasProductos> productos = productosRows.map((p) => VentasProductos(
      productoId: p['producto_id'] as int,
      nombre: p['nombre'] as String,
      marca: p['marca'] as String?,
      precio: p['precio'] as double,
      cantidad: p['cantidad'] as double,
      categoria: p['categoria'] as String,
      categoriaId: p['categoria_id'] as int,
      precioFinalCalculado: p['precio_final_calculado'] as double,
      entregado: (p['entregado'] as int) == 1,
      motivo: p['motivo'] as String?,
      nota: p['nota'] as String?,
      fechaChequeo: p['fecha_chequeo'] != null ? DateTime.parse(p['fecha_chequeo'] as String) : null,
      usuarioChequeoId: p['usuario_chequeo_id'] as int?,
    )).toList();

    // Obtener pagos
    final pagosRows = await db.query(
      _pagosTable,
      where: 'venta_local_id = ?',
      whereArgs: [localId],
    );

    List<VentaPago>? pagos;
    if (pagosRows.isNotEmpty) {
      pagos = pagosRows.map((p) => VentaPago(
        id: p['id'] as int,
        ventaId: 0, // No tenemos el ID del servidor aún
        metodo: MetodoPago.values[p['metodo'] as int],
        monto: p['monto'] as double,
      )).toList();
    }

    // Construir cliente
    final clienteJson = jsonDecode(ventaRow['cliente_json'] as String);
    final cliente = Cliente.fromJson(clienteJson);

    // Construir usuario creador si existe
    User? usuarioCreador;
    if (ventaRow['usuario_creador_json'] != null) {
      final usuarioJson = jsonDecode(ventaRow['usuario_creador_json'] as String);
      usuarioCreador = User.fromJson(usuarioJson);
    }
    
    // Construir usuario asignado si existe
    User? usuarioAsignado;
    if (ventaRow['usuario_asignado_json'] != null) {
      final usuarioJson = jsonDecode(ventaRow['usuario_asignado_json'] as String);
      usuarioAsignado = User.fromJson(usuarioJson);
    }

    return Ventas(
      id: ventaRow['id'] as int?,
      clienteId: ventaRow['cliente_id'] as int,
      cliente: cliente,
      ventasProductos: productos,
      total: ventaRow['total'] as double,
      fecha: DateTime.parse(ventaRow['fecha'] as String),
      metodoPago: ventaRow['metodo_pago'] != null 
        ? MetodoPago.values[ventaRow['metodo_pago'] as int]
        : null,
      pagos: pagos,
      usuarioIdCreador: ventaRow['usuario_id_creador'] as int?,
      usuarioCreador: usuarioCreador,
      usuarioIdAsignado: ventaRow['usuario_id_asignado'] as int?,
      usuarioAsignado: usuarioAsignado,
      estadoEntrega: EstadoEntregaExtension.fromJson(ventaRow['estado_entrega'] as int),
    );
  }

  /// Marca una venta como sincronizada
  Future<void> markVentaAsSynced(String localId, int? serverId) async {
    final db = await database;
    
    await db.update(
      _ventasTable,
      {
        'sync_status': 'synced',
        'id': serverId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    
  }

  /// Marca una venta como fallida en la sincronización
  Future<void> markVentaAsSyncFailed(String localId, String errorMessage) async {
    final db = await database;
    
    final venta = await db.query(
      _ventasTable,
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );

    if (venta.isEmpty) return;

    final attempts = (venta.first['sync_attempts'] as int) + 1;

    await db.update(
      _ventasTable,
      {
        'sync_status': 'failed',
        'sync_attempts': attempts,
        'last_sync_attempt': DateTime.now().toIso8601String(),
        'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    
  }

  /// Reintentar sincronización de una venta fallida
  Future<void> retryVentaSync(String localId) async {
    final db = await database;
    
    await db.update(
      _ventasTable,
      {
        'sync_status': 'pending',
        'error_message': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    
  }

  /// Elimina una venta offline
  Future<void> deleteVentaOffline(String localId) async {
    final db = await database;
    
    await db.delete(
      _ventasTable,
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    
  }

  /// Limpia ventas sincronizadas antiguas (más de 30 días)
  /// CRÍTICO: Solo borra ventas que fueron realmente sincronizadas (sync_status = 'synced')
  /// y que tienen más de 30 días. NUNCA borra ventas pendientes o fallidas.
  Future<int> cleanOldSyncedVentas({int daysOld = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld)).toIso8601String();
    
    // CRÍTICO: Solo borrar ventas con sync_status = 'synced' y que tengan más de 30 días
    // NUNCA borrar ventas con sync_status = 'pending' o 'failed'
    final deleted = await db.delete(
      _ventasTable,
      where: 'sync_status = ? AND updated_at < ?',
      whereArgs: ['synced', cutoffDate],
    );

    debugPrint('🧹 DatabaseHelper: Limpiadas $deleted ventas sincronizadas antiguas (más de $daysOld días)');
    debugPrint('✅ DatabaseHelper: Las ventas pendientes y fallidas NO fueron borradas');
    
    return deleted;
  }

  /// Borra TODAS las ventas del caché SQLite (incluyendo productos y pagos)
  Future<void> borrarTodasLasVentas() async {
    final db = await database;
    
    try {
      await db.transaction((txn) async {
        // Borrar productos (se borran automáticamente por CASCADE, pero lo hacemos explícito)
        final productosBorrados = await txn.delete(_productosTable);
        debugPrint('🗑️ DatabaseHelper: $productosBorrados productos borrados');
        
        // Borrar pagos (se borran automáticamente por CASCADE, pero lo hacemos explícito)
        final pagosBorrados = await txn.delete(_pagosTable);
        debugPrint('🗑️ DatabaseHelper: $pagosBorrados pagos borrados');
        
        // Borrar todas las ventas
        final ventasBorradas = await txn.delete(_ventasTable);
        debugPrint('🗑️ DatabaseHelper: $ventasBorradas ventas borradas');
      });
      
      debugPrint('✅ DatabaseHelper: Todas las ventas borradas del caché SQLite');
    } catch (e) {
      debugPrint('❌ DatabaseHelper: Error al borrar ventas: $e');
      rethrow;
    }
  }

  /// Borra solo las ventas sincronizadas (sync_status = 'synced'), preservando las pendientes
  Future<void> borrarVentasSincronizadas() async {
    try {
      final db = await database;
      
      await db.transaction((txn) async {
        // Obtener las ventas sincronizadas que vamos a borrar
        final ventasSincronizadas = await txn.query(
          _ventasTable,
          where: 'sync_status = ?',
          whereArgs: ['synced'],
          columns: ['local_id'],
        );

        if (ventasSincronizadas.isEmpty) {
          debugPrint('📦 DatabaseHelper: No hay ventas sincronizadas para borrar');
          return;
        }

        final localIds = ventasSincronizadas.map((v) => v['local_id'] as String).toList();

        // Borrar productos de las ventas sincronizadas
        for (final localId in localIds) {
          await txn.delete(
            _productosTable,
            where: 'venta_local_id = ?',
            whereArgs: [localId],
          );
        }

        // Borrar pagos de las ventas sincronizadas
        for (final localId in localIds) {
          await txn.delete(
            _pagosTable,
            where: 'venta_local_id = ?',
            whereArgs: [localId],
          );
        }

        // Borrar las ventas sincronizadas
        final ventasBorradas = await txn.delete(
          _ventasTable,
          where: 'sync_status = ?',
          whereArgs: ['synced'],
        );
        
        debugPrint('🗑️ DatabaseHelper: $ventasBorradas ventas sincronizadas borradas (pendientes preservadas)');
      });
      
      debugPrint('✅ DatabaseHelper: Ventas sincronizadas borradas, pendientes preservadas');
    } catch (e) {
      debugPrint('❌ DatabaseHelper: Error al borrar ventas sincronizadas: $e');
      // Si la BD está cerrada, intentar reinicializar y continuar
      if (e.toString().contains('database_closed')) {
        try {
          _database = null;
          final db = await database;
          debugPrint('✅ DatabaseHelper: Base de datos reinicializada después del error');
        } catch (e2) {
          debugPrint('❌ DatabaseHelper: Error al reinicializar base de datos: $e2');
        }
      }
      // No rethrow, solo loguear el error para no romper el flujo
    }
  }

  /// Borra todas las ventas pendientes (sync_status = 'pending')
  /// Útil para limpiar ventas bugeadas que no se pueden sincronizar
  Future<int> borrarTodasLasVentasPendientes() async {
    try {
      final db = await database;
      int ventasBorradas = 0;
      
      await db.transaction((txn) async {
        // Obtener las ventas pendientes que vamos a borrar
        final ventasPendientes = await txn.query(
          _ventasTable,
          where: 'sync_status = ?',
          whereArgs: ['pending'],
          columns: ['local_id'],
        );

        if (ventasPendientes.isEmpty) {
          debugPrint('📦 DatabaseHelper: No hay ventas pendientes para borrar');
          return;
        }

        final localIds = ventasPendientes.map((v) => v['local_id'] as String).toList();
        debugPrint('🗑️ DatabaseHelper: Borrando ${localIds.length} ventas pendientes...');

        // Borrar productos de las ventas pendientes
        for (final localId in localIds) {
          await txn.delete(
            _productosTable,
            where: 'venta_local_id = ?',
            whereArgs: [localId],
          );
        }

        // Borrar pagos de las ventas pendientes
        for (final localId in localIds) {
          await txn.delete(
            _pagosTable,
            where: 'venta_local_id = ?',
            whereArgs: [localId],
          );
        }

        // Borrar las ventas pendientes
        ventasBorradas = await txn.delete(
          _ventasTable,
          where: 'sync_status = ?',
          whereArgs: ['pending'],
        );
        
        debugPrint('🗑️ DatabaseHelper: $ventasBorradas ventas pendientes borradas');
      });
      
      debugPrint('✅ DatabaseHelper: Todas las ventas pendientes borradas exitosamente');
      return ventasBorradas;
    } catch (e) {
      debugPrint('❌ DatabaseHelper: Error al borrar ventas pendientes: $e');
      // Si la BD está cerrada, intentar reinicializar y retornar 0
      if (e.toString().contains('database_closed')) {
        try {
          _database = null;
          await database;
          debugPrint('✅ DatabaseHelper: Base de datos reinicializada después del error');
        } catch (e2) {
          debugPrint('❌ DatabaseHelper: Error al reinicializar base de datos: $e2');
        }
        return 0;
      }
      rethrow;
    }
  }

  /// Obtiene estadísticas de la base de datos offline
  Future<Map<String, int>> getStats() async {
    try {
      final db = await database;
      
      // Verificar que la base de datos esté abierta
      if (!db.isOpen) {
        debugPrint('⚠️ DatabaseHelper: Base de datos cerrada al obtener stats');
        return {
          'pending': 0,
          'failed': 0,
          'synced': 0,
          'total': 0,
        };
      }
      
      final pending = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_ventasTable WHERE sync_status = ?', ['pending'])
      ) ?? 0;
      
      final failed = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_ventasTable WHERE sync_status = ?', ['failed'])
      ) ?? 0;
      
      final synced = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_ventasTable WHERE sync_status = ?', ['synced'])
      ) ?? 0;

      return {
        'pending': pending,
        'failed': failed,
        'synced': synced,
        'total': pending + failed + synced,
      };
    } catch (e) {
      debugPrint('❌ DatabaseHelper: Error al obtener stats: $e');
      return {
        'pending': 0,
        'failed': 0,
        'synced': 0,
        'total': 0,
      };
    }
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    
  }

  /// Resetea la base de datos (elimina y recrea)
  /// ADVERTENCIA: Esto eliminará todas las ventas offline pendientes
  Future<void> resetDatabase() async {
    
    
    try {
      // Cerrar la base de datos si está abierta
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Eliminar el archivo de base de datos
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      
      
      await deleteDatabase(path);
      
      // Reinicializar la base de datos (se crearán las tablas nuevamente)
      _database = await _initDatabase();
      
      
    } catch (e) {
      
      rethrow;
    }
  }

  /// Verifica si las tablas existen y las crea si faltan
  Future<void> ensureTablesExist() async {
    
    
    final db = await database;
    
    // Verificar si la tabla ventas_offline existe
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$_ventasTable'"
    );
    
    if (tables.isEmpty) {
      
      await resetDatabase();
    } else {
      
    }
  }

  // ==================== MÉTODOS PARA ENTREGAS ====================

  /// Inserta o actualiza una entrega en la base de datos local
  /// Preserva el estado local si la entrega ya fue marcada como completada
  /// IMPORTANTE: Si la entrega que se pasa ya tiene estado completado, preserva ese estado
  Future<void> insertarEntrega(Entrega entrega) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Verificar si la entrega ya existe
    final entregaExistente = await obtenerEntregaPorId(entrega.id!);
    
    // Determinar qué estado usar:
    // 1. Si la entrega que viene YA está completada, usar ese estado (fue preservado en el provider)
    // 2. Si existe localmente y está completada, preservar ese estado
    // 3. Si no existe o está pendiente, usar el estado de la entrega que viene
    final estadoFinal = entrega.estaCompletada 
        ? entrega.estado 
        : (entregaExistente?.estaCompletada == true 
            ? entregaExistente!.estado 
            : entrega.estado);
    
    final fechaEntregaFinal = entrega.estaCompletada && entrega.fechaEntrega != null
        ? entrega.fechaEntrega
        : (entregaExistente?.estaCompletada == true && entregaExistente?.fechaEntrega != null
            ? entregaExistente!.fechaEntrega
            : entrega.fechaEntrega);
    
    final notasFinales = entrega.estaCompletada && entrega.notas != null
        ? entrega.notas
        : (entregaExistente?.estaCompletada == true && entregaExistente?.notas != null
            ? entregaExistente!.notas
            : entrega.notas);
    
    await db.insert(
      _entregasTable,
      {
        'id': entrega.id,
        'venta_id': entrega.ventaId,
        'cliente_id': entrega.clienteId,
        'cliente_nombre': entrega.cliente.nombre,
        'cliente_direccion': entrega.cliente.direccion,
        'latitud': entrega.latitud,
        'longitud': entrega.longitud,
        'estado': estadoFinal.toJson(),
        'fecha_asignacion': entrega.fechaAsignacion.toIso8601String(),
        'fecha_entrega': fechaEntregaFinal?.toIso8601String(),
        'repartidor_id': entrega.repartidorId,
        'orden': entrega.orden,
        'notas': notasFinales,
        'distancia_desde_ubicacion_actual': entrega.distanciaDesdeUbicacionActual,
        'sync_status': entrega.estaCompletada && entregaExistente?.estaCompletada != true 
            ? 'pending' 
            : 'synced',
        'pendiente_sincronizar': entrega.estaCompletada && entregaExistente?.estaCompletada != true 
            ? 1 
            : 0,
        'created_at': entregaExistente != null ? now : now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene las entregas del día actual
  /// Incluye entregas asignadas hoy Y entregas completadas hoy (por fecha de entrega)
  /// [repartidorId] Si se proporciona, filtra las entregas por repartidor
  Future<List<Entrega>> obtenerEntregasDelDia({int? repartidorId}) async {
    final db = await database;
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
    final finDelDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59).toIso8601String();

    // Consulta que incluye:
    // 1. Entregas asignadas hoy (sin importar si están completadas o no)
    // 2. Entregas completadas hoy (por fecha de entrega)
    String whereClause = '(fecha_asignacion >= ? AND fecha_asignacion <= ?) OR (fecha_entrega >= ? AND fecha_entrega <= ?)';
    List<dynamic> whereArgs = [inicioDelDia, finDelDia, inicioDelDia, finDelDia];
    
    // Si se especifica un repartidor, filtrar por él
    if (repartidorId != null) {
      whereClause = '($whereClause) AND repartidor_id = ?';
      whereArgs.add(repartidorId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _entregasTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'orden ASC',
    );

    return List.generate(maps.length, (i) {
      return Entrega.fromMap(maps[i], clienteData: Cliente(
        id: maps[i]['cliente_id'],
        nombre: maps[i]['cliente_nombre'],
        direccion: maps[i]['cliente_direccion'],
      ));
    });
  }

  /// Obtiene una entrega por su ID
  Future<Entrega?> obtenerEntregaPorId(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _entregasTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return Entrega.fromMap(maps.first, clienteData: Cliente(
      id: maps.first['cliente_id'],
      nombre: maps.first['cliente_nombre'],
      direccion: maps.first['cliente_direccion'],
    ));
  }

  /// Elimina una entrega por su ID
  Future<void> eliminarEntregaPorId(int id) async {
    final db = await database;
    await db.delete(
      _entregasTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Actualiza el estado de una entrega
  Future<void> actualizarEstadoEntrega(int id, EstadoEntrega nuevoEstado) async {
    final db = await database;
    await db.update(
      _entregasTable,
      {
        'estado': nuevoEstado.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marca una entrega como completada
  Future<void> marcarEntregaComoEntregada(int id, String? notas) async {
    final db = await database;
    await db.update(
      _entregasTable,
      {
        'estado': EstadoEntrega.entregada.toJson(),
        'fecha_entrega': DateTime.now().toIso8601String(),
        'notas': notas,
        'pendiente_sincronizar': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marca una entrega para sincronizar con el servidor
  Future<void> marcarEntregaParaSincronizar(int id) async {
    final db = await database;
    await db.update(
      _entregasTable,
      {
        'pendiente_sincronizar': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marca una entrega como sincronizada
  Future<void> marcarEntregaSincronizada(int id) async {
    final db = await database;
    await db.update(
      _entregasTable,
      {
        'pendiente_sincronizar': 0,
        'sync_status': 'synced',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina todas las entregas del día actual (excepto las completadas localmente)
  /// Esto asegura que el cache esté sincronizado con el servidor
  Future<void> eliminarEntregasDelDia() async {
    final db = await database;
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
    final finDelDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59).toIso8601String();

    // Eliminar todas las entregas del día actual que no estén completadas o pendientes de sincronizar
    await db.delete(
      _entregasTable,
      where: 'fecha_asignacion >= ? AND fecha_asignacion <= ? AND estado != ? AND pendiente_sincronizar = ?',
      whereArgs: [inicioDelDia, finDelDia, EstadoEntrega.entregada.toJson(), 0],
    );
  }

  /// Obtiene las entregas pendientes de sincronizar
  Future<List<Entrega>> obtenerEntregasPendientesDeSincronizar() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _entregasTable,
      where: 'pendiente_sincronizar = ?',
      whereArgs: [1],
    );

    return List.generate(maps.length, (i) {
      return Entrega.fromMap(maps[i], clienteData: Cliente(
        id: maps[i]['cliente_id'],
        nombre: maps[i]['cliente_nombre'],
        direccion: maps[i]['cliente_direccion'],
      ));
    });
  }

  /// Actualiza las notas de una entrega
  Future<void> actualizarNotasEntrega(int id, String notas) async {
    final db = await database;
    await db.update(
      _entregasTable,
      {
        'notas': notas,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Actualiza el orden de las entregas
  Future<void> actualizarOrdenEntregas(List<Entrega> entregas) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var entrega in entregas) {
        await txn.update(
          _entregasTable,
          {
            'orden': entrega.orden,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [entrega.id],
        );
      }
    });
  }

  /// Elimina todas las entregas del día (útil para refrescar)
  Future<void> limpiarEntregasDelDia() async {
    final db = await database;
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
    final finDelDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59).toIso8601String();

    await db.delete(
      _entregasTable,
      where: 'fecha_asignacion >= ? AND fecha_asignacion <= ?',
      whereArgs: [inicioDelDia, finDelDia],
    );
  }
}

