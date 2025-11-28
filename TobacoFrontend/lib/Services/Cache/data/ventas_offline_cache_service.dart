import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../Models/Ventas.dart';
import '../../../Models/VentasProductos.dart';
import '../../../Models/Cliente.dart';
import '../../../Models/metodoPago.dart';
import '../../../Models/EstadoEntrega.dart';
import '../../../Models/ventasPago.dart';
import '../../../Models/User.dart';
import '../core/cache_interface.dart';
import '../core/database_helper.dart';

/// Servicio de caché para ventas creadas offline
/// Maneja ventas pendientes de sincronización con el servidor
class VentasOfflineCacheService implements ICacheService<Ventas> {
  static final VentasOfflineCacheService _instance = VentasOfflineCacheService._internal();
  factory VentasOfflineCacheService() => _instance;
  VentasOfflineCacheService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  static const String _ventasTable = 'ventas_offline';
  static const String _productosTable = 'ventas_productos_offline';
  static const String _pagosTable = 'ventas_pagos_offline';

  @override
  Future<List<Ventas>> getAll() async {
    final db = await _dbHelper.database;
    
    final ventas = await _dbHelper.query(
      _ventasTable,
      orderBy: 'created_at DESC',
    );

    List<Ventas> result = [];

    for (var ventaRow in ventas) {
      try {
        final venta = await _buildVentaFromRow(ventaRow);
        result.add(venta);
      } catch (e) {
        debugPrint('⚠️ VentasOfflineCacheService: Error construyendo venta: $e');
      }
    }

    return result;
  }

  @override
  Future<void> save(Ventas item) async {
    await saveWithLocalId(item);
  }

  @override
  Future<void> saveAll(List<Ventas> items) async {
    for (var venta in items) {
      await save(venta);
    }
  }

  /// Guarda una venta offline y retorna su local_id
  Future<String> saveWithLocalId(Ventas venta) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await _dbHelper.transaction((txn) async {
        // Insertar venta
        await _dbHelper.insert(
          _ventasTable,
          {
            'local_id': localId,
            'cliente_id': venta.clienteId,
            'cliente_json': jsonEncode(venta.cliente.toJson()),
            'total': venta.total,
            'fecha': DatabaseHelper.formatDateTimeLocal(venta.fecha),
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
          },
        );

        // Insertar productos
        for (var producto in venta.ventasProductos) {
          await _dbHelper.insert(
            _productosTable,
            {
              'venta_local_id': localId,
              'producto_id': producto.productoId,
              'nombre': producto.nombre,
              'marca': producto.marca,
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
            },
          );
        }

        // Insertar pagos si existen
        if (venta.pagos != null) {
          for (var pago in venta.pagos!) {
            await _dbHelper.insert(
              _pagosTable,
              {
                'venta_local_id': localId,
                'metodo': pago.metodo.index,
                'monto': pago.monto,
              },
            );
          }
        }
      });

      debugPrint('✅ VentasOfflineCacheService: Venta offline guardada con local_id: $localId');
      return localId;
    } catch (e) {
      debugPrint('❌ VentasOfflineCacheService: Error guardando venta offline: $e');
      rethrow;
    }
  }

  @override
  Future<Ventas?> getById(dynamic id) async {
    // Para ventas offline, el id puede ser local_id o id numérico
    final db = await _dbHelper.database;
    
    List<Map<String, dynamic>> ventas;
    if (id is String) {
      ventas = await _dbHelper.query(
        _ventasTable,
        where: 'local_id = ?',
        whereArgs: [id],
        limit: 1,
      );
    } else {
      ventas = await _dbHelper.query(
        _ventasTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
    }

    if (ventas.isEmpty) return null;

    return _buildVentaFromRow(ventas.first);
  }

  @override
  Future<bool> deleteById(dynamic id) async {
    // Para ventas offline, el id puede ser local_id o id numérico
    final db = await _dbHelper.database;
    
    String where;
    List<dynamic> whereArgs;
    if (id is String) {
      where = 'local_id = ?';
      whereArgs = [id];
    } else {
      where = 'id = ?';
      whereArgs = [id];
    }
    
    // Los productos y pagos se eliminan automáticamente por CASCADE
    final deleted = await _dbHelper.delete(
      _ventasTable,
      where: where,
      whereArgs: whereArgs,
    );

    return deleted > 0;
  }

  @override
  Future<void> clear() async {
    final db = await _dbHelper.database;
    await _dbHelper.transaction((txn) async {
      await _dbHelper.delete(_productosTable);
      await _dbHelper.delete(_pagosTable);
      await _dbHelper.delete(_ventasTable);
    });
    debugPrint('🧹 VentasOfflineCacheService: Caché de ventas offline limpiado');
  }

  @override
  Future<bool> hasData() async {
    final itemCount = await count();
    return itemCount > 0;
  }

  @override
  Future<int> count() async {
    final db = await _dbHelper.database;
    final result = await _dbHelper.rawQuery('SELECT COUNT(*) as count FROM $_ventasTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Obtiene todas las ventas pendientes de sincronización
  Future<List<Map<String, dynamic>>> getPendingVentas() async {
    try {
      final db = await _dbHelper.database;
      
      final ventas = await _dbHelper.query(
        _ventasTable,
        where: 'sync_status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
      );

      List<Map<String, dynamic>> result = [];

      for (var ventaRow in ventas) {
        try {
          final localId = ventaRow['local_id'] as String;
          
          // Obtener productos
          final productos = await _dbHelper.query(
            _productosTable,
            where: 'venta_local_id = ?',
            whereArgs: [localId],
          );

          // Obtener pagos
          final pagos = await _dbHelper.query(
            _pagosTable,
            where: 'venta_local_id = ?',
            whereArgs: [localId],
          );

          result.add({
            'venta': ventaRow,
            'productos': productos,
            'pagos': pagos,
          });
        } catch (e) {
          debugPrint('⚠️ VentasOfflineCacheService: Error procesando venta pendiente: $e');
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ VentasOfflineCacheService: Error al obtener ventas pendientes: $e');
      return [];
    }
  }

  /// Marca una venta como sincronizada
  Future<void> markAsSynced(String localId, int? serverId) async {
    final db = await _dbHelper.database;
    
    await _dbHelper.update(
      _ventasTable,
      {
        'sync_status': 'synced',
        'id': serverId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    debugPrint('✅ VentasOfflineCacheService: Venta marcada como sincronizada (localId: $localId, serverId: $serverId)');
  }

  /// Marca una venta como fallida en la sincronización
  Future<void> markAsSyncFailed(String localId, String errorMessage) async {
    final db = await _dbHelper.database;
    
    final venta = await _dbHelper.query(
      _ventasTable,
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );

    if (venta.isEmpty) return;

    final attempts = (venta.first['sync_attempts'] as int) + 1;

    await _dbHelper.update(
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

    debugPrint('❌ VentasOfflineCacheService: Venta marcada como fallida (localId: $localId, intentos: $attempts)');
  }

  /// Reintentar sincronización de una venta fallida
  Future<void> retrySync(String localId) async {
    final db = await _dbHelper.database;
    
    await _dbHelper.update(
      _ventasTable,
      {
        'sync_status': 'pending',
        'error_message': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    debugPrint('🔄 VentasOfflineCacheService: Venta marcada para reintentar sincronización (localId: $localId)');
  }

  /// Construye un objeto Ventas desde una fila de base de datos
  Future<Ventas> _buildVentaFromRow(Map<String, dynamic> ventaRow) async {
    final db = await _dbHelper.database;
    final localId = ventaRow['local_id'] as String;

    // Obtener productos
    final productosRows = await _dbHelper.query(
      _productosTable,
      where: 'venta_local_id = ?',
      whereArgs: [localId],
    );

    List<VentasProductos> productos = productosRows.map((p) => VentasProductos(
      productoId: p['producto_id'] as int,
      nombre: p['nombre'] as String,
      marca: p['marca'] as String?,
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
    final pagosRows = await _dbHelper.query(
      _pagosTable,
      where: 'venta_local_id = ?',
      whereArgs: [localId],
    );

    List<VentaPago>? pagos;
    if (pagosRows.isNotEmpty) {
      pagos = pagosRows.map((p) => VentaPago(
        id: p['id'] as int,
        ventaId: 0,
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
      fecha: DatabaseHelper.parseDateTimeLocal(ventaRow['fecha'] as String),
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

  /// Obtiene estadísticas de la base de datos offline
  Future<Map<String, int>> getStats() async {
    try {
      final db = await _dbHelper.database;
      
      final pending = Sqflite.firstIntValue(
        await _dbHelper.rawQuery('SELECT COUNT(*) FROM $_ventasTable WHERE sync_status = ?', ['pending'])
      ) ?? 0;
      
      final failed = Sqflite.firstIntValue(
        await _dbHelper.rawQuery('SELECT COUNT(*) FROM $_ventasTable WHERE sync_status = ?', ['failed'])
      ) ?? 0;
      
      final synced = Sqflite.firstIntValue(
        await _dbHelper.rawQuery('SELECT COUNT(*) FROM $_ventasTable WHERE sync_status = ?', ['synced'])
      ) ?? 0;

      return {
        'pending': pending,
        'failed': failed,
        'synced': synced,
        'total': pending + failed + synced,
      };
    } catch (e) {
      debugPrint('❌ VentasOfflineCacheService: Error al obtener stats: $e');
      return {
        'pending': 0,
        'failed': 0,
        'synced': 0,
        'total': 0,
      };
    }
  }
}
