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
  final GlobalKey _headerKey = GlobalKey();

  double _headerVisibility = 1.0;
  double _lastScrollOffset = 0.0;
  double _maxHeaderHeight = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureHeader();
    });
    Future.microtask(() => context.read<CategoriasProvider>().cargarCategorias());
  }

  void _measureHeader() {
    final ctx = _headerKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        _maxHeaderHeight = box.size.height;
      }
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    final currentOffset = notification.metrics.pixels;
    final delta = currentOffset - _lastScrollOffset;
    _lastScrollOffset = currentOffset;
    if (_maxHeaderHeight <= 0 || delta.abs() > 200) return false;
    double newVisibility;
    if (currentOffset <= 0) {
      newVisibility = 1.0;
    } else {
      newVisibility =
          (_headerVisibility - delta * 0.5 / _maxHeaderHeight).clamp(0.0, 1.0);
    }
    if ((newVisibility - _headerVisibility).abs() > 0.001) {
      setState(() {
        _headerVisibility = newVisibility;
      });
    }
    return false;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureHeader();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null,
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
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                strokeWidth: 3,
              ),
            )
          : provider.errorMessage != null && provider.categorias.isEmpty
              ? Center(
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
                )
              : Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: SafeArea(
                    top: true,
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        MediaQuery.of(context).size.height < 680 ? 12 : 16,
                        16,
                        0,
                      ),
                      child: Column(
                        children: [
                          ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: _headerVisibility,
                              child: Opacity(
                                opacity: _headerVisibility,
                                child: Column(
                                  key: _headerKey,
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    HeaderSimple(
                                      leadingIcon: Icons.category,
                                      title: 'Gestión de Categorías',
                                      subtitle:
                                          '${provider.categorias.length} categorías registradas',
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.height < 680 ? 8 : 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Builder(
                                        builder: (context) {
                                          final isCompact = MediaQuery.of(context).size.height < 680;
                                          return ElevatedButton.icon(
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
                                            icon: Icon(Icons.add_circle_outline, size: isCompact ? 18 : 20),
                                            label: Text(
                                              'Nueva Categoría',
                                              style: TextStyle(
                                                fontSize: isCompact ? 14 : 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: isCompact ? 12 : 16,
                                              ),
                                              elevation: 2,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: MediaQuery.of(context).size.height < 680 ? 8 : 12),
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
                                    SizedBox(height: MediaQuery.of(context).size.height < 680 ? 10 : 20),
                                  ],
                                ),
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
                                : NotificationListener<ScrollNotification>(
                                    onNotification: _onScrollNotification,
                                    child: ReorderableCategoriaList(
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

