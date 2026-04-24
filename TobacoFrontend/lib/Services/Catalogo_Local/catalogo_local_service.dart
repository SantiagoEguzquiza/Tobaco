import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../Models/Cliente.dart';
import '../../Models/Producto.dart';
import '../../Models/Categoria.dart';

/// Almacenamiento local (SQLite) para catálogo: clientes, productos, categorías y precios especiales.
/// No es una capa de caché; es la fuente local para modo offline.
class CatalogoLocalService {
  static final CatalogoLocalService _instance = CatalogoLocalService._internal();
  factory CatalogoLocalService() => _instance;
  CatalogoLocalService._internal();

  static Database? _database;
  static const String _databaseName = 'tobaco_catalogo.db';
  static const int _databaseVersion = 1;

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
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de clientes
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY,
        cliente_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabla de productos
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY,
        producto_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabla de categorías
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY,
        categoria_json TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabla de precios especiales por cliente
    await db.execute('''
      CREATE TABLE precios_especiales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        precios_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // ===== Clientes =====
  Future<void> guardarClientes(List<Cliente> clientes) async {
    if (clientes.isEmpty) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('clientes');
      for (final c in clientes) {
        await txn.insert('clientes', {
          'id': c.id,
          'cliente_json': jsonEncode(c.toJson()),
          'updated_at': now,
        });
      }
    });
  }

  Future<List<Cliente>> obtenerClientes() async {
    final db = await database;
    final rows = await db.query('clientes');
    return rows.map((r) => Cliente.fromJson(jsonDecode(r['cliente_json'] as String))).toList();
  }

  /// Limpia la tabla de clientes (para evitar mostrar datos de otro tenant al cambiar de usuario).
  Future<void> limpiarClientes() async {
    final db = await database;
    await db.delete('clientes');
  }

  // ===== Productos =====
  Future<void> guardarProductos(List<Producto> productos) async {
    final db = await database;
    await db.transaction((txn) async {
      // Limpiar caché anterior (siempre, incluso si está vacío)
      await txn.delete('productos');
      
      if (productos.isEmpty) {
        print('💾 CatalogoLocalService: Lista vacía recibida, caché limpiado');
        return;
      }
      
      // Guardar cada producto
      final now = DateTime.now().toIso8601String();
      for (final p in productos) {
        await txn.insert('productos', {
          'id': p.id,
          'producto_json': jsonEncode(p.toJson()),
          'updated_at': now,
        });
      }
    });
    
    if (productos.isEmpty) {
      print('✅ CatalogoLocalService: Caché limpiado (servidor devolvió lista vacía)');
    } else {
      print('✅ CatalogoLocalService: ${productos.length} productos guardados');
    }
  }

  Future<List<Producto>> obtenerProductos() async {
    final db = await database;
    final rows = await db.query('productos');
    return rows.map((r) => Producto.fromJson(jsonDecode(r['producto_json'] as String))).toList();
  }

  /// Limpia la tabla de productos (para evitar mostrar datos de otro tenant al cambiar de usuario).
  Future<void> limpiarProductos() async {
    final db = await database;
    await db.delete('productos');
  }

  /// Limpia la tabla de categorías (para evitar mostrar datos de otro tenant al cambiar de usuario).
  Future<void> limpiarCategorias() async {
    final db = await database;
    await db.delete('categorias');
  }

  Future<List<Producto>> obtenerProductosPorCategoria(int categoriaId) async {
    final db = await database;
    final rows = await db.query('productos');
    final productos = rows.map((r) => Producto.fromJson(jsonDecode(r['producto_json'] as String))).toList();
    return productos.where((p) => p.categoriaId == categoriaId).toList();
  }

  // ===== Categorías =====
  Future<void> guardarCategorias(List<Categoria> categorias) async {
    if (categorias.isEmpty) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('categorias');
      for (final cat in categorias) {
        await txn.insert('categorias', {
          'id': cat.id,
          'categoria_json': jsonEncode(cat.toJson()),
          'sort_order': cat.sortOrder,
          'updated_at': now,
        });
      }
    });
  }

  Future<List<Categoria>> obtenerCategorias() async {
    final db = await database;
    final rows = await db.query('categorias', orderBy: 'sort_order ASC');
    return rows.map((r) {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(jsonDecode(r['categoria_json'] as String));
      if (!data.containsKey('id') || data['id'] == null) {
        data['id'] = r['id'];
      }
      if (!data.containsKey('sortOrder') || data['sortOrder'] == null) {
        data['sortOrder'] = r['sort_order'];
      }
      return Categoria.fromJson(data);
    }).toList();
  }

  // ===== Precios Especiales =====
  Future<void> guardarPreciosEspeciales(int clienteId, List<dynamic> precios) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.delete('precios_especiales', where: 'cliente_id = ?', whereArgs: [clienteId]);
    await db.insert('precios_especiales', {
      'cliente_id': clienteId,
      'precios_json': jsonEncode(precios),
      'updated_at': now,
    });
  }

  Future<List<dynamic>> obtenerPreciosEspeciales(int clienteId) async {
    final db = await database;
    final rows = await db.query('precios_especiales', where: 'cliente_id = ?', whereArgs: [clienteId], limit: 1);
    if (rows.isEmpty) return [];
    return jsonDecode(rows.first['precios_json'] as String) as List<dynamic>;
  }
}


