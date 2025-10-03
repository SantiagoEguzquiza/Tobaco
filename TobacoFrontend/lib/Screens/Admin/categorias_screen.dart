import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Widgets/ReorderableCategoriaList.dart';
import 'package:tobaco/Helpers/color_picker.dart';
import 'package:tobaco/Utils/loading_utils.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final TextEditingController _nombreController = TextEditingController();
  String _selectedColor = '#9E9E9E';
  bool _isLoading = false;
  String _searchQuery = '';

  final List<String> _availableColors = [
    '#FF8A00', // Orange
    '#3B82F6', // Blue
    '#10B981', // Green
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#06B6D4', // Cyan
    '#9E9E9E', // Gray (default)
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cargar categorías después de que el contexto esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCategorias();
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    // Verificar si ya se están cargando las categorías
    final provider = Provider.of<CategoriasProvider>(context, listen: false);
    if (provider.isLoading) return;

    try {
      await provider.obtenerCategorias();
    } catch (e) {
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al cargar categorías: $e'),
        );
      }
    }
  }

  Future<void> _agregarCategoria() async {
    if (_nombreController.text.trim().isEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('El nombre de la categoría es requerido'),
      );
      return;
    }

    try {
      final nuevaCategoria = Categoria(
        nombre: _nombreController.text.trim(),
        colorHex: _selectedColor,
      );

      await Provider.of<CategoriasProvider>(context, listen: false)
          .agregarCategoria(nuevaCategoria);

      if (mounted) {
        _nombreController.clear();
        _selectedColor = '#9E9E9E';
        
        // Cerrar el diálogo
        Navigator.of(context).pop();
        
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Categoría agregada exitosamente'),
        );
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al agregar categoría: $e'),
        );
      }
    }
  }

  Future<void> _eliminarCategoria(Categoria categoria) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppTheme.alertDialogStyle(
        title: 'Confirmar eliminación',
        content: '¿Estás seguro de que quieres eliminar la categoría "${categoria.nombre}"?',
        onConfirm: () async {
          try {
            await Provider.of<CategoriasProvider>(context, listen: false)
                .eliminarCategoria(categoria.id!);

            if (mounted) {
              AppTheme.showSnackBar(
                context,
                AppTheme.successSnackBar('Categoría eliminada exitosamente'),
              );
            }
          } catch (e) {
            if (mounted) {
              AppTheme.showSnackBar(
                context,
                AppTheme.errorSnackBar('Error al eliminar categoría: $e'),
              );
            }
          }
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showAddCategoriaDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AppTheme.customAlertDialog(
          title: 'Nueva Categoría',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                cursorColor: Colors.black,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la categoría',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
              ),
            ],
          ),
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: _agregarCategoria,
          confirmText: 'Agregar',
          cancelText: 'Cancelar',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Categorías',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
              onPressed: _loadCategorias,
              tooltip: 'Actualizar',
            ),
          ),
        ],
      ),
      body: Consumer<CategoriasProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                strokeWidth: 3,
              ),
            );
          }

          return Column(
            children: [
              // Header fijo
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con estadísticas
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.secondaryColor.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.category,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gestión de Categorías',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      '${provider.categorias.length} categorías registradas',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Botón de crear categoría
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showAddCategoriaDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 2,
                              ),
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              label: const Text(
                                'Crear Nueva Categoría',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Instrucciones de reordenamiento
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Reordenar Categorías',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Mantén presionado y arrastra las categorías para cambiar su orden. El orden se guardará automáticamente.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Lista reordenable con altura específica
              Expanded(
                child: provider.categorias.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay categorías disponibles',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crea tu primera categoría para comenzar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ReorderableCategoriaList(),
              ),
            ],
          );
        },
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
