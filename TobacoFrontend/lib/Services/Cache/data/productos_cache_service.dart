import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../Models/Producto.dart';
import '../core/cache_interface.dart';

/// Servicio de caché específico para Productos
/// Gestiona únicamente la tabla de productos
class ProductosCacheService implements ICacheService<Producto> {
  static final ProductosCacheService _instance = ProductosCacheService._internal();
  factory ProductosCacheService() => _instance;
  ProductosCacheService._internal();

  static Database? _database;
  static const String _databaseName = 'tobaco_cache.db';
  static const int _databaseVersion = 3;
  static const String _tableName = 'productos_cache';

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
        precio REAL NOT NULL,
        stock REAL,
        categoria_id INTEGER NOT NULL,
        categoria_nombre TEXT,
        half INTEGER NOT NULL DEFAULT 0,
        codigo_barras TEXT,
        imagen_url TEXT,
        activo INTEGER NOT NULL DEFAULT 1,
        cached_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_productos_nombre ON $_tableName(nombre)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_productos_categoria ON $_tableName(categoria_id)');
    
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
        debugPrint('✅ ProductosCacheService: Tabla cache_metadata creada');
      }
    } catch (e) {
      debugPrint('⚠️ ProductosCacheService: Error verificando/creando cache_metadata: $e');
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
        debugPrint('❌ ProductosCacheService: Error creando cache_metadata: $e2');
      }
    }
  }

  @override
  Future<List<Producto>> getAll() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'activo = ?',
      whereArgs: [1],
      orderBy: 'nombre ASC',
    );

    if (maps.isEmpty) {
      debugPrint('⚠️ ProductosCacheService: No hay productos en caché');
      return [];
    }

    debugPrint('📦 ProductosCacheService: ${maps.length} productos obtenidos de caché');

    return maps.map((map) {
      return Producto(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
        precio: map['precio'] as double,
        stock: map['stock'] as double?,
        categoriaId: map['categoria_id'] as int,
        categoriaNombre: map['categoria_nombre'] as String? ?? '',
        half: (map['half'] as int) == 1,
        isActive: (map['activo'] as int) == 1,
      );
    }).toList();
  }

  @override
  Future<void> save(Producto item) async {
    await saveAll([item]);
  }

  @override
  Future<void> saveAll(List<Producto> items) async {
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

      // Insertar nuevos productos
      for (var producto in items) {
        await txn.insert(_tableName, {
          'id': producto.id,
          'nombre': producto.nombre,
          'precio': producto.precio,
          'stock': producto.stock,
          'categoria_id': producto.categoriaId,
          'categoria_nombre': producto.categoriaNombre,
          'half': producto.half ? 1 : 0,
          'activo': producto.isActive ? 1 : 0,
          'cached_at': now,
          'updated_at': now,
        });
      }
    });

    if (items.isEmpty) {
      debugPrint('💾 ProductosCacheService: Lista vacía, no se guardó nada');
    } else {
      debugPrint('✅ ProductosCacheService: ${items.length} productos guardados en caché');
    }
  }

  @override
  Future<Producto?> getById(dynamic id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return Producto(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      precio: map['precio'] as double,
      stock: map['stock'] as double?,
      categoriaId: map['categoria_id'] as int,
      categoriaNombre: map['categoria_nombre'] as String? ?? '',
      half: (map['half'] as int) == 1,
      isActive: (map['activo'] as int) == 1,
    );
  }

  @override
  Future<bool> deleteById(dynamic id) async {
    final db = await database;
    
    final deleted = await db.update(
      _tableName,
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    return deleted > 0;
  }

  @override
  Future<void> clear() async {
    final db = await database;
    await db.delete(_tableName);
    debugPrint('🧹 ProductosCacheService: Caché de productos limpiado');
  }

  @override
  Future<bool> hasData() async {
    final itemCount = await count();
    return itemCount > 0;
  }

  @override
  Future<int> count() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName WHERE activo = ?', [1]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Agrega o actualiza un producto en caché
  Future<void> upsert(Producto producto) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      _tableName,
      {
        'id': producto.id,
        'nombre': producto.nombre,
        'precio': producto.precio,
        'stock': producto.stock,
        'categoria_id': producto.categoriaId,
        'categoria_nombre': producto.categoriaNombre,
        'half': producto.half ? 1 : 0,
        'activo': producto.isActive ? 1 : 0,
        'cached_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('✅ ProductosCacheService: Producto ${producto.nombre} actualizado en caché');
  }

  /// Obtiene productos por categoría
  Future<List<Producto>> getByCategoria(int categoriaId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'categoria_id = ? AND activo = ?',
      whereArgs: [categoriaId, 1],
      orderBy: 'nombre ASC',
    );

    return maps.map((map) {
      return Producto(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
        precio: map['precio'] as double,
        stock: map['stock'] as double?,
        categoriaId: map['categoria_id'] as int,
        categoriaNombre: map['categoria_nombre'] as String? ?? '',
        half: (map['half'] as int) == 1,
        isActive: (map['activo'] as int) == 1,
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
    debugPrint('📝 ProductosCacheService: Marcado como vacío');
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
    debugPrint('🧹 ProductosCacheService: Marcador de vacío limpiado');
  }
}
