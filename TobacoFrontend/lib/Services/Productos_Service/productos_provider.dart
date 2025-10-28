import 'package:flutter/material.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Services/Productos_Service/productos_service.dart';
import 'package:tobaco/Services/Cache/datos_cache_service.dart';

class ProductoProvider with ChangeNotifier {
  final ProductoService _productoService = ProductoService();
  final DatosCacheService _cacheService = DatosCacheService();

  List<Producto> _productos = [];

  List<Producto> get productos => _productos;

  /// Obtiene productos: intenta del servidor, si falla usa caché
  Future<List<Producto>> obtenerProductos() async {
    print('📡 ProductoProvider: Intentando obtener productos del servidor...');
    
    try {
      // Intentar obtener del servidor con timeout (500ms para ser más rápido en offline)
      _productos = await _productoService.obtenerProductos()
          .timeout(Duration(milliseconds: 500));
      
      print('✅ ProductoProvider: ${_productos.length} productos obtenidos del servidor');
      
      // Guardar en caché para uso offline
      if (_productos.isNotEmpty) {
        await _cacheService.guardarProductosEnCache(_productos);
        print('✅ ProductoProvider: ${_productos.length} productos guardados en caché');
      }
      
    } catch (e) {
      print('⚠️ ProductoProvider: Error obteniendo del servidor: $e');
      print('📦 ProductoProvider: Cargando productos del caché...');
      
      // Si falla, cargar del caché
      _productos = await _cacheService.obtenerProductosDelCache();
      
      if (_productos.isEmpty) {
        print('❌ ProductoProvider: No hay productos en caché');
        throw Exception('No hay productos disponibles offline. Conecta para sincronizar.');
      } else {
        print('✅ ProductoProvider: ${_productos.length} productos cargados del caché');
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
      
      // Guardar en caché para uso offline (en background)
      if (result['productos'].isNotEmpty) {
        _cacheService.guardarProductosEnCache(result['productos'] as List<Producto>)
            .catchError((e) => print('⚠️ Error guardando productos en caché: $e'));
      }
      
      return result;
    } catch (e) {
      print('⚠️ ProductoProvider: Error obteniendo del servidor: $e');
      print('📦 ProductoProvider: Cargando productos del caché...');
      
      // Si falla, cargar del caché
      final productosCache = await _cacheService.obtenerProductosDelCache();
      
      if (productosCache.isEmpty) {
        print('❌ ProductoProvider: No hay productos en caché');
        rethrow;
      }
      
      print('✅ ProductoProvider: ${productosCache.length} productos cargados del caché');
      
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
      };
    }
  }
}
