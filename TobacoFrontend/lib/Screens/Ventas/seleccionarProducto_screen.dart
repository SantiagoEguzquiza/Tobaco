import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Map<int, TextEditingController> cantidadControllers = {};
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

                        if (!cantidadControllers.containsKey(producto.id)) {
                          cantidadControllers[producto.id!] =
                              TextEditingController(
                            text: cantidad % 1 == 0
                                ? cantidad.toInt().toString()
                                : cantidad.toStringAsFixed(1),
                          );
                        } else {
                          cantidadControllers[producto.id!]!.text =
                              cantidad % 1 == 0
                                  ? cantidad.toInt().toString()
                                  : cantidad.toStringAsFixed(1);
                        }

                        return Container(
                          color: index % 2 == 0
                              ? AppTheme.secondaryColor
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          child: Row(
                            children: [
                              // Nombre del producto
                              Expanded(
                                flex: 6,
                                child: Text(
                                  producto.nombre,
                                  style: AppTheme.itemListaNegrita,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Precio
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '\$ ${producto.precio.toStringAsFixed(0).replaceAllMapped(
                                        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                        (match) => '${match[1]}.',
                                      )}',
                                  style: AppTheme.itemListaPrecio,
                                  textAlign: TextAlign.right,
                                ),
                              ),

                              // Botón 0.5
                              Expanded(
                                flex: 1,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.exposure, // Icono acorde a medio (±0.5)
                                    color: Colors.blueGrey,
                                  ),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      double current =
                                          cantidades[producto.id!] ?? 0;
                                      // Si el decimal es .5, resta 0.5, si no, suma 0.5
                                      if (current % 1 == 0.5) {
                                        current -= 0.5;
                                      } else {
                                        current += 0.5;
                                      }
                                      // Limita el rango entre 0 y 999
                                      if (current < 0) current = 0;
                                      if (current > 999) current = 999;
                                      cantidades[producto.id!] = current;
                                      cantidadControllers[producto.id!]!.text =
                                          current % 1 == 0
                                              ? current.toInt().toString()
                                              : current.toStringAsFixed(1);
                                      cantidadControllers[producto.id!]!
                                          .selection = TextSelection.fromPosition(
                                        TextPosition(
                                            offset:
                                                cantidadControllers[producto.id!]!
                                                    .text
                                                    .length),
                                      );
                                    });
                                  },
                                ),
                              ),

                              // Botón -
                              Expanded(
                                flex: 1,
                                child: IconButton(
                                  icon: const Icon(Icons.remove,
                                      color: Colors.redAccent),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      double current =
                                          cantidades[producto.id!] ?? 0;
                                      if (current > 0) {
                                        current -= 1;
                                        cantidades[producto.id!] = current;
                                        cantidadControllers[producto.id!]!
                                                .text =
                                            current % 1 == 0
                                                ? current.toInt().toString()
                                                : current.toStringAsFixed(1);
                                        cantidadControllers[producto.id!]!
                                                .selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                              offset: cantidadControllers[
                                                      producto.id!]!
                                                  .text
                                                  .length),
                                        );
                                      }
                                    });
                                  },
                                ),
                              ),

                              // Campo cantidad
                              SizedBox(
                                width: 45,
                                height: 36,
                                child: TextField(
                                  controller: cantidadControllers[producto.id!],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d{0,3}(\.\d{0,1})?$')),
                                  ],
                                  onChanged: (value) {
                                    double newCantidad =
                                        double.tryParse(value) ?? 0;
                                    if (newCantidad > 999) newCantidad = 999;
                                    setState(() {
                                      cantidades[producto.id!] =
                                          newCantidad < 0 ? 0.0 : newCantidad;
                                    });
                                  },
                                ),
                              ),

                              // Botón +
                              Expanded(
                                flex: 1,
                                child: IconButton(
                                  icon: const Icon(Icons.add,
                                      color: Colors.green),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      double current =
                                          cantidades[producto.id!] ?? 0;
                                      if (current < 999) {
                                        current += 1;
                                        cantidades[producto.id!] = current;
                                        cantidadControllers[producto.id!]!
                                                .text =
                                            current % 1 == 0
                                                ? current.toInt().toString()
                                                : current.toStringAsFixed(1);
                                        cantidadControllers[producto.id!]!
                                                .selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                              offset: cantidadControllers[
                                                      producto.id!]!
                                                  .text
                                                  .length),
                                        );
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
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
