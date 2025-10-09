import 'package:flutter/material.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/CategoriaReorderDTO.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_service.dart';
import 'package:tobaco/Helpers/api_handler.dart';

class CategoriasProvider with ChangeNotifier {
  final CategoriaService _categoriaService = CategoriaService();

  List<Categoria> _categorias = [];

  List<Categoria> get categorias => _categorias;

  bool isLoading = false;

  // Método para resetear el estado de loading
  void resetLoadingState() {
    if (isLoading) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Categoria>> obtenerCategorias({bool silent = false}) async {
    try {
      // Solo actualizar isLoading si realmente cambió y no es modo silencioso
      if (!isLoading && !silent) {
        isLoading = true;
        notifyListeners();
      }
      
      _categorias = await _categoriaService.obtenerCategorias();
      
      // Solo actualizar isLoading si realmente cambió y no es modo silencioso
      if (isLoading && !silent) {
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      // Si es un error de conexión, limpiar la lista de categorías
      if (Apihandler.isConnectionError(e)) {
        _categorias = [];
      }
      
      if (isLoading && !silent) {
        isLoading = false;
        notifyListeners();
      }
      debugPrint('Error en obtenerCategorias: $e');
      // Relanzar la excepción para que la UI la pueda manejar
      rethrow;
    }
    return _categorias;
  }

  Future<void> agregarCategoria(Categoria categoria) async {
    try {
      if (!isLoading) {
        isLoading = true;
        notifyListeners();
      }
      
      await _categoriaService.crearCategoria(categoria);
      await obtenerCategorias(silent: true);
      
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      // Si es un error de conexión, limpiar la lista de categorías
      if (Apihandler.isConnectionError(e)) {
        _categorias = [];
      }
      
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
      debugPrint('Error al agregar categoría: $e');
      // Relanzar la excepción para que la UI la pueda manejar
      rethrow;
    }
  }

  Future<void> eliminarCategoria(int id) async {
    try {
      if (!isLoading) {
        isLoading = true;
        notifyListeners();
      }
      
      await _categoriaService.eliminarCategoria(id);
      _categorias.removeWhere((cat) => cat.id == id);
      
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      // Si es un error de conexión, limpiar la lista de categorías
      if (Apihandler.isConnectionError(e)) {
        _categorias = [];
      }
      
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
      debugPrint('Error al eliminar categoría: $e');
      // Relanzar la excepción para que la UI la pueda manejar
      rethrow;
    }
  }
  Future<void> editarCategoria(int id, String nombre, String colorHex) async {
    try {
      final categoriaEditada = await _categoriaService.editarCategoria(id, nombre, colorHex);
      final index = _categorias.indexWhere((cat) => cat.id == id);
      if (index != -1) {
        _categorias[index] = categoriaEditada;
        notifyListeners();
      }
    } catch (e) {
      // Si es un error de conexión, limpiar la lista de categorías
      if (Apihandler.isConnectionError(e)) {
        _categorias = [];
        notifyListeners();
      }
      debugPrint('Error al editar categoría: $e');
      // Relanzar la excepción para que la UI la pueda manejar
      rethrow;
    }
  }

  Future<void> reordenarCategorias(List<Categoria> nuevasCategorias) async {
    try {
      if (!isLoading) {
        isLoading = true;
        notifyListeners();
      }
      
      // Crear lista de DTOs para el reordenamiento
      final categoriaOrders = nuevasCategorias.asMap().entries.map((entry) {
        return CategoriaReorderDTO(
          id: entry.value.id!,
          sortOrder: entry.key,
        );
      }).toList();

      // Enviar al backend
      await _categoriaService.reordenarCategorias(categoriaOrders);
      
      // Actualizar la lista local
      _categorias = List.from(nuevasCategorias);
      
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      // Si es un error de conexión, limpiar la lista de categorías
      if (Apihandler.isConnectionError(e)) {
        _categorias = [];
      }
      
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
      debugPrint('Error al reordenar categorías: $e');
      rethrow; // Re-lanzar para manejar el error en la UI
    }
  }
}
