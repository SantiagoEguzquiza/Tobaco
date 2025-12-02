import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tobaco/Services/Cache/cuenta_corriente_cache_service.dart';
import '../data/ventas_offline_cache_service.dart';
import '../../../Models/Ventas.dart';
import '../../../Models/VentasProductos.dart';
import '../../../Models/Cliente.dart';
import '../../../Models/metodoPago.dart';
import '../../../Models/EstadoEntrega.dart';
import '../../../Models/ventasPago.dart';
import '../../../Models/User.dart';
import '../../Connectivity/connectivity_service.dart';
import '../../Ventas_Service/ventas_service.dart';
import '../core/database_helper.dart';

/// Servicio especializado para sincronizar ventas offline con el servidor
class VentasSyncService {
  static final VentasSyncService _instance = VentasSyncService._internal();
  factory VentasSyncService() => _instance;
  VentasSyncService._internal();

  final VentasOfflineCacheService _offlineService = VentasOfflineCacheService();
  final VentasService _ventasService = VentasService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final CuentaCorrienteCacheService _ccCacheService = CuentaCorrienteCacheService();

  bool _isSyncing = false;

  /// Verifica si hay una sincronización en curso
  bool get isSyncing => _isSyncing;

  /// Sincroniza todas las ventas offline pendientes
  Future<Map<String, dynamic>> syncPendingVentas() async {
    if (_isSyncing) {
      debugPrint('⚠️ VentasSyncService: Sincronización ya en curso');
      return {
        'success': false,
        'sincronizadas': 0,
        'fallidas': 0,
        'message': 'Sincronización en curso',
        'ventasSincronizadas': [],
      };
    }

    // Verificar conectividad antes de sincronizar
    final isConnected = await _connectivityService.checkFullConnectivity();
    if (!isConnected) {
      debugPrint('⚠️ VentasSyncService: Sin conexión o backend no disponible');
      final stats = await _offlineService.getStats();
      return {
        'success': false,
        'sincronizadas': 0,
        'fallidas': stats['pending'] ?? 0,
        'message': 'No hay conexión al backend. Verifica que el servidor esté encendido y que tengas conexión a internet.',
        'ventasSincronizadas': [],
      };
    }

    _isSyncing = true;
    int sincronizadas = 0;
    int fallidas = 0;
    List<Ventas> ventasSincronizadas = [];

    try {
      // Obtener ventas pendientes
      final ventasPendientes = await _offlineService.getPendingVentas();
      
      debugPrint('📦 VentasSyncService: ${ventasPendientes.length} ventas pendientes encontradas');
      
      if (ventasPendientes.isEmpty) {
        return {
          'success': true,
          'sincronizadas': 0,
          'fallidas': 0,
          'message': 'No hay ventas pendientes de sincronizar',
          'ventasSincronizadas': [],
        };
      }

      // Procesar cada venta pendiente
      for (var ventaData in ventasPendientes) {
        try {
          final ventaRow = ventaData['venta'] as Map<String, dynamic>;
          final localId = ventaRow['local_id'] as String;

          // Construir objeto Ventas desde los datos
          final venta = await _buildVentaFromPendingData(ventaData);

          // Intentar sincronizar con el servidor
          final resultado = await _ventasService.crearVenta(venta);

          if (resultado['success'] == true) {
            final ventaSincronizada = resultado['venta'] as Ventas;
            final serverId = ventaSincronizada.id;

            // Marcar como sincronizada en el caché
            await _offlineService.markAsSynced(localId, serverId);

            // Actualizar cuenta corriente si corresponde
            if (venta.metodoPago == MetodoPago.cuentaCorriente) {
              await _ccCacheService.marcarMovimientosDeVentaComoSincronizados(
                ventaLocalId: localId,
                ventaServerId: serverId,
              );
            }

            sincronizadas++;
            ventasSincronizadas.add(ventaSincronizada);
            debugPrint('✅ VentasSyncService: Venta sincronizada (localId: $localId, serverId: $serverId)');
          } else {
            final errorMessage = resultado['message'] as String? ?? 'Error desconocido';
            await _offlineService.markAsSyncFailed(localId, errorMessage);
            fallidas++;
            debugPrint('❌ VentasSyncService: Error sincronizando venta (localId: $localId): $errorMessage');
          }
        } catch (e) {
          final ventaRow = ventaData['venta'] as Map<String, dynamic>;
          final localId = ventaRow['local_id'] as String;
          await _offlineService.markAsSyncFailed(localId, e.toString());
          fallidas++;
          debugPrint('❌ VentasSyncService: Excepción sincronizando venta (localId: $localId): $e');
        }
      }

      final mensaje = sincronizadas > 0
          ? '$sincronizadas venta(s) sincronizada(s) correctamente'
          : fallidas > 0
              ? 'Error al sincronizar ventas. Verifica la conexión y los datos.'
              : 'No hay ventas pendientes';

      return {
        'success': fallidas == 0,
        'sincronizadas': sincronizadas,
        'fallidas': fallidas,
        'message': mensaje,
        'ventasSincronizadas': ventasSincronizadas,
      };
    } catch (e) {
      debugPrint('❌ VentasSyncService: Error general en sincronización: $e');
      return {
        'success': false,
        'sincronizadas': sincronizadas,
        'fallidas': fallidas,
        'message': 'Error al sincronizar: ${e.toString()}',
        'ventasSincronizadas': ventasSincronizadas,
      };
    } finally {
      _isSyncing = false;
    }
  }

  /// Construye un objeto Ventas desde datos pendientes
  Future<Ventas> _buildVentaFromPendingData(Map<String, dynamic> ventaData) async {
    final ventaRow = ventaData['venta'] as Map<String, dynamic>;
    final productosRows = ventaData['productos'] as List<dynamic>;
    final pagosRows = ventaData['pagos'] as List<dynamic>?;

    // Parsear cliente
    final clienteJson = jsonDecode(ventaRow['cliente_json'] as String);
    final cliente = Cliente.fromJson(clienteJson);

    // Construir productos
    final productos = productosRows.map((p) {
      return VentasProductos(
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
        fechaChequeo: p['fecha_chequeo'] != null
            ? DateTime.parse(p['fecha_chequeo'] as String)
            : null,
        usuarioChequeoId: p['usuario_chequeo_id'] as int?,
      );
    }).toList();

    // Construir pagos
    List<VentaPago>? pagos;
    if (pagosRows != null && pagosRows.isNotEmpty) {
      pagos = pagosRows.map((p) {
        return VentaPago(
          id: p['id'] as int,
          ventaId: 0,
          metodo: MetodoPago.values[p['metodo'] as int],
          monto: p['monto'] as double,
        );
      }).toList();
    }

    // Parsear usuario creador si existe
    User? usuarioCreador;
    if (ventaRow['usuario_creador_json'] != null) {
      final usuarioJson = jsonDecode(ventaRow['usuario_creador_json'] as String);
      usuarioCreador = User.fromJson(usuarioJson);
    }

    // Parsear usuario asignado si existe
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
}
