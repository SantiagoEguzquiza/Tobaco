import 'package:flutter/foundation.dart';
import 'ventas_sync_service.dart';
import 'sync_status_model.dart';
import '../data/ventas_offline_cache_service.dart';

/// SyncManager: Orquestador de sincronización
/// Coordina la sincronización de datos pendientes con el servidor
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final VentasSyncService _ventasSyncService = VentasSyncService();
  final VentasOfflineCacheService _ventasOfflineService = VentasOfflineCacheService();

  /// Sincroniza todas las ventas pendientes
  Future<Map<String, dynamic>> syncAll() async {
    debugPrint('🔄 SyncManager: Iniciando sincronización de todas las ventas pendientes...');
    
    try {
      final resultado = await _ventasSyncService.syncPendingVentas();
      
      if (resultado['success'] == true) {
        debugPrint('✅ SyncManager: Sincronización completada exitosamente');
      } else {
        debugPrint('⚠️ SyncManager: Sincronización completada con errores');
      }
      
      return resultado;
    } catch (e) {
      debugPrint('❌ SyncManager: Error en sincronización: $e');
      return {
        'success': false,
        'sincronizadas': 0,
        'fallidas': 0,
        'message': 'Error al sincronizar: ${e.toString()}',
        'ventasSincronizadas': [],
      };
    }
  }

  /// Obtiene el estado de sincronización
  Future<SyncStatusModel> getSyncStatus() async {
    final stats = await _ventasOfflineService.getStats();
    
    return SyncStatusModel(
      totalPending: stats['pending'] ?? 0,
      totalSynced: stats['synced'] ?? 0,
      totalFailed: stats['failed'] ?? 0,
      isSyncing: _ventasSyncService.isSyncing,
    );
  }

  /// Verifica si hay datos pendientes de sincronizar
  Future<bool> hasPendingData() async {
    final status = await getSyncStatus();
    return status.hasPending;
  }

  /// Verifica si hay errores en la sincronización
  Future<bool> hasErrors() async {
    final status = await getSyncStatus();
    return status.hasErrors;
  }
}
