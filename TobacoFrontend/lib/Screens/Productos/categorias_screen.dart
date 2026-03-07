import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Widgets/ReorderableCategoriaList.dart';
import 'package:tobaco/Screens/Productos/nueva_categoria_screen.dart';
import 'package:tobaco/Screens/Productos/editar_categoria_screen.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CategoriasProvider>().cargarCategorias());
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
                                onPressed: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NuevaCategoriaScreen(),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    context.read<CategoriasProvider>().cargarCategorias();
                                  }
                                },
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
                                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
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
                            onEdit: (categoria) async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditarCategoriaScreen(categoria: categoria),
                                ),
                              );
                              if (result == true && mounted) {
                                context.read<CategoriasProvider>().cargarCategorias();
                              }
                            },
                          ),
                  ),
                ],
              ],
            ),
    );
  }
}

