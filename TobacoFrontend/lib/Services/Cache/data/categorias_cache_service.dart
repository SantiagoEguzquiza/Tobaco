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
        color_hex TEXT NOT NULL DEFAULT '#9E9E9E',
        sort_order INTEGER NOT NULL DEFAULT 0,
        activa INTEGER NOT NULL DEFAULT 1,
        cached_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_categorias_sort_order ON $_tableName(sort_order)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migraciones si es necesario
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
    if (items.isEmpty) return;

    final db = await database;
    final now = DateTime.now().toIso8601String();

    debugPrint('💾 CategoriasCacheService: Guardando ${items.length} categorías en caché...');

    await db.transaction((txn) async {
      // Limpiar caché anterior
      await txn.delete(_tableName);

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

    debugPrint('✅ CategoriasCacheService: Categorías guardadas en caché');
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
}
