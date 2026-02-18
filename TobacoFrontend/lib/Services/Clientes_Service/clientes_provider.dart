import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_service.dart';
import 'package:tobaco/Services/Cache/datos_cache_service.dart';
import 'package:tobaco/Services/Cache/cuenta_corriente_cache_service.dart';
import 'package:tobaco/Services/Cache/data/clientes_cache_service.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Services/Connectivity/connectivity_service.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class ClienteProvider with ChangeNotifier {
  final ClienteService _clienteService = ClienteService();
  final DatosCacheService _cacheService = DatosCacheService();
  final CuentaCorrienteCacheService _cuentaCorrienteCache = CuentaCorrienteCacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Estados para la lista principal de clientes (paginada)
  List<Cliente> _clientes = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  String _searchQuery = '';
  String? _errorMessage;
  bool _isOffline = false;

  // Estados para clientes con deuda (sin cambios)
  List<Cliente> _clientesConDeuda = [];
  // Getters para clientes con deuda
  List<dynamic> get clientesConDeuda => _clientesConDeuda;

  // Getters para la lista principal
  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;

  // Obtiene clientes del caché inmediatamente (sin llamar al servidor)
  Future<List<Cliente>> obtenerClientesDelCache() async {
    return await _cacheService.obtenerClientesDelCache();
  }

  // Obtiene clientes: intenta del servidor, si falla usa caché
  Future<List<Cliente>> obtenerClientes() async {
    print('📡 ClienteProvider: Intentando obtener clientes del servidor...');

    try {
      // Intentar obtener del servidor con timeout
      _clientes = await _clienteService
          .obtenerClientes()
          .timeout(Duration(seconds: 3));

      print(
          '✅ ClienteProvider: ${_clientes.length} clientes obtenidos del servidor');

      // Guardar en caché para uso offline (siempre, incluso si está vacío para limpiar caché)
      await _cacheService.guardarClientesEnCache(_clientes);
      if (_clientes.isEmpty) {
        print('✅ ClienteProvider: Caché limpiado (servidor devolvió lista vacía)');
      } else {
        print(
            '✅ ClienteProvider: ${_clientes.length} clientes guardados en caché');
      }
    } catch (e) {
      print('⚠️ ClienteProvider: Error obteniendo del servidor: $e');
      print('📦 ClienteProvider: Cargando clientes del caché...');

      // Si falla, cargar del caché
      _clientes = await _cacheService.obtenerClientesDelCache();

      if (_clientes.isEmpty) {
        print('❌ ClienteProvider: No hay clientes en caché');
        throw Exception(
            'No hay clientes disponibles offline. Conecta para sincronizar.');
      } else {
        print(
            '✅ ClienteProvider: ${_clientes.length} clientes cargados del caché');
      }
    }

    notifyListeners();
    return _clientes;
  }

  Future<Cliente?> crearCliente(Cliente cliente) async {
    try {
      final clienteCreado = await _clienteService.crearCliente(cliente);

      // Si estamos en la primera página, agregar el cliente a la lista
      if (_currentPage == 1 && _searchQuery.isEmpty) {
        _clientes.insert(0, clienteCreado);
      }

      // Actualizar el caché con el nuevo cliente
      await _actualizarCache();

      notifyListeners();
      return clienteCreado;
    } catch (e) {
      debugPrint('Error: $e');
      rethrow; // Relanzar la excepción para que se maneje en la UI
    }
  }

  Future<void> eliminarCliente(int id) async {
    try {
      await _clienteService.eliminarCliente(id);
      _clientes.removeWhere((cliente) => cliente.id == id);

      // Actualizar el caché: intentar obtener todos los clientes del servidor
      // Si falla, eliminar el cliente específico del caché
      await _actualizarCacheDespuesDeEliminar(id);

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

        // Actualizar el caché con el cliente editado
        await _actualizarCache();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }
  }

  // Carga la primera página de clientes (reset completo)
  Future<void> cargarClientes() async {
    if (_isLoading) return;

    // Guardar una copia de la lista actual para fallback en caso de error/offline
    final previousClientes = List<Cliente>.from(_clientes);

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _clientes.clear();
    _hasMoreData = true;
    notifyListeners();

    try {
      final data = await _clienteService.obtenerClientesPaginados(
          _currentPage, _pageSize);

      final List<Cliente> nuevosClientes = List<Cliente>.from(data['clientes']);

      // Actualizar caché con TODOS los clientes del servidor (no solo la primera página)
      // Esto asegura que el caché esté siempre sincronizado con el estado real del servidor
      if (_currentPage == 1) {
        _actualizarCacheCompletoEnBackground();
      }

      _clientes = nuevosClientes;
      _hasMoreData = data['hasNextPage'] ?? false;
      _isOffline = false;
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      if (AuthService.isSessionExpiredException(e)) {
        await AuthService.logout();
        notifyListeners();
        return;
      }
      _isOffline = Apihandler.isConnectionError(e);
      _errorMessage = _isOffline
          ? 'Sin conexión. Usando datos en caché.'
          : 'Error al cargar clientes';

      debugPrint('⚠️ ClienteProvider: Error cargando clientes: $e');

      // Si hay error de conexión, intentar cargar del caché
      if (_isOffline) {
        try {
          // Intentar cargar del caché
          final clientesDelCache = await _cacheService.obtenerClientesDelCache();
          if (clientesDelCache.isNotEmpty) {
            final start = (_currentPage - 1) * _pageSize;
            final end = start + _pageSize;
            final clientesPag = clientesDelCache.sublist(
              start,
              end > clientesDelCache.length ? clientesDelCache.length : end,
            );
            _clientes = clientesPag;
            _hasMoreData = end < clientesDelCache.length;
            debugPrint('✅ ClienteProvider: ${_clientes.length} clientes cargados del caché (página $_currentPage)');
          } else {
            // Si no hay nada en caché pero ya teníamos datos antes,
            // mantener la última lista conocida para no dejar al usuario sin datos.
            if (previousClientes.isNotEmpty) {
              _clientes = previousClientes;
              _hasMoreData = false;
              debugPrint('📝 ClienteProvider: Caché vacío, manteniendo lista previa (${_clientes.length} clientes)');
            } else {
              _clientes = [];
              _hasMoreData = false;
              debugPrint('📝 ClienteProvider: Caché vacío y sin datos previos, mostrando lista vacía');
            }
          }
          // No relanzar el error si se pudo cargar del caché
          notifyListeners();
          return;
        } catch (cacheError) {
          debugPrint(
              '❌ ClienteProvider: Error cargando del caché: $cacheError');
          // Si hay error cargando del caché pero teníamos datos previos, mantenerlos
          if (previousClientes.isNotEmpty) {
            _clientes = previousClientes;
            _hasMoreData = false;
            debugPrint('📝 ClienteProvider: Error de caché, manteniendo lista previa (${_clientes.length} clientes)');
          } else {
            _clientes = [];
            _hasMoreData = false;
            debugPrint('📝 ClienteProvider: Error de caché y sin datos previos, mostrando lista vacía');
          }
          notifyListeners();
          return;
        }
      }

      // Si no es un error de conexión y teníamos datos previos, mantenerlos
      if (previousClientes.isNotEmpty) {
        _clientes = previousClientes;
        _hasMoreData = _clientes.length >= _pageSize;
        notifyListeners();
        return;
      }

      notifyListeners();
      rethrow;
    }
  }

  // Carga más clientes (paginación infinita)
  Future<void> cargarMasClientes() async {
    if (_isLoading || !_hasMoreData) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _clienteService.obtenerClientesPaginados(
          _currentPage + 1, _pageSize);

      final List<Cliente> nuevosClientes = List<Cliente>.from(data['clientes']);

      _clientes.addAll(nuevosClientes);
      _currentPage++;
      _hasMoreData = data['hasNextPage'] ?? false;
      _isOffline = false;
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      if (AuthService.isSessionExpiredException(e)) {
        await AuthService.logout();
        notifyListeners();
        return;
      }
      _isOffline = Apihandler.isConnectionError(e);
      _errorMessage = 'Error al cargar más clientes';

      debugPrint('⚠️ ClienteProvider: Error cargando más clientes: $e');

      // Si hay error de conexión, intentar cargar del caché
      if (_isOffline) {
        try {
          final clientesCache = await _cacheService.obtenerClientesDelCache();
          if (clientesCache.isNotEmpty) {
            final start = _currentPage * _pageSize;
            final end = start + _pageSize;
            if (end <= clientesCache.length) {
              final clientesPag = clientesCache.sublist(start, end);
              _clientes.addAll(clientesPag);
              _currentPage++;
              _hasMoreData = end < clientesCache.length;
            } else {
              _hasMoreData = false;
            }
          }
        } catch (cacheError) {
          debugPrint(
              '❌ ClienteProvider: Error cargando del caché: $cacheError');
        }
      }

      notifyListeners();
      rethrow;
    }
  }

  // Busca clientes por nombre (con soporte offline)
  Future<void> buscarClientes(String query) async {
    _searchQuery = query;

    // Si la búsqueda está vacía, recargar clientes normales
    if (query.trim().isEmpty) {
      await cargarClientes();
      return;
    }

    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    // NO limpiar la lista aquí - mantener los clientes actuales mientras se busca
    // _clientes.clear(); // ❌ Comentado para evitar parpadeo
    _currentPage = 1;
    _hasMoreData = false; // La búsqueda no tiene paginación
    notifyListeners();

    List<Cliente> resultados;

    try {
      // Intentar buscar en el servidor con timeout
      debugPrint('📡 ClienteProvider: Buscando clientes en servidor...');
      resultados = await _clienteService
          .buscarClientes(query)
          .timeout(Duration(seconds: 3));

      debugPrint(
          '✅ ClienteProvider: ${resultados.length} clientes encontrados en servidor');
      _isOffline = false;
    } catch (e) {
      debugPrint('⚠️ ClienteProvider: Error buscando en servidor: $e');
      debugPrint('📦 ClienteProvider: Buscando en caché local...');

      _isOffline = Apihandler.isConnectionError(e);

      // Si falla, buscar en caché local
      final todosLosClientes = await _cacheService.obtenerClientesDelCache();

      // Filtrar por nombre
      final queryLower = query.toLowerCase();
      final resultadosCache = todosLosClientes
          .where((c) => c.nombre.toLowerCase().contains(queryLower))
          .toList();

      debugPrint(
          '✅ ClienteProvider: ${resultadosCache.length} clientes encontrados en caché');

      // Ordenar: primero los que empiezan con el query, luego los que lo contienen
      final empiezaCon = resultadosCache
          .where((c) => c.nombre.toLowerCase().startsWith(queryLower))
          .toList();
      final contiene = resultadosCache
          .where((c) =>
              !c.nombre.toLowerCase().startsWith(queryLower) &&
              c.nombre.toLowerCase().contains(queryLower))
          .toList();

      // Solo actualizar si hay resultados o si queremos limpiar la lista
      final nuevosResultados = [...empiezaCon, ...contiene];
      if (nuevosResultados.isNotEmpty || _clientes.isEmpty) {
        _clientes = nuevosResultados;
      }
      // Si no hay resultados pero ya hay clientes en la lista, mantenerlos
      
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Ordenar: primero los que empiezan con el query, luego los que lo contienen
    final queryLower = query.toLowerCase();
    final empiezaCon = resultados
        .where((c) => c.nombre.toLowerCase().startsWith(queryLower))
        .toList();
    final contiene = resultados
        .where((c) =>
            !c.nombre.toLowerCase().startsWith(queryLower) &&
            c.nombre.toLowerCase().contains(queryLower))
        .toList();

    // Solo actualizar si hay resultados o si queremos limpiar la lista
    final nuevosResultados = [...empiezaCon, ...contiene];
    if (nuevosResultados.isNotEmpty) {
      _clientes = nuevosResultados;
    }
    // Si no hay resultados del servidor, mantener la lista actual (puede tener resultados del filtro local)
    
    _isLoading = false;
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

  // Obtiene clientes paginados: intenta del servidor, si falla usa caché
  Future<Map<String, dynamic>> obtenerClientesPaginados(
      int page, int pageSize) async {
    try {
      final data =
          await _clienteService.obtenerClientesPaginados(page, pageSize);

      // Actualizar caché completo con TODOS los clientes del servidor (no solo la primera página)
      // Esto asegura que el caché esté siempre sincronizado con el estado real del servidor
      if (page == 1) {
        _actualizarCacheCompletoEnBackground();
      }

      return data;
    } catch (e) {
      debugPrint(
          '⚠️ ClienteProvider: Error obteniendo clientes paginados del servidor: $e');

      // Si falla, intentar obtener del caché y paginar manualmente
      try {
        final clientesCache = await _cacheService.obtenerClientesDelCache();

        if (clientesCache.isEmpty) {
          debugPrint('❌ ClienteProvider: No hay clientes en caché');
          rethrow;
        }

        debugPrint(
            '✅ ClienteProvider: ${clientesCache.length} clientes cargados del caché');

        // Paginar manualmente desde el caché
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

  // Obtiene un cliente por su ID
  Future<Cliente> obtenerClientePorId(int id) async {
    try {
      return await _clienteService.obtenerClientePorId(id);
    } catch (e) {
      debugPrint('Error al obtener cliente por ID: $e');
      rethrow;
    }
  }

  // Actualiza un cliente en la lista
  Future<void> actualizarClienteEnLista(int clienteId) async {
    try {
      final clienteActualizado =
          await _clienteService.obtenerClientePorId(clienteId);

      final index = _clientes.indexWhere((c) => c.id == clienteId);
      if (index != -1) {
        _clientes[index] = clienteActualizado;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al actualizar cliente en lista: $e');
      // Si falla, recargar toda la lista como fallback
      await cargarClientes();
    }
  }

  // Actualiza un cliente directamente en la lista sin hacer llamada al servidor
  void actualizarClienteDirecto(Cliente clienteActualizado) {
    if (clienteActualizado.id == null) return;
    
    final index = _clientes.indexWhere((c) => c.id == clienteActualizado.id);
    if (index != -1) {
      _clientes[index] = clienteActualizado;
      notifyListeners();
    }
  }

  // Limpia el estado de búsqueda y recarga los clientes
  Future<void> limpiarBusqueda() async {
    _searchQuery = '';
    await cargarClientes();
  }

  // Método privado para actualizar el caché con los clientes actuales
  Future<void> _actualizarCache() async {
    try {
      // Obtener todos los clientes del servidor para actualizar el caché completo
      // Esto asegura que el caché esté sincronizado después de crear/editar/eliminar
      try {
        final todosLosClientes = await _clienteService
            .obtenerClientes()
            .timeout(Duration(seconds: 3));

        // Actualizar caché (si está vacío, limpiará el caché SQLite)
        await _cacheService.guardarClientesEnCache(todosLosClientes);
        if (todosLosClientes.isEmpty) {
          debugPrint('✅ ClienteProvider: Caché limpiado (servidor devolvió lista vacía)');
        } else {
          debugPrint(
              '✅ ClienteProvider: Caché actualizado con ${todosLosClientes.length} clientes');
        }
      } catch (e) {
        // Si no se puede obtener del servidor, actualizar el caché con la lista local actualizada
        // Si estamos en modo búsqueda, no actualizar el caché con resultados filtrados
        if (_clientes.isNotEmpty && _searchQuery.isEmpty) {
          await _cacheService.guardarClientesEnCache(_clientes);
          debugPrint(
              '✅ ClienteProvider: Caché actualizado con lista local (${_clientes.length} clientes)');
        }
      }
    } catch (e) {
      debugPrint('⚠️ ClienteProvider: Error al actualizar caché: $e');
      // No relanzar el error, solo loguearlo para no interrumpir la operación principal
    }
  }

  /// Actualiza el caché después de eliminar un cliente
  /// Intenta obtener todos los clientes del servidor para sincronizar el caché completo
  /// Si falla, elimina el cliente específico del caché
  Future<void> _actualizarCacheDespuesDeEliminar(int clienteIdEliminado) async {
    try {
      // Intentar obtener todos los clientes del servidor para actualizar el caché completo
      try {
        final todosLosClientes = await _clienteService
            .obtenerClientes()
            .timeout(Duration(milliseconds: 2000)); // Timeout más largo para operación crítica

        // Actualizar el caché con la lista completa del servidor (si está vacío, limpiará el caché)
        await _cacheService.guardarClientesEnCache(todosLosClientes);
        if (todosLosClientes.isEmpty) {
          debugPrint('✅ ClienteProvider: Caché limpiado después de eliminar (servidor devolvió lista vacía)');
        } else {
          debugPrint(
              '✅ ClienteProvider: Caché actualizado después de eliminar (${todosLosClientes.length} clientes)');
        }
      } catch (e) {
        // Si no se puede obtener del servidor, eliminar el cliente específico del caché
        debugPrint('⚠️ ClienteProvider: No se pudo obtener todos los clientes, eliminando del caché local');
        final clientesCache = ClientesCacheService();
        await clientesCache.deleteById(clienteIdEliminado);
        debugPrint('✅ ClienteProvider: Cliente $clienteIdEliminado eliminado del caché');
      }
    } catch (e) {
      debugPrint('⚠️ ClienteProvider: Error al actualizar caché después de eliminar: $e');
      // Intentar eliminar del caché de todas formas
      try {
        final clientesCache = ClientesCacheService();
        await clientesCache.deleteById(clienteIdEliminado);
        debugPrint('✅ ClienteProvider: Cliente $clienteIdEliminado eliminado del caché (fallback)');
      } catch (e2) {
        debugPrint('❌ ClienteProvider: Error eliminando del caché: $e2');
      }
    }
  }

  // Actualiza el caché en background sin bloquear
  void _actualizarCacheEnBackground(List<Cliente> clientes) {
    _cacheService.guardarClientesEnCache(clientes).catchError(
        (e) => debugPrint('⚠️ Error guardando clientes en caché: $e'));
  }

  /// Actualiza el caché completo obteniendo TODOS los clientes del servidor
  /// Se ejecuta en background para no bloquear la UI
  void _actualizarCacheCompletoEnBackground() {
    _clienteService.obtenerClientes().then((todosLosClientes) async {
      // Actualizar caché completo (si está vacío, limpiará el caché SQLite)
      await _cacheService.guardarClientesEnCache(todosLosClientes);
      if (todosLosClientes.isEmpty) {
        debugPrint('✅ ClienteProvider: Caché completo limpiado (servidor devolvió lista vacía)');
      } else {
        debugPrint(
            '✅ ClienteProvider: Caché completo actualizado con ${todosLosClientes.length} clientes');
      }
    }).catchError((e) {
      debugPrint('⚠️ ClienteProvider: Error actualizando caché completo en background: $e');
      // Si falla, no hacer nada - el caché se mantendrá con los datos anteriores
    });
  }

  /// Limpia listas y estado al cambiar de usuario (logout). Evita mostrar datos del usuario anterior.
  void clearForNewUser() {
    _clientes = [];
    _clientesConDeuda = [];
    _currentPage = 1;
    _hasMoreData = true;
    _searchQuery = '';
    _errorMessage = null;
    _isOffline = false;
    _isLoading = false;
    notifyListeners();
  }
}
