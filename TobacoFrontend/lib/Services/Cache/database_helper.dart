import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../Models/Ventas.dart';
import '../../Models/VentasProductos.dart';
import '../../Models/Cliente.dart';
import '../../Models/ventasPago.dart';
import '../../Models/metodoPago.dart';
import '../../Models/EstadoEntrega.dart';
import '../../Models/User.dart';
import '../../Models/Entrega.dart';

/// Helper para la base de datos SQLite local
/// Maneja el almacenamiento offline de ventas pendientes de sincronización
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _databaseName = 'tobaco_offline.db';
  static const int _databaseVersion = 3;

  // Nombres de tablas
  static const String _ventasTable = 'ventas_offline';
  static const String _productosTable = 'ventas_productos_offline';
  static const String _pagosTable = 'ventas_pagos_offline';
  static const String _entregasTable = 'entregas_offline';

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
    

    // Tabla de ventas offline
    await db.execute('''
      CREATE TABLE $_ventasTable (
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
      CREATE TABLE $_productosTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_local_id TEXT NOT NULL,
        producto_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
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
        FOREIGN KEY (venta_local_id) REFERENCES $_ventasTable (local_id) ON DELETE CASCADE
      )
    ''');

    // Tabla de pagos de ventas offline
    await db.execute('''
      CREATE TABLE $_pagosTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_local_id TEXT NOT NULL,
        metodo INTEGER NOT NULL,
        monto REAL NOT NULL,
        FOREIGN KEY (venta_local_id) REFERENCES $_ventasTable (local_id) ON DELETE CASCADE
      )
    ''');

    // Tabla de entregas
    await db.execute('''
      CREATE TABLE $_entregasTable (
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

    // Índices para mejorar el rendimiento
    await db.execute('CREATE INDEX idx_venta_sync_status ON $_ventasTable(sync_status)');
    await db.execute('CREATE INDEX idx_venta_created_at ON $_ventasTable(created_at)');
    await db.execute('CREATE INDEX idx_productos_venta ON $_productosTable(venta_local_id)');
    await db.execute('CREATE INDEX idx_pagos_venta ON $_pagosTable(venta_local_id)');
    await db.execute('CREATE INDEX idx_entregas_fecha ON $_entregasTable(fecha_asignacion)');
    await db.execute('CREATE INDEX idx_entregas_repartidor ON $_entregasTable(repartidor_id)');
    await db.execute('CREATE INDEX idx_entregas_estado ON $_entregasTable(estado)');
    await db.execute('CREATE INDEX idx_entregas_sync ON $_entregasTable(pendiente_sincronizar)');

    
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    
    
    // Migración de v1 a v2: agregar tabla de entregas
    if (oldVersion < 2) {
      
      await db.execute('''
        CREATE TABLE $_entregasTable (
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
      
      await db.execute('CREATE INDEX idx_entregas_fecha ON $_entregasTable(fecha_asignacion)');
      await db.execute('CREATE INDEX idx_entregas_repartidor ON $_entregasTable(repartidor_id)');
      await db.execute('CREATE INDEX idx_entregas_estado ON $_entregasTable(estado)');
      await db.execute('CREATE INDEX idx_entregas_sync ON $_entregasTable(pendiente_sincronizar)');
      
      
    }
    
    // Migración de v2 a v3: dividir usuario en creador y asignado
    if (oldVersion < 3) {
      // Agregar nuevos campos
      await db.execute('ALTER TABLE $_ventasTable ADD COLUMN usuario_id_creador INTEGER');
      await db.execute('ALTER TABLE $_ventasTable ADD COLUMN usuario_creador_json TEXT');
      await db.execute('ALTER TABLE $_ventasTable ADD COLUMN usuario_id_asignado INTEGER');
      await db.execute('ALTER TABLE $_ventasTable ADD COLUMN usuario_asignado_json TEXT');
      
      // Migrar datos existentes: mover usuario_id/usuario_json a usuario_id_creador/usuario_creador_json
      await db.execute('''
        UPDATE $_ventasTable 
        SET usuario_id_creador = usuario_id, 
            usuario_creador_json = usuario_json
        WHERE usuario_id IS NOT NULL
      ''');
      
      // Eliminar columnas antiguas
      // Nota: SQLite no soporta DROP COLUMN directamente, pero como estamos 
      // en la v3 nueva, esto solo afecta a usuarios que ya tenían v2
      // Las nuevas instalaciones usarán el esquema correcto de v3 desde el inicio
    }
  }

  /// Guarda una venta offline
  Future<String> saveVentaOffline(Ventas venta) async {
    
    
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await db.transaction((txn) async {
        // Insertar venta
        await txn.insert(_ventasTable, {
          'local_id': localId,
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
          'sync_status': 'pending',
          'sync_attempts': 0,
          'created_at': now,
          'updated_at': now,
        });

        // Insertar productos
        for (var producto in venta.ventasProductos) {
          await txn.insert(_productosTable, {
            'venta_local_id': localId,
            'producto_id': producto.productoId,
            'nombre': producto.nombre,
            'precio': producto.precio,
            'cantidad': producto.cantidad,
            'categoria': producto.categoria,
            'categoria_id': producto.categoriaId,
            'precio_final_calculado': producto.precioFinalCalculado,
            'entregado': producto.entregado ? 1 : 0,
            'motivo': producto.motivo,
            'nota': producto.nota,
            'fecha_chequeo': producto.fechaChequeo?.toIso8601String(),
            'usuario_chequeo_id': producto.usuarioChequeoId,
          });
        }

        // Insertar pagos si existen
        if (venta.pagos != null) {
          for (var pago in venta.pagos!) {
            await txn.insert(_pagosTable, {
              'venta_local_id': localId,
              'metodo': pago.metodo.index,
              'monto': pago.monto,
            });
          }
        }
      });

      
      return localId;
    } catch (e) {
      
      rethrow;
    }
  }

  /// Obtiene todas las ventas offline pendientes de sincronización
  Future<List<Map<String, dynamic>>> getPendingVentas() async {
    final db = await database;
    
    final ventas = await db.query(
      _ventasTable,
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );

    List<Map<String, dynamic>> result = [];

    for (var ventaRow in ventas) {
      final localId = ventaRow['local_id'] as String;
      
      // Obtener productos
      final productos = await db.query(
        _productosTable,
        where: 'venta_local_id = ?',
        whereArgs: [localId],
      );

      // Obtener pagos
      final pagos = await db.query(
        _pagosTable,
        where: 'venta_local_id = ?',
        whereArgs: [localId],
      );

      result.add({
        'venta': ventaRow,
        'productos': productos,
        'pagos': pagos,
      });
    }

    
    return result;
  }

  /// Obtiene todas las ventas offline (incluidas las sincronizadas)
  Future<List<Ventas>> getAllOfflineVentas() async {
    final db = await database;
    
    final ventas = await db.query(
      _ventasTable,
      orderBy: 'created_at DESC',
    );

    List<Ventas> result = [];

    for (var ventaRow in ventas) {
      final venta = await _buildVentaFromRow(ventaRow);
      result.add(venta);
    }

    return result;
  }

  /// Construye un objeto Ventas desde una fila de base de datos
  Future<Ventas> _buildVentaFromRow(Map<String, dynamic> ventaRow) async {
    final db = await database;
    final localId = ventaRow['local_id'] as String;

    // Obtener productos
    final productosRows = await db.query(
      _productosTable,
      where: 'venta_local_id = ?',
      whereArgs: [localId],
    );

    List<VentasProductos> productos = productosRows.map((p) => VentasProductos(
      productoId: p['producto_id'] as int,
      nombre: p['nombre'] as String,
      precio: p['precio'] as double,
      cantidad: p['cantidad'] as double,
      categoria: p['categoria'] as String,
      categoriaId: p['categoria_id'] as int,
      precioFinalCalculado: p['precio_final_calculado'] as double,
      entregado: (p['entregado'] as int) == 1,
      motivo: p['motivo'] as String?,
      nota: p['nota'] as String?,
      fechaChequeo: p['fecha_chequeo'] != null ? DateTime.parse(p['fecha_chequeo'] as String) : null,
      usuarioChequeoId: p['usuario_chequeo_id'] as int?,
    )).toList();

    // Obtener pagos
    final pagosRows = await db.query(
      _pagosTable,
      where: 'venta_local_id = ?',
      whereArgs: [localId],
    );

    List<VentaPago>? pagos;
    if (pagosRows.isNotEmpty) {
      pagos = pagosRows.map((p) => VentaPago(
        id: p['id'] as int,
        ventaId: 0, // No tenemos el ID del servidor aún
        metodo: MetodoPago.values[p['metodo'] as int],
        monto: p['monto'] as double,
      )).toList();
    }

    // Construir cliente
    final clienteJson = jsonDecode(ventaRow['cliente_json'] as String);
    final cliente = Cliente.fromJson(clienteJson);

    // Construir usuario creador si existe
    User? usuarioCreador;
    if (ventaRow['usuario_creador_json'] != null) {
      final usuarioJson = jsonDecode(ventaRow['usuario_creador_json'] as String);
      usuarioCreador = User.fromJson(usuarioJson);
    }
    
    // Construir usuario asignado si existe
    User? usuarioAsignado;
    if (ventaRow['usuario_asignado_json'] != null) {
      final usuarioJson = jsonDecode(ventaRow['usuario_asignado_json'] as String);
      usuarioAsignado = User.fromJson(usuarioJson);
    }

    return Ventas(
      id: ventaRow['id'] as int?,
      clienteId: ventaRow['cliente_id'] as int,
      cliente: cliente,
      ventasProductos: productos,
      total: ventaRow['total'] as double,
      fecha: DateTime.parse(ventaRow['fecha'] as String),
      metodoPago: ventaRow['metodo_pago'] != null 
        ? MetodoPago.values[ventaRow['metodo_pago'] as int]
        : null,
      pagos: pagos,
      usuarioIdCreador: ventaRow['usuario_id_creador'] as int?,
      usuarioCreador: usuarioCreador,
      usuarioIdAsignado: ventaRow['usuario_id_asignado'] as int?,
      usuarioAsignado: usuarioAsignado,
      estadoEntrega: EstadoEntregaExtension.fromJson(ventaRow['estado_entrega'] as int),
    );
  }

  /// Marca una venta como sincronizada
  Future<void> markVentaAsSynced(String localId, int? serverId) async {
    final db = await database;
    
    await db.update(
      _ventasTable,
      {
        'sync_status': 'synced',
        'id': serverId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    
  }

  /// Marca una venta como fallida en la sincronización
  Future<void> markVentaAsSyncFailed(String localId, String errorMessage) async {
    final db = await database;
    
    final venta = await db.query(
      _ventasTable,
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );

    if (venta.isEmpty) return;

    final attempts = (venta.first['sync_attempts'] as int) + 1;

    await db.update(
      _ventasTable,
      {
        'sync_status': 'failed',
        'sync_attempts': attempts,
        'last_sync_attempt': DateTime.now().toIso8601String(),
        'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    
  }

  /// Reintentar sincronización de una venta fallida
  Future<void> retryVentaSync(String localId) async {
    final db = await database;
    
    await db.update(
      _ventasTable,
      {
        'sync_status': 'pending',
        'error_message': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    
  }

  /// Elimina una venta offline
  Future<void> deleteVentaOffline(String localId) async {
    final db = await database;
    
    await db.delete(
      _ventasTable,
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    
  }

  /// Limpia ventas sincronizadas antiguas (más de 30 días)
  Future<int> cleanOldSyncedVentas({int daysOld = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld)).toIso8601String();
    
    final deleted = await db.delete(
      _ventasTable,
      where: 'sync_status = ? AND updated_at < ?',
      whereArgs: ['synced', cutoffDate],
    );

    
    return deleted;
  }

  /// Obtiene estadísticas de la base de datos offline
  Future<Map<String, int>> getStats() async {
    final db = await database;
    
    final pending = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_ventasTable WHERE sync_status = ?', ['pending'])
    ) ?? 0;
    
    final failed = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_ventasTable WHERE sync_status = ?', ['failed'])
    ) ?? 0;
    
    final synced = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_ventasTable WHERE sync_status = ?', ['synced'])
    ) ?? 0;

    return {
      'pending': pending,
      'failed': failed,
      'synced': synced,
      'total': pending + failed + synced,
    };
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    
  }

  /// Resetea la base de datos (elimina y recrea)
  /// ADVERTENCIA: Esto eliminará todas las ventas offline pendientes
  Future<void> resetDatabase() async {
    
    
    try {
      // Cerrar la base de datos si está abierta
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Eliminar el archivo de base de datos
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      
      
      await deleteDatabase(path);
      
      // Reinicializar la base de datos (se crearán las tablas nuevamente)
      _database = await _initDatabase();
      
      
    } catch (e) {
      
      rethrow;
    }
  }

  /// Verifica si las tablas existen y las crea si faltan
  Future<void> ensureTablesExist() async {
    
    
    final db = await database;
    
    // Verificar si la tabla ventas_offline existe
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$_ventasTable'"
    );
    
    if (tables.isEmpty) {
      
      await resetDatabase();
    } else {
      
    }
  }

  // ==================== MÉTODOS PARA ENTREGAS ====================

  /// Inserta o actualiza una entrega en la base de datos local
  /// Preserva el estado local si la entrega ya fue marcada como completada
  /// IMPORTANTE: Solo preserva el estado si pertenece al mismo repartidor
  Future<void> insertarEntrega(Entrega entrega) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Verificar si la entrega ya existe y tiene estado completada localmente
    final entregaExistente = await obtenerEntregaPorId(entrega.id!);
    
    // Si existe, está completada localmente Y pertenece al mismo repartidor, preservar ese estado
    if (entregaExistente != null && 
        entregaExistente.estaCompletada && 
        entregaExistente.repartidorId == entrega.repartidorId) {
      await db.insert(
        _entregasTable,
        {
          'id': entrega.id,
          'venta_id': entrega.ventaId,
          'cliente_id': entrega.clienteId,
          'cliente_nombre': entrega.cliente.nombre,
          'cliente_direccion': entrega.cliente.direccion,
          'latitud': entrega.latitud,
          'longitud': entrega.longitud,
          'estado': entregaExistente.estado.toJson(), // Preservar estado local
          'fecha_asignacion': entrega.fechaAsignacion.toIso8601String(),
          'fecha_entrega': entregaExistente.fechaEntrega?.toIso8601String(), // Preservar fecha entrega
          'repartidor_id': entrega.repartidorId,
          'orden': entrega.orden,
          'notas': entregaExistente.notas ?? entrega.notas, // Preservar notas
          'distancia_desde_ubicacion_actual': entrega.distanciaDesdeUbicacionActual,
          'sync_status': 'synced',
          'pendiente_sincronizar': 0,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // Si no existe, no está completada, o pertenece a otro repartidor, usar el estado del servidor
      await db.insert(
        _entregasTable,
        {
          'id': entrega.id,
          'venta_id': entrega.ventaId,
          'cliente_id': entrega.clienteId,
          'cliente_nombre': entrega.cliente.nombre,
          'cliente_direccion': entrega.cliente.direccion,
          'latitud': entrega.latitud,
          'longitud': entrega.longitud,
          'estado': entrega.estado.toJson(),
          'fecha_asignacion': entrega.fechaAsignacion.toIso8601String(),
          'fecha_entrega': entrega.fechaEntrega?.toIso8601String(),
          'repartidor_id': entrega.repartidorId,
          'orden': entrega.orden,
          'notas': entrega.notas,
          'distancia_desde_ubicacion_actual': entrega.distanciaDesdeUbicacionActual,
          'sync_status': 'synced',
          'pendiente_sincronizar': 0,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Obtiene las entregas del día actual
  /// [repartidorId] Si se proporciona, filtra las entregas por repartidor
  Future<List<Entrega>> obtenerEntregasDelDia({int? repartidorId}) async {
    final db = await database;
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
    final finDelDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59).toIso8601String();

    String whereClause = 'fecha_asignacion >= ? AND fecha_asignacion <= ?';
    List<dynamic> whereArgs = [inicioDelDia, finDelDia];
    
    // Si se especifica un repartidor, filtrar por él
    if (repartidorId != null) {
      whereClause += ' AND repartidor_id = ?';
      whereArgs.add(repartidorId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _entregasTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'orden ASC',
    );

    return List.generate(maps.length, (i) {
      return Entrega.fromMap(maps[i], clienteData: Cliente(
        id: maps[i]['cliente_id'],
        nombre: maps[i]['cliente_nombre'],
        direccion: maps[i]['cliente_direccion'],
      ));
    });
  }

  /// Obtiene una entrega por su ID
  Future<Entrega?> obtenerEntregaPorId(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _entregasTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return Entrega.fromMap(maps.first, clienteData: Cliente(
      id: maps.first['cliente_id'],
      nombre: maps.first['cliente_nombre'],
      direccion: maps.first['cliente_direccion'],
    ));
  }

  /// Elimina una entrega por su ID
  Future<void> eliminarEntregaPorId(int id) async {
    final db = await database;
    await db.delete(
      _entregasTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Actualiza el estado de una entrega
  Future<void> actualizarEstadoEntrega(int id, EstadoEntrega nuevoEstado) async {
    final db = await database;
    await db.update(
      _entregasTable,
      {
        'estado': nuevoEstado.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marca una entrega como completada
  Future<void> marcarEntregaComoEntregada(int id, String? notas) async {
    final db = await database;
    await db.update(
      _entregasTable,
      {
        'estado': EstadoEntrega.entregada.toJson(),
        'fecha_entrega': DateTime.now().toIso8601String(),
        'notas': notas,
        'pendiente_sincronizar': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marca una entrega para sincronizar con el servidor
  Future<void> marcarEntregaParaSincronizar(int id) async {
    final db = await database;
    await db.update(
      _entregasTable,
      {
        'pendiente_sincronizar': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marca una entrega como sincronizada
  Future<void> marcarEntregaSincronizada(int id) async {
    final db = await database;
    await db.update(
      _entregasTable,
      {
        'pendiente_sincronizar': 0,
        'sync_status': 'synced',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina todas las entregas del día actual (excepto las completadas localmente)
  /// Esto asegura que el cache esté sincronizado con el servidor
  Future<void> eliminarEntregasDelDia() async {
    final db = await database;
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
    final finDelDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59).toIso8601String();

    // Eliminar todas las entregas del día actual que no estén completadas o pendientes de sincronizar
    await db.delete(
      _entregasTable,
      where: 'fecha_asignacion >= ? AND fecha_asignacion <= ? AND estado != ? AND pendiente_sincronizar = ?',
      whereArgs: [inicioDelDia, finDelDia, EstadoEntrega.entregada.toJson(), 0],
    );
  }

  /// Obtiene las entregas pendientes de sincronizar
  Future<List<Entrega>> obtenerEntregasPendientesDeSincronizar() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _entregasTable,
      where: 'pendiente_sincronizar = ?',
      whereArgs: [1],
    );

    return List.generate(maps.length, (i) {
      return Entrega.fromMap(maps[i], clienteData: Cliente(
        id: maps[i]['cliente_id'],
        nombre: maps[i]['cliente_nombre'],
        direccion: maps[i]['cliente_direccion'],
      ));
    });
  }

  /// Actualiza las notas de una entrega
  Future<void> actualizarNotasEntrega(int id, String notas) async {
    final db = await database;
    await db.update(
      _entregasTable,
      {
        'notas': notas,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Actualiza el orden de las entregas
  Future<void> actualizarOrdenEntregas(List<Entrega> entregas) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var entrega in entregas) {
        await txn.update(
          _entregasTable,
          {
            'orden': entrega.orden,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [entrega.id],
        );
      }
    });
  }

  /// Elimina todas las entregas del día (útil para refrescar)
  Future<void> limpiarEntregasDelDia() async {
    final db = await database;
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
    final finDelDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59).toIso8601String();

    await db.delete(
      _entregasTable,
      where: 'fecha_asignacion >= ? AND fecha_asignacion <= ?',
      whereArgs: [inicioDelDia, finDelDia],
    );
  }
}

