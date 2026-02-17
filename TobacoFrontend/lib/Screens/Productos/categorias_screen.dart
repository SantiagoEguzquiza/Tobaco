import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Widgets/ReorderableCategoriaList.dart';
import 'package:tobaco/Helpers/color_picker.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _editNombreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CategoriasProvider>().cargarCategorias());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _editNombreController.dispose();
    super.dispose();
  }

  Future<void> _agregarCategoria() async {
    final provider = context.read<CategoriasProvider>();
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('El nombre de la categoría es requerido'),
      );
      return;
    }

    try {
      final nuevaCategoria = Categoria(
        nombre: nombre,
        colorHex: provider.selectedColor,
        sortOrder: provider.categorias.length,
      );

      await provider.agregarCategoria(nuevaCategoria);

      if (mounted) {
        _nombreController.clear();
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Categoría agregada exitosamente'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar(
          'Error al agregar categoría: ${e.toString().replaceFirst('Exception: ', '')}',
        ),
      );
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
        await context.read<CategoriasProvider>().eliminarCategoria(categoria.id!);

        if (!mounted) return;

        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Categoría eliminada exitosamente'),
        );
      } catch (e) {
        if (!mounted) return;

        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    }
  }

  Future<void> _editarCategoria(Categoria categoria) async {
    final provider = context.read<CategoriasProvider>();
    final nombre = _editNombreController.text.trim();
    if (nombre.isEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('El nombre de la categoría es requerido'),
      );
      return;
    }

    try {
      await provider.editarCategoria(
        categoria.id!,
        nombre,
        provider.selectedColor,
      );

      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Categoría actualizada exitosamente'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString().toLowerCase();
      final mensaje = errorStr.contains('ya existe') || errorStr.contains('duplicad')
          ? 'El nombre seleccionado ya existe, pruebe con otro.'
          : e.toString().replaceFirst('Exception: ', '');
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar(mensaje),
      );
    }
  }

  void _showEditCategoriaDialog(Categoria categoria) {
    _editNombreController.text = categoria.nombre;
    _editNombreController.selection = TextSelection.collapsed(
      offset: _editNombreController.text.length,
    );
    context.read<CategoriasProvider>().seleccionarColor(categoria.colorHex);

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer<CategoriasProvider>(
        builder: (context, provider, _) => AppTheme.customAlertDialog(
          title: 'Editar Categoría',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
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
                  controller: _editNombreController,
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
                selectedColor: provider.selectedColor,
                onColorSelected: provider.seleccionarColor,
              ),
            ],
          ),
          onCancel: () => Navigator.of(dialogContext).pop(),
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            _editarCategoria(categoria);
          },
          confirmText: 'Guardar',
          cancelText: 'Cancelar',
        ),
      ),
    );
  }

  void _showAddCategoriaDialog() {
    context.read<CategoriasProvider>().seleccionarColor('#9E9E9E');
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer<CategoriasProvider>(
        builder: (context, provider, _) => AppTheme.customAlertDialog(
          title: 'Nueva Categoría',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
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
                selectedColor: provider.selectedColor,
                onColorSelected: provider.seleccionarColor,
              ),
            ],
          ),
          onCancel: () => Navigator.of(dialogContext).pop(),
          onConfirm: () {
            Navigator.of(dialogContext).pop();
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
    final provider = context.watch<CategoriasProvider>();
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
              onPressed: () =>
                  context.read<CategoriasProvider>().cargarCategorias(),
              tooltip: 'Actualizar',
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                strokeWidth: 3,
              ),
            )
          : Column(
              children: [
                if (provider.errorMessage != null && provider.categorias.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<CategoriasProvider>()
                                  .cargarCategorias(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: HeaderSimple(
                              leadingIcon: Icons.category,
                              title: 'Gestión de Categorías',
                              subtitle:
                                  '${provider.categorias.length} categorías registradas',
                            ),
                          ),
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
                                    borderRadius: BorderRadius.circular(15),
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
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: provider.categorias.isEmpty
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
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
                            onDelete: (categoria) =>
                                _eliminarCategoria(categoria),
                            onEdit: (categoria) =>
                                _showEditCategoriaDialog(categoria),
                          ),
                  ),
                ],
              ],
            ),
    );
  }
}

