import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../Models/Cliente.dart';
import '../../Models/Producto.dart';
import '../../Models/Categoria.dart';
import '../../Models/Ventas.dart';
import '../../Models/VentasProductos.dart';
import '../../Models/metodoPago.dart';
import '../../Models/EstadoEntrega.dart';

/// Manager para caché local de datos maestros (Clientes, Productos, Categorías)
/// Permite que la app funcione offline usando datos guardados previamente
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  static Database? _database;
  static const String _databaseName = 'tobaco_cache.db';
  static const int _databaseVersion = 1;

  // Nombres de tablas
  static const String _clientesTable = 'clientes_cache';
  static const String _productosTable = 'productos_cache';
  static const String _categoriasTable = 'categorias_cache';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('🗄️  CacheManager: Inicializando base de datos de caché...');
    
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
    print('🗄️  CacheManager: Creando tablas de caché...');

    // Tabla de clientes (caché)
    await db.execute('''
      CREATE TABLE $_clientesTable (
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

    // Tabla de productos (caché)
    await db.execute('''
      CREATE TABLE $_productosTable (
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

    // Tabla de categorías (caché)
    await db.execute('''
      CREATE TABLE $_categoriasTable (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        color_hex TEXT NOT NULL DEFAULT '#9E9E9E',
        sort_order INTEGER NOT NULL DEFAULT 0,
        activa INTEGER NOT NULL DEFAULT 1,
        cached_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabla de ventas del servidor (caché)
    await db.execute('''
      CREATE TABLE ventas_cache (
        id INTEGER PRIMARY KEY,
        cliente_id INTEGER NOT NULL,
        cliente_json TEXT NOT NULL,
        total REAL NOT NULL,
        fecha TEXT NOT NULL,
        metodo_pago INTEGER,
        usuario_id INTEGER,
        estado_entrega INTEGER NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Tabla de productos de ventas cacheadas
    await db.execute('''
      CREATE TABLE ventas_cache_productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        cantidad REAL NOT NULL,
        categoria TEXT NOT NULL,
        categoria_id INTEGER NOT NULL,
        precio_final_calculado REAL NOT NULL,
        FOREIGN KEY (venta_id) REFERENCES ventas_cache (id) ON DELETE CASCADE
      )
    ''');

    // Índices
    await db.execute('CREATE INDEX idx_clientes_nombre ON $_clientesTable(nombre)');
    await db.execute('CREATE INDEX idx_productos_nombre ON $_productosTable(nombre)');
    await db.execute('CREATE INDEX idx_productos_categoria ON $_productosTable(categoria_id)');
    await db.execute('CREATE INDEX idx_categorias_sort_order ON $_categoriasTable(sort_order)');
    await db.execute('CREATE INDEX idx_ventas_cache_fecha ON ventas_cache(fecha)');
    await db.execute('CREATE INDEX idx_ventas_cache_productos ON ventas_cache_productos(venta_id)');

    print('✅ CacheManager: Tablas de caché creadas correctamente');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🗄️  CacheManager: Actualizando base de datos de v$oldVersion a v$newVersion');
    // Migraciones futuras aquí
  }

  // ==================== CLIENTES ====================

  /// Guarda clientes en caché
  Future<void> cacheClientes(List<Cliente> clientes) async {
    if (clientes.isEmpty) return;

    final db = await database;
    final now = DateTime.now().toIso8601String();

    print('💾 CacheManager: Guardando ${clientes.length} clientes en caché...');

    await db.transaction((txn) async {
      // Limpiar caché anterior
      await txn.delete(_clientesTable);

      // Insertar nuevos clientes
      for (var cliente in clientes) {
        await txn.insert(_clientesTable, {
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

    print('✅ CacheManager: Clientes guardados en caché');
  }

  /// Obtiene clientes desde caché
  Future<List<Cliente>> getClientesFromCache() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _clientesTable,
      orderBy: 'nombre ASC',
    );

    if (maps.isEmpty) {
      print('⚠️  CacheManager: No hay clientes en caché');
      return [];
    }

    print('📦 CacheManager: ${maps.length} clientes obtenidos de caché');

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

  /// Busca clientes en caché por nombre
  Future<List<Cliente>> buscarClientesEnCache(String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _clientesTable,
      where: 'nombre LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'nombre ASC',
    );

    print('🔍 CacheManager: ${maps.length} clientes encontrados con query "$query"');

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

  /// Agrega o actualiza un cliente en caché
  Future<void> upsertCliente(Cliente cliente) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      _clientesTable,
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

    print('✅ CacheManager: Cliente ${cliente.nombre} actualizado en caché');
  }

  // ==================== PRODUCTOS ====================

  /// Guarda productos en caché
  Future<void> cacheProductos(List<Producto> productos) async {
    if (productos.isEmpty) return;

    final db = await database;
    final now = DateTime.now().toIso8601String();

    print('💾 CacheManager: Guardando ${productos.length} productos en caché...');

    await db.transaction((txn) async {
      // Limpiar caché anterior
      await txn.delete(_productosTable);

      // Insertar nuevos productos
      for (var producto in productos) {
        await txn.insert(_productosTable, {
          'id': producto.id,
          'nombre': producto.nombre,
          'precio': producto.precio,
          'stock': producto.stock,
          'categoria_id': producto.categoriaId,
          'categoria_nombre': producto.categoriaNombre,
          'half': producto.half ? 1 : 0,
          'activo': 1,
          'cached_at': now,
          'updated_at': now,
        });
      }
    });

    print('✅ CacheManager: Productos guardados en caché');
  }

  /// Obtiene productos desde caché
  Future<List<Producto>> getProductosFromCache() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _productosTable,
      where: 'activo = ?',
      whereArgs: [1],
      orderBy: 'nombre ASC',
    );

    if (maps.isEmpty) {
      print('⚠️  CacheManager: No hay productos en caché');
      return [];
    }

    print('📦 CacheManager: ${maps.length} productos obtenidos de caché');

    return maps.map((map) {
      return Producto(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
        precio: map['precio'] as double,
        stock: map['stock'] as double?,
        categoriaId: map['categoria_id'] as int,
        categoriaNombre: map['categoria_nombre'] as String? ?? '',
        half: (map['half'] as int) == 1,
      );
    }).toList();
  }

  /// Obtiene productos por categoría desde caché
  Future<List<Producto>> getProductosPorCategoriaFromCache(int categoriaId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _productosTable,
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
      );
    }).toList();
  }

  /// Agrega o actualiza un producto en caché
  Future<void> upsertProducto(Producto producto) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      _productosTable,
      {
        'id': producto.id,
        'nombre': producto.nombre,
        'precio': producto.precio,
        'stock': producto.stock,
        'categoria_id': producto.categoriaId,
        'categoria_nombre': producto.categoriaNombre,
        'half': producto.half ? 1 : 0,
        'activo': 1,
        'cached_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('✅ CacheManager: Producto ${producto.nombre} actualizado en caché');
  }

  // ==================== CATEGORÍAS ====================

  /// Guarda categorías en caché
  Future<void> cacheCategorias(List<Categoria> categorias) async {
    if (categorias.isEmpty) return;

    final db = await database;
    final now = DateTime.now().toIso8601String();

    print('💾 CacheManager: Guardando ${categorias.length} categorías en caché...');

    await db.transaction((txn) async {
      // Limpiar caché anterior
      await txn.delete(_categoriasTable);

      // Insertar nuevas categorías
      for (var categoria in categorias) {
        await txn.insert(_categoriasTable, {
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

    print('✅ CacheManager: Categorías guardadas en caché');
  }

  /// Obtiene categorías desde caché
  Future<List<Categoria>> getCategoriasFromCache() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _categoriasTable,
      where: 'activa = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC',
    );

    if (maps.isEmpty) {
      print('⚠️  CacheManager: No hay categorías en caché');
      return [];
    }

    print('📦 CacheManager: ${maps.length} categorías obtenidas de caché');

    return maps.map((map) {
      return Categoria(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
        colorHex: map['color_hex'] as String,
        sortOrder: map['sort_order'] as int,
      );
    }).toList();
  }

  // ==================== UTILIDADES ====================

  /// Obtiene la fecha de la última actualización del caché
  Future<Map<String, DateTime?>> getLastCacheUpdate() async {
    final db = await database;

    final clientesResult = await db.rawQuery(
      'SELECT MAX(updated_at) as last_update FROM $_clientesTable'
    );
    final productosResult = await db.rawQuery(
      'SELECT MAX(updated_at) as last_update FROM $_productosTable'
    );
    final categoriasResult = await db.rawQuery(
      'SELECT MAX(updated_at) as last_update FROM $_categoriasTable'
    );

    return {
      'clientes': clientesResult.first['last_update'] != null
        ? DateTime.parse(clientesResult.first['last_update'] as String)
        : null,
      'productos': productosResult.first['last_update'] != null
        ? DateTime.parse(productosResult.first['last_update'] as String)
        : null,
      'categorias': categoriasResult.first['last_update'] != null
        ? DateTime.parse(categoriasResult.first['last_update'] as String)
        : null,
    };
  }

  /// Verifica si hay datos en caché
  Future<Map<String, bool>> hasCachedData() async {
    final db = await database;

    final clientesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_clientesTable')
    ) ?? 0;

    final productosCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_productosTable')
    ) ?? 0;

    final categoriasCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_categoriasTable')
    ) ?? 0;

    return {
      'clientes': clientesCount > 0,
      'productos': productosCount > 0,
      'categorias': categoriasCount > 0,
    };
  }

  /// Limpia toda la caché
  Future<void> clearAllCache() async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete(_clientesTable);
      await txn.delete(_productosTable);
      await txn.delete(_categoriasTable);
    });

    print('🧹 CacheManager: Toda la caché ha sido limpiada');
  }

  // Nombres de tablas de ventas (caché de ventas del servidor)
  static const String _ventasCacheTable = 'ventas_cache';
  static const String _ventasCacheProductosTable = 'ventas_cache_productos';

  /// Guarda ventas del servidor en caché (para ver offline)
  Future<void> cacheVentas(List<dynamic> ventas) async {
    if (ventas.isEmpty) {
      print('💾 CacheManager: No hay ventas para cachear');
      return;
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();

    print('💾 CacheManager: Guardando ${ventas.length} ventas en caché...');

    try {
      await db.transaction((txn) async {
        // Limpiar caché anterior
        await txn.delete(_ventasCacheTable);
        await txn.delete(_ventasCacheProductosTable);

        // Insertar ventas del servidor
        for (var venta in ventas) {
          // Guardar venta principal
          await txn.insert(_ventasCacheTable, {
            'id': venta.id,
            'cliente_id': venta.clienteId,
            'cliente_json': jsonEncode(venta.cliente.toJson()),
            'total': venta.total,
            'fecha': venta.fecha.toIso8601String(),
            'metodo_pago': venta.metodoPago?.index,
            'usuario_id': venta.usuarioId,
            'estado_entrega': venta.estadoEntrega.toJson(),
            'cached_at': now,
          });

          // Guardar productos de la venta
          for (var producto in venta.ventasProductos) {
            await txn.insert(_ventasCacheProductosTable, {
              'venta_id': venta.id,
              'producto_id': producto.productoId,
              'nombre': producto.nombre,
              'precio': producto.precio,
              'cantidad': producto.cantidad,
              'categoria': producto.categoria,
              'categoria_id': producto.categoriaId,
              'precio_final_calculado': producto.precioFinalCalculado,
            });
          }
        }
      });

      print('✅ CacheManager: ${ventas.length} ventas guardadas en caché');
    } catch (e) {
      print('❌ CacheManager: Error guardando ventas en caché: $e');
    }
  }

  /// Obtiene ventas desde caché
  Future<List<Ventas>> getVentasFromCache() async {
    final db = await database;
    
    // Verificar que las tablas existan
    final tableExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$_ventasCacheTable'"
    );
    
    if (tableExists.isEmpty) {
      print('⚠️ CacheManager: Tabla de ventas caché no existe aún');
      return [];
    }
    
    final List<Map<String, dynamic>> ventasMaps = await db.query(
      _ventasCacheTable,
      orderBy: 'fecha DESC',
    );

    if (ventasMaps.isEmpty) {
      print('⚠️ CacheManager: No hay ventas en caché');
      return [];
    }

    print('📦 CacheManager: ${ventasMaps.length} ventas obtenidas de caché');

    // Construir objetos Venta con sus productos
    List<Ventas> ventas = [];
    for (var ventaMap in ventasMaps) {
      try {
        // Obtener productos de esta venta
        final productosMaps = await db.query(
          _ventasCacheProductosTable,
          where: 'venta_id = ?',
          whereArgs: [ventaMap['id']],
        );

        // Parsear cliente
        final clienteJson = jsonDecode(ventaMap['cliente_json'] as String);
        final cliente = Cliente.fromJson(clienteJson);

        // Construir lista de productos
        final productos = productosMaps.map((p) {
          return VentasProductos(
            productoId: p['producto_id'] as int,
            nombre: p['nombre'] as String,
            precio: p['precio'] as double,
            cantidad: p['cantidad'] as double,
            categoria: p['categoria'] as String,
            categoriaId: p['categoria_id'] as int,
            precioFinalCalculado: p['precio_final_calculado'] as double,
          );
        }).toList();

        // Construir objeto Venta
        final venta = Ventas(
          id: ventaMap['id'] as int?,
          clienteId: ventaMap['cliente_id'] as int,
          cliente: cliente,
          ventasProductos: productos,
          total: ventaMap['total'] as double,
          fecha: DateTime.parse(ventaMap['fecha'] as String),
          metodoPago: ventaMap['metodo_pago'] != null 
            ? MetodoPago.values[ventaMap['metodo_pago'] as int]
            : null,
          usuarioId: ventaMap['usuario_id'] as int?,
          estadoEntrega: EstadoEntregaExtension.fromJson(ventaMap['estado_entrega'] as int),
        );

        ventas.add(venta);
      } catch (e) {
        print('❌ CacheManager: Error parseando venta ${ventaMap['id']}: $e');
        // Continuar con las demás ventas
      }
    }

    print('✅ CacheManager: ${ventas.length} ventas parseadas desde caché');
    return ventas;
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('🗄️  CacheManager: Base de datos cerrada');
  }

  /// Resetea la base de datos (elimina y recrea)
  /// ADVERTENCIA: Esto eliminará todo el caché
  Future<void> resetDatabase() async {
    print('⚠️ CacheManager: Reseteando base de datos de caché...');
    
    try {
      // Cerrar la base de datos si está abierta
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Eliminar el archivo de base de datos
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      
      print('🗑️ CacheManager: Eliminando base de datos en: $path');
      await deleteDatabase(path);
      
      // Reinicializar la base de datos (se crearán las tablas nuevamente)
      _database = await _initDatabase();
      
      print('✅ CacheManager: Base de datos de caché reseteada correctamente');
    } catch (e) {
      print('❌ CacheManager: Error reseteando base de datos: $e');
      rethrow;
    }
  }

  /// Verifica si las tablas existen y las crea si faltan
  Future<void> ensureTablesExist() async {
    print('🔍 CacheManager: Verificando tablas...');
    
    final db = await database;
    
    // Verificar si la tabla ventas_cache existe
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='ventas_cache'"
    );
    
    if (tables.isEmpty) {
      print('⚠️ CacheManager: Tablas no existen, recreando base de datos...');
      await resetDatabase();
    } else {
      print('✅ CacheManager: Tablas existen correctamente');
    }
  }
}

