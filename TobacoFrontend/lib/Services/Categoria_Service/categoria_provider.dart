import 'package:flutter/material.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_service.dart';

class CategoriasProvider with ChangeNotifier {
  final CategoriaService _categoriaService = CategoriaService();

  List<Categoria> _categorias = [];

  List<Categoria> get categorias => _categorias;

  bool isLoading = false;

  Future<List<Categoria>> obtenerCategorias() async {
    try {
      _categorias = await _categoriaService.obtenerCategorias();
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
    return _categorias;
  }

  Future<void> agregarCategoria(Categoria categoria) async {
    try {
      await _categoriaService.crearCategoria(categoria);
      await obtenerCategorias();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al agregar categoría: $e');
    }
  }

  Future<void> eliminarCategoria(int id) async {
    try {
      await _categoriaService.eliminarCategoria(id);
      _categorias.removeWhere((cat) => cat.id == id);
      notifyListeners();
    } catch (e) {
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
}
