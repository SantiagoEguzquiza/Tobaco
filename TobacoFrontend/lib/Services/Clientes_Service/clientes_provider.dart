import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_service.dart';
import 'package:tobaco/Services/Cache/datos_cache_service.dart';
import 'package:tobaco/Services/Cache/cuenta_corriente_cache_service.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Services/Connectivity/connectivity_service.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class ClienteProvider with ChangeNotifier {
  final ClienteService _clienteService = ClienteService();
  final DatosCacheService _cacheService = DatosCacheService();
  final CuentaCorrienteCacheService _cuentaCorrienteCache = CuentaCorrienteCacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

  List<Cliente> _clientes = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String _searchQuery = '';
  String? _errorMessage;
  bool _isOffline = false;
  /// Tras clearForNewUser, no mostrar caché en la próxima carga (evita datos de otro usuario).
  bool _skipCacheOnNextLoad = false;

  List<Cliente> _clientesConDeuda = [];
  List<dynamic> get clientesConDeuda => _clientesConDeuda;

  /// Devuelve los clientes filtrados por el query de búsqueda actual.
  /// Prioriza los que empiezan con el query sobre los que solo lo contienen.
  List<Cliente> get clientes {
    if (_searchQuery.trim().isEmpty) return _clientes;
    final q = _searchQuery.toLowerCase();
    final empiezaCon = _clientes
        .where((c) => c.nombre.toLowerCase().startsWith(q))
        .toList();
    final contiene = _clientes
        .where((c) =>
            !c.nombre.toLowerCase().startsWith(q) &&
            c.nombre.toLowerCase().contains(q))
        .toList();
    return [...empiezaCon, ...contiene];
  }

  bool get isLoading => _isLoading;
  bool get hasMoreData => false;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  bool get isSyncing => _isSyncing;

  Future<List<Cliente>> obtenerClientesDelCache() async {
    return await _cacheService.obtenerClientesDelCache();
  }

  Future<List<Cliente>> obtenerClientes() async {
    try {
      _clientes = await _clienteService
          .obtenerClientes()
          .timeout(const Duration(seconds: 3));
      _clientes.sort((a, b) =>
          a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

      await _cacheService.guardarClientesEnCache(_clientes);
    } catch (e) {
      debugPrint('⚠️ ClienteProvider: Error obteniendo del servidor: $e');

      _clientes = await _cacheService.obtenerClientesDelCache();
      _clientes.sort((a, b) =>
          a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

      if (_clientes.isEmpty) {
        throw Exception(
            'No hay clientes disponibles offline. Conecta para sincronizar.');
      }
    }

    notifyListeners();
    return _clientes;
  }

  Future<Cliente?> crearCliente(Cliente cliente) async {
    try {
      final clienteCreado = await _clienteService.crearCliente(cliente);

      _clientes.add(clienteCreado);
      _clientes.sort((a, b) =>
          a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

      _guardarCacheEnBackground();
      notifyListeners();
      return clienteCreado;
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }
  }

  Future<void> eliminarCliente(int id) async {
    try {
      await _clienteService.eliminarCliente(id);
      _clientes.removeWhere((cliente) => cliente.id == id);

      _guardarCacheEnBackground();
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }
  }

  Future<void> editarCliente(Cliente cliente) async {
    try {
      await _clienteService.editarCliente(cliente);
      int index = _clientes.indexWhere((c) => c.id == cliente.id);
      if (index != -1) {
        _clientes[index] = cliente;
        _clientes.sort((a, b) =>
            a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

        _guardarCacheEnBackground();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }
  }

  /// Offline-first: carga inmediatamente desde SQLite y muestra; en segundo plano trae del servidor e integra (agrega/actualiza sin eliminar locales).
  /// Si _skipCacheOnNextLoad (tras cambio de usuario), omite caché y va directo al servidor.
  Future<void> cargarClientes() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _searchQuery = '';
    final skipCache = _skipCacheOnNextLoad;
    if (skipCache) _skipCacheOnNextLoad = false;

    // PASO 1: Cargar desde SQLite al instante y mostrarlos (sin esperar API)
    if (!skipCache) {
      try {
        final clientesLocales = await _cacheService.obtenerClientesDelCache();
        if (clientesLocales.isNotEmpty) {
          clientesLocales.sort((a, b) =>
              a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
          _clientes = clientesLocales;
          _isLoading = false;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('⚠️ ClienteProvider: Error cargando del caché: $e');
      }
    }

    // PASO 2: En segundo plano, consultar API y fusionar (agregar nuevos, actualizar existentes; no eliminar locales)
    _isSyncing = true;
    if (_isLoading) notifyListeners();

    try {
      final clientesServidor = await _clienteService
          .obtenerClientes()
          .timeout(const Duration(seconds: 5));

      _fusionarClientesServidorConLocales(clientesServidor);
      _isOffline = false;
      _isSyncing = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      _isLoading = false;

      if (AuthService.isSessionExpiredException(e)) {
        await AuthService.logout();
        notifyListeners();
        return;
      }

      _isOffline = Apihandler.isConnectionError(e);

      if (_clientes.isEmpty) {
        _errorMessage = _isOffline
            ? 'Sin conexión y sin datos en caché.'
            : 'Error al cargar clientes';
      }

      debugPrint('⚠️ ClienteProvider: Error sincronizando con servidor: $e');
      notifyListeners();
    }
  }

  /// Fusiona clientes del servidor con la lista local: actualiza por id y agrega los que no existan. No elimina clientes locales.
  void _fusionarClientesServidorConLocales(List<Cliente> clientesServidor) {
    final porId = <int, Cliente>{};
    for (final c in _clientes) {
      if (c.id != null) {
        porId[c.id!] = c;
      }
    }
    for (final c in clientesServidor) {
      if (c.id != null) {
        porId[c.id!] = c;
      }
    }
    final sinId = _clientes.where((c) => c.id == null).toList();
    _clientes = [...porId.values, ...sinId];
    _clientes.sort((a, b) =>
        a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    _guardarCacheEnBackground();
  }

  /// No-op. Se mantiene por compatibilidad (ya no hay paginación).
  Future<void> cargarMasClientes() async {}

  /// Búsqueda local: filtra la lista en memoria por el query.
  Future<void> buscarClientes(String query) async {
    _searchQuery = query;

    if (query.trim().isEmpty && _clientes.isEmpty) {
      await cargarClientes();
      return;
    }

    notifyListeners();
  }

  Future<List<Cliente>> obtenerClientesConDeuda() async {
    try {
      _clientesConDeuda = await _clienteService.obtenerClientesConDeuda();
      await _cuentaCorrienteCache.cacheClientesResumen(_clientesConDeuda);
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
      if (Apihandler.isConnectionError(e)) {
        final offline = await _cuentaCorrienteCache.obtenerClientesConSaldoPaginados(page: 1, pageSize: 100);
        _clientesConDeuda = List<Cliente>.from(offline['clientes'] ?? []);
        notifyListeners();
        return _clientesConDeuda;
      }
      rethrow;
    }
    return _clientesConDeuda;
  }

  Future<Map<String, dynamic>> obtenerClientesConDeudaPaginados(
      int page, int pageSize) async {
    try {
      final data = await _clienteService.obtenerClientesConDeudaPaginados(
          page, pageSize);
      if (data['clientes'] != null) {
        await _cuentaCorrienteCache.cacheClientesResumen(
            List<Cliente>.from(data['clientes']));
      }
      return data;
    } catch (e) {
      debugPrint('Error al obtener clientes con deuda paginados: $e');
      if (Apihandler.isConnectionError(e)) {
        return await _cuentaCorrienteCache.obtenerClientesConSaldoPaginados(
            page: page, pageSize: pageSize);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleDeuda(int clienteId) async {
    final tieneConexion = await _connectivityService.checkFullConnectivity();
    if (!tieneConexion) {
      final detalleOffline =
          await _cuentaCorrienteCache.obtenerDetalleDeudaOffline(clienteId);
      if (detalleOffline != null) {
        return detalleOffline;
      }
    }
    try {
      final detalle = await _clienteService.obtenerDetalleDeuda(clienteId);
      final resumen = await _cuentaCorrienteCache.obtenerResumenCliente(clienteId);
      if (resumen != null) {
        await _cuentaCorrienteCache.cacheClientesResumen([
          Cliente(
            id: resumen.clienteId,
            nombre: resumen.clienteNombre,
            direccion: resumen.cliente?.direccion,
            deuda: detalle['deudaFormateada']?.toString(),
          )
        ]);
      }
      return detalle;
    } catch (e) {
      debugPrint('Error al obtener detalle de deuda: $e');
      final esTimeout = e is TimeoutException;
      if (Apihandler.isConnectionError(e) || esTimeout) {
        final detalleOffline = await _cuentaCorrienteCache.obtenerDetalleDeudaOffline(clienteId);
        if (detalleOffline != null) {
          return detalleOffline;
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerClientesPaginados(
      int page, int pageSize) async {
    try {
      final data =
          await _clienteService.obtenerClientesPaginados(page, pageSize);
      return data;
    } catch (e) {
      debugPrint(
          '⚠️ ClienteProvider: Error obteniendo clientes paginados del servidor: $e');

      try {
        final clientesCache = await _cacheService.obtenerClientesDelCache();

        if (clientesCache.isEmpty) {
          debugPrint('❌ ClienteProvider: No hay clientes en caché');
          rethrow;
        }

        final start = (page - 1) * pageSize;
        final end = start + pageSize;
        final clientesPag = clientesCache.sublist(
          start,
          end > clientesCache.length ? clientesCache.length : end,
        );

        return {
          'clientes': clientesPag,
          'totalCount': clientesCache.length,
          'page': page,
          'pageSize': pageSize,
          'totalPages': (clientesCache.length / pageSize).ceil(),
          'hasNextPage': end < clientesCache.length,
          'hasPreviousPage': page > 1,
        };
      } catch (cacheError) {
        debugPrint(
            '❌ ClienteProvider: Error al obtener del caché: $cacheError');
        rethrow;
      }
    }
  }

  Future<Cliente> obtenerClientePorId(int id) async {
    try {
      return await _clienteService.obtenerClientePorId(id);
    } catch (e) {
      debugPrint('Error al obtener cliente por ID: $e');
      rethrow;
    }
  }

  Future<void> actualizarClienteEnLista(int clienteId) async {
    try {
      final clienteActualizado =
          await _clienteService.obtenerClientePorId(clienteId);

      final index = _clientes.indexWhere((c) => c.id == clienteId);
      if (index != -1) {
        _clientes[index] = clienteActualizado;
        _guardarCacheEnBackground();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al actualizar cliente en lista: $e');
      await cargarClientes();
    }
  }

  void actualizarClienteDirecto(Cliente clienteActualizado) {
    if (clienteActualizado.id == null) return;

    final index = _clientes.indexWhere((c) => c.id == clienteActualizado.id);
    if (index != -1) {
      _clientes[index] = clienteActualizado;
      notifyListeners();
    }
  }

  Future<void> limpiarBusqueda() async {
    _searchQuery = '';
    notifyListeners();
  }

  void _guardarCacheEnBackground() {
    _cacheService.guardarClientesEnCache(_clientes).catchError(
        (e) => debugPrint('⚠️ Error guardando clientes en caché: $e'));
  }

  /// Limpia listas y caché al cambiar de usuario. Evita mostrar datos de otro usuario.
  Future<void> clearForNewUser() async {
    _clientes = [];
    _clientesConDeuda = [];
    _searchQuery = '';
    _errorMessage = null;
    _isOffline = false;
    _isLoading = false;
    _isSyncing = false;
    _skipCacheOnNextLoad = true;
    notifyListeners();
    try {
      await _cacheService.limpiarCache();
    } catch (e) {
      debugPrint('⚠️ ClienteProvider: error limpiando caché para nuevo usuario: $e');
    }
  }
}
