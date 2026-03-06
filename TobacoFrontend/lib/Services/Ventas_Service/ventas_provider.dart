import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Models/User.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Models/ventasPago.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Cache/database_helper.dart';
import 'package:tobaco/Services/Cache/ventas_cache_service.dart';
import 'package:tobaco/Services/Cache/cuenta_corriente_cache_service.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_service.dart';
import 'package:tobaco/Services/Sync/simple_sync_service.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_service.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Services/Connectivity/connectivity_service.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class VentasProvider with ChangeNotifier {
  final VentasService _ventasService = VentasService();
  final DatabaseHelper _db = DatabaseHelper();
  final SimpleSyncService _syncService = SimpleSyncService();
  final VentasCacheService _cacheService = VentasCacheService();
  final CuentaCorrienteCacheService _ccCacheService = CuentaCorrienteCacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

  final Map<Ventas, String> _ventaLocalIds = {};

  List<Ventas> _ventas = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isOffline = false;
  bool _isSincronizando = false;
  String? _errorMessage;
  int _currentPage = 1;
  final int _pageSize = 20;
  String _searchQuery = '';
  bool _offlineMessageShown = false;
  /// Tras clearForNewUser, no mostrar caché en la próxima carga (evita datos de otro usuario).
  bool _skipCacheOnNextLoad = false;

  List<Ventas> get ventas => List.unmodifiable(_ventas);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  bool get isOffline => _isOffline;
  bool get isSincronizando => _isSincronizando;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String get searchQuery => _searchQuery;
  bool get offlineMessageShown => _offlineMessageShown;

  List<Ventas> get ventasFiltradas {
    if (_searchQuery.isEmpty) return List.unmodifiable(_ventas);
    final query = _searchQuery.toLowerCase();
    return _ventas.where((venta) {
      final cliente = venta.cliente.nombre.toLowerCase();
      final fecha = '${venta.fecha.day}/${venta.fecha.month}';
      final total = venta.total.toString();
      return cliente.contains(query) ||
          fecha.contains(query) ||
          total.contains(query);
    }).toList(growable: false);
  }

  /// Ordena _ventas: primero las pendientes offline (local_*), luego por fecha más reciente.
  /// Dentro de las ventas del servidor, se ordena por ID de base de datos (más nuevo primero),
  /// para que el orden coincida exactamente con el backend.
  void _ordenarVentasRecientesPrimero() {
    if (_ventas.isEmpty) return;
    _ventas.sort((a, b) {
      final idA = _ventaLocalIds[a] ?? '';
      final idB = _ventaLocalIds[b] ?? '';
      final aEsOffline = idA.startsWith('local_');
      final bEsOffline = idB.startsWith('local_');
      if (aEsOffline && !bEsOffline) return -1; // offline primero
      if (!aEsOffline && bEsOffline) return 1;
      // Ambos mismo tipo:
      // - Si ambos tienen ID de servidor, ordenar por ID desc (más nuevo primero).
      // - Si no, usar fecha como fallback.
      if (a.id != null && b.id != null) {
        return b.id!.compareTo(a.id!);
      }
      return b.fecha.compareTo(a.fecha);
    });
  }

  Future<void> cargarVentas({bool usarTimeoutNormal = false}) async {
    _errorMessage = null;
    _isOffline = false;
    _currentPage = 1;
    _hasMoreData = true;
    final skipCache = _skipCacheOnNextLoad;
    if (skipCache) _skipCacheOnNextLoad = false;

    // PASO 1: Mostrar datos cacheados inmediatamente solo si no acabamos de cambiar de usuario
    if (!skipCache && _ventas.isEmpty) {
      _isLoading = true;
      notifyListeners();

      try {
        final cacheadas = await _cacheService.obtenerVentasDelCache();
        final soloDelUsuario = await _filtrarVentasPorUsuarioActual(cacheadas);
        if (soloDelUsuario.isNotEmpty) {
          final combinadas = await _combinarConVentasOfflinePendientes(
            soloDelUsuario,
            incluirPendientesOffline: true,
          );
          _ventas = combinadas;
          _ordenarVentasRecientesPrimero();
          _isLoading = false;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('⚠️ VentasProvider: Error cargando caché inicial: $e');
      }
    }

    // Si saltamos caché, asegurar loading visible hasta que responda la API
    if (skipCache && _ventas.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    // PASO 2: Verificar si el backend está prendido con GET /health (2s). Sin backend → modo offline al instante.
    final backendOk = await _ventasService.backendDisponible;
    if (!backendOk) {
      _isOffline = true;
      _hasMoreData = false;
      if (_ventas.isEmpty) {
        _errorMessage = 'Sin conexión con el servidor.';
        await _cargarVentasOffline();
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    // PASO 3: Backend disponible → traer página 1 (timeout normal por si responde lento).
    try {
      final resultado = await _ventasService.obtenerVentasPaginadas(1, _pageSize);
      final ventasDelServidor = resultado['ventas'] as List<Ventas>;
      _hasMoreData = resultado['hasNextPage'] as bool? ?? false;
      _currentPage = 1;

      // Reemplazar caché con la página 1 fresca
      await _cacheService.guardarVentasEnCache(
        ventasDelServidor.where((v) => v.id != null).toList(),
        limpiarAnterior: true,
      );

      // Combinar ventas del servidor con las pendientes de sincronizar
      final combinadas = await _combinarConVentasOfflinePendientes(
        ventasDelServidor,
        incluirPendientesOffline: true,
      );

      _ventas = combinadas;
      _ordenarVentasRecientesPrimero();
      _isOffline = false;
      _offlineMessageShown = false;
    } catch (e) {
      if (AuthService.isSessionExpiredException(e)) {
        await AuthService.logout();
        _isLoading = false;
        notifyListeners();
        return;
      }
      // Marcar offline de inmediato para que el banner "Modo Offline" aparezca aunque falle algo después
      _isOffline = true;
      _hasMoreData = false;
      if (_ventas.isEmpty) {
        _errorMessage = _limpiarMensajeError(e.toString());
      }
      notifyListeners(); // Actualizar UI con el banner antes de cargar datos offline
      if (_ventas.isEmpty) {
        await _cargarVentasOffline();
      }
    } finally {
      _isLoading = false;
      _ordenarVentasRecientesPrimero();
      notifyListeners();
    }
  }

  Future<void> cargarMasVentas() async {
    if (_isLoadingMore || !_hasMoreData || _isOffline) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final resultado = await _ventasService.obtenerVentasPaginadas(nextPage, _pageSize);
      final nuevasVentas = resultado['ventas'] as List<Ventas>;
      _hasMoreData = resultado['hasNextPage'] as bool? ?? false;
      _currentPage = nextPage;

      final idsExistentes = _ventas
          .where((v) => v.id != null)
          .map((v) => v.id!)
          .toSet();

      for (final venta in nuevasVentas) {
        if (venta.id != null && !idsExistentes.contains(venta.id!)) {
          _ventas.add(venta);
          _ventaLocalIds[venta] = 'servidor_${venta.id}';
          idsExistentes.add(venta.id!);
        }
      }

      // Append al caché (no limpiar, solo agregar la nueva página)
      await _cacheService.guardarVentasEnCache(
        nuevasVentas.where((v) => v.id != null).toList(),
        limpiarAnterior: false,
      );
    } catch (e) {
      debugPrint('⚠️ VentasProvider: Error al cargar más ventas: $e');
      // Si falla al cargar más (ej. sin backend), marcar offline para que aparezca el banner y no siga intentando
      _isOffline = true;
      _hasMoreData = false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> sincronizarAhora() async {
    if (_isSincronizando) {
      return {
        'success': false,
        'message': 'Ya hay una sincronización en progreso',
        'sincronizadas': 0,
        'fallidas': 0,
      };
    }

    // CRÍTICO: Validar conexión ANTES de iniciar sincronización
    // Si no hay conexión, NO intentar sincronizar y NO modificar las ventas
    final tieneConexion = await _connectivityService.checkFullConnectivity();
    if (!tieneConexion) {
      debugPrint('⚠️ VentasProvider: Sin conexión - ABORTANDO sincronización');
      final stats = await _db.getStats();
      final cantidadPendientes = stats['pending'] ?? 0;
      
      return {
        'success': false,
        'sincronizadas': 0,
        'fallidas': 0,
        'message': 'Sin conexión. No se puede sincronizar en este momento. Los datos siguen guardados localmente.',
        'noConnection': true, // Flag para identificar que fue por falta de conexión
        'ventasPendientes': cantidadPendientes,
      };
    }

    _isSincronizando = true;
    notifyListeners();

    Map<String, dynamic> resultado;
    try {
      // El servicio SimpleSyncService también valida conexión, pero hacerlo aquí
      // evita cualquier intento de sincronización si no hay conexión
      resultado = await _syncService.sincronizarAhora();
      
      // CRÍTICO: Solo recargar ventas si la sincronización fue exitosa
      // Si falló, NO recargar para no perder las ventas pendientes de la vista
      if (resultado['success'] == true || (resultado['sincronizadas'] as int? ?? 0) > 0) {
        await cargarVentas(usarTimeoutNormal: true);
      }
    } catch (e) {
      debugPrint('❌ VentasProvider: Error en sincronización: $e');
      debugPrint('⚠️ VentasProvider: NINGUNA venta fue borrada - todas permanecen en la BD local');
      
      _errorMessage = _limpiarMensajeError(e.toString());
      resultado = {
        'success': false,
        'message': 'Error al sincronizar. Los datos siguen guardados localmente.',
        'sincronizadas': 0,
        'fallidas': 0,
        'error': _errorMessage,
      };
    } finally {
      _isSincronizando = false;
      notifyListeners();
    }

    return resultado;
  }

  void actualizarBusqueda(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  Future<void> eliminarVenta(int id) async {
    Ventas? venta;
    for (final item in _ventas) {
      if (item.id == id) {
        venta = item;
        break;
      }
    }

    if (venta == null) {
      return;
    }

    final localId = _ventaLocalIds[venta] ?? 'servidor_$id';

    try {
      await _ventasService.eliminarVenta(id);
      _ventas.removeWhere((v) => v.id == id);
      _ventaLocalIds.removeWhere((v, _) => v.id == id);
      await _db.deleteVentaOffline(localId);
      await _ccCacheService.eliminarMovimientosPorVenta(
        ventaId: id,
        ventaLocalId: localId.startsWith('local_') ? localId : null,
      );
      await _cacheService.eliminarVentaDelCache(id);
      await _actualizarCacheDesdeVentasActuales();
      notifyListeners();
    } catch (e) {
      if (Apihandler.isConnectionError(e)) {
        _ventas.removeWhere((v) => v.id == id);
        _ventaLocalIds.removeWhere((v, _) => v.id == id);
        _isOffline = true;
        await _db.deleteVentaOffline(localId);
        await _ccCacheService.eliminarMovimientosPorVenta(
          ventaId: id,
          ventaLocalId: localId.startsWith('local_') ? localId : null,
        );
        await _cacheService.eliminarVentaDelCache(id);
        await _actualizarCacheDesdeVentasActuales();
        notifyListeners();
      } else {
        _errorMessage = _limpiarMensajeError(e.toString());
        rethrow;
      }
    }
  }

  Future<void> eliminarVentaLocal(Ventas venta) async {
    // Obtener localId de la venta que está en _ventas (por referencia o por id) para borrarla de la BD
    Ventas? ventaEnLista = _ventas.where((v) => v == venta).firstOrNull;
    if (ventaEnLista == null && venta.id != null) {
      ventaEnLista = _ventas.where((v) => v.id == venta.id).firstOrNull;
    }
    final localId = ventaEnLista != null ? _ventaLocalIds[ventaEnLista] : null;

    // Quitar por id o por referencia para que el listado se actualice siempre
    if (venta.id != null) {
      _ventas.removeWhere((v) => v.id == venta.id);
      _ventaLocalIds.removeWhere((v, _) => v.id == venta.id);
    } else {
      _ventas.remove(venta);
      _ventaLocalIds.remove(venta);
    }

    // Borrar siempre de la BD offline para que no vuelva a aparecer al reabrir
    if (localId != null && localId.startsWith('local_')) {
      await _db.deleteVentaOffline(localId);
      await _ccCacheService.eliminarMovimientosPorVenta(
        ventaId: venta.id,
        ventaLocalId: localId,
      );
    }
    // Quitar también del caché de ventas (por si estaba guardada ahí) para que no reaparezca en modo offline
    if (venta.id != null) {
      await _cacheService.eliminarVentaDelCache(venta.id!);
    }
    await _actualizarCacheDesdeVentasActuales();
    notifyListeners();
  }

  Future<void> eliminarVentaDeLista(Ventas venta) async {
    // Resolver la venta que está en _ventas (misma referencia o mismo id) para que remove/notifyListeners actualice la UI
    Ventas? enLista = _ventas.where((v) => v == venta).firstOrNull;
    if (enLista == null && venta.id != null) {
      enLista = _ventas.where((v) => v.id == venta.id).firstOrNull;
    }
    final ventaAUsar = enLista ?? venta;

    final localId = _ventaLocalIds[ventaAUsar];
    final esVentaLocal = localId != null && localId.startsWith('local_');

    if (ventaAUsar.id != null && !esVentaLocal) {
      await eliminarVenta(ventaAUsar.id!);
      return;
    }

    await eliminarVentaLocal(ventaAUsar);
  }

  Future<List<Ventas>> obtenerVentas({bool usarTimeoutNormal = false}) async {
    await cargarVentas(usarTimeoutNormal: usarTimeoutNormal);
    return ventas;
  }

  Future<Map<String, dynamic>> crearVenta(Ventas venta) async {
    // PRIORIDAD: Intentar guardar en el servidor primero
    try {
      debugPrint('📤 VentasProvider: Intentando guardar venta en el servidor...');
      
      final response = await _ventasService.crearVenta(
        venta,
        customTimeout: const Duration(seconds: 10),
      );

      // Éxito: la venta se guardó en el servidor
      debugPrint('✅ VentasProvider: Venta guardada exitosamente en el servidor');
      
      if (response['ventaId'] != null) {
        venta.id = response['ventaId'];
      }

      _ventas.insert(0, venta);

      if (venta.id != null) {
        await _guardarVentaDelServidor(venta);
        _ventaLocalIds[venta] = 'servidor_${venta.id}';
      } else {
        _ventaLocalIds[venta] =
            'servidor_temp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      }

      // IMPORTANTE: Actualizar estado a online cuando la venta se crea exitosamente
      _isOffline = false;
      await _actualizarCacheDesdeVentasActuales();
      notifyListeners();

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
      final errorStr = e.toString().toLowerCase();
      final esErrorStock = errorStr.contains('stock insuficiente') ||
          (errorStr.contains('insuficiente') && errorStr.contains('disponible'));

      if (esErrorStock) {
        final message = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
        debugPrint('⚠️ VentasProvider: Error de stock, no se guarda offline: $message');
        return {
          'success': false,
          'isOffline': false,
          'message': message,
        };
      }

      // FALLBACK: Solo si falla el servidor (conexión, etc.), guardar localmente como excepción
      debugPrint('⚠️ VentasProvider: Error al guardar en servidor, guardando localmente como fallback...');
      debugPrint('   Error: $e');
      
      try {
        final localId = await _db.saveVentaOffline(venta);
        _ventas.insert(0, venta);
        _ventaLocalIds[venta] = localId;
        _isOffline = true;
        
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
        
        await _actualizarCacheDesdeVentasActuales();
        notifyListeners();

        final bool esErrorConexion = _esErrorDeConexion(e);
        final String message = esErrorConexion
            ? 'Sin conexión. Venta guardada localmente. Se sincronizará cuando haya conexión.'
            : 'Error del servidor. Venta guardada localmente. Puedes sincronizar después.';

        debugPrint('✅ VentasProvider: Venta guardada localmente como fallback');

        return {
          'success': true,
          'isOffline': true,
          'message': message,
          'serverError': !esErrorConexion,
        };
      } catch (localError) {
        // Si incluso el guardado local falla, retornar error crítico
        debugPrint('❌ VentasProvider: Error crítico - no se pudo guardar ni en servidor ni localmente');
        debugPrint('   Error local: $localError');
        
        return {
          'success': false,
          'isOffline': false,
          'message': 'Error crítico: No se pudo guardar la venta. Por favor, intenta nuevamente.',
          'error': localError.toString(),
        };
      }
    }
  }

  double _calcularMontoCuentaCorriente(Ventas venta) {
    if (venta.pagos != null && venta.pagos!.isNotEmpty) {
      return venta.pagos!
          .where((pago) => pago.metodo == MetodoPago.cuentaCorriente)
          .fold(0.0, (sum, pago) => sum + pago.monto);
    }
    return venta.metodoPago == MetodoPago.cuentaCorriente ? venta.total : 0;
  }

  bool _esErrorDeConexion(dynamic error) {
    return Apihandler.isConnectionError(error) || error is TimeoutException;
  }

  Future<void> asignarVenta(int ventaId, int usuarioId) async {
    try {
      await _ventasService.asignarVenta(ventaId, usuarioId);
      final index = _ventas.indexWhere((venta) => venta.id == ventaId);
      if (index != -1) {
        _ventas[index].usuarioIdAsignado = usuarioId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al asignar venta: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> asignarVentaAutomaticamente(
      int ventaId, int usuarioIdExcluir) async {
    try {
      final resultado = await _ventasService.asignarVentaAutomaticamente(
        ventaId,
        usuarioIdExcluir,
      );
      if (resultado['asignada'] == true &&
          resultado['usuarioAsignadoId'] != null) {
        final index = _ventas.indexWhere((venta) => venta.id == ventaId);
        if (index != -1) {
          _ventas[index].usuarioIdAsignado = resultado['usuarioAsignadoId'];
          notifyListeners();
        }
      }
      return resultado;
    } catch (e) {
      debugPrint('Error al asignar venta automáticamente: $e');
      rethrow;
    }
  }

  /// Verifica si una venta está pendiente de sincronización
  bool esVentaPendiente(Ventas venta) {
    // Una venta está pendiente si no tiene ID del servidor (id == null)
    // Las ventas offline/pendientes se guardan sin ID hasta que se sincronizan
    if (venta.id == null) return true;
    
    // También verificar si está en el mapa de IDs locales como pendiente
    final localId = _ventaLocalIds[venta];
    if (localId != null && localId.startsWith('local_')) {
      return true;
    }
    
    return false;
  }

  /// Cantidad por producto ya "reservada" en ventas pendientes de sincronizar (offline).
  /// Al hacer otra venta offline, el máximo disponible debe ser stock - esta cantidad.
  Map<int, double> get cantidadReservadaOfflinePorProducto {
    final Map<int, double> reservada = {};
    for (final venta in _ventas) {
      if (!esVentaPendiente(venta)) continue;
      for (final vp in venta.ventasProductos) {
        reservada[vp.productoId] = (reservada[vp.productoId] ?? 0) + vp.cantidad;
      }
    }
    return reservada;
  }

  Future<int> contarVentasPendientes() async {
    final stats = await _db.getStats();
    return stats['pending'] ?? 0;
  }

  /// Limpia listas y caché al cambiar de usuario. Evita mostrar ventas de otro usuario.
  Future<void> clearForNewUser() async {
    _ventas = [];
    _ventaLocalIds.clear();
    _currentPage = 1;
    _hasMoreData = true;
    _searchQuery = '';
    _errorMessage = null;
    _isOffline = false;
    _isLoading = false;
    _isLoadingMore = false;
    _offlineMessageShown = false;
    _skipCacheOnNextLoad = true;
    notifyListeners();
    try {
      await _cacheService.limpiarCache();
    } catch (e) {
      debugPrint('⚠️ VentasProvider: error limpiando caché para nuevo usuario: $e');
    }
  }

  /// Deja la lista vacía y activa loading para que al abrir Ventas se muestre carga y no la lista anterior.
  void prepararParaCargaInicial() {
    _currentPage = 1;
    _hasMoreData = true;
    _errorMessage = null;
    _isLoadingMore = false;
    // Solo mostrar loading si no hay datos previos/cacheados (evita parpadeo)
    if (_ventas.isEmpty) {
      _isLoading = true;
    }
    // Defer to avoid setState/markNeedsBuild during build
    Future.microtask(() => notifyListeners());
  }

  /// Borra todas las ventas pendientes de sincronizar (útil para limpiar ventas bugeadas)
  Future<int> borrarTodasLasVentasPendientes() async {
    try {
      // Obtener las ventas pendientes antes de borrarlas para eliminar también de cuenta corriente
      final db = await _db.database;
      List<Map<String, dynamic>> ventasPendientes = [];
      
      try {
        ventasPendientes = await db.query(
          'ventas_offline',
          where: 'sync_status = ?',
          whereArgs: ['pending'],
          columns: ['local_id', 'id', 'cliente_id'],
        );
      } catch (e) {
        debugPrint('⚠️ VentasProvider: Error obteniendo ventas pendientes: $e');
        // Si hay error, continuar sin eliminar movimientos de cuenta corriente
      }

      // Eliminar movimientos de cuenta corriente asociados
      for (final ventaRow in ventasPendientes) {
        try {
          final localId = ventaRow['local_id'] as String;
          final ventaId = ventaRow['id'] as int?;
          final clienteId = ventaRow['cliente_id'] as int?;
          
          if (clienteId != null) {
            await _ccCacheService.eliminarMovimientosPorVenta(
              ventaId: ventaId,
              ventaLocalId: localId.startsWith('local_') ? localId : null,
            );
          }
        } catch (e) {
          debugPrint('⚠️ VentasProvider: Error eliminando movimiento de cuenta corriente: $e');
          // Continuar con la siguiente venta
        }
      }

      // Borrar todas las ventas pendientes de SQLite
      final ventasBorradas = await _db.borrarTodasLasVentasPendientes();
      
      // Actualizar la lista de ventas si hay alguna pendiente en memoria
      _ventas.removeWhere((venta) {
        final localId = _ventaLocalIds[venta];
        return localId != null && localId.startsWith('local_');
      });
      _ventaLocalIds.removeWhere((venta, localId) => localId.startsWith('local_'));
      
      notifyListeners();
      
      debugPrint('✅ VentasProvider: $ventasBorradas ventas pendientes borradas');
      return ventasBorradas;
    } catch (e) {
      debugPrint('❌ VentasProvider: Error al borrar ventas pendientes: $e');
      // No rethrow, retornar 0 para no romper el flujo
      return 0;
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
    final tieneConexion = await _connectivityService.checkFullConnectivity();
    if (!tieneConexion) {
      final offlineVentas = await _ccCacheService.obtenerVentasOffline(clienteId);
      return {
        'ventas': offlineVentas,
        'hasNextPage': false,
        'page': 1,
        'pageSize': offlineVentas.length,
        'totalItems': offlineVentas.length,
      };
    }
    try {
      final data = await _ventasService.obtenerVentasCuentaCorrientePorClienteId(
        clienteId,
        page,
        pageSize,
      );
      
      // En modo online: borrar solo las ventas SINCRONIZADAS de cuenta corriente de este cliente
      // (preservar las pendientes) y reemplazarlas con las del servidor
      if (data['ventas'] != null) {
        await _ccCacheService.eliminarVentasSincronizadasDelCliente(clienteId);
        await _ccCacheService.cacheVentasCuentaCorriente(
          clienteId,
          List<Ventas>.from(data['ventas']),
        );
      }
      
      // Combinar ventas del servidor con las pendientes de sincronizar
      final ventasPendientes = await _ccCacheService.obtenerVentasPendientesOffline(clienteId);
      final ventasDelServidor = List<Ventas>.from(data['ventas'] ?? []);
      
      // Combinar ambas listas, evitando duplicados
      final idsServidor = ventasDelServidor.where((v) => v.id != null).map((v) => v.id!).toSet();
      final ventasCombinadas = <Ventas>[
        ...ventasDelServidor,
        ...ventasPendientes.where((v) => v.id == null || !idsServidor.contains(v.id)),
      ];
      
      // Ordenar por fecha descendente
      ventasCombinadas.sort((a, b) => b.fecha.compareTo(a.fecha));
      
      return {
        'ventas': ventasCombinadas,
        'hasNextPage': data['hasNextPage'] ?? false,
        'page': data['page'] ?? page,
        'pageSize': data['pageSize'] ?? pageSize,
        'totalItems': ventasCombinadas.length,
      };
    } catch (e) {
      debugPrint('Error al obtener ventas con cuenta corriente: $e');
      final esTimeout = e is TimeoutException;
      if (Apihandler.isConnectionError(e) || esTimeout) {
        final offlineVentas = await _ccCacheService.obtenerVentasOffline(clienteId);
        return {
          'ventas': offlineVentas,
          'hasNextPage': false,
          'page': 1,
          'pageSize': offlineVentas.length,
          'totalItems': offlineVentas.length,
        };
      }
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

  void marcarOfflineMessageMostrado() {
    if (!_offlineMessageShown) {
      _offlineMessageShown = true;
      notifyListeners();
    }
  }

  Future<List<Ventas>> _combinarConVentasOfflinePendientes(
    List<Ventas> ventasDelServidor, {
    bool incluirPendientesOffline = true,
  }) async {
    final resultado = <Ventas>[];
    final idsServidor = <int>{};

    _ventaLocalIds.clear();

    for (final venta in ventasDelServidor) {
      resultado.add(venta);
      if (venta.id != null) {
        idsServidor.add(venta.id!);
        _ventaLocalIds[venta] = 'servidor_${venta.id}';
      }
    }

    if (!incluirPendientesOffline) {
      return resultado;
    }

    List<Map<String, dynamic>> ventasOffline = [];
    try {
      ventasOffline = await _db.getPendingVentas();
    } catch (e) {
      debugPrint('⚠️ VentasProvider: Error obteniendo ventas pendientes offline: $e');
      // Si hay error, retornar solo las ventas del servidor
      return resultado;
    }

    final currentUser = await AuthService.getCurrentUser();
    final currentUserId = currentUser?.id;

    for (var ventaData in ventasOffline) {
      final ventaRow = ventaData['venta'] as Map<String, dynamic>;
      // Solo incluir ventas del usuario actual (evitar mostrar ventas de otros en modo offline)
      final creadorId = ventaRow['usuario_id_creador'] as int?;
      if (currentUserId == null || creadorId != currentUserId) {
        continue;
      }

      final localId = ventaRow['local_id'] as String;
      final ventaId = ventaRow['id'] as int?;

      if (ventaId != null && idsServidor.contains(ventaId)) {
        continue;
      }

      try {
        final productos = (ventaData['productos'] as List).map((p) {
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

        final pagosRows = ventaData['pagos'] as List;
        List<VentaPago>? pagos;
        if (pagosRows.isNotEmpty) {
          pagos = pagosRows.map((p) {
            return VentaPago(
              id: 0,
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
          usuarioCreador =
              User.fromJson(jsonDecode(ventaRow['usuario_creador_json'] as String));
        }

        User? usuarioAsignado;
        if (ventaRow['usuario_asignado_json'] != null) {
          usuarioAsignado = User.fromJson(
              jsonDecode(ventaRow['usuario_asignado_json'] as String));
        }

        // Parsear fecha preservando la hora local usando el método helper
        final fechaStr = ventaRow['fecha'] as String;
        final fecha = DatabaseHelper.parseDateTimeLocal(fechaStr);

        final ventaOffline = Ventas(
          id: ventaRow['id'] as int?,
          clienteId: ventaRow['cliente_id'] as int,
          cliente: cliente,
          ventasProductos: productos,
          total: ventaRow['total'] as double,
          fecha: fecha,
          metodoPago: ventaRow['metodo_pago'] != null
              ? MetodoPago.values[ventaRow['metodo_pago'] as int]
              : null,
          pagos: pagos,
          usuarioIdCreador: ventaRow['usuario_id_creador'] as int?,
          usuarioCreador: usuarioCreador,
          usuarioIdAsignado: ventaRow['usuario_id_asignado'] as int?,
          usuarioAsignado: usuarioAsignado,
          estadoEntrega: EstadoEntregaExtension.fromJson(
            ventaRow['estado_entrega'] as int,
          ),
        );

        resultado.add(ventaOffline);
        _ventaLocalIds[ventaOffline] = localId;
      } catch (e) {
        debugPrint('⚠️ VentasProvider: Error construyendo venta offline: $e');
      }
    }

    // Ordenar: pendientes offline primero, luego por ID de base de datos (más nuevo primero)
    resultado.sort((a, b) {
      final idA = _ventaLocalIds[a] ?? '';
      final idB = _ventaLocalIds[b] ?? '';
      final aEsOffline = idA.startsWith('local_');
      final bEsOffline = idB.startsWith('local_');
      if (aEsOffline && !bEsOffline) return -1;
      if (!aEsOffline && bEsOffline) return 1;
      if (a.id != null && b.id != null) {
        return b.id!.compareTo(a.id!);
      }
      return b.fecha.compareTo(a.fecha);
    });
    return resultado;
  }

  /// Solo ventas del usuario actual (evita mostrar datos de otro usuario en offline/caché).
  Future<List<Ventas>> _filtrarVentasPorUsuarioActual(List<Ventas> ventas) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return [];
    final userId = user.id;
    return ventas.where((v) => v.usuarioIdCreador == userId).toList();
  }

  Future<void> _cargarVentasOffline() async {
    final resultado = <Ventas>[];
    final idsAgregados = <int>{};

    _ventaLocalIds.clear();

    final user = await AuthService.getCurrentUser();
    final currentUserId = user?.id;

    debugPrint('📦 VentasProvider: Cargando ventas en modo offline (solo usuario actual)...');

    // 1) Cargar ventas del servidor desde caché (solo del usuario actual)
    try {
      final cacheadas = await _cacheService.obtenerVentasDelCache();
      final soloDelUsuario = await _filtrarVentasPorUsuarioActual(cacheadas);
      for (final venta in soloDelUsuario) {
        if (venta.id != null && !idsAgregados.contains(venta.id!)) {
          resultado.add(venta);
          idsAgregados.add(venta.id!);
          _ventaLocalIds[venta] = 'servidor_${venta.id}';
        }
      }
    } catch (e) {
      debugPrint('⚠️ VentasProvider: Error leyendo caché de ventas: $e');
    }

    // 2) Cargar ventas pendientes de sincronizar (ventas_offline) solo del usuario actual
    try {
      final db = await _db.database;
      if (db.isOpen) {
        final ventasRows = currentUserId != null
            ? await db.query(
                'ventas_offline',
                where: 'usuario_id_creador = ?',
                whereArgs: [currentUserId],
                orderBy: 'created_at DESC',
              )
            : <Map<String, dynamic>>[]; // Sin usuario no mostrar ventas offline de nadie

        for (final ventaRow in ventasRows) {
          try {
            final localId = ventaRow['local_id'] as String;
            final ventaId = ventaRow['id'] as int?;

            if (ventaId != null && idsAgregados.contains(ventaId)) {
              continue;
            }

            final venta = await _buildVentaFromRow(ventaRow);
            resultado.add(venta);
            _ventaLocalIds[venta] = localId;
            if (ventaId != null) {
              idsAgregados.add(ventaId);
            }
          } catch (e) {
            debugPrint('⚠️ VentasProvider: Error procesando venta offline: $e');
          }
        }
      } else {
        debugPrint('⚠️ VentasProvider: Base de datos cerrada al cargar ventas offline');
      }
    } catch (e) {
      debugPrint('⚠️ VentasProvider: Error obteniendo ventas offline: $e');
    }

    _ventas = resultado;
    _ordenarVentasRecientesPrimero();
    _isOffline = true;
    _hasMoreData = false;
    _errorMessage = null;
  }

  Future<void> _actualizarCacheDesdeVentasActuales() async {
    await _cacheService.guardarVentasEnCache(
      _ventas.where((venta) => venta.id != null).toList(),
      limpiarAnterior: true,
    );
  }

  Future<Ventas> _buildVentaFromRow(Map<String, dynamic> ventaRow) async {
    try {
      final db = await _db.database;
      final localId = ventaRow['local_id'] as String;

      // Verificar que la base de datos esté abierta
      if (!db.isOpen) {
        throw Exception('Base de datos cerrada');
      }

      final productosRows = await db.query(
        'ventas_productos_offline',
        where: 'venta_local_id = ?',
        whereArgs: [localId],
      );

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

    final pagosRows = await db.query(
      'ventas_pagos_offline',
      where: 'venta_local_id = ?',
      whereArgs: [localId],
    );

    List<VentaPago>? pagos;
    if (pagosRows.isNotEmpty) {
      pagos = pagosRows.map((p) {
        return VentaPago(
          id: p['id'] as int,
          ventaId: ventaRow['id'] as int? ?? 0,
          metodo: MetodoPago.values[p['metodo'] as int],
          monto: p['monto'] as double,
        );
      }).toList();
    }

    final clienteJson = jsonDecode(ventaRow['cliente_json'] as String);
    final cliente = Cliente.fromJson(clienteJson);

    User? usuarioCreador;
    if (ventaRow['usuario_creador_json'] != null) {
      usuarioCreador =
          User.fromJson(jsonDecode(ventaRow['usuario_creador_json'] as String));
    }

    User? usuarioAsignado;
    if (ventaRow['usuario_asignado_json'] != null) {
      usuarioAsignado = User.fromJson(
          jsonDecode(ventaRow['usuario_asignado_json'] as String));
    }

    // Parsear fecha preservando la hora local usando el método helper
    final fechaStr = ventaRow['fecha'] as String;
    final fecha = DatabaseHelper.parseDateTimeLocal(fechaStr);

    return Ventas(
      id: ventaRow['id'] as int?,
      clienteId: ventaRow['cliente_id'] as int,
      cliente: cliente,
      ventasProductos: productos,
      total: ventaRow['total'] as double,
      fecha: fecha,
        metodoPago: ventaRow['metodo_pago'] != null
            ? MetodoPago.values[ventaRow['metodo_pago'] as int]
            : null,
        pagos: pagos,
        usuarioIdCreador: ventaRow['usuario_id_creador'] as int?,
        usuarioCreador: usuarioCreador,
        usuarioIdAsignado: ventaRow['usuario_id_asignado'] as int?,
        usuarioAsignado: usuarioAsignado,
        estadoEntrega:
            EstadoEntregaExtension.fromJson(ventaRow['estado_entrega'] as int),
      );
    } catch (e) {
      debugPrint('⚠️ VentasProvider: Error construyendo venta desde row: $e');
      // Retornar una venta básica con los datos mínimos disponibles
      final clienteJson = jsonDecode(ventaRow['cliente_json'] as String);
      final cliente = Cliente.fromJson(clienteJson);
      // Parsear fecha preservando la hora local usando el método helper
      final fechaStr = ventaRow['fecha'] as String;
      final fecha = DatabaseHelper.parseDateTimeLocal(fechaStr);
      
      return Ventas(
        id: ventaRow['id'] as int?,
        clienteId: ventaRow['cliente_id'] as int,
        cliente: cliente,
        ventasProductos: <VentasProductos>[],
        total: ventaRow['total'] as double,
        fecha: fecha,
        estadoEntrega: EstadoEntregaExtension.fromJson(ventaRow['estado_entrega'] as int),
      );
    }
  }

  Future<void> _guardarVentaDelServidor(Ventas venta) async {
    if (venta.id == null) return;

    try {
      final db = await _db.database;
      
      // Verificar que la base de datos esté abierta
      if (!db.isOpen) {
        debugPrint('⚠️ VentasProvider: Base de datos cerrada al guardar venta del servidor');
        return;
      }
      
      final now = DateTime.now().toIso8601String();
      final localId = 'servidor_${venta.id}';

      await db.transaction((txn) async {
        await txn.insert(
          'ventas_offline',
          {
            'local_id': localId,
            'id': venta.id,
            'cliente_id': venta.clienteId,
            'cliente_json': jsonEncode(venta.cliente.toJson()),
            'total': venta.total,
            // Guardar fecha en hora local (formato ISO sin zona horaria para preservar hora exacta)
            'fecha': DatabaseHelper.formatDateTimeLocal(venta.fecha),
            'metodo_pago': venta.metodoPago?.index,
            'usuario_id_creador': venta.usuarioIdCreador,
            'usuario_creador_json': venta.usuarioCreador != null
                ? jsonEncode(venta.usuarioCreador!.toJson())
                : null,
            'usuario_id_asignado': venta.usuarioIdAsignado,
            'usuario_asignado_json': venta.usuarioAsignado != null
                ? jsonEncode(venta.usuarioAsignado!.toJson())
                : null,
            'estado_entrega': venta.estadoEntrega.toJson(),
            'sync_status': 'synced',
            'sync_attempts': 0,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.delete(
          'ventas_productos_offline',
          where: 'venta_local_id = ?',
          whereArgs: [localId],
        );

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

        await txn.delete(
          'ventas_pagos_offline',
          where: 'venta_local_id = ?',
          whereArgs: [localId],
        );

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
      // Si la BD está cerrada, no rethrow para no romper el flujo
      if (e.toString().contains('database_closed')) {
        debugPrint('⚠️ VentasProvider: Base de datos cerrada, no se pudo guardar venta del servidor');
        return;
      }
      // Para otros errores, no rethrow para no romper el flujo
    }
  }

  String _limpiarMensajeError(String mensaje) {
    return mensaje.replaceFirst('Exception: ', '');
  }

  bool _esErrorServidor(dynamic error) {
    final mensaje = error.toString().toLowerCase();
    return mensaje.contains('código de estado: 500') ||
        mensaje.contains('status: 500') ||
        mensaje.contains('internal server error');
  }

  // Métodos estáticos para lógica de nueva venta
  static Future<Cliente?> obtenerOCrearConsumidorFinal({
    required BuildContext context,
    required List<Cliente> clientesIniciales,
    required List<Cliente> clientesFiltrados,
    required Cliente? clienteSeleccionado,
  }) async {
    // Primero buscar en las colecciones locales
    Cliente? clienteConsumidor = _buscarConsumidorFinalEnColecciones([
      if (clienteSeleccionado != null) [clienteSeleccionado],
      clientesFiltrados,
      clientesIniciales,
    ]);

    if (clienteConsumidor != null) {
      return clienteConsumidor;
    }

    final clienteProvider = Provider.of<ClienteProvider>(context, listen: false);

    clienteConsumidor = _buscarConsumidorFinalEnColecciones([clienteProvider.clientes]);
    if (clienteConsumidor != null) {
      return clienteConsumidor;
    }

    // Buscar en caché de clientes (por si estamos offline o antes de llamar al servidor)
    try {
      final clientesCache = await clienteProvider.obtenerClientesDelCache();
      clienteConsumidor = _buscarConsumidorFinalEnColecciones([clientesCache]);
      if (clienteConsumidor != null) return clienteConsumidor;
    } catch (_) {}

    // Si no se encuentra localmente, usar el endpoint del backend que garantiza un único Consumidor Final compartido
    try {
      final clienteService = ClienteService();
      clienteConsumidor = await clienteService.obtenerOCrearConsumidorFinal();
      
      // Actualizar la lista de clientes para incluir el Consumidor Final
      await clienteProvider.obtenerClientes();
      return clienteConsumidor;
    } catch (e) {
      debugPrint('Error al obtener o crear Consumidor Final desde el servidor: $e');
      // Sin conexión (Failed host lookup, SocketException, etc.): usar Consumidor Final local para venta offline
      if (Apihandler.isConnectionError(e)) {
        try {
          final clientesCache = await clienteProvider.obtenerClientesDelCache();
          clienteConsumidor = _buscarConsumidorFinalEnColecciones([clientesCache]);
        } catch (_) {}
        if (clienteConsumidor != null) {
          if (context.mounted) {
            AppTheme.showSnackBar(
              context,
              const SnackBar(
                content: Text('Usando Consumidor Final en modo offline'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return clienteConsumidor;
        }
        // Placeholder local para poder continuar la venta sin conexión
        clienteConsumidor = Cliente(
          id: 0,
          nombre: 'Consumidor Final',
          direccion: null,
          descuentoGlobal: 0.0,
          preciosEspeciales: const [],
          visible: true,
        );
        if (context.mounted) {
          AppTheme.showSnackBar(
            context,
            const SnackBar(
              content: Text('Modo offline: usando Consumidor Final local. Se sincronizará al conectar.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return clienteConsumidor;
      }
      // Para otros errores (no de conexión), mostrar el error y retornar null
      if (context.mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al obtener Consumidor Final: $e'),
        );
      }
      return null;
    }
  }

  static Cliente? _buscarConsumidorFinalEnColecciones(List<Iterable<Cliente>> colecciones) {
    String normalizar(String nombre) => nombre.trim().toLowerCase();

    for (final coleccion in colecciones) {
      for (final cliente in coleccion) {
        if (normalizar(cliente.nombre) == 'consumidor final') {
          return cliente;
        }
      }
    }
    return null;
  }
}

