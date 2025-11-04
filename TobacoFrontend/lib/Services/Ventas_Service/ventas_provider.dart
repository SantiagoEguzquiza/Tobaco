import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/ventasPago.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Models/User.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_service.dart';
import 'package:tobaco/Services/Cache/database_helper.dart';
import 'package:tobaco/Services/Sync/simple_sync_service.dart';

class VentasProvider with ChangeNotifier {
  final VentasService _ventasService = VentasService();
  final DatabaseHelper _db = DatabaseHelper();
  final SimpleSyncService _syncService = SimpleSyncService();

  List<Ventas> _ventas = [];
  bool _cargando = false;

  List<Ventas> get ventas => _ventas;
  bool get cargando => _cargando;

  /// Obtiene ventas: intenta del servidor, si falla usa ventas locales (SQLite)
  Future<List<Ventas>> obtenerVentas({bool usarTimeoutNormal = false}) async {
    _cargando = true;
    // Evitar notificar durante el build
    Future.microtask(() => notifyListeners());
    
    try {
      // Intentar obtener ventas del servidor con timeout rápido para detección offline
      final ventasDelServidor = await _ventasService.obtenerVentas(timeoutRapido: !usarTimeoutNormal, timeoutNormal: usarTimeoutNormal);
      
      // Cuando el backend está disponible, sincronizar SQLite con el servidor
      // IMPORTANTE: Esto se ejecuta siempre que el servidor responde, incluso si está vacío
      try {
        // Obtener IDs de ventas del servidor (puede estar vacío si se borraron todas)
        final idsDelServidor = <int>{};
        for (final venta in ventasDelServidor) {
          if (venta.id != null) {
            idsDelServidor.add(venta.id!);
            // Guardar cada venta del servidor en SQLite (sincronizadas)
            await _guardarVentaDelServidor(venta);
          }
        }
        
        if (ventasDelServidor.isNotEmpty) {
          debugPrint('✅ VentasProvider: ${ventasDelServidor.length} ventas del servidor guardadas en SQLite');
        } else {
          debugPrint('ℹ️ VentasProvider: No hay ventas en el servidor (lista vacía)');
        }
        
        // Obtener todas las ventas sincronizadas del SQLite
        final db = await _db.database;
        final ventasSincronizadasSQLite = await db.query(
          'ventas_offline',
          where: 'sync_status = ? AND id IS NOT NULL',
          whereArgs: ['synced'],
        );
        
        debugPrint('🔍 VentasProvider: Comparando ${ventasSincronizadasSQLite.length} ventas sincronizadas en SQLite con ${idsDelServidor.length} ventas del servidor');
        
        // Borrar del SQLite las ventas sincronizadas que ya no existen en el servidor
        int ventasBorradas = 0;
        for (var ventaRow in ventasSincronizadasSQLite) {
          final ventaId = ventaRow['id'] as int?;
          if (ventaId != null && !idsDelServidor.contains(ventaId)) {
            // Esta venta ya no existe en el servidor, borrarla del SQLite
            final localId = ventaRow['local_id'] as String;
            await _db.deleteVentaOffline(localId);
            ventasBorradas++;
            debugPrint('🗑️ VentasProvider: Venta ID $ventaId eliminada del SQLite (ya no existe en servidor)');
          }
        }
        
        if (ventasBorradas > 0) {
          debugPrint('✅ VentasProvider: $ventasBorradas ventas eliminadas del SQLite (no existen en servidor)');
        } else if (ventasSincronizadasSQLite.isNotEmpty && idsDelServidor.isEmpty) {
          debugPrint('✅ VentasProvider: Todas las ventas sincronizadas fueron eliminadas del servidor - SQLite sincronizado');
        }
      } catch (e) {
        debugPrint('⚠️ VentasProvider: Error sincronizando SQLite con servidor: $e');
      }
      
      // Mostrar solo las ventas del servidor cuando el backend está disponible
      _ventas = ventasDelServidor;
      _ventas.sort((a, b) => b.fecha.compareTo(a.fecha)); // Ordenar por fecha descendente
      
      // Obtener ventas offline pendientes de sincronizar para agregarlas a la lista
      final ventasOffline = await _db.getPendingVentas();
      
      // Agregar ventas pendientes offline a la lista (solo las que no están en el servidor)
      final idsDelServidorSet = ventasDelServidor.where((v) => v.id != null).map((v) => v.id!).toSet();
      
      for (var ventaData in ventasOffline) {
        final ventaRow = ventaData['venta'] as Map<String, dynamic>;
        final ventaId = ventaRow['id'] as int?;
        
        // Solo agregar si no existe ya en el servidor
        if (ventaId == null || !idsDelServidorSet.contains(ventaId)) {
          try {
            // Construir venta desde datos offline
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
                fechaChequeo: p['fecha_chequeo'] != null ? DateTime.parse(p['fecha_chequeo'] as String) : null,
                usuarioChequeoId: p['usuario_chequeo_id'] as int?,
              );
            }).toList();

            final pagosRows = ventaData['pagos'] as List;
            List<VentaPago>? pagos;
            if (pagosRows.isNotEmpty) {
              pagos = pagosRows.map((p) {
                return VentaPago(
                  id: 0, // ID será 0 para ventas pendientes
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
              final usuarioJson = jsonDecode(ventaRow['usuario_creador_json'] as String);
              usuarioCreador = User.fromJson(usuarioJson);
            }
            
            User? usuarioAsignado;
            if (ventaRow['usuario_asignado_json'] != null) {
              final usuarioJson = jsonDecode(ventaRow['usuario_asignado_json'] as String);
              usuarioAsignado = User.fromJson(usuarioJson);
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
              estadoEntrega: EstadoEntregaExtension.fromJson(ventaRow['estado_entrega'] as int),
            );
            
            _ventas.add(ventaOffline);
          } catch (e) {
            debugPrint('⚠️ VentasProvider: Error construyendo venta offline: $e');
          }
        }
      }
      
      // Reordenar por fecha después de agregar las offline
      _ventas.sort((a, b) => b.fecha.compareTo(a.fecha));
      
    } catch (e) {
      debugPrint('⚠️ VentasProvider: Error obteniendo ventas del servidor: $e');
      // Si falla online, cargar solo ventas locales (pendientes/sincronizadas) desde SQLite
      _ventas = await _db.getAllOfflineVentas();
      _ventas.sort((a, b) => b.fecha.compareTo(a.fecha));
    } finally {
      _cargando = false;
      // Evitar notificar durante el build
      Future.microtask(() => notifyListeners());
    }

    return _ventas;
  }

  /// Crea una venta (online u offline)
  Future<Map<String, dynamic>> crearVenta(Ventas venta) async {
    try {
      // Intentar crear online con timeout MUY corto (1 segundo) para detectar offline rápido
      final response = await _ventasService.crearVenta(venta, customTimeout: const Duration(seconds: 1));
      
      // Actualizar el ID de la venta con el que retornó el servidor
      if (response['ventaId'] != null) {
        venta.id = response['ventaId'];
      }
      
      // Agregar a la lista local
      _ventas.insert(0, venta);
      
      // No hay actualización de caché de servidor
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
      // Guardar offline en background para que el mensaje aparezca inmediatamente
      // No esperar el guardado para responder rápido
      _db.saveVentaOffline(venta).catchError((offlineError) {
        debugPrint('⚠️ Error guardando venta offline: $offlineError');
      });
      
      return {
        'success': true,
        'isOffline': true,
        'message': 'Venta guardada localmente. Se sincronizará cuando haya conexión.',
      };
    }
  }

  /// Asigna una venta a un usuario
  Future<void> asignarVenta(int ventaId, int usuarioId) async {
    try {
      await _ventasService.asignarVenta(ventaId, usuarioId);
      // Actualizar la venta en la lista local
      final ventaIndex = _ventas.indexWhere((v) => v.id == ventaId);
      if (ventaIndex != -1) {
        _ventas[ventaIndex].usuarioIdAsignado = usuarioId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al asignar venta: $e');
      rethrow;
    }
  }

  /// Asigna una venta automáticamente a otro repartidor
  Future<Map<String, dynamic>> asignarVentaAutomaticamente(int ventaId, int usuarioIdExcluir) async {
    try {
      final resultado = await _ventasService.asignarVentaAutomaticamente(ventaId, usuarioIdExcluir);
      // Actualizar la venta en la lista local
      if (resultado['asignada'] == true && resultado['usuarioAsignadoId'] != null) {
        final ventaIndex = _ventas.indexWhere((v) => v.id == ventaId);
        if (ventaIndex != -1) {
          _ventas[ventaIndex].usuarioIdAsignado = resultado['usuarioAsignadoId'];
          notifyListeners();
        }
      }
      return resultado;
    } catch (e) {
      debugPrint('Error al asignar venta automáticamente: $e');
      rethrow;
    }
  }

  /// Cuenta ventas pendientes de sincronización
  Future<int> contarVentasPendientes() async {
    final stats = await _db.getStats();
    return stats['pending'] ?? 0;
  }

  /// Sincroniza manualmente las ventas pendientes utilizando el servicio simple de sync
  Future<Map<String, dynamic>> sincronizarAhora() async {
    return await _syncService.sincronizarAhora();
  }

  Future<void> eliminarVenta(int id) async {
    try {
      await _ventasService.eliminarVenta(id);
      _ventas.removeWhere((venta) => venta.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
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
          clienteId, page, pageSize);
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

  /// Guarda una venta del servidor en SQLite (ya sincronizada)
  /// Usa el ID del servidor como identificador único
  Future<void> _guardarVentaDelServidor(Ventas venta) async {
    if (venta.id == null) return;
    
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final localId = 'servidor_${venta.id}'; // Usar ID del servidor como identificador
    
    try {
      await db.transaction((txn) async {
        // Insertar o actualizar venta (usar conflictAlgorithm.replace para actualizar si existe)
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
            'usuario_creador_json': venta.usuarioCreador != null ? jsonEncode(venta.usuarioCreador!.toJson()) : null,
            'usuario_id_asignado': venta.usuarioIdAsignado,
            'usuario_asignado_json': venta.usuarioAsignado != null ? jsonEncode(venta.usuarioAsignado!.toJson()) : null,
            'estado_entrega': venta.estadoEntrega.toJson(),
            'sync_status': 'synced', // Ya está sincronizada
            'sync_attempts': 0,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Eliminar productos anteriores de esta venta
        await txn.delete(
          'ventas_productos_offline',
          where: 'venta_local_id = ?',
          whereArgs: [localId],
        );

        // Insertar productos actualizados
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

        // Eliminar pagos anteriores de esta venta
        await txn.delete(
          'ventas_pagos_offline',
          where: 'venta_local_id = ?',
          whereArgs: [localId],
        );

        // Insertar pagos actualizados si existen
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
}
