import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';

class SeleccionarProductosScreen extends StatefulWidget {
  final List<ProductoSeleccionado> productosYaSeleccionados;

  const SeleccionarProductosScreen({
    super.key,
    required this.productosYaSeleccionados,
  });

  @override
  State<SeleccionarProductosScreen> createState() =>
      _SeleccionarProductosScreenState();
}

class _SeleccionarProductosScreenState
    extends State<SeleccionarProductosScreen> {
  List<Producto> productos = [];
  final Map<int, int> cantidades = {};
  List<String> categorias = Categoria.values.map((e) => e.name).toList();
  String? selectedCategory;
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    selectedCategory = categorias.isNotEmpty ? categorias[0] : null;
    loadProductos();
  }

  Future<void> loadProductos() async {
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
        for (var ps in widget.productosYaSeleccionados) {
          cantidades[ps.producto.id!] = ps.cantidad;
        }
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
        title: const Text('Seleccionar', style: AppTheme.appBarTitleStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de búsqueda
            TextField(
              decoration: AppTheme.searchInputDecoration,
              cursorColor: Colors.grey,
              onChanged: (query) {
                setState(() {
                  if (query.isEmpty) {
                    loadProductos(); // Recargar todos los productos
                  } else {
                    searchQuery = query;
                    productos = productos
                        .where((producto) => producto.nombre
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                        .toList();
                  }
                });
              },
            ),
            const SizedBox(height: 15),
            // Filtro de categorías
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categorias.length, // Lista de categorías
                itemBuilder: (context, index) {
                  final categoria = categorias[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
            const SizedBox(height: 10),

            // Lista de productos
            Expanded(
              child: filteredProductos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredProductos.length,
                      itemBuilder: (context, index) {
                        final producto = filteredProductos[index];
                        final cantidad = cantidades[producto.id] ?? 0;

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      producto.nombre,
                                      style: AppTheme.itemListaNegrita,
                                    ),
                                  ),
                                  Text(
                                    '\$ ${producto.precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}',
                                    style: AppTheme.itemListaNegrita,
                                  ),
                                  IconButton(
                                   icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                    onPressed: () {
                                      if (cantidad > 0) {
                                        setState(() {
                                          cantidades[producto.id!] =
                                              cantidad - 1;
                                        });
                                      }
                                    },
                                  ),
                                  Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    alignment: Alignment.center,
                                    child: EditableText(
                                      controller: TextEditingController(
                                          text: cantidad.toString()),
                                      focusNode: FocusNode(),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                      cursorColor: Colors.grey,
                                      backgroundCursorColor: Colors.transparent,
                                      inputFormatters: [], // Si querés, agregás restricciones acá
                                      onChanged: (value) {
                                        final newCantidad =
                                            int.tryParse(value) ?? cantidad;
                                        setState(() {
                                          cantidades[producto.id!] =
                                              newCantidad < 0 ? 0 : newCantidad;
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle,
                                      color: Colors.green),
                                    onPressed: () {
                                      setState(() {
                                        cantidades[producto.id!] = cantidad + 1;
                                      });
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: AppTheme.elevatedButtonStyle(Colors.green),
          onPressed: () {
            final seleccionados =
                cantidades.entries.where((e) => e.value > 0).map((e) {
              final producto = filteredProductos.firstWhere(
                (p) => p.id == e.key,
                orElse: () => productos.firstWhere((p) => p.id == e.key),
              );
              return ProductoSeleccionado(
                  producto: producto, cantidad: e.value);
            }).toList();

            Navigator.pop(context, seleccionados);
          },
          child: const Text("Confirmar selección"),
        ),
      ),
    );
  }
}
