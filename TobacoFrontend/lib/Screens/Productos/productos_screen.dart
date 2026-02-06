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
  

  // ScrollController para detectar cuando llegar al final
  final ScrollController _scrollController = ScrollController();
  
  // ScrollController para el ListView horizontal de categorías
  final ScrollController _categoriesScrollController = ScrollController();

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
    // Cargar productos iniciales usando el Provider
    Future.microtask(() {
      final productoProvider = context.read<ProductoProvider>();
      final categoriasProvider = context.read<CategoriasProvider>();
      productoProvider.cargarProductosInicial(categoriasProvider).then((_) {
      }).catchError((e) {
        // Manejar errores
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
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoriesScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final productoProvider = context.read<ProductoProvider>();
      if (!productoProvider.isLoadingMore && productoProvider.hasMoreData) {
        productoProvider.cargarMasProductos().catchError((e) {
          if (mounted) {
            if (Apihandler.isConnectionError(e)) {
              Apihandler.handleConnectionError(context, e);
            } else {
              AppDialogs.showErrorDialog(
                context: context,
                message: 'Error al cargar más productos',
              );
            }
          }
        });
      }
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null, // Usar el tema
        title: const Text(
          'Productos',
          style: AppTheme.appBarTitleStyle,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header con buscador y controles - SIEMPRE VISIBLE
              _buildHeaderSection(prov, categorias, searchQuery, selectedCategory),
              const SizedBox(height: 20),
              // Lista con estados dentro
              Expanded(child: _buildProductosList(prov, categorias)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ProductoProvider prov, List<Categoria> categorias, String searchQuery, String? selectedCategory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderConBuscador(
          leadingIcon: Icons.inventory_2,
          title: 'Gestión de Productos',
          subtitle: '${prov.productos.length} productos • ${categorias.length} categorías',
          controller: _searchController,
          hintText: 'Buscar productos...',
          onChanged: (value) {
            prov.filtrarPorBusqueda(value);
          },
          onClear: () {
            prov.limpiarBusqueda();
            _searchController.clear();
          },
        ),
        const SizedBox(height: 15),
        // Botón de crear producto - Solo mostrar si tiene permiso
        Consumer<PermisosProvider>(
          builder: (context, permisosProvider, child) {
            if (permisosProvider.canCreateProductos || permisosProvider.isAdmin) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text(
                    'Crear Nuevo Producto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 15),
        // Filtros de categoría (solo mostrar cuando NO hay búsqueda activa)
        if (categorias.isNotEmpty && searchQuery.isEmpty) ...[
          SizedBox(
            height: 45,
            child: ListView.builder(
              controller: _categoriesScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final categoria = categorias[index];
                final isSelected = selectedCategory == categoria.nombre;
                final categoriaColor = _parseColor(categoria.colorHex);
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      prov.seleccionarCategoria(categoria.nombre);
                      _centerCategoryButton(index, categorias);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? categoriaColor : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? categoriaColor : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        categoria.nombre[0].toUpperCase() + categoria.nombre.substring(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // Indicador de búsqueda global (solo cuando hay productos)
        if (prov.productosFiltrados.isNotEmpty && searchQuery.isNotEmpty) ...[
          const SizedBox(height: 12),
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
    final isLoadingMore = prov.isLoadingMore;
    final searchQuery = prov.searchQuery;

    if (isLoading && filteredProductos.isEmpty) {
      return _buildLoadingState();
    }

    if (filteredProductos.isEmpty) {
      return _buildEmptyState(searchQuery);
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
        itemCount: filteredProductos.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredProductos.length) {
            return _buildLoadingIndicator();
          }
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

      // Cerrar loading
      Navigator.pop(context);

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

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ),
    );
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

  Widget _buildEmptyState(String searchQuery) {
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
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isNotEmpty ? 'Sin resultados' : 'No hay productos disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  searchQuery.isNotEmpty
                      ? 'No se encontraron productos que coincidan con "$searchQuery"'
                      : 'Crea tu primer producto para comenzar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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

          // Cerrar loading
          Navigator.pop(context);

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

          // Cerrar loading
          Navigator.pop(context);

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
