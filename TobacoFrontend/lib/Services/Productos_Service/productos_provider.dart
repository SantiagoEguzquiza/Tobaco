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
      debugPrint('Error: $e');
    }
  }

  Future<void> eliminarProducto(int id) async {
    try {
      await _productoService.eliminarProducto(id);
      _productos.removeWhere((producto) => producto.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
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
      debugPrint('Error: $e');
    }
  }
}
