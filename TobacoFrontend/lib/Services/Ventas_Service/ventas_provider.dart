import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Models/User.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Models/ventasPago.dart';
import 'package:tobaco/Services/Cache/database_helper.dart';
import 'package:tobaco/Services/Cache/ventas_cache_service.dart';
import 'package:tobaco/Services/Sync/simple_sync_service.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_service.dart';

class VentasProvider with ChangeNotifier {
  final VentasService _ventasService = VentasService();
  final DatabaseHelper _db = DatabaseHelper();
  final SimpleSyncService _syncService = SimpleSyncService();
  final VentasCacheService _cacheService = VentasCacheService();

  final Map<Ventas, String> _ventaLocalIds = {};

  List<Ventas> _ventas = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isOffline = false;
  bool _isSincronizando = false;
  String? _errorMessage;
  int _currentPage = 1;
  final int _pageSize = 20;
  String _searchQuery = '';
  bool _offlineMessageShown = false;

  List<Ventas> get ventas => List.unmodifiable(_ventas);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  bool get isOffline => _isOffline;
  bool get isSincronizando => _isSincronizando;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String get searchQuery => _searchQuery;
  bool get offlineMessageShown => _offlineMessageShown;

  List<Ventas> get ventasFiltradas {
    if (_searchQuery.isEmpty) return List.unmodifiable(_ventas);
    final query = _searchQuery.toLowerCase();
    return _ventas.where((venta) {
      final cliente = venta.cliente.nombre.toLowerCase();
      final fecha = '${venta.fecha.day}/${venta.fecha.month}';
      final total = venta.total.toString();
      return cliente.contains(query) ||
          fecha.contains(query) ||
          total.contains(query);
    }).toList(growable: false);
  }

  Future<void> cargarVentas({bool usarTimeoutNormal = false}) async {
    _isLoading = true;
    _errorMessage = null;
    _isOffline = false;
    _currentPage = 1;
    _hasMoreData = true;
    notifyListeners();

    try {
      final ventasDelServidor = await _ventasService.obtenerVentas(
        timeoutRapido: !usarTimeoutNormal,
        timeoutNormal: usarTimeoutNormal,
      );

      await _sincronizarSQLiteConServidor(ventasDelServidor);

      final combinadas =
          await _combinarConVentasOfflinePendientes(ventasDelServidor);

      _ventas = combinadas..sort((a, b) => b.fecha.compareTo(a.fecha));
      _isOffline = false;
      _hasMoreData = false;
      _offlineMessageShown = false;

      await _cacheService.guardarVentasEnCache(
        ventasDelServidor.where((venta) => venta.id != null).toList(),
      );
    } catch (e) {
      if (Apihandler.isConnectionError(e)) {
        await _cargarVentasOffline();
      } else {
        _ventas = [];
        _errorMessage = _limpiarMensajeError(e.toString());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarMasVentas() async {
    if (_isLoadingMore || !_hasMoreData) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage += 1;
      _hasMoreData = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> sincronizarAhora() async {
    if (_isSincronizando) {
      return {
        'success': false,
        'message': 'Ya hay una sincronización en progreso',
        'sincronizadas': 0,
        'fallidas': 0,
      };
    }

    _isSincronizando = true;
    notifyListeners();

    Map<String, dynamic> resultado;
    try {
      resultado = await _syncService.sincronizarAhora();
      await cargarVentas(usarTimeoutNormal: true);
    } catch (e) {
      _errorMessage = _limpiarMensajeError(e.toString());
      resultado = {
        'success': false,
        'message': _errorMessage,
        'sincronizadas': 0,
        'fallidas': 0,
      };
    } finally {
      _isSincronizando = false;
      notifyListeners();
    }

    return resultado;
  }

  void actualizarBusqueda(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  Future<void> eliminarVenta(int id) async {
    Ventas? venta;
    for (final item in _ventas) {
      if (item.id == id) {
        venta = item;
        break;
      }
    }

    if (venta == null) {
      return;
    }

    final localId = _ventaLocalIds[venta] ?? 'servidor_$id';

    try {
      await _ventasService.eliminarVenta(id);
      _ventas.remove(venta);
      _ventaLocalIds.remove(venta);
      await _db.deleteVentaOffline(localId);
      await _actualizarCacheDesdeVentasActuales();
      notifyListeners();
    } catch (e) {
      if (Apihandler.isConnectionError(e)) {
        _ventas.remove(venta);
        _ventaLocalIds.remove(venta);
        _isOffline = true;
        await _db.deleteVentaOffline(localId);
        await _actualizarCacheDesdeVentasActuales();
        notifyListeners();
      } else {
        _errorMessage = _limpiarMensajeError(e.toString());
        rethrow;
      }
    }
  }

  Future<void> eliminarVentaLocal(Ventas venta) async {
    final localId = _ventaLocalIds[venta];
    _ventas.remove(venta);
    _ventaLocalIds.remove(venta);
    if (localId != null) {
      await _db.deleteVentaOffline(localId);
    }
    await _actualizarCacheDesdeVentasActuales();
    notifyListeners();
  }

  Future<void> eliminarVentaDeLista(Ventas venta) async {
    if (venta.id != null) {
      await eliminarVenta(venta.id!);
    } else {
      await eliminarVentaLocal(venta);
    }
  }

  Future<List<Ventas>> obtenerVentas({bool usarTimeoutNormal = false}) async {
    await cargarVentas(usarTimeoutNormal: usarTimeoutNormal);
    return ventas;
  }

  Future<Map<String, dynamic>> crearVenta(Ventas venta) async {
    try {
      final response = await _ventasService.crearVenta(
        venta,
        customTimeout: const Duration(seconds: 1),
      );

      if (response['ventaId'] != null) {
        venta.id = response['ventaId'];
      }

      _ventas.insert(0, venta);

      if (venta.id != null) {
        await _guardarVentaDelServidor(venta);
        _ventaLocalIds[venta] = 'servidor_${venta.id}';
      } else {
        _ventaLocalIds[venta] =
            'servidor_temp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      }

      await _actualizarCacheDesdeVentasActuales();
      notifyListeners();

      return {
        'success': true,
        'isOffline': false,
        'message': response['message'] ?? 'Venta creada exitosamente',
        'ventaId': response['ventaId'],
        'asignada': response['asignada'] ?? false,
        'usuarioAsignadoId': response['usuarioAsignadoId'],
        'usuarioAsignadoNombre': response['usuarioAsignadoNombre'],
      };
    } catch (e) {
      final localId = await _db.saveVentaOffline(venta);
      _ventas.insert(0, venta);
      _ventaLocalIds[venta] = localId;
      _isOffline = true;
      await _actualizarCacheDesdeVentasActuales();
      notifyListeners();

      return {
        'success': true,
        'isOffline': true,
        'message':
            'Venta guardada localmente. Se sincronizará cuando haya conexión.',
      };
    }
  }

  Future<void> asignarVenta(int ventaId, int usuarioId) async {
    try {
      await _ventasService.asignarVenta(ventaId, usuarioId);
      final index = _ventas.indexWhere((venta) => venta.id == ventaId);
      if (index != -1) {
        _ventas[index].usuarioIdAsignado = usuarioId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al asignar venta: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> asignarVentaAutomaticamente(
      int ventaId, int usuarioIdExcluir) async {
    try {
      final resultado = await _ventasService.asignarVentaAutomaticamente(
        ventaId,
        usuarioIdExcluir,
      );
      if (resultado['asignada'] == true &&
          resultado['usuarioAsignadoId'] != null) {
        final index = _ventas.indexWhere((venta) => venta.id == ventaId);
        if (index != -1) {
          _ventas[index].usuarioIdAsignado = resultado['usuarioAsignadoId'];
          notifyListeners();
        }
      }
      return resultado;
    } catch (e) {
      debugPrint('Error al asignar venta automáticamente: $e');
      rethrow;
    }
  }

  Future<int> contarVentasPendientes() async {
    final stats = await _db.getStats();
    return stats['pending'] ?? 0;
  }

  Future<Map<String, dynamic>> obtenerVentasPaginadas(
      int page, int pageSize) async {
    try {
      return await _ventasService.obtenerVentasPaginadas(page, pageSize);
    } catch (e) {
      debugPrint('Error al obtener ventas paginadas: $e');
      rethrow;
    }
  }

  Future<Ventas> obtenerVentaPorId(int id) async {
    try {
      return await _ventasService.obtenerVentaPorId(id);
    } catch (e) {
      debugPrint('Error al obtener venta por ID: $e');
      rethrow;
    }
  }

  Future<Ventas> obtenerUltimaVenta() async {
    try {
      return await _ventasService.obtenerUltimaVenta();
    } catch (e) {
      debugPrint('Error al obtener última venta: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerVentasPorCliente(
    int clienteId, {
    int pageNumber = 1,
    int pageSize = 10,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      return await _ventasService.obtenerVentasPorCliente(
        clienteId,
        pageNumber: pageNumber,
        pageSize: pageSize,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    } catch (e) {
      debugPrint('Error al obtener ventas por cliente: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerVentasCuentaCorrientePorClienteId(
      int clienteId, int page, int pageSize) async {
    try {
      return await _ventasService.obtenerVentasCuentaCorrientePorClienteId(
        clienteId,
        page,
        pageSize,
      );
    } catch (e) {
      debugPrint('Error al obtener ventas con cuenta corriente: $e');
      rethrow;
    }
  }

  Future<void> actualizarEstadoEntrega(
      int ventaId, List<VentasProductos> items) async {
    try {
      await _ventasService.actualizarEstadoEntrega(ventaId, items);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al actualizar estado de entrega: $e');
      rethrow;
    }
  }

  void marcarOfflineMessageMostrado() {
    if (!_offlineMessageShown) {
      _offlineMessageShown = true;
      notifyListeners();
    }
  }

  Future<void> _sincronizarSQLiteConServidor(
      List<Ventas> ventasDelServidor) async {
    try {
      final idsDelServidor = <int>{};
      for (final venta in ventasDelServidor) {
        if (venta.id != null) {
          idsDelServidor.add(venta.id!);
          await _guardarVentaDelServidor(venta);
        }
      }

      final db = await _db.database;
      final ventasSincronizadasSQLite = await db.query(
        'ventas_offline',
        where: 'sync_status = ? AND id IS NOT NULL',
        whereArgs: ['synced'],
      );

      for (var ventaRow in ventasSincronizadasSQLite) {
        final ventaId = ventaRow['id'] as int?;
        if (ventaId != null && !idsDelServidor.contains(ventaId)) {
          final localId = ventaRow['local_id'] as String;
          await _db.deleteVentaOffline(localId);
        }
      }
    } catch (e) {
      debugPrint('⚠️ VentasProvider: Error sincronizando SQLite con servidor: $e');
    }
  }

  Future<List<Ventas>> _combinarConVentasOfflinePendientes(
    List<Ventas> ventasDelServidor,
  ) async {
    final resultado = <Ventas>[];
    final idsServidor = <int>{};

    _ventaLocalIds.clear();

    for (final venta in ventasDelServidor) {
      resultado.add(venta);
      if (venta.id != null) {
        idsServidor.add(venta.id!);
        _ventaLocalIds[venta] = 'servidor_${venta.id}';
      }
    }

    final ventasOffline = await _db.getPendingVentas();
    for (var ventaData in ventasOffline) {
      final ventaRow = ventaData['venta'] as Map<String, dynamic>;
      final localId = ventaRow['local_id'] as String;
      final ventaId = ventaRow['id'] as int?;

      if (ventaId != null && idsServidor.contains(ventaId)) {
        continue;
      }

      try {
        final productos = (ventaData['productos'] as List).map((p) {
          return VentasProductos(
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
            fechaChequeo: p['fecha_chequeo'] != null
                ? DateTime.parse(p['fecha_chequeo'] as String)
                : null,
            usuarioChequeoId: p['usuario_chequeo_id'] as int?,
          );
        }).toList();

        final pagosRows = ventaData['pagos'] as List;
        List<VentaPago>? pagos;
        if (pagosRows.isNotEmpty) {
          pagos = pagosRows.map((p) {
            return VentaPago(
              id: 0,
              ventaId: 0,
              metodo: MetodoPago.values[p['metodo'] as int],
              monto: (p['monto'] as num).toDouble(),
            );
          }).toList();
        }

        final clienteJson = jsonDecode(ventaRow['cliente_json'] as String);
        final cliente = Cliente.fromJson(clienteJson);

        User? usuarioCreador;
        if (ventaRow['usuario_creador_json'] != null) {
          usuarioCreador =
              User.fromJson(jsonDecode(ventaRow['usuario_creador_json'] as String));
        }

        User? usuarioAsignado;
        if (ventaRow['usuario_asignado_json'] != null) {
          usuarioAsignado = User.fromJson(
              jsonDecode(ventaRow['usuario_asignado_json'] as String));
        }

        final ventaOffline = Ventas(
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
          estadoEntrega: EstadoEntregaExtension.fromJson(
            ventaRow['estado_entrega'] as int,
          ),
        );

        resultado.add(ventaOffline);
        _ventaLocalIds[ventaOffline] = localId;
      } catch (e) {
        debugPrint('⚠️ VentasProvider: Error construyendo venta offline: $e');
      }
    }

    return resultado;
  }

  Future<void> _cargarVentasOffline() async {
    final resultado = <Ventas>[];
    final idsAgregados = <int>{};

    _ventaLocalIds.clear();

    try {
      final cache = await _cacheService.obtenerVentasDelCache();
      for (final venta in cache) {
        resultado.add(venta);
        if (venta.id != null) {
          idsAgregados.add(venta.id!);
          _ventaLocalIds[venta] = 'servidor_${venta.id}';
        }
      }
    } catch (e) {
      debugPrint('⚠️ VentasProvider: Error leyendo ventas del caché simple: $e');
    }

    try {
      final db = await _db.database;
      final ventasRows = await db.query(
        'ventas_offline',
        orderBy: 'created_at DESC',
      );

      for (final ventaRow in ventasRows) {
        final localId = ventaRow['local_id'] as String;
        final ventaId = ventaRow['id'] as int?;

        if (ventaId != null && idsAgregados.contains(ventaId)) {
          continue;
        }

        final venta = await _buildVentaFromRow(ventaRow);
        resultado.add(venta);
        _ventaLocalIds[venta] = localId;
        if (ventaId != null) {
          idsAgregados.add(ventaId);
        }
      }
    } catch (e) {
      debugPrint('⚠️ VentasProvider: Error obteniendo ventas offline: $e');
    }

    if (resultado.isEmpty) {
      _errorMessage =
          'No hay ventas disponibles offline. Conecta para sincronizar.';
    }

    _ventas = resultado..sort((a, b) => b.fecha.compareTo(a.fecha));
    _isOffline = true;
    _hasMoreData = false;
  }

  Future<void> _actualizarCacheDesdeVentasActuales() async {
    await _cacheService.guardarVentasEnCache(
      _ventas.where((venta) => venta.id != null).toList(),
    );
  }

  Future<Ventas> _buildVentaFromRow(Map<String, dynamic> ventaRow) async {
    final db = await _db.database;
    final localId = ventaRow['local_id'] as String;

    final productosRows = await db.query(
      'ventas_productos_offline',
      where: 'venta_local_id = ?',
      whereArgs: [localId],
    );

    final productos = productosRows.map((p) {
      return VentasProductos(
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
        fechaChequeo: p['fecha_chequeo'] != null
            ? DateTime.parse(p['fecha_chequeo'] as String)
            : null,
        usuarioChequeoId: p['usuario_chequeo_id'] as int?,
      );
    }).toList();

    final pagosRows = await db.query(
      'ventas_pagos_offline',
      where: 'venta_local_id = ?',
      whereArgs: [localId],
    );

    List<VentaPago>? pagos;
    if (pagosRows.isNotEmpty) {
      pagos = pagosRows.map((p) {
        return VentaPago(
          id: p['id'] as int,
          ventaId: ventaRow['id'] as int? ?? 0,
          metodo: MetodoPago.values[p['metodo'] as int],
          monto: p['monto'] as double,
        );
      }).toList();
    }

    final clienteJson = jsonDecode(ventaRow['cliente_json'] as String);
    final cliente = Cliente.fromJson(clienteJson);

    User? usuarioCreador;
    if (ventaRow['usuario_creador_json'] != null) {
      usuarioCreador =
          User.fromJson(jsonDecode(ventaRow['usuario_creador_json'] as String));
    }

    User? usuarioAsignado;
    if (ventaRow['usuario_asignado_json'] != null) {
      usuarioAsignado = User.fromJson(
          jsonDecode(ventaRow['usuario_asignado_json'] as String));
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
      estadoEntrega:
          EstadoEntregaExtension.fromJson(ventaRow['estado_entrega'] as int),
    );
  }

  Future<void> _guardarVentaDelServidor(Ventas venta) async {
    if (venta.id == null) return;

    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final localId = 'servidor_${venta.id}';

    try {
      await db.transaction((txn) async {
        await txn.insert(
          'ventas_offline',
          {
            'local_id': localId,
            'id': venta.id,
            'cliente_id': venta.clienteId,
            'cliente_json': jsonEncode(venta.cliente.toJson()),
            'total': venta.total,
            'fecha': venta.fecha.toIso8601String(),
            'metodo_pago': venta.metodoPago?.index,
            'usuario_id_creador': venta.usuarioIdCreador,
            'usuario_creador_json': venta.usuarioCreador != null
                ? jsonEncode(venta.usuarioCreador!.toJson())
                : null,
            'usuario_id_asignado': venta.usuarioIdAsignado,
            'usuario_asignado_json': venta.usuarioAsignado != null
                ? jsonEncode(venta.usuarioAsignado!.toJson())
                : null,
            'estado_entrega': venta.estadoEntrega.toJson(),
            'sync_status': 'synced',
            'sync_attempts': 0,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.delete(
          'ventas_productos_offline',
          where: 'venta_local_id = ?',
          whereArgs: [localId],
        );

        for (var producto in venta.ventasProductos) {
          await txn.insert('ventas_productos_offline', {
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

        await txn.delete(
          'ventas_pagos_offline',
          where: 'venta_local_id = ?',
          whereArgs: [localId],
        );

        if (venta.pagos != null) {
          for (var pago in venta.pagos!) {
            await txn.insert('ventas_pagos_offline', {
              'venta_local_id': localId,
              'metodo': pago.metodo.index,
              'monto': pago.monto,
            });
          }
        }
      });
    } catch (e) {
      debugPrint('⚠️ Error guardando venta del servidor en SQLite: $e');
      rethrow;
    }
  }

  String _limpiarMensajeError(String mensaje) {
    return mensaje.replaceFirst('Exception: ', '');
  }
}

