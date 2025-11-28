import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Helper genérico para acceso a SQLite
/// Solo proporciona operaciones CRUD básicas sin lógica de negocio
/// No conoce modelos concretos
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _databaseName = 'tobaco_offline.db';
  static const int _databaseVersion = 4;

  Future<Database> get database async {
    if (_database != null) {
      try {
        await _database!.rawQuery('SELECT 1');
        return _database!;
      } catch (e) {
        debugPrint('⚠️ DatabaseHelper: Base de datos cerrada, reinicializando...');
        _database = null;
      }
    }
    _database = await _initDatabase();
    return _database!;
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
      CREATE TABLE ventas_offline (
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
      CREATE TABLE ventas_productos_offline (
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
        FOREIGN KEY (venta_local_id) REFERENCES ventas_offline (local_id) ON DELETE CASCADE
      )
    ''');

    // Tabla de pagos de ventas offline
    await db.execute('''
      CREATE TABLE ventas_pagos_offline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_local_id TEXT NOT NULL,
        metodo INTEGER NOT NULL,
        monto REAL NOT NULL,
        FOREIGN KEY (venta_local_id) REFERENCES ventas_offline (local_id) ON DELETE CASCADE
      )
    ''');

    // Tabla de entregas
    await db.execute('''
      CREATE TABLE entregas_offline (
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

    // Índices
    await db.execute('CREATE INDEX idx_venta_sync_status ON ventas_offline(sync_status)');
    await db.execute('CREATE INDEX idx_venta_created_at ON ventas_offline(created_at)');
    await db.execute('CREATE INDEX idx_productos_venta ON ventas_productos_offline(venta_local_id)');
    await db.execute('CREATE INDEX idx_pagos_venta ON ventas_pagos_offline(venta_local_id)');
    await db.execute('CREATE INDEX idx_entregas_fecha ON entregas_offline(fecha_asignacion)');
    await db.execute('CREATE INDEX idx_entregas_repartidor ON entregas_offline(repartidor_id)');
    await db.execute('CREATE INDEX idx_entregas_estado ON entregas_offline(estado)');
    await db.execute('CREATE INDEX idx_entregas_sync ON entregas_offline(pendiente_sincronizar)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE entregas_offline (
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
      
      await db.execute('CREATE INDEX idx_entregas_fecha ON entregas_offline(fecha_asignacion)');
      await db.execute('CREATE INDEX idx_entregas_repartidor ON entregas_offline(repartidor_id)');
      await db.execute('CREATE INDEX idx_entregas_estado ON entregas_offline(estado)');
      await db.execute('CREATE INDEX idx_entregas_sync ON entregas_offline(pendiente_sincronizar)');
    }
    
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE ventas_offline ADD COLUMN usuario_id_creador INTEGER');
      await db.execute('ALTER TABLE ventas_offline ADD COLUMN usuario_creador_json TEXT');
      await db.execute('ALTER TABLE ventas_offline ADD COLUMN usuario_id_asignado INTEGER');
      await db.execute('ALTER TABLE ventas_offline ADD COLUMN usuario_asignado_json TEXT');
      
      await db.execute('''
        UPDATE ventas_offline 
        SET usuario_id_creador = usuario_id, 
            usuario_creador_json = usuario_json
        WHERE usuario_id IS NOT NULL
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE ventas_productos_offline ADD COLUMN marca TEXT');
    }
  }

  /// Métodos genéricos de acceso a datos (sin lógica de negocio)

  /// Ejecuta una query genérica
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Inserta un registro genérico
  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await database;
    return db.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Actualiza registros genéricos
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await database;
    return db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Elimina registros genéricos
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// Ejecuta una transacción
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  /// Ejecuta una query SQL raw
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  /// Ejecuta un comando SQL raw
  Future<int> rawUpdate(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return db.rawUpdate(sql, arguments);
  }

  /// Ejecuta un comando SQL raw (INSERT, UPDATE, DELETE, etc.)
  Future<void> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  /// Cierra la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('🗄️ DatabaseHelper: Base de datos cerrada');
    }
  }

  /// Verifica si las tablas existen y las crea si faltan
  Future<void> ensureTablesExist() async {
    final db = await database;
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='ventas_offline'"
    );
    
    if (tables.isEmpty) {
      debugPrint('⚠️ DatabaseHelper: Tablas no existen, recreando...');
      await resetDatabase();
    }
  }

  /// Resetea la base de datos (elimina y recrea)
  Future<void> resetDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      await deleteDatabase(path);
      
      _database = await _initDatabase();
      debugPrint('✅ DatabaseHelper: Base de datos reseteada correctamente');
    } catch (e) {
      debugPrint('❌ DatabaseHelper: Error reseteando base de datos: $e');
      rethrow;
    }
  }

  /// Formatea una fecha en hora local sin conversión a UTC
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
      if (dateTimeStr.endsWith('Z') || dateTimeStr.contains('+') || 
          (dateTimeStr.contains('-') && dateTimeStr.length > 19 && 
           dateTimeStr.substring(19).contains('-'))) {
        return DateTime.parse(dateTimeStr).toLocal();
      }
      
      if (dateTimeStr.contains(' ')) {
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
      
      final parsed = DateTime.parse(dateTimeStr);
      return parsed.isUtc ? parsed.toLocal() : parsed;
    } catch (e) {
      debugPrint('⚠️ DatabaseHelper: Error parseando fecha: $dateTimeStr, usando DateTime.now()');
      return DateTime.now();
    }
  }
}
