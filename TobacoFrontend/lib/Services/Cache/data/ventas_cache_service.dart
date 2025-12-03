import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../Models/Ventas.dart';
import '../../../Models/VentasProductos.dart';
import '../../../Models/Cliente.dart';
import '../../../Models/metodoPago.dart';
import '../../../Models/EstadoEntrega.dart';
import '../../../Models/User.dart';
import '../core/cache_interface.dart';

/// Servicio de caché para ventas del servidor
/// Guarda ventas sincronizadas del servidor para visualización offline
class VentasCacheService implements ICacheService<Ventas> {
  static final VentasCacheService _instance = VentasCacheService._internal();
  factory VentasCacheService() => _instance;
  VentasCacheService._internal();

  static Database? _database;
  static const String _databaseName = 'tobaco_cache.db';
  static const int _databaseVersion = 3;
  static const String _tableName = 'ventas_cache';
  static const String _productosTableName = 'ventas_cache_productos';

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
    // Tabla de ventas del servidor (caché)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY,
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
        cached_at TEXT NOT NULL
      )
    ''');

    // Tabla de productos de ventas cacheadas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_productosTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        marca TEXT,
        precio REAL NOT NULL,
        cantidad REAL NOT NULL,
        categoria TEXT NOT NULL,
        categoria_id INTEGER NOT NULL,
        precio_final_calculado REAL NOT NULL,
        FOREIGN KEY (venta_id) REFERENCES $_tableName (id) ON DELETE CASCADE
      )
    ''');

    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ventas_cache_fecha ON $_tableName(fecha)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ventas_cache_productos ON $_productosTableName(venta_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migración de v1 a v2: dividir usuario en creador y asignado
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $_tableName ADD COLUMN usuario_id_creador INTEGER');
      await db.execute('ALTER TABLE $_tableName ADD COLUMN usuario_creador_json TEXT');
      await db.execute('ALTER TABLE $_tableName ADD COLUMN usuario_id_asignado INTEGER');
      await db.execute('ALTER TABLE $_tableName ADD COLUMN usuario_asignado_json TEXT');
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $_productosTableName ADD COLUMN marca TEXT');
    }
  }

  @override
  Future<List<Ventas>> getAll() async {
    final db = await database;
    
    // Verificar que las tablas existan
    final tableExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$_tableName'"
    );
    
    if (tableExists.isEmpty) {
      debugPrint('⚠️ VentasCacheService: Tabla de ventas caché no existe aún');
      return [];
    }
    
    final List<Map<String, dynamic>> ventasMaps = await db.query(
      _tableName,
      orderBy: 'fecha DESC',
    );

    if (ventasMaps.isEmpty) {
      debugPrint('⚠️ VentasCacheService: No hay ventas en caché');
      return [];
    }

    debugPrint('📦 VentasCacheService: ${ventasMaps.length} ventas obtenidas de caché');

    List<Ventas> ventas = [];
    for (var ventaMap in ventasMaps) {
      try {
        ventas.add(await _buildVentaFromMap(ventaMap, db));
      } catch (e) {
        debugPrint('❌ VentasCacheService: Error parseando venta ${ventaMap['id']}: $e');
      }
    }

    debugPrint('✅ VentasCacheService: ${ventas.length} ventas parseadas desde caché');
    return ventas;
  }

  @override
  Future<void> save(Ventas item) async {
    await saveAll([item]);
  }

  @override
  Future<void> saveAll(List<Ventas> items) async {
    if (items.isEmpty) {
      debugPrint('💾 VentasCacheService: No hay ventas para cachear');
      // Limpiar caché anterior incluso si la lista está vacía
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete(_tableName);
        await txn.delete(_productosTableName);
      });
      return;
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();

    debugPrint('💾 VentasCacheService: Guardando ${items.length} ventas en caché...');

    try {
      await db.transaction((txn) async {
        // Limpiar caché anterior
        await txn.delete(_tableName);
        await txn.delete(_productosTableName);

        // Insertar ventas del servidor
        for (var venta in items) {
          // Guardar venta principal
          await txn.insert(_tableName, {
            'id': venta.id,
            'cliente_id': venta.clienteId,
            'cliente_json': jsonEncode(venta.cliente.toJson()),
            'total': venta.total,
            'fecha': venta.fecha.toIso8601String(),
            'metodo_pago': venta.metodoPago?.index,
            'usuario_id_creador': venta.usuarioIdCreador,
            'usuario_creador_json': venta.usuarioCreador != null ? jsonEncode(venta.usuarioCreador!.toJson()) : null,
            'usuario_id_asignado': venta.usuarioIdAsignado,
            'usuario_asignado_json': venta.usuarioAsignado != null ? jsonEncode(venta.usuarioAsignado!.toJson()) : null,
            'estado_entrega': venta.estadoEntrega.toJson(),
            'cached_at': now,
          });

          // Guardar productos de la venta
          for (var producto in venta.ventasProductos) {
            await txn.insert(_productosTableName, {
              'venta_id': venta.id,
              'producto_id': producto.productoId,
              'nombre': producto.nombre,
              'marca': producto.marca,
              'precio': producto.precio,
              'cantidad': producto.cantidad,
              'categoria': producto.categoria,
              'categoria_id': producto.categoriaId,
              'precio_final_calculado': producto.precioFinalCalculado,
            });
          }
        }
      });

      debugPrint('✅ VentasCacheService: ${items.length} ventas guardadas en caché');
    } catch (e) {
      debugPrint('❌ VentasCacheService: Error guardando ventas en caché: $e');
    }
  }

  @override
  Future<Ventas?> getById(dynamic id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return _buildVentaFromMap(maps.first, db);
  }

  @override
  Future<bool> deleteById(dynamic id) async {
    final db = await database;
    
    // Los productos se eliminan automáticamente por CASCADE
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
    await db.transaction((txn) async {
      await txn.delete(_tableName);
      await txn.delete(_productosTableName);
    });
    debugPrint('🧹 VentasCacheService: Caché de ventas limpiado');
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

  /// Construye un objeto Ventas desde un Map de base de datos
  Future<Ventas> _buildVentaFromMap(Map<String, dynamic> ventaMap, Database db) async {
    // Obtener productos de esta venta
    final productosMaps = await db.query(
      _productosTableName,
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
        marca: p['marca'] as String?,
        precio: p['precio'] as double,
        cantidad: p['cantidad'] as double,
        categoria: p['categoria'] as String,
        categoriaId: p['categoria_id'] as int,
        precioFinalCalculado: p['precio_final_calculado'] as double,
      );
    }).toList();

    // Parsear usuario creador si existe
    User? usuarioCreador;
    if (ventaMap['usuario_creador_json'] != null) {
      final usuarioJson = jsonDecode(ventaMap['usuario_creador_json'] as String);
      usuarioCreador = User.fromJson(usuarioJson);
    }
    
    // Parsear usuario asignado si existe
    User? usuarioAsignado;
    if (ventaMap['usuario_asignado_json'] != null) {
      final usuarioJson = jsonDecode(ventaMap['usuario_asignado_json'] as String);
      usuarioAsignado = User.fromJson(usuarioJson);
    }

    // Construir objeto Venta
    return Ventas(
      id: ventaMap['id'] as int?,
      clienteId: ventaMap['cliente_id'] as int,
      cliente: cliente,
      ventasProductos: productos,
      total: ventaMap['total'] as double,
      fecha: DateTime.parse(ventaMap['fecha'] as String),
      metodoPago: ventaMap['metodo_pago'] != null 
        ? MetodoPago.values[ventaMap['metodo_pago'] as int]
        : null,
      usuarioIdCreador: ventaMap['usuario_id_creador'] as int?,
      usuarioCreador: usuarioCreador,
      usuarioIdAsignado: ventaMap['usuario_id_asignado'] as int?,
      usuarioAsignado: usuarioAsignado,
      estadoEntrega: EstadoEntregaExtension.fromJson(ventaMap['estado_entrega'] as int),
    );
  }

  @override
  Future<void> markAsEmpty() async {
    final db = await database;
    await _ensureCacheMetadataTable(db);
    await db.insert(
      'cache_metadata',
      {
        'entity_name': _tableName,
        'is_empty': 1,
        'marked_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('📝 VentasCacheService: Caché marcado como vacío');
  }

  @override
  Future<bool> isEmptyMarked() async {
    final db = await database;
    await _ensureCacheMetadataTable(db);
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
    await _ensureCacheMetadataTable(db);
    await db.delete(
      'cache_metadata',
      where: 'entity_name = ?',
      whereArgs: [_tableName],
    );
    debugPrint('🧹 VentasCacheService: Marcador de vacío limpiado');
  }

  /// Asegura que la tabla cache_metadata existe
  Future<void> _ensureCacheMetadataTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache_metadata (
        entity_name TEXT PRIMARY KEY,
        is_empty INTEGER NOT NULL DEFAULT 0,
        marked_at TEXT NOT NULL
      )
    ''');
  }
}
