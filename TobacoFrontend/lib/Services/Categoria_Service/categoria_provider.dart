import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/CategoriaReorderDTO.dart';
import 'package:tobaco/Services/Cache/datos_cache_service.dart';
import 'package:tobaco/Services/Cache/data/categorias_cache_service.dart';
import 'package:tobaco/Services/Catalogo_Local/catalogo_local_service.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_service.dart';

class CategoriasProvider with ChangeNotifier {
  final CategoriaService _categoriaService = CategoriaService();
  final CatalogoLocalService _catalogoLocal = CatalogoLocalService();
  final DatosCacheService _datosCacheService = DatosCacheService();

  List<Categoria> _categorias = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String? _errorMessage;
  String _selectedColor = '#9E9E9E';
  bool _loadedFromCache = false;
  List<CategoriaReorderDTO>? _pendingReorderDtos;
  int _offlineIdSequence = -1;

  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;
  List<Categoria> get categorias => List.unmodifiable(_categorias);
  String get selectedColor => _selectedColor;
  bool get loadedFromCache => _loadedFromCache;

  Future<void> cargarCategorias({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final resultado = await _categoriaService.obtenerCategorias();
      _categorias = List.from(resultado)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _categorias = _normalizeCategorias(_categorias);
      _isOffline = false;
      _loadedFromCache = false;
      await _syncPendingReorder();

      if (_categorias.isNotEmpty) {
        await _catalogoLocal.guardarCategorias(_categorias);
        await _datosCacheService.guardarCategoriasEnCache(_categorias);
        // También guardar en CategoriasCacheService para SQLite
        final categoriasCache = CategoriasCacheService();
        await categoriasCache.saveAll(_categorias);
        await categoriasCache.clearEmptyMark(); // Limpiar marcador de vacío si hay datos
      } else {
        // Si no hay datos en modo online, marcar como vacío en caché
        final categoriasCache = CategoriasCacheService();
        await categoriasCache.markAsEmpty();
        debugPrint('📝 CategoriasProvider: Sin datos, marcado como vacío en caché');
      }
    } catch (e) {
      if (Apihandler.isConnectionError(e)) {
        await _cargarCategoriasOffline();
      } else {
        _errorMessage = _limpiarMensajeError(e.toString());
      }
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> _cargarCategoriasOffline() async {
    try {
      // Verificar si está marcado como vacío
      final categoriasCache = CategoriasCacheService();
      final isEmptyMarked = await categoriasCache.isEmptyMarked();
      
      if (isEmptyMarked) {
        // Está marcado como vacío, no intentar cargar
        _categorias = [];
        _isOffline = true;
        _loadedFromCache = false;
        _errorMessage = null;
        debugPrint('📝 CategoriasProvider: Caché marcado como vacío, mostrando lista vacía');
        return;
      }
      
      // Intentar cargar desde DatosCacheService primero
      final cache = await _datosCacheService.obtenerCategoriasDelCache();
      if (cache.isNotEmpty) {
        _categorias = List.from(cache)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        _categorias = _normalizeCategorias(_categorias);
        _isOffline = true;
        _loadedFromCache = true;
        _errorMessage = null;
        debugPrint('✅ CategoriasProvider: Categorías cargadas desde DatosCacheService');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ CategoriasProvider: Error cargando desde DatosCacheService: $e');
    }

    // Intentar cargar desde CategoriasCacheService (SQLite normalizado)
    try {
      final categoriasCache = CategoriasCacheService();
      final cacheSqlite = await categoriasCache.getAll();
      if (cacheSqlite.isNotEmpty) {
        _categorias = List.from(cacheSqlite)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        _categorias = _normalizeCategorias(_categorias);
        _isOffline = true;
        _loadedFromCache = true;
        _errorMessage = null;
        debugPrint('✅ CategoriasProvider: Categorías cargadas desde CategoriasCacheService (SQLite)');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ CategoriasProvider: Error cargando desde CategoriasCacheService: $e');
    }

    // Intentar cargar desde catalogo local como último recurso
    try {
      final locales = await _catalogoLocal.obtenerCategorias();
      if (locales.isNotEmpty) {
        _categorias = List.from(locales)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        _categorias = _normalizeCategorias(_categorias);
        _isOffline = true;
        _loadedFromCache = true;
        _errorMessage = null;
        debugPrint('✅ CategoriasProvider: Categorías cargadas desde CatalogoLocal');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ CategoriasProvider: Error cargando desde CatalogoLocal: $e');
    }

    // Si no se encontraron categorías en ningún lugar
    _categorias = [];
    _isOffline = true;
    _loadedFromCache = false;
    _errorMessage = null;
    debugPrint('⚠️ CategoriasProvider: No se encontraron categorías en ningún caché');
  }

  Future<void> agregarCategoria(Categoria nueva) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _categoriaService.crearCategoria(nueva);
      await cargarCategorias(silent: true);
      _selectedColor = '#9E9E9E';
    } catch (e) {
      if (Apihandler.isConnectionError(e)) {
        await _agregarCategoriaOffline(nueva);
      } else {
        _errorMessage = _limpiarMensajeError(e.toString());
        rethrow;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _agregarCategoriaOffline(Categoria nueva) async {
    final provisionalId =
        -(DateTime.now().millisecondsSinceEpoch + Random().nextInt(1000));
    final categoriaOffline = Categoria(
      id: nueva.id ?? provisionalId,
      nombre: nueva.nombre,
      colorHex: nueva.colorHex,
      sortOrder: nueva.sortOrder,
    );

    _categorias = List.from(_categorias)..add(categoriaOffline);
    _isOffline = true;
    _loadedFromCache = true;
    _selectedColor = '#9E9E9E';
    _categorias = _normalizeCategorias(_categorias, forceSortOrder: true);
    await _guardarCategoriasLocales();
  }

  Future<void> eliminarCategoria(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Verificar si hay productos vinculados a esta categoría antes de eliminar
      await _verificarProductosVinculados(id);
      
      await _categoriaService.eliminarCategoria(id);
      _categorias.removeWhere((cat) => cat.id == id);
      await _guardarCategoriasLocales();
    } catch (e) {
      if (Apihandler.isConnectionError(e)) {
        // Verificar productos vinculados también en modo offline
        await _verificarProductosVinculados(id);
        
        _categorias.removeWhere((cat) => cat.id == id);
        _isOffline = true;
        await _guardarCategoriasLocales();
      } else {
        _errorMessage = _limpiarMensajeError(e.toString());
        rethrow;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifica si hay productos vinculados a una categoría
  /// Lanza una excepción si hay productos vinculados
  Future<void> _verificarProductosVinculados(int categoriaId) async {
    try {
      // Obtener productos del cache
      final productos = await _datosCacheService.obtenerProductosDelCache();
      
      // Filtrar productos que tienen esta categoría
      final productosVinculados = productos.where((p) => p.categoriaId == categoriaId).toList();
      
      if (productosVinculados.isNotEmpty) {
        final cantidad = productosVinculados.length;
        final mensaje = cantidad == 1
            ? 'No se puede eliminar la categoría porque tiene 1 producto vinculado. Primero elimina o cambia la categoría del producto.'
            : 'No se puede eliminar la categoría porque tiene $cantidad productos vinculados. Primero elimina o cambia la categoría de los productos.';
        throw Exception(mensaje);
      }
    } catch (e) {
      // Si el error ya contiene un mensaje sobre productos vinculados, re-lanzarlo
      if (e.toString().contains('producto') && e.toString().contains('vinculado')) {
        rethrow;
      }
      // Si hay un error al verificar (por ejemplo, cache vacío), intentar continuar
      // pero registrar el error
      debugPrint('⚠️ CategoriasProvider: Error verificando productos vinculados: $e');
      // No re-lanzar el error para no bloquear la eliminación si el cache falla
      // El backend también validará esto
    }
  }

  Future<void> editarCategoria(int id, String nombre, String colorHex) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final categoriaEditada =
          await _categoriaService.editarCategoria(id, nombre, colorHex);
      final index = _categorias.indexWhere((cat) => cat.id == id);
      if (index != -1) {
        _categorias[index] = categoriaEditada;
      }
      await _guardarCategoriasLocales();
    } catch (e) {
      if (Apihandler.isConnectionError(e)) {
        _errorMessage = 'Sin conexión. Los cambios se aplicarán al reconectar.';
        rethrow;
      } else {
        _errorMessage = _limpiarMensajeError(e.toString());
        rethrow;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reordenarCategorias(List<Categoria> nuevasCategorias) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final normalizadas =
        _normalizeCategorias(List<Categoria>.from(nuevasCategorias), forceSortOrder: true);

    final categoriaOrders = normalizadas
        .where((categoria) => categoria.id != null && categoria.id! > 0)
        .map(
          (categoria) => CategoriaReorderDTO(
            id: categoria.id!,
            sortOrder: categoria.sortOrder,
          ),
        )
        .toList();

    final bool todosConIdValido =
        categoriaOrders.length == normalizadas.length && categoriaOrders.isNotEmpty;

    try {
      if (todosConIdValido) {
        await _categoriaService.reordenarCategorias(categoriaOrders);
        _pendingReorderDtos = null;
        _isOffline = false;
      } else {
        throw const _OfflineReorderException();
      }
    } catch (e) {
      if (e is _OfflineReorderException || Apihandler.isConnectionError(e)) {
        _pendingReorderDtos = todosConIdValido ? categoriaOrders : null;
        _isOffline = true;
        _errorMessage = 'No se pudo sincronizar el orden por falta de conexión.';
      } else {
        _errorMessage = _limpiarMensajeError(e.toString());
        rethrow;
      }
    } finally {
      _categorias = normalizadas;
      await _guardarCategoriasLocales();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _guardarCategoriasLocales() async {
    await _catalogoLocal.guardarCategorias(_categorias);
    await _datosCacheService.guardarCategoriasEnCache(_categorias);
    // También guardar en CategoriasCacheService para SQLite
    if (_categorias.isNotEmpty) {
      final categoriasCache = CategoriasCacheService();
      await categoriasCache.saveAll(_categorias);
      await categoriasCache.clearEmptyMark(); // Limpiar marcador de vacío si hay datos
    }
  }

  void seleccionarColor(String color) {
    _selectedColor = color;
    notifyListeners();
  }

  void resetLoadingState() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtiene categorías del caché inmediatamente (sin llamar al servidor).
  /// Si la caché está vacía, intenta CatalogoLocal para modo offline.
  /// Siempre devuelve la lista ordenada de primera a última (por sortOrder).
  Future<List<Categoria>> obtenerCategoriasDelCache() async {
    try {
      final list = await _datosCacheService.obtenerCategoriasDelCache();
      if (list.isNotEmpty) return _sortCategoriasFirstToLast(list);
      final locales = await _catalogoLocal.obtenerCategorias();
      return _sortCategoriasFirstToLast(locales);
    } catch (e) {
      final locales = await _catalogoLocal.obtenerCategorias();
      return _sortCategoriasFirstToLast(locales);
    }
  }

  /// Ordena categorías de primera a última por sortOrder (ascendente).
  List<Categoria> _sortCategoriasFirstToLast(List<Categoria> list) {
    if (list.isEmpty) return list;
    return List<Categoria>.from(list)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<List<Categoria>> obtenerCategorias({bool silent = false}) async {
    await cargarCategorias(silent: silent);
    return _categorias;
  }

  String _limpiarMensajeError(String mensaje) {
    return mensaje.replaceFirst('Exception: ', '');
  }

  List<Categoria> _normalizeCategorias(
    List<Categoria> categorias, {
    bool forceSortOrder = false,
  }) {
    return categorias.asMap().entries.map((entry) {
      final index = entry.key;
      final categoria = entry.value;
      final id = categoria.id ?? _generateOfflineId();
      final sortOrder = forceSortOrder ? index : categoria.sortOrder;
      return categoria.copyWith(
        id: id,
        sortOrder: sortOrder,
      );
    }).toList();
  }

  int _generateOfflineId() {
    return _offlineIdSequence--;
  }

  Future<void> _syncPendingReorder() async {
    if (_pendingReorderDtos == null || _pendingReorderDtos!.isEmpty) {
      return;
    }

    try {
      await _categoriaService.reordenarCategorias(_pendingReorderDtos!);
      _pendingReorderDtos = null;
      await cargarCategorias(silent: true);
    } catch (e) {
      if (!Apihandler.isConnectionError(e)) {
        _errorMessage = _limpiarMensajeError(e.toString());
      }
    }
  }

  /// Limpia listas y caché al cambiar de usuario. Evita mostrar categorías de otro usuario.
  Future<void> clearForNewUser() async {
    _categorias = [];
    _isLoading = false;
    _isOffline = false;
    _errorMessage = null;
    _loadedFromCache = false;
    _pendingReorderDtos = null;
    notifyListeners();
    try {
      final categoriasCache = CategoriasCacheService();
      await categoriasCache.clear();
    } catch (e) {
      debugPrint('⚠️ CategoriasProvider: error limpiando caché para nuevo usuario: $e');
    }
  }
}

class _OfflineReorderException implements Exception {
  const _OfflineReorderException();
}
