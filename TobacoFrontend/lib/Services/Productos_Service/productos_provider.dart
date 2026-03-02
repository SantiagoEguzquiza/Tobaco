import 'package:flutter/material.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Services/Productos_Service/productos_service.dart';
import 'package:tobaco/Services/Catalogo_Local/catalogo_local_service.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Cache/datos_cache_service.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class ProductoProvider with ChangeNotifier {
  final ProductoService _productoService = ProductoService();
  final CatalogoLocalService _catalogoLocal = CatalogoLocalService();
  final DatosCacheService _cacheService = DatosCacheService();

  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isOffline = false;
  String? _errorMessage;
  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  String? _selectedCategory;
  String _searchQuery = '';
  static const Duration _timeoutDuration = Duration(seconds: 6);

  bool get isLoading => _isLoading;
  bool get isLoadingMore => false;
  bool get hasMoreData => false;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;
  List<Producto> get productos => _productos;
  List<Categoria> get categorias => _categorias;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isSyncing => _isSyncing;

  List<Producto> get productosFiltrados {
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      return _productos.where((p) {
        final nombreMatch = p.nombre.toLowerCase().contains(queryLower);
        final marcaMatch = p.marca != null &&
            p.marca!.isNotEmpty &&
            p.marca!.toLowerCase().contains(queryLower);
        return nombreMatch || marcaMatch;
      }).toList();
    } else if (_selectedCategory != null) {
      return _productos
          .where((p) => p.categoriaNombre == _selectedCategory)
          .toList();
    }
    return List.from(_productos);
  }

  List<Producto> get productosOriginal => _productos;

  void _ordenarProductos() {
    _productos.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  }

  /// Cache-first: carga desde SQLite al instante, luego sincroniza con el servidor.
  Future<void> cargarProductosInicial(
      CategoriasProvider categoriasProvider) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _searchQuery = '';
    _isOffline = false;

    // PASO 1: Cargar productos y categorías desde caché (rápido, <50ms)
    try {
      final results = await Future.wait([
        _cacheService.obtenerProductosDelCache(),
        _cacheService.obtenerCategoriasDelCache(),
      ]);
      final productosCache = results[0] as List<Producto>;
      final categoriasCache = results[1] as List<Categoria>;

      if (productosCache.isNotEmpty) {
        _productos = productosCache;
        _ordenarProductos();
      }
      if (categoriasCache.isNotEmpty) {
        categoriasCache
            .sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        _categorias = categoriasCache;
      }
      if (_productos.isNotEmpty) {
        if (_selectedCategory == null && _categorias.isNotEmpty) {
          _selectedCategory = _categorias.first.nombre;
        }
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ ProductoProvider: Error cargando del caché: $e');
    }

    // PASO 2: Sincronizar con el servidor en background
    _isSyncing = true;
    if (_isLoading) notifyListeners();

    try {
      final futures = await Future.wait([
        _productoService.obtenerProductos().timeout(_timeoutDuration),
        categoriasProvider.obtenerCategorias(silent: true),
      ]);

      final productosServidor = futures[0] as List<Producto>;
      final categoriasServidor = futures[1] as List<Categoria>;

      _productos = productosServidor;
      _ordenarProductos();
      _categorias = categoriasServidor;

      if (_selectedCategory == null && _categorias.isNotEmpty) {
        _selectedCategory = _categorias.first.nombre;
      }

      _isOffline = false;
      _isLoading = false;
      _isSyncing = false;

      // Guardar en caché en background
      _cacheService
          .guardarProductosEnCache(_productos)
          .catchError((e) => debugPrint('⚠️ Error guardando productos en caché: $e'));
      _catalogoLocal
          .guardarProductos(_productos)
          .catchError((e) => debugPrint('⚠️ Error guardando en catálogo local: $e'));

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

      if (_productos.isEmpty) {
        _errorMessage = _isOffline
            ? 'Sin conexión y sin datos en caché.'
            : 'Error al cargar productos';
      }

      debugPrint('⚠️ ProductoProvider: Error sincronizando con servidor: $e');
      notifyListeners();
    }
  }

  /// No-op. Se mantiene por compatibilidad (ya no hay paginación).
  Future<void> cargarMasProductos() async {}

  void seleccionarCategoria(String? nombre) {
    _selectedCategory = nombre;
    _searchQuery = '';
    notifyListeners();
  }

  void filtrarPorBusqueda(String query) {
    _searchQuery = query;
    if (query.isNotEmpty) {
      _selectedCategory = null;
    }
    notifyListeners();
  }

  void limpiarBusqueda() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> clearForNewUser() async {
    _productos = [];
    _categorias = [];
    _selectedCategory = null;
    _searchQuery = '';
    _errorMessage = null;
    _isOffline = false;
    _isLoading = false;
    _isSyncing = false;
    notifyListeners();

    try {
      await _cacheService.limpiarCache();
      await _catalogoLocal.limpiarClientes();
      await _catalogoLocal.limpiarProductos();
      await _catalogoLocal.limpiarCategorias();
    } catch (e) {
      debugPrint('⚠️ ProductoProvider: error limpiando caché para nuevo usuario: $e');
    }
  }

  Future<void> recargarProductos(CategoriasProvider categoriasProvider) async {
    await cargarProductosInicial(categoriasProvider);
  }

  void sincronizarCategoriasDesde(CategoriasProvider categoriasProvider) {
    final nuevasCategorias =
        List<Categoria>.from(categoriasProvider.categorias);
    _categorias = nuevasCategorias;

    final categoriaSeleccionadaExiste = _selectedCategory != null &&
        _categorias.any((cat) => cat.nombre == _selectedCategory);

    if (!categoriaSeleccionadaExiste) {
      _selectedCategory =
          _categorias.isNotEmpty ? _categorias.first.nombre : null;
    }

    notifyListeners();
  }

  Future<List<Producto>> obtenerProductosDelCache() async {
    try {
      final list = await _cacheService.obtenerProductosDelCache();
      if (list.isNotEmpty) return list;
      return await _catalogoLocal.obtenerProductos();
    } catch (e) {
      return await _catalogoLocal.obtenerProductos();
    }
  }

  Future<List<Producto>> obtenerProductos() async {
    try {
      _productos = await _productoService
          .obtenerProductos()
          .timeout(_timeoutDuration);

      _ordenarProductos();

      await _cacheService.guardarProductosEnCache(_productos);
      await _catalogoLocal.guardarProductos(_productos);
    } catch (e) {
      debugPrint('⚠️ ProductoProvider: Error obteniendo del servidor: $e');

      _productos = await _cacheService.obtenerProductosDelCache();
      if (_productos.isEmpty) {
        _productos = await _catalogoLocal.obtenerProductos();
      }

      _ordenarProductos();

      if (_productos.isEmpty) {
        throw Exception(
            'No hay productos disponibles offline. Conecta para sincronizar.');
      }
    }

    notifyListeners();
    return _productos;
  }

  Future<void> crearProducto(Producto producto) async {
    try {
      await _productoService.crearProducto(producto);
      await obtenerProductos();
      _guardarCacheEnBackground();
    } catch (e) {
      debugPrint('Error al crear producto: $e');
      rethrow;
    }
  }

  Future<bool> eliminarProducto(int id) async {
    try {
      await _productoService.eliminarProducto(id);
      _productos.removeWhere((producto) => producto.id == id);
      _guardarCacheEnBackground();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }
  }

  Future<String?> eliminarProductoConMensaje(int id) async {
    try {
      await _productoService.eliminarProducto(id);
      _productos.removeWhere((producto) => producto.id == id);
      _guardarCacheEnBackground();
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error al eliminar producto: $e');
      final errorMessage = e.toString();

      if (errorMessage.contains('ventas vinculadas') ||
          errorMessage.contains('precios especiales') ||
          errorMessage.contains('No se puede eliminar el producto')) {
        final cleanMessage = errorMessage.replaceFirst('Exception: ', '');
        return cleanMessage;
      } else {
        rethrow;
      }
    }
  }

  Future<void> editarProducto(Producto producto) async {
    try {
      await _productoService.editarProducto(producto);
      int index = _productos.indexWhere((p) => p.id == producto.id);
      if (index != -1) {
        _productos[index] = producto;
        _ordenarProductos();
        _guardarCacheEnBackground();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al editar producto: $e');
      rethrow;
    }
  }

  Future<String?> desactivarProductoConMensaje(int id) async {
    try {
      await _productoService.desactivarProducto(id);
      _productos.removeWhere((producto) => producto.id == id);
      _guardarCacheEnBackground();
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error al desactivar producto: $e');
      final errorMessage = e.toString();
      final cleanMessage = errorMessage.replaceFirst('Exception: ', '');
      return cleanMessage;
    }
  }

  Future<String?> activarProductoConMensaje(int id) async {
    try {
      await _productoService.activarProducto(id);
      await obtenerProductos();
      _guardarCacheEnBackground();
      return null;
    } catch (e) {
      debugPrint('Error al activar producto: $e');
      final errorMessage = e.toString();
      final cleanMessage = errorMessage.replaceFirst('Exception: ', '');
      return cleanMessage;
    }
  }

  Future<Map<String, dynamic>> obtenerProductosPaginados(
      int page, int pageSize) async {
    try {
      final result = await _productoService
          .obtenerProductosPaginados(page, pageSize)
          .timeout(_timeoutDuration);
      return result;
    } catch (e) {
      debugPrint('⚠️ ProductoProvider: Error obteniendo del servidor: $e');

      final productosCache = await _cacheService.obtenerProductosDelCache();
      List<Producto> source = productosCache;
      if (source.isEmpty) {
        source = await _catalogoLocal.obtenerProductos();
      }

      if (source.isEmpty) rethrow;

      final start = (page - 1) * pageSize;
      final end = start + pageSize;
      final productosPag = source.sublist(
        start,
        end > source.length ? source.length : end,
      );

      return {
        'productos': productosPag,
        'total': source.length,
        'page': page,
        'pageSize': pageSize,
        'totalPages': (source.length / pageSize).ceil(),
        'hasNextPage': end < source.length,
      };
    }
  }

  void _guardarCacheEnBackground() {
    _cacheService.guardarProductosEnCache(_productos).catchError(
        (e) => debugPrint('⚠️ Error guardando productos en caché: $e'));
    _catalogoLocal.guardarProductos(_productos).catchError(
        (e) => debugPrint('⚠️ Error guardando en catálogo local: $e'));
  }
}
