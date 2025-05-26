import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
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
  final Map<int, double> cantidades = {};
  List<Categoria> categorias = [];
  String? selectedCategory;
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadProductos();
  }

  Future<void> loadProductos() async {
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
        categorias = fetchedCategorias;
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
      debugPrint('Error al cargar los Productos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    
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
                  searchQuery = query;
                  selectedCategory = null; // Deseleccionar la categoría
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
            const SizedBox(height: 10),

            // Lista de productos
            Expanded(
              child: filteredProductos.isEmpty
                  ? Center(
                      child: Text(
                        selectedCategory != null
                            ? 'No hay productos en esta categoría'
                            : 'No hay productos disponibles',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
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
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 6.0,
                            ),
                            child: InkWell(
                              onTap: () {
                                // Navegación a detalles del producto
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      producto.nombre,
                                      style: AppTheme.itemListaNegrita,
                                    ),
                                  ),
                                  Text(
                                    '\$ ${producto.precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}',
                                    style: AppTheme.itemListaPrecio,
                                  ),
                                  if (producto.half)
                                    IconButton(
                                      icon: const Icon(Icons.contrast,
                                          color: Colors.blueGrey),
                                      onPressed: () {
                                        setState(() {
                                          final currentCantidad =
                                              cantidades[producto.id!] ?? 0;
                                          if (currentCantidad % 1 == 0) {
                                            cantidades[producto.id!] =
                                                currentCantidad + 0.5;
                                          } else {
                                            cantidades[producto.id!] =
                                                currentCantidad - 0.5;
                                          }
                                        });
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () {
                                      if (cantidad > 0 && cantidad != 0.5) {
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
                                          text: cantidad % 1 == 0
                                              ? cantidad.toInt().toString()
                                              : cantidad.toStringAsFixed(1)),
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
                                            double.tryParse(value) ?? cantidad;
                                        setState(() {
                                          cantidades[producto.id!] =
                                              newCantidad < 0
                                                  ? 0.0
                                                  : newCantidad;
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
        padding: const EdgeInsets.all(26.0),
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
