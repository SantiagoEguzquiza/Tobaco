import 'package:flutter/material.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_service.dart';
import 'package:tobaco/Services/Cache/ventas_cache_service.dart';
import 'package:tobaco/Services/Cache/ventas_offline_cache_service.dart';
import 'package:tobaco/Services/Sync/simple_sync_service.dart';

class VentasProvider with ChangeNotifier {
  final VentasService _ventasService = VentasService();
  final VentasCacheService _cacheService = VentasCacheService();
  final VentasOfflineCacheService _offlineService = VentasOfflineCacheService();
  final SimpleSyncService _syncService = SimpleSyncService();

  List<Ventas> _ventas = [];
  bool _cargando = false;

  List<Ventas> get ventas => _ventas;
  bool get cargando => _cargando;

  /// Obtiene ventas: intenta del servidor, si falla usa caché (optimizado para offline)
  Future<List<Ventas>> obtenerVentas() async {
    print('📡 VentasProvider: Intentando obtener ventas del servidor...');
    
    try {
      // Timeout reducido a 500ms para ser ultra rápido offline
      _ventas = await _ventasService.obtenerVentas()
          .timeout(Duration(milliseconds: 500));
      
      print('✅ VentasProvider: ${_ventas.length} ventas obtenidas del servidor');
      
      // Guardar en caché para uso offline (en background, no esperar)
      if (_ventas.isNotEmpty) {
        _cacheService.guardarVentasEnCache(_ventas).catchError((e) {
          print('⚠️ VentasProvider: Error guardando en caché: $e');
        });
      }
      
    } catch (e) {
      print('⚠️ VentasProvider: Error obteniendo del servidor: $e');
      print('📦 VentasProvider: Cargando ventas del caché...');
      
      // Si falla, cargar del caché
      _ventas = await _cacheService.obtenerVentasDelCache();
      
      if (_ventas.isEmpty) {
        print('❌ VentasProvider: No hay ventas en caché');
      } else {
        print('✅ VentasProvider: ${_ventas.length} ventas cargadas del caché');
      }
    }

    return _ventas;
  }

  /// Crea una venta (online u offline)
  Future<Map<String, dynamic>> crearVenta(Ventas venta) async {
    print('💰 VentasProvider: Creando venta...');
    
    try {
      // Intentar crear online con timeout (1s)
      await _ventasService.crearVenta(venta)
          .timeout(Duration(seconds: 1));
      
      print('✅ VentasProvider: Venta creada online exitosamente');
      
      // Agregar a la lista local
      _ventas.insert(0, venta);
      
      // Actualizar caché en background
      _cacheService.guardarVentasEnCache(_ventas).catchError((e) {
        print('⚠️ VentasProvider: Error actualizando caché: $e');
      });
      
      return {
        'success': true,
        'isOffline': false,
        'message': 'Venta creada exitosamente',
      };
      
    } catch (e) {
      print('⚠️ VentasProvider: Error creando venta online: $e');
      print('📴 VentasProvider: Guardando venta offline...');
      
      try {
        // Guardar offline para sincronizar después
        await _offlineService.guardarVentaOffline(venta);
        
        print('✅ VentasProvider: Venta guardada offline');
        
        return {
          'success': true,
          'isOffline': true,
          'message': 'Venta guardada localmente. Se sincronizará cuando haya conexión.',
        };
      } catch (offlineError) {
        print('❌ VentasProvider: Error guardando venta offline: $offlineError');
        
        return {
          'success': false,
          'isOffline': false,
          'message': 'Error guardando venta: $offlineError',
        };
      }
    }
  }

  /// Cuenta ventas pendientes de sincronización
  Future<int> contarVentasPendientes() async {
    return await _offlineService.contarPendientes();
  }

  /// Sincroniza manualmente las ventas pendientes
  Future<Map<String, dynamic>> sincronizarAhora() async {
    print('🔄 VentasProvider: Sincronización manual iniciada');
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
}
