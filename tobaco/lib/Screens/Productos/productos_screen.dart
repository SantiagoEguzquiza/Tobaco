// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Screens/Productos/nuevoProducto_screen.dart';
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
  String? selectedCategory;
  String? errorMessage;
  List<Producto> productos = [];
  List<String> categorias = Categoria.values.map((e) => e.name).toList();

  @override
void initState() {
  super.initState();
  selectedCategory = categorias.isNotEmpty ? categorias[0] : null;
  _loadProductos();
}


  Future<void> _loadProductos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final productoProvider = ProductoProvider();
      final List<Producto> fetchedProductos =
          await productoProvider.obtenerProductos();

      setState(() {
        productos = fetchedProductos;
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
    final filteredProductos = productos.where((producto) {
      final matchesSearchQuery =
          producto.nombre.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == null ||
          producto.categoria.name == selectedCategory;

      return matchesSearchQuery && matchesCategory;
    }).toList()
      ..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Productos',
          style: AppTheme.appBarTitleStyle, // Usa el estilo del tema
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
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
                itemCount: categorias.length, // Lista de categorías
                itemBuilder: (context, index) {
                  final categoria = categorias[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedCategory == categoria
                            ? AppTheme.primaryColor
                            : AppTheme.greyColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedCategory =
                              selectedCategory == categoria ? null : categoria;
                        });
                      },
                      child: Text(
                        categoria[0].toUpperCase() + categoria.substring(1),
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
                          // Navegación a detalles del producto
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
                                      Navigator.of(context).pop();
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
                                // Navegación a editar producto
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
