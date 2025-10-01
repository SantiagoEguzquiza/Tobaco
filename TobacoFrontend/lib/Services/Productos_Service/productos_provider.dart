import 'package:flutter/material.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Services/Productos_Service/productos_service.dart';

class ProductoProvider with ChangeNotifier {
  final ProductoService _productoService = ProductoService();

  List<Producto> _productos = [];

  List<Producto> get productos => _productos;

  Future<List<Producto>> obtenerProductos() async {
    try {
      _productos = await _productoService.obtenerProductos();
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
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
    try {
      return await _productoService.obtenerProductosPaginados(page, pageSize);
    } catch (e) {
      debugPrint('Error al obtener productos paginados: $e');
      rethrow;
    }
  }
}
