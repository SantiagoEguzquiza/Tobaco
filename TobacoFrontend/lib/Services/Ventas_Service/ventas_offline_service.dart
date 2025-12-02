import '../Connectivity/connectivity_service.dart';
import '../Cache/database_helper.dart';
import '../Cache/cache_manager.dart';
import '../Sync/sync_service.dart';
import './ventas_service.dart';
import '../../Models/Ventas.dart';
import '../Cache/cuenta_corriente_cache_service.dart';
import '../../Models/metodoPago.dart';

/// Servicio offline-first para ventas
/// Gestiona la creación de ventas tanto online como offline
/// y sincroniza automáticamente cuando hay conexión
class VentasOfflineService {
  static final VentasOfflineService _instance = VentasOfflineService._internal();
  factory VentasOfflineService() => _instance;
  VentasOfflineService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CacheManager _cacheManager = CacheManager();
  final SyncService _syncService = SyncService();
  final VentasService _ventasService = VentasService();
  final CuentaCorrienteCacheService _ccCacheService = CuentaCorrienteCacheService();

  bool _isInitialized = false;

  /// Inicializa el servicio offline
  Future<void> initialize() async {
    if (_isInitialized) {
      
      return;
    }

    

    try {
      // ⭐ VERIFICAR QUE LAS TABLAS EXISTAN
      await _dbHelper.ensureTablesExist();
      
      // Inicializar servicios de conectividad y sincronización
      await _connectivityService.initialize();
      await _syncService.initialize();
      
      _isInitialized = true;
      
      
      // Mostrar estado inicial
      final stats = await _dbHelper.getStats();
      
    } catch (e) {
      
      rethrow;
    }
  }

  /// Crea una venta (offline-first)
  /// Intenta crearla online, si falla la guarda localmente
  Future<VentaCreationResult> crearVenta(Ventas venta) async {
    if (!_isInitialized) {
      await initialize();
    }

    
    
    // Verificar conectividad
    final isConnected = _connectivityService.isFullyConnected;
    

    if (isConnected) {
      // Intentar crear online
      try {
        
        await _ventasService.crearVenta(venta);
        
        
        
        // ⭐ ACTUALIZAR CACHÉ: Refrescar ventas desde el servidor para que estén disponibles offline
        try {
          
          
          // Asegurar que las tablas del caché existan
          await _cacheManager.ensureTablesExist();
          
          final ventasActualizadas = await _ventasService.obtenerVentas()
              .timeout(Duration(seconds: 5));
          
          if (ventasActualizadas.isNotEmpty) {
            await _cacheManager.cacheVentas(ventasActualizadas);
            
          }
        } catch (cacheError) {
          
          // No es crítico, continuar de todas formas
        }
        
        // Intentar sincronizar ventas pendientes en background
        _syncService.syncPendingVentas().then((result) {
          if (result.success) {
            
          }
        }).catchError((e) {
          
        });
        
        return VentaCreationResult(
          success: true,
          isOffline: false,
          localId: null,
          message: 'Venta creada exitosamente',
        );
      } catch (e) {
        
        
        
        // Si falla online, guardar offline
        return await _saveVentaOffline(venta, 'Error online: $e');
      }
    } else {
      // Sin conexión, guardar offline directamente
    
      return await _saveVentaOffline(venta, 'Sin conexión a internet o backend');
    }
  }

  /// Guarda una venta offline
  Future<VentaCreationResult> _saveVentaOffline(Ventas venta, String reason) async {
    try {
      final localId = await _dbHelper.saveVentaOffline(venta);
      final deudaGenerada = _calcularMontoCuentaCorriente(venta);
      if (deudaGenerada > 0) {
        await _ccCacheService.registrarVentaOffline(
          clienteId: venta.clienteId,
          clienteNombre: venta.cliente.nombre,
          ventaLocalId: localId,
          deudaGenerada: deudaGenerada,
          venta: venta,
        );
      }
      
      
      
      
      return VentaCreationResult(
        success: true,
        isOffline: true,
        localId: localId,
        message: 'Venta guardada localmente. Se sincronizará cuando haya conexión.',
      );
    } catch (e) {
      
      
      return VentaCreationResult(
        success: false,
        isOffline: false,
        localId: null,
        message: 'Error guardando venta: $e',
      );
    }
  }

  /// Obtiene ventas (combina online y offline)
  Future<List<Ventas>> obtenerVentas() async {
    if (!_isInitialized) {
      
      await initialize();
    }

    
    
    // SIEMPRE obtener ventas offline primero (son rápidas, desde SQLite)
    List<Ventas> ventasOffline = [];
    try {
      ventasOffline = await _dbHelper.getAllOfflineVentas();
      
    } catch (e) {
      
    }

    // INTENTAR SIEMPRE obtener del backend
    List<Ventas> ventasOnline = [];
    List<Ventas> ventasCache = [];
    
    try {
      
      
      // Timeout de 5 segundos - si falla, usamos caché
      ventasOnline = await _ventasService.obtenerVentas()
          .timeout(
            Duration(seconds: 5),
            onTimeout: () {
              
              return <Ventas>[];
            },
          );
      
      if (ventasOnline.isNotEmpty) {
        
        
        // ⭐ GUARDAR EN CACHÉ para uso futuro offline
        try {
          await _cacheManager.ensureTablesExist(); // Verificar tablas antes de cachear
          await _cacheManager.cacheVentas(ventasOnline);
          
        } catch (cacheError) {
          
          // Continuar de todas formas
        }
      } else {
        
      }
    } catch (e) {
      
      
      
      // Si falla obtener del backend, usar caché
      try {
        await _cacheManager.ensureTablesExist(); // Verificar tablas antes de leer caché
        ventasCache = await _cacheManager.getVentasFromCache();
        
      } catch (cacheError) {
        
      }
    }

    // Combinar ventas: offline primero, luego online (o caché si no hay online)
    final ventasCombinadas = [
      ...ventasOffline,
      ...(ventasOnline.isNotEmpty ? ventasOnline : ventasCache),
    ];
    
    
    print('   - Offline (creadas localmente): ${ventasOffline.length}');
    print('   - Online (del servidor): ${ventasOnline.length}');
    print('   - Caché (servidor anterior): ${ventasCache.length}');
    
    return ventasCombinadas;
  }

  /// Fuerza la sincronización de ventas pendientes
  Future<SyncResult> sincronizarAhora() async {
    if (!_isInitialized) {
      await initialize();
    }

    
    
    if (!_connectivityService.isFullyConnected) {
      return SyncResult(
        success: false,
        syncedCount: 0,
        failedCount: 0,
        message: 'Sin conexión disponible',
      );
    }

    return await _syncService.syncPendingVentas();
  }

  /// Reintentar ventas fallidas
  Future<SyncResult> reintentarVentasFallidas() async {
    if (!_isInitialized) {
      await initialize();
    }

    
    return await _syncService.retrySyncFailedVentas();
  }

  /// Obtiene estadísticas de sincronización
  Future<Map<String, int>> obtenerEstadisticas() async {
    return await _dbHelper.getStats();
  }

  double _calcularMontoCuentaCorriente(Ventas venta) {
    if (venta.pagos != null && venta.pagos!.isNotEmpty) {
      return venta.pagos!
          .where((pago) => pago.metodo == MetodoPago.cuentaCorriente)
          .fold(0.0, (sum, pago) => sum + pago.monto);
    }
    return venta.metodoPago == MetodoPago.cuentaCorriente ? venta.total : 0;
  }

  /// Obtiene el estado de conectividad actual
  bool get tieneConexion => _connectivityService.isFullyConnected;

  /// Obtiene el número de ventas pendientes
  int get ventasPendientes => _syncService.pendingCount;

  /// Obtiene el número de ventas fallidas
  int get ventasFallidas => _syncService.failedCount;

  /// Stream de cambios en la conectividad
  Stream<bool> get onConnectivityChanged => _connectivityService.onConnectivityChanged;

  /// Stream de cambios en el estado de sincronización
  Stream<SyncStatus> get onSyncStatusChanged => _syncService.onSyncStatusChanged;

  /// Limpia ventas antiguas sincronizadas
  Future<int> limpiarVentasAntiguas({int dias = 30}) async {
    return await _syncService.cleanOldSyncedVentas(daysOld: dias);
  }

  /// Elimina una venta offline específica
  Future<void> eliminarVentaOffline(String localId) async {
    await _dbHelper.deleteVentaOffline(localId);
  }

  /// Libera recursos
  void dispose() {
    
    _syncService.dispose();
    _connectivityService.dispose();
  }
}

/// Resultado de la creación de una venta
class VentaCreationResult {
  final bool success;
  final bool isOffline;
  final String? localId;
  final String message;

  VentaCreationResult({
    required this.success,
    required this.isOffline,
    required this.localId,
    required this.message,
  });

  @override
  String toString() => message;
}

