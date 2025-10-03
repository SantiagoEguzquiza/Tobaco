import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';

class ReorderableCategoriaList extends StatefulWidget {
  const ReorderableCategoriaList({super.key});

  @override
  State<ReorderableCategoriaList> createState() => _ReorderableCategoriaListState();
}

class _ReorderableCategoriaListState extends State<ReorderableCategoriaList> {
  List<Categoria> _categorias = [];
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  void _loadCategorias() {
    final provider = Provider.of<CategoriasProvider>(context, listen: false);
    _categorias = List.from(provider.categorias);
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
    return Container(
      key: ValueKey(categoria.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _parseColor(categoria.colorHex),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        title: Text(
          categoria.nombre,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Orden: ${index + 1}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.reorder,
              color: Colors.grey.shade400,
            ),
          ],
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
}
