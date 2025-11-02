import 'dart:async';
import 'dart:convert';
import '../Cache/ventas_offline_cache_service.dart';
import '../Ventas_Service/ventas_service.dart';
import '../../Models/Ventas.dart';
import '../Connectivity/connectivity_service.dart';

/// Servicio simple de sincronización de ventas offline
class SimpleSyncService {
  static final SimpleSyncService _instance = SimpleSyncService._internal();
  factory SimpleSyncService() => _instance;
  SimpleSyncService._internal();

  final VentasOfflineCacheService _offlineService = VentasOfflineCacheService();
  final VentasService _ventasService = VentasService();
  final ConnectivityService _connectivityService = ConnectivityService();

  Timer? _syncTimer;
  bool _isSyncing = false;
  int _intentosSinDatos = 0;

  /// Inicia el servicio de sincronización (optimizado)
  void iniciar() {
    // Auto-sincronización deshabilitada: solo manual mediante botón
    // Método dejado intencionalmente vacío para evitar ejecuciones en background
  }

  /// Sincronización inteligente que verifica conectividad primero
  Future<void> _sincronizarInteligente() async {
    // Solo sincronizar si hay conexión
    if (!_connectivityService.isFullyConnected) {
      // Si no hay conexión, saltar esta sincronización
      return;
    }

    // Si llevamos 5 intentos sin datos, reducir frecuencia
    if (_intentosSinDatos >= 5) {
      // Solo sincronizar 1 de cada 3 veces (efectivamente cada 3 minutos)
      if (DateTime.now().second % 3 != 0) {
        return;
      }
    }

    await sincronizarAhora();
  }

  /// Sincroniza ventas offline pendientes
  Future<Map<String, dynamic>> sincronizarAhora() async {
    if (_isSyncing) {
      
      return {
        'success': false,
        'sincronizadas': 0,
        'fallidas': 0,
        'message': 'Sincronización en curso',
        'ventasSincronizadas': [],
      };
    }

    _isSyncing = true;
    int sincronizadas = 0;
    int fallidas = 0;
    List<Ventas> ventasSincronizadas = [];

    try {
      // Limpiar ventas atascadas en "syncing" al inicio
      await _offlineService.limpiarSyncingAtascadas();
      
      
      final ventasPendientes = await _offlineService.obtenerVentasPendientes();
      
      if (ventasPendientes.isEmpty) {
        _intentosSinDatos++; // Incrementar contador
        // Solo imprimir cada 5 intentos para no llenar el log
        if (_intentosSinDatos % 5 == 0) {
          
        }
        return {
          'success': true,
          'sincronizadas': 0,
          'fallidas': 0,
          'message': 'No hay ventas pendientes',
          'ventasSincronizadas': [],
        };
      }

      // Resetear contador cuando hay datos
      _intentosSinDatos = 0;

      

      for (var ventaData in ventasPendientes) {
        final ventaId = ventaData['id'] as int;
        
        // Intentar marcar como "syncing" - retorna false si ya está siendo sincronizada
        final marcadoExitoso = await _offlineService.marcarComoSyncing(ventaId);
        
        if (!marcadoExitoso) {
          // Ya está siendo sincronizada por otro proceso, saltar
          continue;
        }
        
        try {
          // Parsear la venta
          final ventaJson = jsonDecode(ventaData['venta_json'] as String);
          final venta = Ventas.fromJson(ventaJson);
          
          

          // Enviar al servidor (usa timeout del servicio - 10s)
          final response = await _ventasService.crearVenta(venta);
          
          // Actualizar el ID de la venta
          if (response['ventaId'] != null) {
            venta.id = response['ventaId'];
          }

          // IMPORTANTE: Marcar como sincronizada DESPUÉS de éxito
          // Esto asegura que la venta solo se marca si realmente fue creada en el servidor
          await _offlineService.marcarComoSincronizada(ventaId);
          
          // Agregar a lista de ventas sincronizadas
          ventasSincronizadas.add(venta);
          sincronizadas++;
          

        } catch (e) {
          // Si falla, revertir el marcado de "syncing" para que pueda intentarse de nuevo
          await _offlineService.revertirSyncing(ventaId);
          fallidas++;
          
          // Continuar con las demás ventas
        }

        // Pausa pequeña entre ventas
        await Future.delayed(Duration(milliseconds: 500));
      }

      

      // Limpiar ventas sincronizadas
      if (sincronizadas > 0) {
        await _offlineService.limpiarVentasSincronizadas();
        
      }

      return {
        'success': fallidas == 0,
        'sincronizadas': sincronizadas,
        'fallidas': fallidas,
        'message': '$sincronizadas ventas sincronizadas, $fallidas fallidas',
        'ventasSincronizadas': ventasSincronizadas,
      };

    } catch (e) {
      
      return {
        'success': false,
        'sincronizadas': sincronizadas,
        'fallidas': fallidas,
        'message': 'Error: $e',
        'ventasSincronizadas': ventasSincronizadas,
      };
    } finally {
      // Asegurar que el flag se resetee SIEMPRE
      _isSyncing = false;
    }
  }

  /// Detiene el servicio
  void detener() {
    _syncTimer?.cancel();
    _syncTimer = null;
    
  }
}

