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

    // CRÍTICO: Verificar conectividad ANTES de sincronizar
    // Si no hay conexión, NO intentar sincronizar y NO modificar las ventas
    final isConnected = await _connectivityService.checkFullConnectivity();
    if (!isConnected) {
      debugPrint('⚠️ VentasSyncService: Sin conexión o backend no disponible - ABORTANDO sincronización');
      final stats = await _offlineService.getStats();
      return {
        'success': false,
        'sincronizadas': 0,
        'fallidas': 0, // No son fallidas, solo no se pueden sincronizar
        'message': 'Sin conexión. No se puede sincronizar en este momento. Los datos siguen guardados localmente.',
        'ventasSincronizadas': [],
        'noConnection': true, // Flag para identificar que fue por falta de conexión
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

          // CRÍTICO: Verificar conexión antes de cada intento de sincronización
          // Si se perdió la conexión durante el proceso, abortar
          final stillConnected = await _connectivityService.checkFullConnectivity();
          if (!stillConnected) {
            debugPrint('⚠️ VentasSyncService: Se perdió la conexión durante la sincronización');
            debugPrint('⚠️ VentasSyncService: NO se modifica el estado de la venta - permanece como pendiente');
            fallidas++;
            continue; // Continuar con la siguiente venta sin modificar esta
          }

          // Intentar sincronizar con el servidor
          final resultado = await _ventasService.crearVenta(venta);

          // CRÍTICO: Solo marcar como sincronizada si recibimos confirmación exitosa del servidor
          if (resultado['success'] == true) {
            final ventaSincronizada = resultado['venta'] as Ventas;
            final serverId = ventaSincronizada.id;

            // SOLO después de confirmación exitosa del servidor, marcar como sincronizada
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
          
          // Verificar si perdió conexión durante la sincronización
          final stillConnected = await _connectivityService.checkFullConnectivity();
          if (!stillConnected) {
            debugPrint('⚠️ VentasSyncService: Se perdió la conexión durante la sincronización');
            debugPrint('⚠️ VentasSyncService: NO se modifica el estado de la venta - permanece como pendiente');
            fallidas++;
            continue; // Continuar con la siguiente venta sin modificar esta
          }
          
          // Marcar como fallida PERO NO BORRAR - la venta permanece en la BD para reintentar
          await _offlineService.markAsSyncFailed(localId, e.toString());
          fallidas++;
          debugPrint('❌ VentasSyncService: Excepción sincronizando venta (localId: $localId): $e');
          debugPrint('✅ VentasSyncService: La venta permanece en la BD local para reintentar más tarde');
        }
      }

      final mensaje = sincronizadas > 0
          ? '$sincronizadas venta(s) sincronizada(s) correctamente'
          : fallidas > 0
              ? 'Error al sincronizar. Los datos siguen guardados localmente. Puedes reintentar más tarde.'
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
      debugPrint('⚠️ VentasSyncService: NINGUNA venta fue borrada - todas permanecen en la BD local');
      return {
        'success': false,
        'sincronizadas': sincronizadas,
        'fallidas': fallidas,
        'message': 'Error al sincronizar: ${e.toString()}. Los datos siguen guardados localmente.',
        'ventasSincronizadas': ventasSincronizadas,
      };
    } finally {
      _isSyncing = false;
      debugPrint('✅ VentasSyncService: Sincronización finalizada. Estado de ventas preservado.');
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
