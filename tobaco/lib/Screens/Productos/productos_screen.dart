// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Screens/Productos/detalleProducto_screen.dart';
import 'package:tobaco/Screens/Productos/editarProducto_screen.dart';
import 'package:tobaco/Screens/Productos/nuevoProducto_screen.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema
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

  @override
  void initState() {
    super.initState();
    selectedCategory = null;
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final productoProvider = ProductoProvider();
      final categoriasProvider = CategoriasProvider();

      final List<Producto> fetchedProductos =
          await productoProvider.obtenerProductos();
      final List<Categoria> fetchedCategorias =
          await categoriasProvider.obtenerCategorias();

      setState(() {
        productos = fetchedProductos;
        categorias = fetchedCategorias;
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

  @override
  Widget build(BuildContext context) {
    // Selecciona la primera categoría por defecto si no hay ninguna seleccionada y hay categorías cargadas
    if (selectedCategory == null && categorias.isNotEmpty) {
      selectedCategory = categorias.first.nombre;
    }

    final filteredProductos = productos.where((producto) {
      final matchesSearchQuery =
          producto.nombre.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == null ||
          producto.categoriaNombre == selectedCategory;

      return matchesSearchQuery && matchesCategory;
    }).toList()
      ..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Productos',
          style: AppTheme.appBarTitleStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
                color: Colors.white,
                shape: AppTheme.showMenuShape,
                items: [
                  PopupMenuItem(
                    value: '1',
                    child: Text(
                      'Agregar categoria',
                      style: AppTheme.showMenuItemTextStyle,
                    ),
                  ),
                  PopupMenuItem(
                    value: '2',
                    child: Text(
                      'Ver categorias',
                      style: AppTheme.showMenuItemTextStyle,
                    ),
                  ),
                ],
              ).then((value) {
                if (value == '1') {
                  showDialog(
                    context: context,
                    builder: (context) {
                      String newCategoryName = '';
                      return AppTheme.customAlertDialog(
                        title: 'Agregar nueva categoría',
                        content: TextField(
                          cursorColor: Colors.black,
                          autofocus: true,
                          onChanged: (value) {
                            newCategoryName = value;
                          },
                        ),
                        onCancel: () => Navigator.of(context).pop(),
                        onConfirm: () async {
                          if (newCategoryName.trim().isNotEmpty) {
                            await CategoriasProvider().agregarCategoria(
                                Categoria(id: null, nombre: newCategoryName));
                            Navigator.of(context).pop();
                            _loadProductos();
                          }
                        },
                        confirmText: 'Agregar',
                        cancelText: 'Cancelar',
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
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return AppTheme
                                                            .minimalAlertDialog(
                                                          title:
                                                              'Editar categoría',
                                                          content: TextField(
                                                            autofocus: true,
                                                            controller:
                                                                TextEditingController(
                                                                    text: categoria
                                                                        .nombre),
                                                            onChanged: (value) {
                                                              editedName =
                                                                  value;
                                                            },
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(),
                                                              child: const Text(
                                                                  'Cancelar'),
                                                            ),
                                                            TextButton(
                                                              onPressed:
                                                                  () async {
                                                                if (editedName
                                                                        .trim()
                                                                        .isNotEmpty &&
                                                                    editedName !=
                                                                        categoria
                                                                            .nombre) {
                                                                  await CategoriasProvider()
                                                                      .editarCategoria(
                                                                    categoria
                                                                        .id!,
                                                                    editedName,
                                                                  );
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                  _loadProductos();
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
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AppTheme
                                                              .alertDialogStyle(
                                                        title:
                                                            'Eliminar categoría',
                                                        content:
                                                            '¿Estás seguro de que deseas eliminar esta categoría?',
                                                        onConfirm: () async {
                                                          await CategoriasProvider()
                                                              .eliminarCategoria(
                                                                  categoria
                                                                      .id!);
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          _loadProductos();
                                                        },
                                                        onCancel: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                      ),
                                                    );
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
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (categorias.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Primero debes crear una categoría'),
                              duration: const Duration(seconds: 3),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NuevoProductoScreen(),
                          ),
                        );
                        _loadProductos();
                      },
                      style: AppTheme.elevatedButtonStyle(
                          AppTheme.addGreenColor), // Usa el estilo del tema
                      child: const Text(
                        'Crear nuevo producto',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    cursorColor: Colors.black,
                    style: const TextStyle(fontSize: 15),
                    decoration: AppTheme.searchInputDecoration, // Usa el tema
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categorias.length,
                      itemBuilder: (context, index) {
                        final categoria = categorias[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedCategory == categoria.nombre
                                  ? AppTheme.primaryColor
                                  : AppTheme.greyColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedCategory = categoria.nombre;
                              });
                            },
                            child: Text(
                              categoria.nombre[0].toUpperCase() +
                                  categoria.nombre.substring(1),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredProductos.length,
                      itemBuilder: (context, index) {
                        final producto = filteredProductos[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          color: index % 2 == 0
                              ? AppTheme.secondaryColor // Verde para impares
                              : AppTheme.greyColor, // Gris claro para pares
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetalleProductoScreen(producto: producto),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Image.asset(
                                    'Assets/images/cigarettes.png',
                                    height: 30,
                                  ),
                                  const SizedBox(width: 25),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          producto.nombre,
                                          style:
                                              AppTheme.cardTitleStyle, // Usa el tema
                                        ),
                                        Text(
                                          'Precio: \$${producto.precio}',
                                          style: AppTheme
                                              .cardSubtitleStyle, // Usa el tema
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Image.asset(
                                      'Assets/images/borrar.png',
                                      height: 24,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            AppTheme.alertDialogStyle(
                                          title: 'Eliminar producto',
                                          content:
                                              '¿Estás seguro de que deseas eliminar este producto?',
                                          onConfirm: () async {
                                            await ProductoProvider()
                                                .eliminarProducto(producto.id!);
                                            _loadProductos();
                                            if (mounted) {
                                              Navigator.of(context).pop();
                                            }
                                          },
                                          onCancel: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Image.asset(
                                      'Assets/images/editar.png',
                                      height: 24,
                                    ),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditarProductoScreen(
                                              producto: producto),
                                        ),
                                      );
                                      _loadProductos();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
