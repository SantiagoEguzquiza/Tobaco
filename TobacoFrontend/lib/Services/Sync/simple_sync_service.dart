import 'dart:async';
import 'dart:convert';
import '../Cache/ventas_offline_cache_service.dart';
import '../Ventas_Service/ventas_service.dart';
import '../../Models/Ventas.dart';

/// Servicio simple de sincronización de ventas offline
class SimpleSyncService {
  static final SimpleSyncService _instance = SimpleSyncService._internal();
  factory SimpleSyncService() => _instance;
  SimpleSyncService._internal();

  final VentasOfflineCacheService _offlineService = VentasOfflineCacheService();
  final VentasService _ventasService = VentasService();

  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Inicia el servicio de sincronización (cada 30 segundos)
  void iniciar() {
    print('🔄 SimpleSyncService: Iniciando...');
    
    // Sincronizar cada 30 segundos
    _syncTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!_isSyncing) {
        sincronizarAhora();
      }
    });

    // Sincronización inicial
    Future.delayed(Duration(seconds: 5), () {
      sincronizarAhora();
    });
  }

  /// Sincroniza ventas offline pendientes
  Future<Map<String, dynamic>> sincronizarAhora() async {
    if (_isSyncing) {
      print('⚠️ SimpleSyncService: Ya hay una sincronización en curso');
      return {
        'success': false,
        'sincronizadas': 0,
        'fallidas': 0,
        'message': 'Sincronización en curso',
      };
    }

    _isSyncing = true;
    int sincronizadas = 0;
    int fallidas = 0;

    try {
      print('🔄 SimpleSyncService: Obteniendo ventas pendientes...');
      
      final ventasPendientes = await _offlineService.obtenerVentasPendientes();
      
      if (ventasPendientes.isEmpty) {
        print('✅ SimpleSyncService: No hay ventas pendientes');
        _isSyncing = false;
        return {
          'success': true,
          'sincronizadas': 0,
          'fallidas': 0,
          'message': 'No hay ventas pendientes',
        };
      }

      print('📤 SimpleSyncService: ${ventasPendientes.length} ventas pendientes de sincronizar');

      for (var ventaData in ventasPendientes) {
        try {
          // Parsear la venta
          final ventaJson = jsonDecode(ventaData['venta_json'] as String);
          final venta = Ventas.fromJson(ventaJson);
          
          final ventaId = ventaData['id'] as int;
          
          print('📤 SimpleSyncService: Sincronizando venta offline ID: $ventaId');

          // Enviar al servidor con timeout
          await _ventasService.crearVenta(venta)
              .timeout(Duration(seconds: 5));

          // Marcar como sincronizada
          await _offlineService.marcarComoSincronizada(ventaId);
          
          sincronizadas++;
          print('✅ SimpleSyncService: Venta $ventaId sincronizada exitosamente');

        } catch (e) {
          fallidas++;
          print('❌ SimpleSyncService: Error sincronizando venta: $e');
          // Continuar con las demás ventas
        }

        // Pausa pequeña entre ventas
        await Future.delayed(Duration(milliseconds: 500));
      }

      print('✅ SimpleSyncService: Sincronización completada - $sincronizadas exitosas, $fallidas fallidas');

      // Limpiar ventas sincronizadas
      if (sincronizadas > 0) {
        await _offlineService.limpiarVentasSincronizadas();
        print('🧹 SimpleSyncService: Ventas sincronizadas limpiadas');
      }

      _isSyncing = false;

      return {
        'success': fallidas == 0,
        'sincronizadas': sincronizadas,
        'fallidas': fallidas,
        'message': '$sincronizadas ventas sincronizadas, $fallidas fallidas',
      };

    } catch (e) {
      print('❌ SimpleSyncService: Error general en sincronización: $e');
      _isSyncing = false;
      
      return {
        'success': false,
        'sincronizadas': sincronizadas,
        'fallidas': fallidas,
        'message': 'Error: $e',
      };
    }
  }

  /// Detiene el servicio
  void detener() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('🔄 SimpleSyncService: Detenido');
  }
}

