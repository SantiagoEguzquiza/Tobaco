import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../Models/Cliente.dart';
import '../../Models/Producto.dart';
import '../../Models/Categoria.dart';

/// Servicio de caché para Clientes y Productos
/// Permite crear ventas offline con datos guardados previamente
class DatosCacheService {
  static final DatosCacheService _instance = DatosCacheService._internal();
  factory DatosCacheService() => _instance;
  DatosCacheService._internal();

  static Database? _database;
  static const String _databaseName = 'datos_cache.db';
  static const int _databaseVersion = 3; // Incrementado para agregar tabla de precios especiales

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('💾 DatosCacheService: Inicializando base de datos...');
    
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
    print('💾 DatosCacheService: Creando tablas...');

    // Tabla de clientes
    await db.execute('''
      CREATE TABLE clientes_cache (
        id INTEGER PRIMARY KEY,
        cliente_json TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Tabla de productos
    await db.execute('''
      CREATE TABLE productos_cache (
        id INTEGER PRIMARY KEY,
        producto_json TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Tabla de categorías
    await db.execute('''
      CREATE TABLE categorias_cache (
        id INTEGER PRIMARY KEY,
        categoria_json TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Tabla de precios especiales
    await db.execute('''
      CREATE TABLE precios_especiales_cache (
        id INTEGER PRIMARY KEY,
        cliente_id INTEGER NOT NULL,
        precios_json TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    print('✅ DatosCacheService: Tablas creadas correctamente');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 DatosCacheService: Actualizando BD de v$oldVersion a v$newVersion');
    
    // Si está actualizando de v1 a v2, crear tabla de categorías
    if (oldVersion < 2) {
      print('➕ DatosCacheService: Creando tabla categorias_cache...');
      await db.execute('''
        CREATE TABLE categorias_cache (
          id INTEGER PRIMARY KEY,
          categoria_json TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
      print('✅ DatosCacheService: Tabla categorias_cache creada');
    }
    
    // Si está actualizando de v2 a v3, crear tabla de precios especiales
    if (oldVersion < 3) {
      print('➕ DatosCacheService: Creando tabla precios_especiales_cache...');
      await db.execute('''
        CREATE TABLE precios_especiales_cache (
          id INTEGER PRIMARY KEY,
          cliente_id INTEGER NOT NULL,
          precios_json TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
      print('✅ DatosCacheService: Tabla precios_especiales_cache creada');
    }
  }

  // ==================== CLIENTES ====================

  /// Guarda clientes en caché
  /// Si la lista está vacía, limpia el caché para mantener sincronización con el servidor
  Future<void> guardarClientesEnCache(List<Cliente> clientes) async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        // Limpiar caché anterior (siempre, incluso si está vacío)
        await txn.delete('clientes_cache');

        if (clientes.isEmpty) {
          print('💾 DatosCacheService: Lista vacía recibida, caché limpiado');
          return;
        }

        // Guardar cada cliente como JSON
        final now = DateTime.now().toIso8601String();
        for (var cliente in clientes) {
          await txn.insert('clientes_cache', {
            'id': cliente.id,
            'cliente_json': jsonEncode(cliente.toJson()),
            'cached_at': now,
          });
        }
      });

      if (clientes.isEmpty) {
        print('✅ DatosCacheService: Caché limpiado (servidor devolvió lista vacía)');
      } else {
        print('✅ DatosCacheService: ${clientes.length} clientes guardados en caché');
      }
    } catch (e) {
      print('❌ DatosCacheService: Error guardando clientes: $e');
    }
  }

  /// Obtiene clientes del caché
  Future<List<Cliente>> obtenerClientesDelCache() async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'clientes_cache',
        orderBy: 'cliente_json DESC',
      );

      if (maps.isEmpty) {
        print('📦 DatosCacheService: No hay clientes en caché');
        return [];
      }

      List<Cliente> clientes = [];
      for (var map in maps) {
        try {
          final clienteJson = jsonDecode(map['cliente_json'] as String);
          clientes.add(Cliente.fromJson(clienteJson));
        } catch (e) {
          print('⚠️ DatosCacheService: Error parseando cliente ${map['id']}: $e');
        }
      }

      print('✅ DatosCacheService: ${clientes.length} clientes obtenidos del caché');
      return clientes;
    } catch (e) {
      print('❌ DatosCacheService: Error obteniendo clientes del caché: $e');
      return [];
    }
  }

  // ==================== PRODUCTOS ====================

  /// Guarda productos en caché
  /// Si la lista está vacía, limpia el caché para mantener sincronización con el servidor
  Future<void> guardarProductosEnCache(List<Producto> productos) async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        // Limpiar caché anterior (siempre, incluso si está vacío)
        await txn.delete('productos_cache');

        if (productos.isEmpty) {
          print('💾 DatosCacheService: Lista vacía recibida, caché limpiado');
          return;
        }

        // Guardar cada producto como JSON
        final now = DateTime.now().toIso8601String();
        for (var producto in productos) {
          await txn.insert('productos_cache', {
            'id': producto.id,
            'producto_json': jsonEncode(producto.toJson()),
            'cached_at': now,
          });
        }
      });

      if (productos.isEmpty) {
        print('✅ DatosCacheService: Caché limpiado (servidor devolvió lista vacía)');
      } else {
        print('✅ DatosCacheService: ${productos.length} productos guardados en caché');
      }
    } catch (e) {
      print('❌ DatosCacheService: Error guardando productos: $e');
    }
  }

  /// Obtiene productos del caché
  Future<List<Producto>> obtenerProductosDelCache() async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'productos_cache',
        orderBy: 'producto_json DESC',
      );

      if (maps.isEmpty) {
        print('📦 DatosCacheService: No hay productos en caché');
        return [];
      }

      List<Producto> productos = [];
      for (var map in maps) {
        try {
          final productoJson = jsonDecode(map['producto_json'] as String);
          productos.add(Producto.fromJson(productoJson));
        } catch (e) {
          print('⚠️ DatosCacheService: Error parseando producto ${map['id']}: $e');
        }
      }

      print('✅ DatosCacheService: ${productos.length} productos obtenidos del caché');
      return productos;
    } catch (e) {
      print('❌ DatosCacheService: Error obteniendo productos del caché: $e');
      return [];
    }
  }

  // ==================== CATEGORÍAS ====================

  /// Guarda categorías en caché
  Future<void> guardarCategoriasEnCache(List<Categoria> categorias) async {
    if (categorias.isEmpty) {
      print('💾 DatosCacheService: No hay categorías para guardar');
      return;
    }

    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        // Limpiar caché anterior
        await txn.delete('categorias_cache');

        // Guardar cada categoría como JSON
        for (var categoria in categorias) {
          await txn.insert('categorias_cache', {
            'id': categoria.id,
            'categoria_json': jsonEncode(categoria.toJson()),
            'cached_at': now,
          });
        }
      });

      print('✅ DatosCacheService: ${categorias.length} categorías guardadas en caché');
    } catch (e) {
      print('❌ DatosCacheService: Error guardando categorías: $e');
    }
  }

  /// Obtiene categorías del caché
  Future<List<Categoria>> obtenerCategoriasDelCache() async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'categorias_cache',
        orderBy: 'id ASC',
      );

      if (maps.isEmpty) {
        print('📦 DatosCacheService: No hay categorías en caché');
        return [];
      }

      List<Categoria> categorias = [];
      for (var map in maps) {
        try {
          final categoriaJson = jsonDecode(map['categoria_json'] as String);
          categorias.add(Categoria.fromJson(categoriaJson));
        } catch (e) {
          print('⚠️ DatosCacheService: Error parseando categoría ${map['id']}: $e');
        }
      }

      print('✅ DatosCacheService: ${categorias.length} categorías obtenidas del caché');
      return categorias;
    } catch (e) {
      print('❌ DatosCacheService: Error obteniendo categorías del caché: $e');
      return [];
    }
  }

  // ==================== PRECIOS ESPECIALES ====================

  /// Guarda precios especiales de un cliente en caché
  Future<void> guardarPreciosEspecialesEnCache(int clienteId, List<dynamic> preciosEspeciales) async {
    if (preciosEspeciales.isEmpty) {
      print('💾 DatosCacheService: No hay precios especiales para guardar para cliente $clienteId');
      return;
    }

    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      
      // Eliminar precios existentes del cliente
      await db.delete(
        'precios_especiales_cache',
        where: 'cliente_id = ?',
        whereArgs: [clienteId],
      );
      
      // Insertar nuevos precios
      await db.insert('precios_especiales_cache', {
        'cliente_id': clienteId,
        'precios_json': jsonEncode(preciosEspeciales),
        'cached_at': now,
      });
      
      print('✅ DatosCacheService: ${preciosEspeciales.length} precios especiales guardados en caché para cliente $clienteId');
    } catch (e) {
      print('❌ DatosCacheService: Error guardando precios especiales en caché: $e');
    }
  }

  /// Obtiene precios especiales de un cliente del caché
  Future<List<dynamic>> obtenerPreciosEspecialesDelCache(int clienteId) async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> result = await db.query(
        'precios_especiales_cache',
        where: 'cliente_id = ?',
        whereArgs: [clienteId],
        limit: 1,
      );
      
      if (result.isEmpty) {
        print('📦 DatosCacheService: No hay precios especiales en caché para cliente $clienteId');
        return [];
      }
      
      final preciosJson = result.first['precios_json'] as String;
      final List<dynamic> precios = jsonDecode(preciosJson);
      
      print('✅ DatosCacheService: ${precios.length} precios especiales obtenidos del caché para cliente $clienteId');
      return precios;
    } catch (e) {
      print('❌ DatosCacheService: Error obteniendo precios especiales del caché: $e');
      return [];
    }
  }

  // ==================== UTILIDADES ====================

  /// Limpia todo el caché
  Future<void> limpiarCache() async {
    try {
      final db = await database;
      await db.delete('clientes_cache');
      await db.delete('productos_cache');
      await db.delete('categorias_cache');
      await db.delete('precios_especiales_cache');
      print('🧹 DatosCacheService: Caché limpiado');
    } catch (e) {
      print('❌ DatosCacheService: Error limpiando caché: $e');
    }
  }

  /// Verifica cuántos registros hay en caché
  Future<Map<String, int>> obtenerEstadisticas() async {
    try {
      final db = await database;
      
      final clientes = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM clientes_cache')
      ) ?? 0;
      
      final productos = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM productos_cache')
      ) ?? 0;
      
      final categorias = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM categorias_cache')
      ) ?? 0;
      
      return {
        'clientes': clientes,
        'productos': productos,
        'categorias': categorias,
      };
    } catch (e) {
      print('❌ DatosCacheService: Error obteniendo estadísticas: $e');
      return {'clientes': 0, 'productos': 0, 'categorias': 0};
    }
  }
}

