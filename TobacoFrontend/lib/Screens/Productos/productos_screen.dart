// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Screens/Productos/categorias_screen.dart';
import 'package:tobaco/Screens/Productos/detalleProducto_screen.dart';
import 'package:tobaco/Screens/Productos/editarProducto_screen.dart';
import 'package:tobaco/Screens/Productos/nuevoProducto_screen.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Services/Permisos_Service/permisos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart'; 
import 'package:tobaco/Theme/dialogs.dart'; 
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Helpers/producto_descuento_helper.dart'; 

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  _ProductosScreenState createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  bool _categoriesLoadTriggered = false;
  bool _advancedSearchExpanded = false;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoriesScrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();

  double _headerVisibility = 1.0;
  double _lastScrollOffset = 0.0;
  double _maxHeaderHeight = 0.0;

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureHeader();
    });
    // Cargar categorías y productos al entrar (importante en app recién instalada o sin caché)
    Future.microtask(() async {
      if (!mounted) return;
      final productoProvider = context.read<ProductoProvider>();
      final categoriasProvider = context.read<CategoriasProvider>();
      try {
        // Cargar categorías primero para que estén disponibles al cargar productos
        await categoriasProvider.cargarCategorias(silent: true);
        if (!mounted) return;
        await productoProvider.cargarProductosInicial(categoriasProvider);
        if (!mounted) return;
        // Si ProductoProvider no tiene categorías pero CategoriasProvider sí (ej. falló la copia interna), sincronizar
        if (productoProvider.categorias.isEmpty && categoriasProvider.categorias.isNotEmpty) {
          productoProvider.sincronizarCategoriasDesde(categoriasProvider);
        }
      } catch (e) {
        if (mounted) {
          if (Apihandler.isConnectionError(e)) {
            AppTheme.showSnackBar(
              context,
              AppTheme.warningSnackBar('Sin conexión. Verifica tu conexión a internet.'),
            );
          } else {
            AppDialogs.showErrorDialog(
              context: context,
              message: 'Error al cargar productos',
            );
          }
        }
      }
    });
  }

  Future<void> _cargarCategoriasYSincronizar() async {
    if (!mounted || _categoriesLoadTriggered) return;
    _categoriesLoadTriggered = true;
    try {
      await context.read<CategoriasProvider>().cargarCategorias(silent: true);
      if (!mounted) return;
      context.read<ProductoProvider>().sincronizarCategoriasDesde(context.read<CategoriasProvider>());
    } catch (_) {}
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoriesScrollController.dispose();
    _searchController.dispose();
    _marcaController.dispose();
    super.dispose();
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

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;
    _lastScrollOffset = currentOffset;
    if (_maxHeaderHeight <= 0 || delta.abs() > 200) return;
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
  }

  void _centerCategoryButton(int index, List<Categoria> categorias) {
    if (!_categoriesScrollController.hasClients || !mounted) return;
    
    // Esperar un frame para que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_categoriesScrollController.hasClients || !mounted) return;
      
      // Obtener el ancho de la pantalla
      final screenWidth = MediaQuery.of(context).size.width;
      
      // Estimar el ancho de cada botón (padding + texto aproximado + padding)
      // Vamos a calcular la posición sumando los anchos de los botones anteriores
      double estimatedPosition = 0.0;
      for (int i = 0; i < index; i++) {
        // Ancho aproximado: padding horizontal (12*2) + padding right (10) + ancho del texto
        final categoria = categorias[i];
        final textWidth = categoria.nombre.length * 9.0; // Aproximación: 9px por carácter
        estimatedPosition += 12 * 2 + 10 + textWidth;
      }
      
      // Calcular la posición del centro del botón actual
      final currentCategoria = categorias[index];
      final currentTextWidth = currentCategoria.nombre.length * 9.0;
      final currentButtonWidth = 12 * 2 + currentTextWidth;
      final currentButtonCenter = estimatedPosition + (currentButtonWidth / 2);
      
      // Calcular la posición de scroll para centrar el botón en la pantalla
      final targetPosition = currentButtonCenter - (screenWidth / 2);
      
      // Hacer scroll animado
      _categoriesScrollController.animateTo(
        targetPosition.clamp(0.0, _categoriesScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    // Observar el Provider para obtener el estado actual
    final prov = context.watch<ProductoProvider>();
    final categorias = prov.categorias;
    final searchQuery = prov.searchQuery;
    final selectedCategory = prov.selectedCategory;

    // Si entramos directo a Productos y aún no hay categorías (ni está cargando), cargarlas una vez
    if (categorias.isEmpty && !prov.isLoading && !prov.isSyncing && !_categoriesLoadTriggered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _cargarCategoriasYSincronizar();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureHeader();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).scaffoldBackgroundColor
            : AppTheme.primaryColor,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? null
            : Colors.white,
        scrolledUnderElevation: 0,
        title: const Text(
          'Productos',
          style: AppTheme.appBarTitleStyle,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.transparent
                  : AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
              ),
              onPressed: () async {
                final value = await showMenu<String>(
                  context: context,
                  position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  items: [
                    PopupMenuItem(
                      value: '1',
                      child: Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Ver categorías',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (value == '1') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriasScreen(),
                    ),
                  );

                  if (!mounted) return;
                  final categoriasProvider =
                      context.read<CategoriasProvider>();
                  try {
                    await categoriasProvider.cargarCategorias(silent: true);
                  } catch (_) {
                    // Si falla la recarga silenciosa, usamos el estado actual
                  }
                  if (!mounted) return;
                  context
                      .read<ProductoProvider>()
                      .sincronizarCategoriasDesde(categoriasProvider);
                }
              },
            ),
          )
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _headerVisibility,
                    child: Opacity(
                      opacity: _headerVisibility,
                      child: Builder(
                        builder: (context) {
                          final screenHeight = MediaQuery.of(context).size.height;
                          final viewInsets = MediaQuery.of(context).viewInsets.bottom;
                          final keyboardOpen = viewInsets > 0;
                          final filterExpanded = _advancedSearchExpanded;
                          final headerNeedsLimit = keyboardOpen || filterExpanded;
                          final minListHeight = 360.0;
                          final maxHeaderHeight = (screenHeight - minListHeight - 32).clamp(120.0, double.infinity);
                          if (headerNeedsLimit) {
                            return ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: maxHeaderHeight),
                              child: SingleChildScrollView(
                                child: Column(
                                  key: _headerKey,
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHeaderSearchAndFilter(prov),
                                    SizedBox(height: MediaQuery.of(context).size.height < 680 ? 8 : 12),
                                    _buildHeaderActions(prov, categorias, searchQuery, selectedCategory),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Column(
                            key: _headerKey,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeaderSearchAndFilter(prov),
                              SizedBox(height: MediaQuery.of(context).size.height < 680 ? 8 : 12),
                              _buildHeaderActions(prov, categorias, searchQuery, selectedCategory),
                              const SizedBox(height: 6),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildProductosList(prov, categorias),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Solo buscador + filtro Marca (esta parte puede hacer scroll cuando falta espacio).
  Widget _buildHeaderSearchAndFilter(ProductoProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HeaderConBuscador(
          leadingIcon: Icons.inventory_2,
          title: 'Gestión de Productos',
          subtitle: '${prov.productos.length} productos • ${context.read<CategoriasProvider>().categorias.length} categorías',
          controller: _searchController,
          hintText: 'Buscar por nombre...',
          onChanged: (value) => prov.filtrarPorBusqueda(value),
          onClear: () {
            prov.limpiarBusqueda();
            _searchController.clear();
          },
          trailing: IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: _advancedSearchExpanded ? AppTheme.primaryColor : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 22,
            ),
            onPressed: () => setState(() => _advancedSearchExpanded = !_advancedSearchExpanded),
            tooltip: 'Buscador avanzado',
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _advancedSearchExpanded
              ? Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height < 680 ? 6 : 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Marca',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height < 680 ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height < 680 ? 4 : 6),
                      TextField(
                        controller: _marcaController,
                        onChanged: (value) => prov.setFiltroMarca(value),
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height < 680 ? 14 : 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Filtrar por marca',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: MediaQuery.of(context).size.height < 680 ? 13 : 14,
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: MediaQuery.of(context).size.height < 680 ? 10 : 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.sell_outlined,
                            size: 20,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              prov.limpiarFiltrosAvanzados();
                              _searchController.clear();
                              _marcaController.clear();
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.clear_all_rounded,
                              size: 20,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            tooltip: 'Limpiar filtros',
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(8),
                              minimumSize: const Size(36, 36),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Botón Crear Nuevo Producto + chips de categoría + indicador búsqueda (siempre fijo encima del listado).
  Widget _buildHeaderActions(ProductoProvider prov, List<Categoria> categorias, String searchQuery, String? selectedCategory) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFiltrosActivos = searchQuery.isNotEmpty || prov.searchMarca.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer<PermisosProvider>(
          builder: (context, permisosProvider, child) {
            if (permisosProvider.canCreateProductos || permisosProvider.isAdmin) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () async {
                    if (categorias.isEmpty) {
                      AppTheme.showSnackBar(
                        context,
                        AppTheme.warningSnackBar('Primero debes crear una categoría'),
                      );
                      return;
                    }
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NuevoProductoScreen(),
                      ),
                    );
                    if (result == true) {
                      final categoriasProvider = context.read<CategoriasProvider>();
                      prov.recargarProductos(categoriasProvider);
                    }
                  },                
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: MediaQuery.of(context).size.height < 680 ? 18 : 20,
                  ),
                  label: Text(
                    'Crear Nuevo Producto',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.height < 680 ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        SizedBox(height: MediaQuery.of(context).size.height < 680 ? 8 : 12),
        // Filtros de categoría (solo mostrar cuando NO hay búsqueda activa)
        if (categorias.isNotEmpty && searchQuery.isEmpty && prov.searchMarca.isEmpty) ...[
          SizedBox(
            height: MediaQuery.of(context).size.height < 680 ? 38 : 42,
            child: ListView.builder(
              controller: _categoriesScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final categoria = categorias[index];
                final isSelected = selectedCategory == categoria.nombre;
                final categoriaColor = _parseColor(categoria.colorHex);
                final isCompact = MediaQuery.of(context).size.height < 680;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      prov.seleccionarCategoria(categoria.nombre);
                      _centerCategoryButton(index, categorias);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: isCompact ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? categoriaColor : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? categoriaColor : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          categoria.nombre[0].toUpperCase() + categoria.nombre.substring(1),
                          style: TextStyle(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // Indicador de búsqueda global (solo cuando hay filtros activos)
        if (prov.productosFiltrados.isNotEmpty && hasFiltrosActivos) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'Búsqueda global',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${prov.productosFiltrados.length} resultado${prov.productosFiltrados.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProductosList(ProductoProvider prov, List<Categoria> categorias) {
    final filteredProductos = prov.productosFiltrados;
    final isLoading = prov.isLoading;
    final searchQuery = prov.searchQuery;

    if (isLoading && filteredProductos.isEmpty) {
      return _buildLoadingState();
    }

    if (filteredProductos.isEmpty) {
      return _buildEmptyState(prov);
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        final categoriasProvider = context.read<CategoriasProvider>();
        final productoProvider = context.read<ProductoProvider>();
        await productoProvider.recargarProductos(categoriasProvider);
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        itemCount: filteredProductos.length,
        itemBuilder: (context, index) {
          final producto = filteredProductos[index];
          return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetalleProductoScreen(
                                          producto: producto,
                                        ),
                                      ),
                                    );
                                    // If a product was deleted, refresh the list
                                    if (result == true) {
                                    final categoriasProvider = context.read<CategoriasProvider>();
                                    prov.recargarProductos(categoriasProvider);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                    child: Row(
                                      children: [
                                        // Indicador de categoría
                                        Container(
                                          width: 4,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: _parseColor(
                                              categorias
                                                  .firstWhere(
                                                    (c) =>
                                                        c.nombre ==
                                                        producto
                                                            .categoriaNombre,
                                                    orElse: () => Categoria(
                                                        nombre: '',
                                                        colorHex: '#9E9E9E'),
                                                  )
                                                  .colorHex,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Información del producto
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                producto.nombre,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : AppTheme.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.inventory_2_outlined,
                                                    size: 16,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey.shade400
                                                        : Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${producto.stock?.toStringAsFixed(0)} unidades',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.grey.shade400
                                                          : Colors
                                                              .grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              _buildPrecioConDescuento(context, producto),
                                              const SizedBox(height: 2),
                                            ],
                                          ),
                                        ),

                                        // Botones de acción - Ocultar según permisos
                                        Consumer<PermisosProvider>(
                                          builder: (context, permisosProvider, child) {
                                            final canEdit = permisosProvider.canEditProductos || permisosProvider.isAdmin;
                                            final canDelete = permisosProvider.canDeleteProductos || permisosProvider.isAdmin;
                                            
                                            // Si no tiene ningún permiso de acción, no mostrar la fila
                                            if (!canEdit && !canDelete) {
                                              return const SizedBox.shrink();
                                            }
                                            
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Botón Editar
                                                if (canEdit)
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primaryColor
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.edit_outlined,
                                                        color: AppTheme.primaryColor,
                                                        size: 20,
                                                      ),
                                                      onPressed: () async {
                                                        final result =
                                                            await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                EditarProductoScreen(
                                                              producto: producto,
                                                            ),
                                                          ),
                                                        );
                                                        if (result == true) {
                                                          final categoriasProvider = context.read<CategoriasProvider>();
                                                          prov.recargarProductos(categoriasProvider);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                if (canEdit && canDelete)
                                                  const SizedBox(width: 8),
                                                // Botón Eliminar
                                                if (canDelete)
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.red.withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.red,
                                                        size: 20,
                                                      ),
                                                      onPressed: () =>
                                                          _eliminarProducto(
                                                              context, producto),
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
        },
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context, Producto producto) async {
    final confirmado = await AppDialogs.showDeactivateProductDialog(
      context: context,
      productName: producto.nombre,
    );

    if (confirmado) {
      await _deactivateProduct(context, producto);
    }
  }

  Future<void> _deactivateProduct(
      BuildContext context, Producto producto) async {
    if (producto.id != null) {
      // Mostrar loading básico
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );

      final productoProvider =
          Provider.of<ProductoProvider>(context, listen: false);
      final errorMessage =
          await productoProvider.desactivarProductoConMensaje(producto.id!);

      if (!context.mounted) return;

      // Cerrar solo el diálogo de loading (root navigator), no la pantalla Productos
      Navigator.of(context, rootNavigator: true).pop();

      if (errorMessage == null) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar(
              'Producto desactivado exitosamente. Ya no aparecerá en los catálogos.'),
        );

        // Recargar lista de productos
        final categoriasProvider = context.read<CategoriasProvider>();
        final productoProvider = context.read<ProductoProvider>();
        productoProvider.recargarProductos(categoriasProvider);
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar(errorMessage),
        );
      }
    }
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
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
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando productos...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ProductoProvider prov) {
    final hasFiltros = prov.searchQuery.isNotEmpty || prov.searchMarca.isNotEmpty;
    final mensajeFiltros = hasFiltros
        ? (prov.searchQuery.isNotEmpty && prov.searchMarca.isNotEmpty
            ? 'Nombre: "${prov.searchQuery}" · Marca: "${prov.searchMarca}"'
            : prov.searchQuery.isNotEmpty
                ? '"${prov.searchQuery}"'
                : 'Marca: "${prov.searchMarca}"')
        : '';
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 400 || size.height < 640;
    final padding = isSmallPhone ? 20.0 : 40.0;
    final iconSize = isSmallPhone ? 56.0 : 80.0;
    final titleSize = isSmallPhone ? 16.0 : 18.0;
    final subtitleSize = isSmallPhone ? 13.0 : 14.0;
    final spacing1 = isSmallPhone ? 12.0 : 16.0;
    final spacing2 = isSmallPhone ? 6.0 : 8.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
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
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, padding, padding, padding + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: iconSize, color: Colors.grey.shade400),
              SizedBox(height: spacing1),
              Text(
                hasFiltros ? 'Sin resultados' : 'No hay productos disponibles',
                style: TextStyle(
                  fontSize: titleSize,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing2),
              Text(
                hasFiltros
                    ? 'No se encontraron productos que coincidan con $mensajeFiltros'
                    : 'Crea tu primer producto para comenzar',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para mostrar precio con descuento
  Widget _buildPrecioConDescuento(BuildContext context, Producto producto) {
    final tieneDescuentoActivo = ProductoDescuentoHelper.tieneDescuentoActivo(producto);
    final precioConDescuento = ProductoDescuentoHelper.calcularPrecioConDescuento(producto);
    final fechaExpiracion = ProductoDescuentoHelper.obtenerFechaExpiracionFormateada(producto);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tieneDescuentoActivo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                size: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              // Precio original tachado
              Text(
                producto.precio.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 8),
              // Precio con descuento
              Text(
                precioConDescuento.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 4),
              // Badge de descuento
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-${producto.descuento.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          // Fecha de expiración si existe
          if (fechaExpiracion != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  'Vence: $fechaExpiracion',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    } else {
      // Precio normal sin descuento
      return Row(
        children: [
          Icon(
            Icons.attach_money,
            size: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            producto.precio.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      );
    }
  }

  /// Función para eliminar un producto usando el diálogo centralizado
  Future<void> _eliminarProducto(
      BuildContext context, Producto producto) async {
    final confirmado = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Producto',
      itemName: producto.nombre,
    );

    if (confirmado) {
      final productoProvider =
          Provider.of<ProductoProvider>(context, listen: false);

      if (producto.id != null) {
        // Mostrar loading básico
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        );

        try {
          // Intentar eliminación física primero
          await productoProvider.eliminarProducto(producto.id!);

          if (!context.mounted) return;

          // Cerrar solo el diálogo de loading (root navigator), no la pantalla Productos
          Navigator.of(context, rootNavigator: true).pop();

          // Si llegamos aquí, la eliminación fue exitosa (sin ventas vinculadas)
          AppTheme.showSnackBar(
            context,
            AppTheme.successSnackBar('Producto eliminado con éxito'),
          );

          // Recargar lista de productos
          final categoriasProvider = context.read<CategoriasProvider>();
          productoProvider.recargarProductos(categoriasProvider);
        } catch (e) {
          if (!context.mounted) return;

          // Cerrar solo el diálogo de loading (root navigator), no la pantalla Productos
          Navigator.of(context, rootNavigator: true).pop();

          // Si es un error 409 (Conflict) - producto con ventas vinculadas
          if (e.toString().contains('ventas vinculadas') ||
              e.toString().contains('Conflict')) {
            _showDeactivateDialog(context, producto);
          } else if (Apihandler.isConnectionError(e)) {
            await Apihandler.handleConnectionError(context, e);
          } else {
            // Otros errores
            AppTheme.showSnackBar(
              context,
              AppTheme.errorSnackBar(
                  e.toString().replaceFirst('Exception: ', '')),
            );
          }
        }
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error: ID del producto no válido'),
        );
      }
    }
  }
}
