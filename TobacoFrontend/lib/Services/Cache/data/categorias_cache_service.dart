import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../Models/Categoria.dart';
import '../core/cache_interface.dart';

/// Servicio de caché específico para Categorías
/// Gestiona únicamente la tabla de categorías
class CategoriasCacheService implements ICacheService<Categoria> {
  static final CategoriasCacheService _instance = CategoriasCacheService._internal();
  factory CategoriasCacheService() => _instance;
  CategoriasCacheService._internal();

  static Database? _database;
  static const String _databaseName = 'tobaco_cache.db';
  static const int _databaseVersion = 3;
  static const String _tableName = 'categorias_cache';

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
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        color_hex TEXT NOT NULL DEFAULT '#9E9E9E',
        sort_order INTEGER NOT NULL DEFAULT 0,
        activa INTEGER NOT NULL DEFAULT 1,
        cached_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_categorias_sort_order ON $_tableName(sort_order)');
    
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
        debugPrint('✅ CategoriasCacheService: Tabla cache_metadata creada');
      }
    } catch (e) {
      debugPrint('⚠️ CategoriasCacheService: Error verificando/creando cache_metadata: $e');
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
        debugPrint('❌ CategoriasCacheService: Error creando cache_metadata: $e2');
      }
    }
  }

  @override
  Future<List<Categoria>> getAll() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'activa = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC',
    );

    if (maps.isEmpty) {
      debugPrint('⚠️ CategoriasCacheService: No hay categorías en caché');
      return [];
    }

    debugPrint('📦 CategoriasCacheService: ${maps.length} categorías obtenidas de caché');

    return maps.map((map) {
      return Categoria(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
        colorHex: map['color_hex'] as String,
        sortOrder: map['sort_order'] as int,
      );
    }).toList();
  }

  @override
  Future<void> save(Categoria item) async {
    await saveAll([item]);
  }

  @override
  Future<void> saveAll(List<Categoria> items) async {
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

      // Insertar nuevas categorías
      for (var categoria in items) {
        await txn.insert(_tableName, {
          'id': categoria.id,
          'nombre': categoria.nombre,
          'color_hex': categoria.colorHex,
          'sort_order': categoria.sortOrder,
          'activa': 1,
          'cached_at': now,
          'updated_at': now,
        });
      }
    });

    if (items.isEmpty) {
      debugPrint('💾 CategoriasCacheService: Lista vacía, no se guardó nada');
    } else {
      debugPrint('✅ CategoriasCacheService: ${items.length} categorías guardadas en caché');
    }
  }

  @override
  Future<Categoria?> getById(dynamic id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return Categoria(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      colorHex: map['color_hex'] as String,
      sortOrder: map['sort_order'] as int,
    );
  }

  @override
  Future<bool> deleteById(dynamic id) async {
    final db = await database;
    
    final deleted = await db.update(
      _tableName,
      {'activa': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    return deleted > 0;
  }

  @override
  Future<void> clear() async {
    final db = await database;
    await db.delete(_tableName);
    debugPrint('🧹 CategoriasCacheService: Caché de categorías limpiado');
  }

  @override
  Future<bool> hasData() async {
    final itemCount = await count();
    return itemCount > 0;
  }

  @override
  Future<int> count() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE activa = ?', [1]);
    return Sqflite.firstIntValue(result) ?? 0;
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
    debugPrint('📝 CategoriasCacheService: Marcado como vacío');
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
    debugPrint('🧹 CategoriasCacheService: Marcador de vacío limpiado');
  }
}
