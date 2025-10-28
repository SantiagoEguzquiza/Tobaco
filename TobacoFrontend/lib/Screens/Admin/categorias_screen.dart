import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Widgets/ReorderableCategoriaList.dart';
import 'package:tobaco/Helpers/color_picker.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Utils/loading_utils.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final TextEditingController _nombreController = TextEditingController();
  String _selectedColor = '#9E9E9E';
  final bool _isLoading = false;
  final String _searchQuery = '';
  bool _offlineMessageShown = false; // Para mostrar el mensaje solo la primera vez

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
    // Cargar categorías al inicializar la pantalla
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
    final provider = Provider.of<CategoriasProvider>(context, listen: false);
    
    // Si ya hay categorías cargadas del servidor (no del caché), solo resetear loading
    if (provider.categorias.isNotEmpty && !provider.loadedFromCache) {
      provider.resetLoadingState();
      return;
    }

    try {
      // Siempre intentar cargar del servidor cuando se abre la pantalla
      await provider.obtenerCategorias();
      
      // 📱 Mostrar snackbar si cargó del caché (solo la primera vez)
      if (mounted && provider.loadedFromCache && provider.categorias.isNotEmpty && !_offlineMessageShown) {
        _offlineMessageShown = true;
        AppTheme.showSnackBar(
          context,
          AppTheme.warningSnackBar('Modo Offline Activado'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Si hay error y no hay categorías, mostrar mensaje
      if (Apihandler.isConnectionError(e)) {
        // Solo mostrar mensaje si no hay categorías en caché
        if (provider.categorias.isEmpty) {
          AppTheme.showSnackBar(
            context,
            AppTheme.warningSnackBar('Sin conexión. Verifica tu conexión a internet.'),
          );
        }
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al cargar categorías: ${e.toString().replaceFirst('Exception: ', '')}'),
        );
      }
    }
  }

  Future<bool> _agregarCategoria() async {
    if (_nombreController.text.trim().isEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('El nombre de la categoría es requerido'),
      );
      return false;
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
        
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Categoría agregada exitosamente'),
        );
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al agregar categoría: ${e.toString().replaceFirst('Exception: ', '')}'),
        );
      }
      return false;
    }
  }

  Future<void> _eliminarCategoria(Categoria categoria) async {
    final confirmed = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Categoría',
      itemName: categoria.nombre,
    );

    if (confirmed) {
      try {
        await Provider.of<CategoriasProvider>(context, listen: false)
            .eliminarCategoria(categoria.id!);

        if (!mounted) return;

        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Categoría eliminada exitosamente'),
        );
      } catch (e) {
        if (!mounted) return;

        if (Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
        } else {
          // Mostrar el mensaje de error del backend
          await AppDialogs.showErrorDialog(
            context: context,
            message: e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    }
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
              Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    selectionColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.white,
                  ),
                ),
                child: TextField(
                  controller: _nombreController,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la categoría',
                  ),
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
          onConfirm: () {
            // Cerrar el diálogo inmediatamente
            Navigator.of(context).pop();
            // Luego ejecutar la función de agregar categoría
            _agregarCategoria();
          },
          confirmText: 'Agregar',
          cancelText: 'Cancelar',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null, // Usar el tema
        title: const Text(
          'Categorías',
          style: AppTheme.appBarTitleStyle,
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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: HeaderSimple(
                  leadingIcon: Icons.category,
                  title: 'Gestión de Categorías',
                  subtitle: '${provider.categorias.length} categorías registradas',
                ),
              ),
              
              // Add category button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddCategoriaDialog,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text(
                      'Nueva Categoría',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, 
                        vertical: 16,
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),

              // Instrucciones de reordenamiento
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
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
                    : ReorderableCategoriaList(
                        onDelete: (categoria) => _eliminarCategoria(categoria),
                      ),
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
