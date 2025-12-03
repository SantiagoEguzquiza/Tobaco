import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../Models/Cliente.dart';
import '../core/cache_interface.dart';

/// Servicio de caché específico para Clientes
/// Gestiona únicamente la tabla de clientes
class ClientesCacheService implements ICacheService<Cliente> {
  static final ClientesCacheService _instance = ClientesCacheService._internal();
  factory ClientesCacheService() => _instance;
  ClientesCacheService._internal();

  static Database? _database;
  static const String _databaseName = 'tobaco_cache.db';
  static const int _databaseVersion = 3;
  static const String _tableName = 'clientes_cache';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    final db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    // Asegurar que cache_metadata existe después de abrir la base de datos
    await _ensureCacheMetadataTable(db);
    
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        direccion TEXT,
        telefono TEXT,
        deuda TEXT,
        descuento_global REAL NOT NULL DEFAULT 0.0,
        precios_especiales_json TEXT,
        cached_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_clientes_nombre ON $_tableName(nombre)');
    
    // Crear tabla de metadatos si no existe
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache_metadata (
        entity_name TEXT PRIMARY KEY,
        is_empty INTEGER NOT NULL DEFAULT 0,
        marked_at TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Asegurar que la tabla cache_metadata existe
    await _ensureCacheMetadataTable(db);
    
    // Migraciones si es necesario
    if (oldVersion < 3) {
      // Agregar cualquier migración necesaria aquí
    }
  }

  /// Asegura que la tabla cache_metadata existe
  Future<void> _ensureCacheMetadataTable(Database db) async {
    try {
      // Verificar si la tabla existe
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='cache_metadata'"
      );
      
      if (result.isEmpty) {
        // Crear la tabla si no existe
        await db.execute('''
          CREATE TABLE cache_metadata (
            entity_name TEXT PRIMARY KEY,
            is_empty INTEGER NOT NULL DEFAULT 0,
            marked_at TEXT
          )
        ''');
        debugPrint('✅ ClientesCacheService: Tabla cache_metadata creada');
      }
    } catch (e) {
      debugPrint('⚠️ ClientesCacheService: Error verificando/creando cache_metadata: $e');
      // Intentar crear de todas formas
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cache_metadata (
            entity_name TEXT PRIMARY KEY,
            is_empty INTEGER NOT NULL DEFAULT 0,
            marked_at TEXT
          )
        ''');
      } catch (e2) {
        debugPrint('❌ ClientesCacheService: Error creando cache_metadata: $e2');
      }
    }
  }

  @override
  Future<List<Cliente>> getAll() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'nombre ASC',
    );

    if (maps.isEmpty) {
      debugPrint('⚠️ ClientesCacheService: No hay clientes en caché');
      return [];
    }

    debugPrint('📦 ClientesCacheService: ${maps.length} clientes obtenidos de caché');

    return maps.map((map) {
      return Cliente(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        direccion: map['direccion'] as String?,
        telefono: map['telefono'] != null 
          ? int.tryParse(map['telefono'] as String)
          : null,
        deuda: map['deuda'] as String?,
        descuentoGlobal: map['descuento_global'] as double,
        preciosEspeciales: [], // Se pueden cargar después si es necesario
      );
    }).toList();
  }

  @override
  Future<void> save(Cliente item) async {
    await saveAll([item]);
  }

  @override
  Future<void> saveAll(List<Cliente> items) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // Limpiar caché anterior
      await txn.delete(_tableName);
      
      // Limpiar marcador de vacío si hay datos
      if (items.isNotEmpty) {
        await txn.delete(
          'cache_metadata',
          where: 'entity_name = ?',
          whereArgs: [_tableName],
        );
      }

      // Insertar nuevos clientes
      for (var cliente in items) {
        await txn.insert(_tableName, {
          'id': cliente.id,
          'nombre': cliente.nombre,
          'direccion': cliente.direccion,
          'telefono': cliente.telefono?.toString(),
          'deuda': cliente.deuda,
          'descuento_global': cliente.descuentoGlobal,
          'precios_especiales_json': jsonEncode(
            cliente.preciosEspeciales.map((p) => p.toJson()).toList()
          ),
          'cached_at': now,
          'updated_at': now,
        });
      }
    });

    if (items.isEmpty) {
      debugPrint('💾 ClientesCacheService: Lista vacía, no se guardó nada');
    } else {
      debugPrint('✅ ClientesCacheService: ${items.length} clientes guardados en caché');
    }
  }

  @override
  Future<Cliente?> getById(dynamic id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return Cliente(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      direccion: map['direccion'] as String?,
      telefono: map['telefono'] != null 
        ? int.tryParse(map['telefono'] as String)
        : null,
      deuda: map['deuda'] as String?,
      descuentoGlobal: map['descuento_global'] as double,
      preciosEspeciales: [],
    );
  }

  @override
  Future<bool> deleteById(dynamic id) async {
    final db = await database;
    
    final deleted = await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    return deleted > 0;
  }

  @override
  Future<void> clear() async {
    final db = await database;
    await db.delete(_tableName);
    debugPrint('🧹 ClientesCacheService: Caché de clientes limpiado');
  }

  @override
  Future<bool> hasData() async {
    final itemCount = await count();
    return itemCount > 0;
  }

  @override
  Future<int> count() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Agrega o actualiza un cliente en caché
  Future<void> upsert(Cliente cliente) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      _tableName,
      {
        'id': cliente.id,
        'nombre': cliente.nombre,
        'direccion': cliente.direccion,
        'telefono': cliente.telefono?.toString(),
        'deuda': cliente.deuda,
        'descuento_global': cliente.descuentoGlobal,
        'precios_especiales_json': jsonEncode(
          cliente.preciosEspeciales.map((p) => p.toJson()).toList()
        ),
        'cached_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('✅ ClientesCacheService: Cliente ${cliente.nombre} actualizado en caché');
  }

  /// Busca clientes en caché por nombre
  Future<List<Cliente>> search(String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'nombre LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'nombre ASC',
    );

    debugPrint('🔍 ClientesCacheService: ${maps.length} clientes encontrados con query "$query"');

    return maps.map((map) {
      return Cliente(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        direccion: map['direccion'] as String?,
        telefono: map['telefono'] != null 
          ? int.tryParse(map['telefono'] as String)
          : null,
        deuda: map['deuda'] as String?,
        descuentoGlobal: map['descuento_global'] as double,
        preciosEspeciales: [],
      );
    }).toList();
  }

  @override
  Future<void> markAsEmpty() async {
    final db = await database;
    await db.insert(
      'cache_metadata',
      {
        'entity_name': _tableName,
        'is_empty': 1,
        'marked_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('📝 ClientesCacheService: Marcado como vacío');
  }

  @override
  Future<bool> isEmptyMarked() async {
    final db = await database;
    final result = await db.query(
      'cache_metadata',
      where: 'entity_name = ?',
      whereArgs: [_tableName],
      limit: 1,
    );
    if (result.isEmpty) return false;
    return (result.first['is_empty'] as int) == 1;
  }

  @override
  Future<void> clearEmptyMark() async {
    final db = await database;
    await db.delete(
      'cache_metadata',
      where: 'entity_name = ?',
      whereArgs: [_tableName],
    );
    debugPrint('🧹 ClientesCacheService: Marcador de vacío limpiado');
  }
}
