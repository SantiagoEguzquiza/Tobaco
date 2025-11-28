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

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migraciones si es necesario
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
    if (items.isEmpty) return;

    final db = await database;
    final now = DateTime.now().toIso8601String();

    debugPrint('💾 ProductosCacheService: Guardando ${items.length} productos en caché...');

    await db.transaction((txn) async {
      // Limpiar caché anterior
      await txn.delete(_tableName);

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

    debugPrint('✅ ProductosCacheService: Productos guardados en caché');
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
}
