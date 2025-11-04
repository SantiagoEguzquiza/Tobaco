import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../Connectivity/connectivity_service.dart';
import '../Cache/database_helper.dart';
import '../Ventas_Service/ventas_service.dart';
import '../../Models/Ventas.dart';
import '../../Models/VentasProductos.dart';
import '../../Models/Cliente.dart';
import '../../Models/ventasPago.dart';
import '../../Models/metodoPago.dart';
import '../../Models/EstadoEntrega.dart';
import '../../Models/User.dart';

/// Servicio de sincronización de ventas offline
/// Se encarga de enviar al backend las ventas creadas sin conexión
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final VentasService _ventasService = VentasService();

  StreamController<SyncStatus>? _syncStatusController;
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _syncTimer;
  
  bool _isSyncing = false;
  int _pendingCount = 0;
  int _failedCount = 0;

  /// Stream que emite el estado de sincronización
  Stream<SyncStatus> get onSyncStatusChanged {
    _syncStatusController ??= StreamController<SyncStatus>.broadcast();
    return _syncStatusController!.stream;
  }

  /// Número de ventas pendientes de sincronización
  int get pendingCount => _pendingCount;
  
  /// Número de ventas que fallaron en la sincronización
  int get failedCount => _failedCount;
  
  /// Indica si hay una sincronización en progreso
  bool get isSyncing => _isSyncing;

  /// Inicializa el servicio de sincronización
  Future<void> initialize() async {
    print('🔄 SyncService: Inicializando...');

    // Asegurar que la base de datos esté inicializada primero
    try {
      await _dbHelper.database; // Esto fuerza la creación de la BD
      print('✅ SyncService: Base de datos inicializada');
    } catch (e) {
      print('❌ SyncService: Error inicializando base de datos: $e');
      // Continuar de todas formas
    }

    // Actualizar contadores
    try {
      await _updateStats();
    } catch (e) {
      print('⚠️ SyncService: Error actualizando stats (ignorando): $e');
      _pendingCount = 0;
      _failedCount = 0;
    }

    // Escuchar cambios en la conectividad
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected && !_isSyncing) {
        print('🔄 SyncService: Conectividad restaurada, iniciando sincronización...');
        syncPendingVentas();
      }
    });

    // Sincronizar cada 5 minutos si hay conexión
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      if (_connectivityService.isFullyConnected && !_isSyncing && _pendingCount > 0) {
        print('🔄 SyncService: Sincronización programada iniciada');
        await syncPendingVentas();
      }
    });

    // Intentar sincronización inicial
    if (_connectivityService.isFullyConnected && _pendingCount > 0) {
      print('🔄 SyncService: Sincronización inicial');
      await syncPendingVentas();
    }

    print('✅ SyncService: Inicializado correctamente');
  }

  /// Actualiza las estadísticas de sincronización
  Future<void> _updateStats() async {
    final stats = await _dbHelper.getStats();
    _pendingCount = stats['pending'] ?? 0;
    _failedCount = stats['failed'] ?? 0;
    
    _notifySyncStatus(SyncStatus(
      isSyncing: _isSyncing,
      pendingCount: _pendingCount,
      failedCount: _failedCount,
      lastSyncTime: DateTime.now(),
    ));
  }

  /// Sincroniza todas las ventas pendientes
  Future<SyncResult> syncPendingVentas() async {
    if (_isSyncing) {
      print('⚠️ SyncService: Ya hay una sincronización en progreso');
      return SyncResult(
        success: false,
        syncedCount: 0,
        failedCount: 0,
        message: 'Sincronización ya en progreso',
      );
    }

    if (!_connectivityService.isFullyConnected) {
      print('⚠️ SyncService: No hay conexión disponible');
      return SyncResult(
        success: false,
        syncedCount: 0,
        failedCount: 0,
        message: 'Sin conexión a internet o backend no disponible',
      );
    }

    _isSyncing = true;
    _notifySyncStatus(SyncStatus(
      isSyncing: true,
      pendingCount: _pendingCount,
      failedCount: _failedCount,
      lastSyncTime: DateTime.now(),
    ));

    int syncedCount = 0;
    int failedCount = 0;

    try {
      print('🔄 SyncService: Obteniendo ventas pendientes...');
      final pendingVentas = await _dbHelper.getPendingVentas();
      

      for (var ventaData in pendingVentas) {
        try {
          final venta = _buildVentaFromData(ventaData);
          final localId = ventaData['venta']['local_id'] as String;

          print('📤 SyncService: Enviando venta $localId al servidor...');
          
          // Enviar al backend
          await _ventasService.crearVenta(venta);
          
          // Marcar como sincronizada
          await _dbHelper.markVentaAsSynced(localId, null);
          syncedCount++;
          
          print('✅ SyncService: Venta $localId sincronizada correctamente');
        } catch (e) {
          final localId = ventaData['venta']['local_id'] as String;
          final errorMessage = e.toString();
          
          print('❌ SyncService: Error sincronizando venta $localId: $errorMessage');
          
          await _dbHelper.markVentaAsSyncFailed(localId, errorMessage);
          failedCount++;
        }

        // Pequeña pausa entre sincronizaciones para no saturar el servidor
        await Future.delayed(Duration(milliseconds: 500));
      }

      await _updateStats();

      final result = SyncResult(
        success: failedCount == 0,
        syncedCount: syncedCount,
        failedCount: failedCount,
        message: 'Sincronización completada: $syncedCount exitosas, $failedCount fallidas',
      );

      print('✅ SyncService: ${result.message}');
      return result;
    } catch (e) {
      print('❌ SyncService: Error general en sincronización: $e');
      
      await _updateStats();
      
      return SyncResult(
        success: false,
        syncedCount: syncedCount,
        failedCount: failedCount,
        message: 'Error en sincronización: $e',
      );
    } finally {
      _isSyncing = false;
      await _updateStats();
    }
  }

  /// Reintentar sincronización de ventas fallidas
  Future<SyncResult> retrySyncFailedVentas() async {
    print('🔄 SyncService: Reintentando sincronización de ventas fallidas...');
    
    final stats = await _dbHelper.getStats();
    final failedCount = stats['failed'] ?? 0;
    
    if (failedCount == 0) {
      return SyncResult(
        success: true,
        syncedCount: 0,
        failedCount: 0,
        message: 'No hay ventas fallidas para reintentar',
      );
    }

    // Obtener todas las ventas y marcar las fallidas como pendientes
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE ventas_offline SET sync_status = ?, error_message = NULL WHERE sync_status = ?',
      ['pending', 'failed'],
    );

    await _updateStats();

    // Sincronizar
    return await syncPendingVentas();
  }

  /// Construye un objeto Ventas desde los datos de la base de datos
  Ventas _buildVentaFromData(Map<String, dynamic> data) {
    final ventaRow = data['venta'] as Map<String, dynamic>;
    final productosRows = data['productos'] as List<dynamic>;
    final pagosRows = data['pagos'] as List<dynamic>;

    // Construir productos
    List<VentasProductos> productos = productosRows.map((p) {
      final productMap = p as Map<String, dynamic>;
      return VentasProductos(
        productoId: productMap['producto_id'] as int,
        nombre: productMap['nombre'] as String,
        precio: productMap['precio'] as double,
        cantidad: productMap['cantidad'] as double,
        categoria: productMap['categoria'] as String,
        categoriaId: productMap['categoria_id'] as int,
        precioFinalCalculado: productMap['precio_final_calculado'] as double,
        entregado: (productMap['entregado'] as int) == 1,
        motivo: productMap['motivo'] as String?,
        nota: productMap['nota'] as String?,
        fechaChequeo: productMap['fecha_chequeo'] != null 
          ? DateTime.parse(productMap['fecha_chequeo'] as String) 
          : null,
        usuarioChequeoId: productMap['usuario_chequeo_id'] as int?,
      );
    }).toList();

    // Construir pagos
    List<VentaPago>? pagos;
    if (pagosRows.isNotEmpty) {
      pagos = pagosRows.map((p) {
        final pagoMap = p as Map<String, dynamic>;
        return VentaPago(
          id: pagoMap['id'] as int,
          ventaId: 0,
          metodo: MetodoPago.values[pagoMap['metodo'] as int],
          monto: pagoMap['monto'] as double,
        );
      }).toList();
    }

    // Construir cliente
    final clienteJson = jsonDecode(ventaRow['cliente_json'] as String);
    final cliente = Cliente.fromJson(clienteJson);

    // Construir usuario creador si existe
    User? usuarioCreador;
    if (ventaRow['usuario_creador_json'] != null) {
      final usuarioJson = jsonDecode(ventaRow['usuario_creador_json'] as String);
      usuarioCreador = User.fromJson(usuarioJson);
    }
    
    // Construir usuario asignado si existe
    User? usuarioAsignado;
    if (ventaRow['usuario_asignado_json'] != null) {
      final usuarioJson = jsonDecode(ventaRow['usuario_asignado_json'] as String);
      usuarioAsignado = User.fromJson(usuarioJson);
    }

    return Ventas(
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
  }

  /// Notifica el estado de sincronización a los listeners
  void _notifySyncStatus(SyncStatus status) {
    if (_syncStatusController != null && !_syncStatusController!.isClosed) {
      _syncStatusController!.add(status);
    }
  }

  /// Limpia ventas sincronizadas antiguas
  Future<int> cleanOldSyncedVentas({int daysOld = 30}) async {
    print('🧹 SyncService: Limpiando ventas antiguas...');
    final deleted = await _dbHelper.cleanOldSyncedVentas(daysOld: daysOld);
    await _updateStats();
    return deleted;
  }

  /// Libera los recursos del servicio
  void dispose() {
    print('🔄 SyncService: Liberando recursos...');
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncStatusController?.close();
  }
}

/// Estado de sincronización
class SyncStatus {
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final DateTime lastSyncTime;

  SyncStatus({
    required this.isSyncing,
    required this.pendingCount,
    required this.failedCount,
    required this.lastSyncTime,
  });

  @override
  String toString() => 
    'SyncStatus(syncing: $isSyncing, pending: $pendingCount, failed: $failedCount)';
}

/// Resultado de sincronización
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final String message;

  SyncResult({
    required this.success,
    required this.syncedCount,
    required this.failedCount,
    required this.message,
  });

  @override
  String toString() => message;
}

