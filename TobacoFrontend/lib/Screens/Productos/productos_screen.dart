// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Screens/Admin/categorias_screen.dart';
import 'package:tobaco/Screens/Productos/detalleProducto_screen.dart';
import 'package:tobaco/Screens/Productos/editarProducto_screen.dart';
import 'package:tobaco/Screens/Productos/nuevoProducto_screen.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema
import 'package:tobaco/Theme/dialogs.dart'; // Importa los diálogos centralizados
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Utils/loading_utils.dart';
import 'package:tobaco/Helpers/api_handler.dart'; // Importa el manejador de errores de API
import 'dart:developer';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  _ProductosScreenState createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  bool isLoading = true;
  String searchQuery = '';
  String? selectedCategory; // Nombre de la categoría seleccionada
  String? errorMessage;
  List<Producto> productos = [];
  List<Categoria> categorias = [];
  final TextEditingController _searchController = TextEditingController();

  // Variables para infinite scroll
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  
  // ScrollController para detectar cuando llegar al final
  final ScrollController _scrollController = ScrollController();

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
    _loadProductos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _cargarMasProductos();
    }
  }

  
  Future<void> _loadProductos() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
      _currentPage = 1;
      productos.clear();
      _hasMoreData = true;
    });

    try {
      // Usar los providers del contexto en lugar de crear nuevas instancias
      final productoProvider =
          Provider.of<ProductoProvider>(context, listen: false);
      final categoriasProvider =
          Provider.of<CategoriasProvider>(context, listen: false);

      // Obtener categorías y productos en paralelo para evitar múltiples notifyListeners
      final futures = await Future.wait([
        categoriasProvider.obtenerCategorias(silent: true), // Modo silencioso para evitar notifyListeners durante build
        productoProvider.obtenerProductosPaginados(_currentPage, _pageSize),
      ]);

      final categoriasData = futures[0] as List<Categoria>;
      final productosData = futures[1] as Map<String, dynamic>;

      if (!mounted) return;
      
      setState(() {
        productos = List<Producto>.from(productosData['productos']);
        categorias = categoriasData;
        _hasMoreData = productosData['hasNextPage'];
        isLoading = false;
        
        // Seleccionar la primera categoría por defecto si no hay ninguna seleccionada
        if (selectedCategory == null && categoriasData.isNotEmpty) {
          selectedCategory = categoriasData.first.nombre;
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      log('Error al cargar los Productos: $e', level: 1000);
      
      // Mostrar diálogo de error
      if (Apihandler.isConnectionError(e)) {
        setState(() {
          isLoading = false;
          // No establecer errorMessage para errores de conexión
        });
        await Apihandler.handleConnectionError(context, e);
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Error al cargar los Productos: $e';
        });
        await AppDialogs.showErrorDialog(
          context: context,
          message: 'Error al cargar productos',
        );
      }
    }
  }

  Future<void> _cargarMasProductos() async {
    if (_isLoadingMore || !_hasMoreData || !mounted) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final productoProvider =
          Provider.of<ProductoProvider>(context, listen: false);
      
      final data = await productoProvider.obtenerProductosPaginados(_currentPage + 1, _pageSize);
      if (!mounted) return;
      
      setState(() {
        productos.addAll(List<Producto>.from(data['productos']));
        _currentPage++;
        _hasMoreData = data['hasNextPage'];
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoadingMore = false;
      });
      log('Error al cargar más productos: $e', level: 1000);
      
      // Mostrar diálogo de error
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        await AppDialogs.showErrorDialog(
          context: context,
          message: 'Error al cargar más productos',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    // Lógica de filtrado: búsqueda global vs filtro por categoría
    List<Producto> filteredProductos;
    
    if (searchQuery.isNotEmpty) {
      // Modo búsqueda global: buscar en todo el catálogo
      filteredProductos = productos.where((producto) {
        return producto.nombre.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    } else {
      // Modo categoría: filtrar por categoría seleccionada
      filteredProductos = productos.where((producto) {
        return selectedCategory == null || producto.categoriaNombre == selectedCategory;
      }).toList();
    }
    
    // Ordenar alfabéticamente
    filteredProductos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

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
              onPressed: () {
                showMenu(
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
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Ver categorías',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).then((value) {
                  if (value == '1') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CategoriasScreen()),
                    );
                  }
                });
              },
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando productos...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderConBuscador(
                    leadingIcon: Icons.inventory_2,
                    title: 'Gestión de Productos',
                    subtitle: '${productos.length} productos • ${categorias.length} categorías',
                    controller: _searchController,
                    hintText: 'Buscar productos...',
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    onClear: () {
                      setState(() {
                        searchQuery = '';
                      });
                      _searchController.clear();
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botón de crear producto
                  SizedBox(
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
                            builder: (context) =>
                                const NuevoProductoScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadProductos();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                      icon:
                          const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text(
                        'Crear Nuevo Producto',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Filtros de categoría (solo mostrar cuando NO hay búsqueda activa)
                  if (categorias.isNotEmpty && searchQuery.isEmpty) ...[
                    Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categorias.length,
                        itemBuilder: (context, index) {
                          final categoria = categorias[index];
                          final isSelected =
                              selectedCategory == categoria.nombre;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    categoria.nombre[0].toUpperCase() +
                                        categoria.nombre.substring(1),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategory = categoria.nombre;
                                });
                              },
                              backgroundColor: Theme.of(context).cardTheme.color,
                              selectedColor: _parseColor(categoria.colorHex),
                              checkmarkColor: Colors.white,
                              side: BorderSide(
                                color: isSelected
                                    ? _parseColor(categoria.colorHex)
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Lista de productos
                  if (filteredProductos.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'Sin resultados'
                                : 'No hay productos disponibles',
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
                  ] else ...[
                    // Indicador de búsqueda global o título normal
                    Row(
                      children: [
                        if (searchQuery.isNotEmpty) ...[
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
                                Icon(
                                  Icons.search,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
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
                              '${filteredProductos.length} resultado${filteredProductos.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Productos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : AppTheme.textColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredProductos.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredProductos.length) {
                          return _buildLoadingIndicator();
                        }
                        final producto = filteredProductos[index];
                        return Container(
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
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleProductoScreen(
                                      producto: producto,
                                    ),
                                  ),
                                );
                                // If a product was deleted, refresh the list
                                if (result == true) {
                                  _loadProductos();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
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
                                                    producto.categoriaNombre,
                                                orElse: () => Categoria(
                                                    nombre: '',
                                                    colorHex: '#9E9E9E'),
                                              )
                                              .colorHex,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
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
                                              color: Theme.of(context).brightness == Brightness.dark
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
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Stock: ${producto.stock}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? Colors.grey.shade400
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.attach_money,
                                                size: 16,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Precio: \$${producto.precio.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? Colors.grey.shade400
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.category_outlined,
                                                size: 16,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                producto.categoriaNombre ??
                                                    'Sin categoría',
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
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
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditarProductoScreen(
                                                    producto: producto,
                                                  ),
                                                ),
                                              );
                                              if (result == true) {
                                                _loadProductos();
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () => _eliminarProducto(context, producto),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
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

  Future<void> _deactivateProduct(BuildContext context, Producto producto) async {
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
      
      final productoProvider = Provider.of<ProductoProvider>(context, listen: false);
      final errorMessage = await productoProvider
          .desactivarProductoConMensaje(producto.id!);
      
      if (!context.mounted) return;
      
      // Cerrar loading
      Navigator.pop(context);
      
      if (errorMessage == null) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Producto desactivado exitosamente. Ya no aparecerá en los catálogos.'),
        );
        
        // Recargar lista de productos
        _loadProductos();
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

  /// Función para eliminar un producto usando el diálogo centralizado
  Future<void> _eliminarProducto(BuildContext context, Producto producto) async {
    final confirmado = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Producto',
      itemName: producto.nombre,
    );

    if (confirmado) {
      final productoProvider = Provider.of<ProductoProvider>(context, listen: false);
      
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
          _loadProductos();
          
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
              AppTheme.errorSnackBar(e.toString().replaceFirst('Exception: ', '')),
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