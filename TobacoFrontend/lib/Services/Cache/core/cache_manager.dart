import 'package:flutter/foundation.dart';
import '../data/clientes_cache_service.dart';
import '../data/productos_cache_service.dart';
import '../data/categorias_cache_service.dart';
import '../data/ventas_cache_service.dart';
import '../data/ventas_offline_cache_service.dart';
import '../../../Models/Cliente.dart';
import '../../../Models/Producto.dart';
import '../../../Models/Categoria.dart';
import '../../../Models/Ventas.dart';

/// CacheManager: Orquestador principal de los servicios de caché
/// Actúa como fachada que coordina todos los servicios de caché
/// No maneja lógica de negocio, solo orquesta las operaciones
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final ClientesCacheService _clientesService = ClientesCacheService();
  final ProductosCacheService _productosService = ProductosCacheService();
  final CategoriasCacheService _categoriasService = CategoriasCacheService();
  final VentasCacheService _ventasService = VentasCacheService();
  final VentasOfflineCacheService _ventasOfflineService = VentasOfflineCacheService();

  /// Refresca todos los cachés con nuevos datos
  /// Útil para cargar datos iniciales después de sincronizar con el servidor
  Future<void> refreshAll({
    List<Cliente>? clientes,
    List<Producto>? productos,
    List<Categoria>? categorias,
    List<Ventas>? ventas,
  }) async {
    debugPrint('🔄 CacheManager: Refrescando todos los cachés...');
    
    try {
      if (clientes != null) {
        await _clientesService.saveAll(clientes);
      }
      
      if (productos != null) {
        await _productosService.saveAll(productos);
      }
      
      if (categorias != null) {
        await _categoriasService.saveAll(categorias);
      }
      
      if (ventas != null) {
        await _ventasService.saveAll(ventas);
      }
      
      debugPrint('✅ CacheManager: Todos los cachés refrescados correctamente');
    } catch (e) {
      debugPrint('❌ CacheManager: Error refrescando cachés: $e');
      rethrow;
    }
  }

  /// Limpia todos los cachés
  Future<void> clearAll() async {
    debugPrint('🧹 CacheManager: Limpiando todos los cachés...');
    
    try {
      await Future.wait([
        _clientesService.clear(),
        _productosService.clear(),
        _categoriasService.clear(),
        _ventasService.clear(),
      ]);
      
      debugPrint('✅ CacheManager: Todos los cachés limpiados correctamente');
    } catch (e) {
      debugPrint('❌ CacheManager: Error limpiando cachés: $e');
      rethrow;
    }
  }

  /// Carga datos iniciales en los cachés
  /// Útil para preparar la app con datos básicos
  Future<void> loadInitialData({
    required List<Cliente> clientes,
    required List<Producto> productos,
    required List<Categoria> categorias,
  }) async {
    debugPrint('📦 CacheManager: Cargando datos iniciales...');
    
    try {
      await refreshAll(
        clientes: clientes,
        productos: productos,
        categorias: categorias,
      );
      
      debugPrint('✅ CacheManager: Datos iniciales cargados correctamente');
    } catch (e) {
      debugPrint('❌ CacheManager: Error cargando datos iniciales: $e');
      rethrow;
    }
  }

  /// Verifica si hay datos en caché
  Future<Map<String, bool>> hasCachedData() async {
    return {
      'clientes': await _clientesService.hasData(),
      'productos': await _productosService.hasData(),
      'categorias': await _categoriasService.hasData(),
      'ventas': await _ventasService.hasData(),
    };
  }

  /// Obtiene estadísticas de todos los cachés
  Future<Map<String, int>> getCacheStats() async {
    return {
      'clientes': await _clientesService.count(),
      'productos': await _productosService.count(),
      'categorias': await _categoriasService.count(),
      'ventas': await _ventasService.count(),
      'ventas_offline': await _ventasOfflineService.count(),
    };
  }

  // ==================== DELEGACIÓN A SERVICIOS ESPECÍFICOS ====================

  /// Delegación a ClientesCacheService
  Future<List<Cliente>> getClientesFromCache() => _clientesService.getAll();
  Future<void> cacheClientes(List<Cliente> clientes) => _clientesService.saveAll(clientes);
  Future<Cliente?> getClienteById(int id) => _clientesService.getById(id);
  Future<List<Cliente>> buscarClientes(String query) => _clientesService.search(query);
  Future<void> upsertCliente(Cliente cliente) => _clientesService.upsert(cliente);

  /// Delegación a ProductosCacheService
  Future<List<Producto>> getProductosFromCache() => _productosService.getAll();
  Future<void> cacheProductos(List<Producto> productos) => _productosService.saveAll(productos);
  Future<Producto?> getProductoById(int id) => _productosService.getById(id);
  Future<List<Producto>> getProductosPorCategoria(int categoriaId) => _productosService.getByCategoria(categoriaId);
  Future<void> upsertProducto(Producto producto) => _productosService.upsert(producto);

  /// Delegación a CategoriasCacheService
  Future<List<Categoria>> getCategoriasFromCache() => _categoriasService.getAll();
  Future<void> cacheCategorias(List<Categoria> categorias) => _categoriasService.saveAll(categorias);
  Future<Categoria?> getCategoriaById(int id) => _categoriasService.getById(id);

  /// Delegación a VentasCacheService
  Future<List<Ventas>> getVentasFromCache() => _ventasService.getAll();
  Future<void> cacheVentas(List<Ventas> ventas) => _ventasService.saveAll(ventas);
  Future<Ventas?> getVentaById(int id) => _ventasService.getById(id);

  /// Delegación a VentasOfflineCacheService
  Future<List<Ventas>> getAllOfflineVentas() => _ventasOfflineService.getAll();
  Future<String> saveVentaOffline(Ventas venta) => _ventasOfflineService.saveWithLocalId(venta);
  Future<List<Map<String, dynamic>>> getPendingVentas() => _ventasOfflineService.getPendingVentas();
  Future<void> markVentaAsSynced(String localId, int? serverId) => _ventasOfflineService.markAsSynced(localId, serverId);
  Future<void> markVentaAsSyncFailed(String localId, String error) => _ventasOfflineService.markAsSyncFailed(localId, error);
  Future<Map<String, int>> getOfflineVentasStats() => _ventasOfflineService.getStats();
}
