import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../Models/Ventas.dart';
import '../../Models/VentasProductos.dart';
import '../../Models/Cliente.dart';
import '../../Models/ventasPago.dart';
import '../../Models/metodoPago.dart';
import '../../Models/EstadoEntrega.dart';
import '../../Models/User.dart';

/// Helper para la base de datos SQLite local
/// Maneja el almacenamiento offline de ventas pendientes de sincronización
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _databaseName = 'tobaco_offline.db';
  static const int _databaseVersion = 1;

  // Nombres de tablas
  static const String _ventasTable = 'ventas_offline';
  static const String _productosTable = 'ventas_productos_offline';
  static const String _pagosTable = 'ventas_pagos_offline';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('📦 DatabaseHelper: Inicializando base de datos...');
    
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
    print('📦 DatabaseHelper: Creando tablas...');

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
        usuario_id INTEGER,
        usuario_json TEXT,
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

    // Índices para mejorar el rendimiento
    await db.execute('CREATE INDEX idx_venta_sync_status ON $_ventasTable(sync_status)');
    await db.execute('CREATE INDEX idx_venta_created_at ON $_ventasTable(created_at)');
    await db.execute('CREATE INDEX idx_productos_venta ON $_productosTable(venta_local_id)');
    await db.execute('CREATE INDEX idx_pagos_venta ON $_pagosTable(venta_local_id)');

    print('✅ DatabaseHelper: Tablas creadas correctamente');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('📦 DatabaseHelper: Actualizando base de datos de v$oldVersion a v$newVersion');
    // Aquí puedes agregar migraciones futuras
  }

  /// Guarda una venta offline
  Future<String> saveVentaOffline(Ventas venta) async {
    print('💾 DatabaseHelper: Guardando venta offline...');
    
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
          'fecha': venta.fecha.toIso8601String(),
          'metodo_pago': venta.metodoPago?.index,
          'usuario_id': venta.usuarioId,
          'usuario_json': venta.usuario != null ? jsonEncode(venta.usuario!.toJson()) : null,
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

      print('✅ DatabaseHelper: Venta offline guardada con ID: $localId');
      return localId;
    } catch (e) {
      print('❌ DatabaseHelper: Error guardando venta offline: $e');
      rethrow;
    }
  }

  /// Obtiene todas las ventas offline pendientes de sincronización
  Future<List<Map<String, dynamic>>> getPendingVentas() async {
    final db = await database;
    
    final ventas = await db.query(
      _ventasTable,
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );

    List<Map<String, dynamic>> result = [];

    for (var ventaRow in ventas) {
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
    }

    print('📋 DatabaseHelper: ${result.length} ventas pendientes de sincronización');
    return result;
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

    // Construir usuario si existe
    User? usuario;
    if (ventaRow['usuario_json'] != null) {
      final usuarioJson = jsonDecode(ventaRow['usuario_json'] as String);
      usuario = User.fromJson(usuarioJson);
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
      usuarioId: ventaRow['usuario_id'] as int?,
      usuario: usuario,
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

    print('✅ DatabaseHelper: Venta $localId marcada como sincronizada (ID servidor: $serverId)');
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

    print('⚠️ DatabaseHelper: Venta $localId marcada como fallida (intento $attempts): $errorMessage');
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

    print('🔄 DatabaseHelper: Venta $localId marcada para reintentar sincronización');
  }

  /// Elimina una venta offline
  Future<void> deleteVentaOffline(String localId) async {
    final db = await database;
    
    await db.delete(
      _ventasTable,
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    print('🗑️ DatabaseHelper: Venta offline $localId eliminada');
  }

  /// Limpia ventas sincronizadas antiguas (más de 30 días)
  Future<int> cleanOldSyncedVentas({int daysOld = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld)).toIso8601String();
    
    final deleted = await db.delete(
      _ventasTable,
      where: 'sync_status = ? AND updated_at < ?',
      whereArgs: ['synced', cutoffDate],
    );

    print('🧹 DatabaseHelper: $deleted ventas antiguas eliminadas');
    return deleted;
  }

  /// Obtiene estadísticas de la base de datos offline
  Future<Map<String, int>> getStats() async {
    final db = await database;
    
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
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('📦 DatabaseHelper: Base de datos cerrada');
  }

  /// Resetea la base de datos (elimina y recrea)
  /// ADVERTENCIA: Esto eliminará todas las ventas offline pendientes
  Future<void> resetDatabase() async {
    print('⚠️ DatabaseHelper: Reseteando base de datos...');
    
    try {
      // Cerrar la base de datos si está abierta
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Eliminar el archivo de base de datos
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      
      print('🗑️ DatabaseHelper: Eliminando base de datos en: $path');
      await deleteDatabase(path);
      
      // Reinicializar la base de datos (se crearán las tablas nuevamente)
      _database = await _initDatabase();
      
      print('✅ DatabaseHelper: Base de datos reseteada correctamente');
    } catch (e) {
      print('❌ DatabaseHelper: Error reseteando base de datos: $e');
      rethrow;
    }
  }

  /// Verifica si las tablas existen y las crea si faltan
  Future<void> ensureTablesExist() async {
    print('🔍 DatabaseHelper: Verificando tablas...');
    
    final db = await database;
    
    // Verificar si la tabla ventas_offline existe
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$_ventasTable'"
    );
    
    if (tables.isEmpty) {
      print('⚠️ DatabaseHelper: Tabla $_ventasTable no existe, recreando base de datos...');
      await resetDatabase();
    } else {
      print('✅ DatabaseHelper: Tablas existen correctamente');
    }
  }
}

