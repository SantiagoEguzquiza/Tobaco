import 'package:flutter/material.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/CategoriaReorderDTO.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_service.dart';

class CategoriasProvider with ChangeNotifier {
  final CategoriaService _categoriaService = CategoriaService();

  List<Categoria> _categorias = [];

  List<Categoria> get categorias => _categorias;

  bool isLoading = false;

  Future<List<Categoria>> obtenerCategorias({bool silent = false}) async {
    try {
      // Solo actualizar isLoading si realmente cambió y no es modo silencioso
      if (!isLoading && !silent) {
        isLoading = true;
        // Usar WidgetsBinding para evitar notifyListeners durante build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
      
      _categorias = await _categoriaService.obtenerCategorias();
      
      // Solo actualizar isLoading si realmente cambió y no es modo silencioso
      if (isLoading && !silent) {
        isLoading = false;
        // Usar WidgetsBinding para evitar notifyListeners durante build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      if (isLoading && !silent) {
        isLoading = false;
        // Usar WidgetsBinding para evitar notifyListeners durante build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
      debugPrint('Error: $e');
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
      
    } catch (e) {
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
      debugPrint('Error al agregar categoría: $e');
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
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
      debugPrint('Error al eliminar categoría: $e');
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
      debugPrint('Error al editar categoría: $e');
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
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
      debugPrint('Error al reordenar categorías: $e');
      rethrow; // Re-lanzar para manejar el error en la UI
    }
  }
}
