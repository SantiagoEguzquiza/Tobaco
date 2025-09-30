// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Screens/Productos/detalleProducto_screen.dart';
import 'package:tobaco/Screens/Productos/editarProducto_screen.dart';
import 'package:tobaco/Screens/Productos/nuevoProducto_screen.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema
import 'package:tobaco/Helpers/color_picker.dart';
import 'package:tobaco/Utils/loading_utils.dart';
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

      // Obtener categorías
      await categoriasProvider.obtenerCategorias();

      // Obtener primera página de productos
      final data = await productoProvider.obtenerProductosPaginados(_currentPage, _pageSize);

      setState(() {
        productos = List<Producto>.from(data['productos']);
        categorias = categoriasProvider.categorias;
        _hasMoreData = data['hasNextPage'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar los Productos: $e';
      });
      log('Error al cargar los Productos: $e', level: 1000);
    }
  }

  Future<void> _cargarMasProductos() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final productoProvider =
          Provider.of<ProductoProvider>(context, listen: false);
      
      final data = await productoProvider.obtenerProductosPaginados(_currentPage + 1, _pageSize);
      
      setState(() {
        productos.addAll(List<Producto>.from(data['productos']));
        _currentPage++;
        _hasMoreData = data['hasNextPage'];
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      log('Error al cargar más productos: $e', level: 1000);
    }
  }

  Future<void> _loadProductosWithLoading() async {
    await LoadingUtils.executeWithLoading(
      context,
      () async {
        await _loadProductos();
      },
      loadingMessage: 'Cargando productos...',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Selecciona la primera categoría por defecto si no hay ninguna seleccionada y hay categorías cargadas
    if (selectedCategory == null && categorias.isNotEmpty) {
      selectedCategory = categorias.first.nombre;
    }

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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Productos',
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
              icon: const Icon(Icons.menu, color: AppTheme.primaryColor),
              onPressed: () {
                showMenu(
                  context: context,
                  position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  items: [
                    PopupMenuItem(
                      value: '1',
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          const Text('Agregar categoría'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: '2',
                      child: Row(
                        children: [
                          Icon(Icons.category_outlined,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          const Text('Ver categorías'),
                        ],
                      ),
                    ),
                  ],
                ).then((value) {
                  if (value == '1') {
                    showDialog(
                      context: context,
                      builder: (context) {
                        String newCategoryName = '';
                        String selectedColor = '#9E9E9E'; // Default gray
                        return StatefulBuilder(
                          builder: (context, setStateDialog) {
                            return AppTheme.customAlertDialog(
                              title: 'Agregar nueva categoría',
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    cursorColor: Colors.black,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre de la categoría',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      newCategoryName = value;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  ColorPicker(
                                    selectedColor: selectedColor,
                                    onColorSelected: (color) {
                                      setStateDialog(() {
                                        selectedColor = color;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              onCancel: () => Navigator.of(context).pop(),
                              onConfirm: () async {
                                if (newCategoryName.trim().isNotEmpty) {
                                  await CategoriasProvider()
                                      .agregarCategoria(Categoria(
                                    id: null,
                                    nombre: newCategoryName,
                                    colorHex: selectedColor,
                                  ));
                                  Navigator.of(context).pop();
                                  _loadProductosWithLoading();
                                }
                              },
                              confirmText: 'Agregar',
                              cancelText: 'Cancelar',
                            );
                          },
                        );
                      },
                    );
                  } else if (value == '2') {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setStateDialog) {
                            return AppTheme.minimalAlertDialog(
                              title: 'Categorías',
                              content: Container(
                                width: double.maxFinite,
                                constraints: const BoxConstraints(
                                  maxHeight: 240,
                                ),
                                child: categorias.isEmpty
                                    ? const Text('No hay categorías.')
                                    : Scrollbar(
                                        thumbVisibility: true,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: categorias.length,
                                          itemExtent:
                                              56, // Altura fija para cada ListTile (aprox. 5 en 300px)
                                          itemBuilder: (context, index) {
                                            final categoria = categorias[index];
                                            return ListTile(
                                              leading: Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: _parseColor(
                                                      categoria.colorHex),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              title: Text(categoria.nombre),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit,
                                                        color: Colors.blue),
                                                    onPressed: () {
                                                      String editedName =
                                                          categoria.nombre;
                                                      String editedColor =
                                                          categoria.colorHex;
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return StatefulBuilder(
                                                            builder: (context,
                                                                setStateDialog) {
                                                              return AppTheme
                                                                  .minimalAlertDialog(
                                                                title:
                                                                    'Editar categoría',
                                                                content: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    TextField(
                                                                      autofocus:
                                                                          true,
                                                                      controller:
                                                                          TextEditingController(
                                                                              text: categoria.nombre),
                                                                      decoration:
                                                                          const InputDecoration(
                                                                        labelText:
                                                                            'Nombre de la categoría',
                                                                        border:
                                                                            OutlineInputBorder(),
                                                                      ),
                                                                      onChanged:
                                                                          (value) {
                                                                        editedName =
                                                                            value;
                                                                      },
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            16),
                                                                    ColorPicker(
                                                                      selectedColor:
                                                                          editedColor,
                                                                      onColorSelected:
                                                                          (color) {
                                                                        setStateDialog(
                                                                            () {
                                                                          editedColor =
                                                                              color;
                                                                        });
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(context)
                                                                            .pop(),
                                                                    child: const Text(
                                                                        'Cancelar'),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed:
                                                                        () async {
                                                                      if (editedName
                                                                          .trim()
                                                                          .isNotEmpty) {
                                                                        await CategoriasProvider()
                                                                            .editarCategoria(
                                                                          categoria
                                                                              .id!,
                                                                          editedName,
                                                                          editedColor,
                                                                        );
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                        _loadProductosWithLoading();
                                                                      }
                                                                    },
                                                                    child: const Text(
                                                                        'Guardar'),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                   IconButton(
                                                     icon: const Icon(
                                                         Icons.delete,
                                                         color: Colors.red),
                                                     onPressed: () {
                                                       // Verificar si la categoría tiene productos asociados
                                                       final productosAsociados = productos.where(
                                                         (producto) => producto.categoriaNombre == categoria.nombre
                                                       ).toList();
                                                       
                                                       if (productosAsociados.isNotEmpty) {
                                                         // Mostrar mensaje de error si hay productos asociados
                                                         showDialog(
                                                           context: context,
                                                           builder: (context) => AlertDialog(
                                                             shape: RoundedRectangleBorder(
                                                               borderRadius: BorderRadius.circular(16),
                                                             ),
                                                             title: Row(
                                                               children: [
                                                                 Icon(
                                                                   Icons.warning_amber_rounded,
                                                                   color: Colors.orange,
                                                                   size: 28,
                                                                 ),
                                                                 const SizedBox(width: 12),
                                                                 const Expanded(
                                                                   child: Text(
                                                                     'No se puede eliminar',
                                                                     style: TextStyle(
                                                                       fontSize: 18,
                                                                       fontWeight: FontWeight.bold,
                                                                     ),
                                                                   ),
                                                                 ),
                                                               ],
                                                             ),
                                                             content: Column(
                                                               mainAxisSize: MainAxisSize.min,
                                                               crossAxisAlignment: CrossAxisAlignment.start,
                                                               children: [
                                                                 Text(
                                                                   'La categoría "${categoria.nombre}" no se puede eliminar porque tiene ${productosAsociados.length} producto${productosAsociados.length == 1 ? '' : 's'} asociado${productosAsociados.length == 1 ? '' : 's'}.',
                                                                   style: const TextStyle(fontSize: 16),
                                                                 ),
                                                                 const SizedBox(height: 16),
                                                                 const Text(
                                                                   'Para eliminar esta categoría:',
                                                                   style: TextStyle(
                                                                     fontWeight: FontWeight.w600,
                                                                     fontSize: 14,
                                                                   ),
                                                                 ),
                                                                 const SizedBox(height: 8),
                                                                 Row(
                                                                   children: [
                                                                     Icon(
                                                                       Icons.check_circle_outline,
                                                                       color: Colors.green,
                                                                       size: 16,
                                                                     ),
                                                                     const SizedBox(width: 8),
                                                                     const Expanded(
                                                                       child: Text(
                                                                         'Elimina o mueve todos los productos de esta categoría',
                                                                         style: TextStyle(fontSize: 14),
                                                                       ),
                                                                     ),
                                                                   ],
                                                                 ),
                                                                 const SizedBox(height: 4),
                                                                 Row(
                                                                   children: [
                                                                     Icon(
                                                                       Icons.check_circle_outline,
                                                                       color: Colors.green,
                                                                       size: 16,
                                                                     ),
                                                                     const SizedBox(width: 8),
                                                                     const Expanded(
                                                                       child: Text(
                                                                         'Luego intenta eliminar la categoría nuevamente',
                                                                         style: TextStyle(fontSize: 14),
                                                                       ),
                                                                     ),
                                                                   ],
                                                                 ),
                                                               ],
                                                             ),
                                                             actions: [
                                                               ElevatedButton(
                                                                 onPressed: () => Navigator.of(context).pop(),
                                                                 style: ElevatedButton.styleFrom(
                                                                   backgroundColor: AppTheme.primaryColor,
                                                                   foregroundColor: Colors.white,
                                                                   shape: RoundedRectangleBorder(
                                                                     borderRadius: BorderRadius.circular(8),
                                                                   ),
                                                                 ),
                                                                 child: const Text('Entendido'),
                                                               ),
                                                             ],
                                                           ),
                                                         );
                                                       } else {
                                                         // Si no hay productos asociados, proceder con la eliminación
                                                         showDialog(
                                                           context: context,
                                                           builder: (context) =>
                                                               AppTheme
                                                                   .alertDialogStyle(
                                                             title:
                                                                 'Eliminar categoría',
                                                             content:
                                                                 '¿Estás seguro de que deseas eliminar la categoría "${categoria.nombre}"?',
                                                             onConfirm: () async {
                                                               try {
                                                                 await CategoriasProvider()
                                                                     .eliminarCategoria(
                                                                         categoria
                                                                             .id!);
                                                                 Navigator.of(
                                                                         context)
                                                                     .pop();
                                                                 Navigator.of(
                                                                         context)
                                                                     .pop();
                                                                 _loadProductosWithLoading();
                                                                 
                                                                 // Mostrar mensaje de éxito
                                                                 if (mounted) {
                                                                   AppTheme.showSnackBar(
                                                                     context,
                                                                     AppTheme.successSnackBar('Categoría "${categoria.nombre}" eliminada exitosamente'),
                                                                   );
                                                                 }
                                                               } catch (e) {
                                                                 // Mostrar mensaje de error si falla la eliminación
                                                                 if (mounted) {
                                                                   AppTheme.showSnackBar(
                                                                     context,
                                                                     AppTheme.errorSnackBar('Error al eliminar la categoría: $e'),
                                                                   );
                                                                 }
                                                                 Navigator.of(context).pop();
                                                               }
                                                             },
                                                             onCancel: () {
                                                               Navigator.of(
                                                                       context)
                                                                   .pop();
                                                             },
                                                           ),
                                                         );
                                                       }
                                                     },
                                                   ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                              ),
                              actions: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cerrar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
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
                                Icons.inventory_2,
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
                                    'Gestión de Productos',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  Text(
                                    '${productos.length} productos • ${categorias.length} categorías',
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
                                _loadProductosWithLoading();
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Barra de búsqueda mejorada
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      cursorColor: AppTheme.primaryColor,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Buscar productos...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  setState(() {
                                    searchQuery = '';
                                  });
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Filtros de categoría (solo mostrar cuando NO hay búsqueda activa)
                  if (categorias.isNotEmpty && searchQuery.isEmpty) ...[
                    const Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
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
                              backgroundColor: Colors.white,
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
                          const Text(
                            'Productos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
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
                                  _loadProductosWithLoading();
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
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.inventory_2_outlined,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Cantidad: ${producto.cantidad}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
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
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Precio: \$${producto.precio.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
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
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                producto.categoriaNombre ??
                                                    'Sin categoría',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
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
                                                _loadProductosWithLoading();
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
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  title: const Text(
                                                      'Eliminar Producto'),
                                                  content: Text(
                                                    '¿Estás seguro de que deseas eliminar "${producto.nombre}"?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                      child: const Text(
                                                          'Cancelar'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        final productoProvider =
                                                            Provider.of<
                                                                    ProductoProvider>(
                                                                context,
                                                                listen: false);
                                                        
                                                        if (producto.id != null) {
                                                          try {
                                                            // Intentar eliminación física primero
                                                            await productoProvider.eliminarProducto(producto.id!);
                                                            
                                                            // Si llegamos aquí, la eliminación fue exitosa (sin ventas vinculadas)
                                                            AppTheme.showSnackBar(
                                                              context,
                                                              AppTheme.successSnackBar('Producto eliminado con éxito'),
                                                            );
                                                            _loadProductosWithLoading();
                                                            Navigator.of(context).pop();
                                                            
                                                          } catch (e) {
                                                            // Si es un error 409 (Conflict) - producto con ventas vinculadas
                                                            if (e.toString().contains('ventas vinculadas') || 
                                                                e.toString().contains('Conflict')) {
                                                              Navigator.of(context).pop(); // Cerrar el diálogo de confirmación
                                                              _showDeactivateDialog(context, producto);
                                                            } else {
                                                              // Otros errores
                                                              AppTheme.showSnackBar(
                                                                context,
                                                                AppTheme.errorSnackBar(e.toString().replaceFirst('Exception: ', '')),
                                                              );
                                                              Navigator.of(context).pop();
                                                            }
                                                          }
                                                        } else {
                                                          AppTheme.showSnackBar(
                                                            context,
                                                            AppTheme.errorSnackBar('Error: ID del producto no válido'),
                                                          );
                                                          Navigator.of(context).pop();
                                                        }
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                      child: const Text(
                                                          'Eliminar'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
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

  void _showDeactivateDialog(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No se puede eliminar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El producto "${producto.nombre}" no se puede eliminar porque tiene ventas vinculadas.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Desea desactivarlo en su lugar?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'El producto se ocultará de los catálogos pero se mantendrá en las ventas existentes',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deactivateProduct(context, producto);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Desactivar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deactivateProduct(BuildContext context, Producto producto) async {
    if (producto.id != null) {
      final productoProvider = Provider.of<ProductoProvider>(context, listen: false);
      final errorMessage = await productoProvider
          .desactivarProductoConMensaje(producto.id!);
      
      if (errorMessage == null) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Producto desactivado exitosamente. Ya no aparecerá en los catálogos.'),
        );
        _loadProductosWithLoading();
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
}
