import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Permisos_Service/permisos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';

class ReorderableCategoriaList extends StatefulWidget {
  final Function(Categoria)? onDelete;
  
  const ReorderableCategoriaList({
    super.key,
    this.onDelete,
  });

  @override
  State<ReorderableCategoriaList> createState() => _ReorderableCategoriaListState();
}

class _ReorderableCategoriaListState extends State<ReorderableCategoriaList> {
  List<Categoria> _categorias = [];
  bool _isReordering = false;
  final Map<String, String> _offlineKeyCache = {};

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  void _loadCategorias() {
    final provider = Provider.of<CategoriasProvider>(context, listen: false);
    _categorias = List.from(provider.categorias);
    _syncOfflineKeys();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      _isReordering = true;
    });

    try {
      // Crear una copia de la lista para el reordenamiento
      final List<Categoria> reorderedCategorias = List.from(_categorias);
      
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      final Categoria item = reorderedCategorias.removeAt(oldIndex);
      reorderedCategorias.insert(newIndex, item);

      // Actualizar la lista local inmediatamente (persistencia optimista)
      setState(() {
        _categorias = reorderedCategorias;
      });

      // Enviar al backend
      await Provider.of<CategoriasProvider>(context, listen: false)
          .reordenarCategorias(reorderedCategorias);

      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Categorías reordenadas exitosamente'),
        );
      }
    } catch (e) {
      // Rollback en caso de error
      setState(() {
        _loadCategorias(); // Restaurar el orden original
      });

      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al reordenar categorías: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReordering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoriasProvider>(
      builder: (context, provider, child) {
        // Actualizar la lista local cuando cambie el provider
        if (!_isReordering) {
          _categorias = List.from(provider.categorias);
          _syncOfflineKeys();
        }

        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              strokeWidth: 3,
            ),
          );
        }

        if (_categorias.isEmpty) {
          return const Center(
            child: Text(
              'No hay categorías disponibles',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _categorias.length,
          onReorder: _onReorder, 
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget? child) {
                final double animValue = Curves.easeInOut.transform(animation.value);
                final double elevation = 0 + (6 - 0) * animValue;
                final double scale = 1 + (1.02 - 1) * animValue;
                return Transform.scale(
                  scale: scale,
                  child: Material(
                    elevation: elevation,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final categoria = _categorias[index];
            return _buildCategoriaItem(categoria, index);
          },
        );
      },
    );
  }

  Widget _buildCategoriaItem(Categoria categoria, int index) {
    final categoriaColor = _parseColor(categoria.colorHex);
    final itemKey = _itemKeyForCategoria(categoria);

    return Container(
      key: itemKey,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicador lateral con color de la categoría
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: categoriaColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Información de la categoría
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria.nombre,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered_outlined,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Orden: ${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botones de acción
              Consumer<PermisosProvider>(
                builder: (context, permisosProvider, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onDelete != null && permisosProvider.canDeleteProductos)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              widget.onDelete!(categoria);
                            },
                            tooltip: 'Eliminar',
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.drag_handle,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade400,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to safely parse color hex
  Color _parseColor(String colorHex) {
    try {
      if (colorHex.isEmpty || colorHex.length < 7) {
        return const Color(0xFF9E9E9E); // Default gray
      }
      return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF9E9E9E); // Default gray on error
    }
  }

  Key _itemKeyForCategoria(Categoria categoria) {
    if (categoria.id != null) {
      return ValueKey('categoria_${categoria.id}');
    }

    final cacheKey = _offlineCacheKeyFor(categoria);
    final storedValue = _offlineKeyCache.putIfAbsent(
      cacheKey,
      () => 'offline_${cacheKey}_${_offlineKeyCache.length}',
    );

    return ValueKey(storedValue);
  }

  void _syncOfflineKeys() {
    final activeKeys = <String>{};
    for (final categoria in _categorias) {
      if (categoria.id == null) {
        activeKeys.add(_offlineCacheKeyFor(categoria));
      }
    }

    _offlineKeyCache.removeWhere(
      (cacheKey, _) => !activeKeys.contains(cacheKey),
    );
  }

  String _offlineCacheKeyFor(Categoria categoria) {
    return '${categoria.nombre}_${categoria.colorHex}_${categoria.sortOrder}';
  }
}
