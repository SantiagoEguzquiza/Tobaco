import 'package:flutter/material.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Services/Productos_Service/productos_service.dart';
import 'package:tobaco/Services/Catalogo_Local/catalogo_local_service.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Cache/datos_cache_service.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'dart:developer';

class ProductoProvider with ChangeNotifier {
  final ProductoService _productoService = ProductoService();
  final CatalogoLocalService _catalogoLocal = CatalogoLocalService();

  // Estado de la pantalla de productos

  // Variables de estado
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isOffline = false;
  String? _errorMessage;
  int _currentPage = 1;
  final int _pageSize = 20;
  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  String? _selectedCategory;
  String _searchQuery = '';


  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;
  List<Producto> get productos => _productos;
  List<Categoria> get categorias => _categorias;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<Producto> get productosFiltrados {
    List<Producto> filtered;
    if (_searchQuery.isNotEmpty) {
      filtered = _productos.where((p) =>
          p.nombre.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    } else if (_selectedCategory != null) {
      filtered = _productos.where((p) => p.categoriaNombre == _selectedCategory).toList();
    } else {
      filtered = List.from(_productos);
    }
    // Ordenar alfabéticamente
    filtered.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return filtered;
  }

  // Lista de productos original (para compatibilidad con métodos existentes)
  List<Producto> get productosOriginal => _productos;

  /// Carga productos y categorías iniciales (primera página)
  Future<void> cargarProductosInicial(CategoriasProvider categoriasProvider) async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _productos.clear();
    _hasMoreData = true;
    _isOffline = false;
    notifyListeners();

    try {
      // Obtener categorías y productos en paralelo
      final futures = await Future.wait([
        categoriasProvider.obtenerCategorias(silent: true),
        obtenerProductosPaginados(_currentPage, _pageSize),
      ]);

      final categoriasData = futures[0] as List<Categoria>;
      final productosData = futures[1] as Map<String, dynamic>;

      _productos = List<Producto>.from(productosData['productos']);
      _categorias = categoriasData;
      _hasMoreData = productosData['hasNextPage'] ?? false;
      _isOffline = categoriasProvider.loadedFromCache;

      // Seleccionar la primera categoría por defecto si no hay ninguna seleccionada
      if (_selectedCategory == null && categoriasData.isNotEmpty) {
        _selectedCategory = categoriasData.first.nombre;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      log('Error al cargar los Productos: $e', level: 1000);

      // Verificar si hay datos del caché disponibles
      if (Apihandler.isConnectionError(e)) {
        try {
          // Intentar obtener del caché directamente
          final cacheService = DatosCacheService();
          final productosCache = await cacheService.obtenerProductosDelCache();

          if (productosCache.isNotEmpty) {
            // Hay datos en caché, cargarlos manualmente
            final start = (_currentPage - 1) * _pageSize;
            final end = start + _pageSize;
            final productosPag = productosCache.sublist(
              start,
              end > productosCache.length ? productosCache.length : end,
            );

            _productos = productosPag;
            _hasMoreData = end < productosCache.length;
            _isOffline = true;
            _isLoading = false;
            notifyListeners();
            return;
          }
        } catch (cacheError) {
          // Si falla el caché, continuar con el error normal
        }
      }

      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Carga más productos con scroll infinito
  Future<void> cargarMasProductos() async {
    if (_isLoadingMore || !_hasMoreData) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final data = await obtenerProductosPaginados(_currentPage + 1, _pageSize);
      
      _productos.addAll(List<Producto>.from(data['productos']));
      _currentPage++;
      _hasMoreData = data['hasNextPage'] ?? false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _errorMessage = e.toString();
      notifyListeners();
      log('Error al cargar más productos: $e', level: 1000);
      rethrow;
    }
  }

  /// Cambia la categoría seleccionada
  void seleccionarCategoria(String? nombre) {
    _selectedCategory = nombre;
    _searchQuery = ''; // Limpiar búsqueda al seleccionar categoría
    notifyListeners();
  }

  /// Actualiza la búsqueda y filtra productos
  void filtrarPorBusqueda(String query) {
    _searchQuery = query;
    if (query.isNotEmpty) {
      _selectedCategory = null; // Limpiar categoría al buscar
    }
    notifyListeners();
  }

  /// Limpia la búsqueda
  void limpiarBusqueda() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Recarga los productos iniciales (usado después de crear/editar/eliminar)
  Future<void> recargarProductos(CategoriasProvider categoriasProvider) async {
    await cargarProductosInicial(categoriasProvider);
  }

  /// Obtiene productos: intenta del servidor, si falla usa SQLite local
  Future<List<Producto>> obtenerProductos() async {
    print('📡 ProductoProvider: Intentando obtener productos del servidor...');
    
    try {
      // Intentar obtener del servidor con timeout (500ms para ser más rápido en offline)
      _productos = await _productoService.obtenerProductos()
          .timeout(Duration(milliseconds: 500));
      
      print('✅ ProductoProvider: ${_productos.length} productos obtenidos del servidor');
      
      // Guardar localmente para uso offline
      if (_productos.isNotEmpty) {
        await _catalogoLocal.guardarProductos(_productos);
        print('✅ ProductoProvider: ${_productos.length} productos guardados localmente');
      }
      
    } catch (e) {
      print('⚠️ ProductoProvider: Error obteniendo del servidor: $e');
      print('📦 ProductoProvider: Cargando productos locales (SQLite)...');
      // Si falla, cargar desde SQLite local
      _productos = await _catalogoLocal.obtenerProductos();
      
      if (_productos.isEmpty) {
        print('❌ ProductoProvider: No hay productos locales');
        throw Exception('No hay productos disponibles offline. Conecta para sincronizar.');
      } else {
        print('✅ ProductoProvider: ${_productos.length} productos cargados de SQLite');
      }
    }

    notifyListeners();
    return _productos;
  }

  Future<void> crearProducto(Producto producto) async {
    try {
      await _productoService.crearProducto(producto);
      // Recargar la lista completa para obtener el ID real del servidor
      await obtenerProductos();
    } catch (e) {
      debugPrint('Error al crear producto: $e');
      rethrow; // Propagar el error para que la UI pueda manejarlo
    }
  }

  Future<bool> eliminarProducto(int id) async {
    try {
      await _productoService.eliminarProducto(id);
      _productos.removeWhere((producto) => producto.id == id);
      notifyListeners();
      return true; // Éxito
    } catch (e) {
      debugPrint('Error: $e');
      rethrow; // Re-lanzar para que el UI pueda manejar el error
    }
  }

  Future<String?> eliminarProductoConMensaje(int id) async {
    try {
      await _productoService.eliminarProducto(id);
      _productos.removeWhere((producto) => producto.id == id);
      notifyListeners();
      return null; // Sin error
    } catch (e) {
      debugPrint('Error al eliminar producto: $e');
      final errorMessage = e.toString();
      
      // Verificar si es un error de validación (ventas o precios especiales)
      if (errorMessage.contains('ventas vinculadas') || 
          errorMessage.contains('precios especiales') ||
          errorMessage.contains('No se puede eliminar el producto')) {
        // Extraer solo el mensaje sin "Exception: "
        final cleanMessage = errorMessage.replaceFirst('Exception: ', '');
        debugPrint('Mensaje de validación detectado: $cleanMessage');
        return cleanMessage;
      } else {
        // Para otros errores, re-lanzar la excepción
        debugPrint('Error no es de validación, re-lanzando: $errorMessage');
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
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al editar producto: $e');
      rethrow; // Propagar el error para que la UI pueda manejarlo
    }
  }

  Future<String?> desactivarProductoConMensaje(int id) async {
    try {
      await _productoService.desactivarProducto(id);
      _productos.removeWhere((producto) => producto.id == id);
      notifyListeners();
      return null; // Sin error
    } catch (e) {
      debugPrint('Error al desactivar producto: $e');
      final errorMessage = e.toString();
      
      // Extraer solo el mensaje sin "Exception: "
      final cleanMessage = errorMessage.replaceFirst('Exception: ', '');
      debugPrint('Mensaje de error: $cleanMessage');
      return cleanMessage;
    }
  }

  Future<String?> activarProductoConMensaje(int id) async {
    try {
      await _productoService.activarProducto(id);
      // Recargar la lista para incluir el producto activado
      await obtenerProductos();
      return null; // Sin error
    } catch (e) {
      debugPrint('Error al activar producto: $e');
      final errorMessage = e.toString();
      
      // Extraer solo el mensaje sin "Exception: "
      final cleanMessage = errorMessage.replaceFirst('Exception: ', '');
      debugPrint('Mensaje de error: $cleanMessage');
      return cleanMessage;
    }
  }

  Future<Map<String, dynamic>> obtenerProductosPaginados(int page, int pageSize) async {
    print('📡 ProductoProvider: Intentando obtener productos paginados del servidor...');
    
    try {
      // Intentar obtener del servidor con timeout (500ms para ser más rápido en offline)
      final result = await _productoService.obtenerProductosPaginados(page, pageSize)
          .timeout(Duration(milliseconds: 500));
      
      print('✅ ProductoProvider: ${result['productos'].length} productos obtenidos del servidor');
      
      // Guardar localmente (SQLite) para uso offline (en background)
      if (result['productos'].isNotEmpty) {
        _catalogoLocal.guardarProductos(result['productos'] as List<Producto>)
            .catchError((e) => print('⚠️ Error guardando productos localmente: $e'));
      }
      
      return result;
    } catch (e) {
      print('⚠️ ProductoProvider: Error obteniendo del servidor: $e');
      print('📦 ProductoProvider: Cargando productos locales (SQLite)...');
      
      // Si falla, cargar desde SQLite local
      final productosCache = await _catalogoLocal.obtenerProductos();
      
      if (productosCache.isEmpty) {
        print('❌ ProductoProvider: No hay productos locales');
        rethrow;
      }
      
      print('✅ ProductoProvider: ${productosCache.length} productos cargados de SQLite');
      
      // Paginar manualmente desde el caché
      final start = (page - 1) * pageSize;
      final end = start + pageSize;
      final productosPag = productosCache.sublist(
        start,
        end > productosCache.length ? productosCache.length : end,
      );
      
      return {
        'productos': productosPag,
        'total': productosCache.length,
        'page': page,
        'pageSize': pageSize,
        'totalPages': (productosCache.length / pageSize).ceil(),
        'hasNextPage': end < productosCache.length,
      };
    }
  }
}
