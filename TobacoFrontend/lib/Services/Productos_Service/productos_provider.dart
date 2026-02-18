import 'package:flutter/material.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Services/Productos_Service/productos_service.dart';
import 'package:tobaco/Services/Catalogo_Local/catalogo_local_service.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Cache/datos_cache_service.dart';
import 'package:tobaco/Services/Cache/data/productos_cache_service.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';
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
   static const Duration _timeoutDuration = Duration(seconds: 6);


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
      // Búsqueda global: filtrar todos los productos cargados
      final queryLower = _searchQuery.toLowerCase();
      filtered = _productos.where((p) {
        // Buscar en el nombre
        final nombreMatch = p.nombre.toLowerCase().contains(queryLower);
        // Buscar en la marca (si existe)
        final marcaMatch = p.marca != null && 
                          p.marca!.isNotEmpty && 
                          p.marca!.toLowerCase().contains(queryLower);
        return nombreMatch || marcaMatch;
      }).toList();
    } else if (_selectedCategory != null) {
      // Filtrar por categoría seleccionada
      filtered = _productos.where((p) => p.categoriaNombre == _selectedCategory).toList();
    } else {
      // Sin filtros: mostrar todos los productos
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
    // Guardar copia de estado actual para fallback en caso de error/offline
    final previousProductos = List<Producto>.from(_productos);
    final previousCategorias = List<Categoria>.from(_categorias);
    final previousSelectedCategory = _selectedCategory;

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

      // Actualizar caché completo en background (sin bloquear la UI)
      // Esto asegura que el caché esté siempre sincronizado con el servidor
      _actualizarCacheCompletoEnBackground();
      
      // Seleccionar la primera categoría por defecto si no hay ninguna seleccionada
      String? categoriaInicial;
      if (_selectedCategory == null && categoriasData.isNotEmpty) {
        categoriaInicial = categoriasData.first.nombre;
        _selectedCategory = categoriaInicial;
      } else if (_selectedCategory != null) {
        categoriaInicial = _selectedCategory;
      }

      // Cargar todos los productos desde el caché para permitir filtrado por categoría
      // Si el caché está vacío o desactualizado, se actualizará en background
      List<Producto> productosList = [];
      try {
        // Intentar cargar todos los productos desde el caché
        final cacheService = DatosCacheService();
        productosList = await cacheService.obtenerProductosDelCache();
        
        if (productosList.isNotEmpty) {
          debugPrint('📦 ProductoProvider: ${productosList.length} productos cargados desde caché');
        } else {
          // Si no hay productos en caché, usar productos paginados como fallback inicial
          productosList = List<Producto>.from(productosData['productos']);
          debugPrint('⚠️ ProductoProvider: Caché vacío, usando productos paginados como fallback (${productosList.length} productos)');
        }
      } catch (e) {
        debugPrint('⚠️ ProductoProvider: Error cargando productos desde caché: $e');
        // Fallback a productos paginados
        productosList = List<Producto>.from(productosData['productos']);
      }
      
      _productos = productosList;
      _categorias = categoriasData;
      _hasMoreData = false; // No usamos scroll infinito cuando filtramos por categoría
      _isOffline = categoriasProvider.loadedFromCache;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      log('Error al cargar los Productos: $e', level: 1000);
      if (AuthService.isSessionExpiredException(e)) {
        await AuthService.logout();
        _isLoading = false;
        notifyListeners();
        return;
      }
      // Verificar si hay datos del caché disponibles
      if (Apihandler.isConnectionError(e)) {
        try {
          // Verificar si está marcado como vacío
          final productosCache = ProductosCacheService();
          final isEmptyMarked = await productosCache.isEmptyMarked();
          
          if (isEmptyMarked) {
            // Está marcado como vacío, no intentar cargar.
            // Si ya teníamos productos antes, mantener la última lista conocida.
            if (previousProductos.isNotEmpty) {
              _productos = previousProductos;
              _categorias = previousCategorias;
              _selectedCategory = previousSelectedCategory;
              _hasMoreData = false;
              _isOffline = true;
              _isLoading = false;
              debugPrint('📝 ProductoProvider: Caché marcado como vacío, manteniendo lista previa (${_productos.length} productos)');
            } else {
              _productos = [];
              _categorias = [];
              _selectedCategory = null;
              _hasMoreData = false;
              _isOffline = true;
              _isLoading = false;
              debugPrint('📝 ProductoProvider: Caché marcado como vacío y sin datos previos, mostrando lista vacía');
            }
            notifyListeners();
            return;
          }
          
          // Intentar obtener del caché directamente
          final cacheService = DatosCacheService();
          
          // Cargar todos los productos desde el caché
          final productosDelCache = await cacheService.obtenerProductosDelCache();
          if (productosDelCache.isNotEmpty) {
            _productos = productosDelCache;
            _hasMoreData = false;
            _isOffline = true;
            _isLoading = false;
            notifyListeners();
            return;
          } else {
            // No hay datos en caché. Si teníamos datos previos en memoria,
            // mantenerlos para no dejar al usuario sin productos.
            if (previousProductos.isNotEmpty) {
              _productos = previousProductos;
              _categorias = previousCategorias;
              _selectedCategory = previousSelectedCategory;
              _hasMoreData = false;
              _isOffline = true;
              _isLoading = false;
              debugPrint('📝 ProductoProvider: Caché vacío, manteniendo lista previa (${_productos.length} productos)');
            } else {
              _productos = [];
              _categorias = [];
              _selectedCategory = null;
              _hasMoreData = false;
              _isOffline = true;
              _isLoading = false;
              debugPrint('📝 ProductoProvider: Caché vacío y sin datos previos, mostrando lista vacía');
            }
            notifyListeners();
            return;
          }
        } catch (cacheError) {
          // Si falla el caché, continuar con el error normal
        }
      }

      // Si no es error de conexión y teníamos datos previos, mantenerlos
      if (previousProductos.isNotEmpty) {
        _productos = previousProductos;
        _categorias = previousCategorias;
        _selectedCategory = previousSelectedCategory;
        _hasMoreData = false;
        _isLoading = false;
        _errorMessage = e.toString();
        notifyListeners();
        return;
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
      if (AuthService.isSessionExpiredException(e)) {
        await AuthService.logout();
        notifyListeners();
        return;
      }
      _errorMessage = e.toString();
      notifyListeners();
      log('Error al cargar más productos: $e', level: 1000);
      rethrow;
    }
  }

  /// Cambia la categoría seleccionada (el filtrado se hace en productosFiltrados)
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

  /// Limpia listas, caché y catálogo local al cambiar de usuario (logout).
  /// Evita mostrar productos/categorías de otro tenant.
  Future<void> clearForNewUser() async {
    _productos = [];
    _categorias = [];
    _selectedCategory = null;
    _searchQuery = '';
    _currentPage = 1;
    _hasMoreData = true;
    _errorMessage = null;
    _isOffline = false;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();

    try {
      final cacheService = DatosCacheService();
      await cacheService.limpiarCache();
      await _catalogoLocal.limpiarClientes();
      await _catalogoLocal.limpiarProductos();
      await _catalogoLocal.limpiarCategorias();
      debugPrint('✅ ProductoProvider: caché y catálogo local limpiados para nuevo usuario/tenant');
    } catch (e) {
      debugPrint('⚠️ ProductoProvider: error limpiando caché para nuevo usuario: $e');
    }
  }

  /// Recarga los productos iniciales (usado después de crear/editar/eliminar)
  Future<void> recargarProductos(CategoriasProvider categoriasProvider) async {
    await cargarProductosInicial(categoriasProvider);
  }

  void sincronizarCategoriasDesde(CategoriasProvider categoriasProvider) {
    final nuevasCategorias = List<Categoria>.from(categoriasProvider.categorias);
    _categorias = nuevasCategorias;

    final categoriaSeleccionadaExiste = _selectedCategory != null &&
        _categorias.any((cat) => cat.nombre == _selectedCategory);

    if (!categoriaSeleccionadaExiste) {
      _selectedCategory =
          _categorias.isNotEmpty ? _categorias.first.nombre : null;
    }

    notifyListeners();
  }

  /// Obtiene productos del caché inmediatamente (sin llamar al servidor).
  /// Si la caché está vacía (p. ej. tras logout), intenta CatalogoLocal para modo offline.
  Future<List<Producto>> obtenerProductosDelCache() async {
    try {
      final cacheService = DatosCacheService();
      final list = await cacheService.obtenerProductosDelCache();
      if (list.isNotEmpty) return list;
      // Caché vacía: usar catálogo local (modo offline)
      return await _catalogoLocal.obtenerProductos();
    } catch (e) {
      return await _catalogoLocal.obtenerProductos();
    }
  }

  /// Obtiene productos: intenta del servidor, si falla usa SQLite local
  Future<List<Producto>> obtenerProductos() async {
    print('📡 ProductoProvider: Intentando obtener productos del servidor...');
    
    try {
      // Intentar obtener del servidor con timeout
      _productos = await _productoService.obtenerProductos()
          .timeout(_timeoutDuration);
      
      print('✅ ProductoProvider: ${_productos.length} productos obtenidos del servidor');
      
      // Guardar en ambos almacenamientos para uso offline
      final cacheService = DatosCacheService();
      await cacheService.guardarProductosEnCache(_productos);
      await _catalogoLocal.guardarProductos(_productos);
      if (_productos.isEmpty) {
        print('✅ ProductoProvider: Caché limpiado (servidor devolvió lista vacía)');
      } else {
        print('✅ ProductoProvider: ${_productos.length} productos guardados en caché y catálogo local');
      }
      
    } catch (e) {
      print('⚠️ ProductoProvider: Error obteniendo del servidor: $e');
      print('📦 ProductoProvider: Cargando productos locales (SQLite)...');
      _productos = await _catalogoLocal.obtenerProductos();
      
      if (_productos.isEmpty) {
        print('❌ ProductoProvider: No hay productos locales');
        throw Exception('No hay productos disponibles offline. Conecta para sincronizar.');
      } else {
        print('✅ ProductoProvider: ${_productos.length} productos cargados de SQLite');
        // Sincronizar a caché para que obtenerProductosDelCache() tenga datos la próxima vez
        final cacheService = DatosCacheService();
        await cacheService.guardarProductosEnCache(_productos);
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
      // Intentar obtener del servidor con timeout
      final result = await _productoService.obtenerProductosPaginados(page, pageSize)
          .timeout(_timeoutDuration);
      
      print('✅ ProductoProvider: ${result['productos'].length} productos obtenidos del servidor');
      
      // NO guardar aquí - el provider maneja la actualización completa del caché
      // para asegurar que siempre refleje TODOS los productos del servidor
      
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

  /// Actualiza el caché completo obteniendo TODOS los productos del servidor
  /// Se ejecuta en background para no bloquear la UI
  void _actualizarCacheCompletoEnBackground() {
    debugPrint('🔄 ProductoProvider: Iniciando actualización completa del caché en background...');
    _productoService.obtenerProductos()
        .timeout(_timeoutDuration) // Timeout más largo para operación crítica
        .then((todosLosProductos) async {
      debugPrint('📦 ProductoProvider: ${todosLosProductos.length} productos obtenidos del servidor para actualizar caché');
      
      // Actualizar AMBOS sistemas de caché para asegurar sincronización completa
      // 1. DatosCacheService (tabla productos_cache)
      final cacheService = DatosCacheService();
      await cacheService.guardarProductosEnCache(todosLosProductos);
      debugPrint('✅ ProductoProvider: DatosCacheService actualizado en background');
      
      // 2. CatalogoLocalService (tabla productos)
      await _catalogoLocal.guardarProductos(todosLosProductos);
      debugPrint('✅ ProductoProvider: CatalogoLocalService actualizado en background');
      
      if (todosLosProductos.isEmpty) {
        debugPrint('✅ ProductoProvider: Caché completo limpiado (servidor devolvió lista vacía)');
      } else {
        debugPrint(
            '✅ ProductoProvider: Caché completo actualizado con ${todosLosProductos.length} productos en ambos sistemas');
      }
    }).catchError((e) {
      debugPrint('⚠️ ProductoProvider: Error actualizando caché completo en background: $e');
      // Si falla por timeout o error de conexión, no hacer nada
      // El caché se mantendrá con los datos anteriores hasta la próxima actualización exitosa
    });
  }
}
