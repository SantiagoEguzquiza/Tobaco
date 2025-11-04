import 'package:flutter/material.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/CategoriaReorderDTO.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_service.dart';
import 'package:tobaco/Services/Catalogo_Local/catalogo_local_service.dart';
import 'package:tobaco/Helpers/api_handler.dart';

class CategoriasProvider with ChangeNotifier {
  final CategoriaService _categoriaService = CategoriaService();
  final CatalogoLocalService _catalogoLocal = CatalogoLocalService();

  List<Categoria> _categorias = [];
  bool loadedFromCache = false; // Indica si la última carga fue del caché

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
    // Si ya hay categorías cargadas del servidor (no del caché) y no se solicita recargar, retornar las existentes
    if (!silent && _categorias.isNotEmpty && !loadedFromCache) {
      return _categorias;
    }
    
    print('📡 CategoriasProvider: Intentando obtener categorías del servidor... (silent: $silent)');
    
    // En modo silencioso, no modificar el estado de loading para evitar notificaciones durante build
    // Solo establecer estado de carga si no es modo silencioso
    if (!silent && !isLoading) {
      isLoading = true;
      // Diferir la notificación hasta después del build actual para evitar setState during build
      Future.microtask(() => notifyListeners());
    }
    
    loadedFromCache = false; // Reset
    
    try {
      // Intentar obtener del servidor (el servicio maneja el timeout)
      _categorias = await _categoriaService.obtenerCategorias();
      
      print('✅ CategoriasProvider: ${_categorias.length} categorías obtenidas del servidor');
      loadedFromCache = false; // Cargado del servidor
      
      // Guardar localmente (SQLite) para uso offline
      if (_categorias.isNotEmpty) {
        await _catalogoLocal.guardarCategorias(_categorias);
        print('✅ CategoriasProvider: ${_categorias.length} categorías guardadas localmente');
      }
      
      // Notificar cambios solo si no es modo silencioso
      if (!silent) {
        isLoading = false;
        notifyListeners();
      }
      
    } catch (e) {
      print('⚠️ CategoriasProvider: Error obteniendo del servidor: $e');
      print('📦 CategoriasProvider: Cargando categorías locales (SQLite)...');
      
      // Si falla, cargar del caché
      try {
        _categorias = await _catalogoLocal.obtenerCategorias();
        
        if (_categorias.isEmpty) {
          print('❌ CategoriasProvider: No hay categorías locales');
          loadedFromCache = false;
          if (!silent) {
            isLoading = false;
            notifyListeners();
          }
          throw Exception('No hay categorías disponibles offline. Conecta para sincronizar.');
        } else {
          print('✅ CategoriasProvider: ${_categorias.length} categorías cargadas de SQLite');
          loadedFromCache = true; // Cargado del caché
          if (!silent) {
            isLoading = false;
            notifyListeners();
          }
        }
      } catch (cacheError) {
        if (!silent) {
          isLoading = false;
          notifyListeners();
        }
        rethrow;
      }
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
