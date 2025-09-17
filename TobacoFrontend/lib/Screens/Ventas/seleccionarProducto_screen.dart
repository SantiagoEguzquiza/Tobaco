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
        title: const Text('Nueva venta', style: AppTheme.appBarTitleStyle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header con información
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
                              Icons.shopping_cart,
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
                                  'Seleccionar Productos',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  'Busca y selecciona los productos para la venta',
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
                          decoration: InputDecoration(
                            hintText: 'Buscar productos por nombre...',
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
                                        selectedCategory = null;
                                      });
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
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            focusedErrorBorder: OutlineInputBorder(
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
                          cursorColor: AppTheme.primaryColor,
                          style: const TextStyle(fontSize: 16),
                          onChanged: (query) {
                            setState(() {
                              searchQuery = query;
                              selectedCategory =
                                  null; // Deseleccionar la categoría
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Filtros de categorías simples
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = categorias[index];
                      final isSelected = selectedCategory == categoria.nombre;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCategory = categoria.nombre;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.greyColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            categoria.nombre[0].toUpperCase() +
                                categoria.nombre.substring(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Lista de productos mejorada
                if (filteredProductos.isEmpty)
                  Container(
                    height: 300,
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
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedCategory != null
                                ? 'No hay productos en esta categoría'
                                : 'No hay productos disponibles',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otra categoría o término de búsqueda',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: index % 2 == 0
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // Información del producto
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      producto.nombre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${producto.precio.toStringAsFixed(0).replaceAllMapped(
                                            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                            (match) => '${match[1]}.',
                                          )} c/u',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Controles de cantidad compactos
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Botón 0.5
                                  IconButton(
                                    icon: const Icon(
                                      Icons.exposure,
                                      color: Colors.blueGrey,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        double current =
                                            cantidades[producto.id!] ?? 0;
                                        if (current % 1 == 0.5) {
                                          current -= 0.5;
                                        } else {
                                          current += 0.5;
                                        }
                                        if (current < 0) current = 0;
                                        if (current > 999) current = 999;
                                        cantidades[producto.id!] = current;
                                        cantidadControllers[producto.id!]!
                                                .text =
                                            current % 1 == 0
                                                ? current.toInt().toString()
                                                : current.toStringAsFixed(1);
                                      });
                                    },
                                  ),

                                  // Botón -
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove,
                                      color: Colors.red,
                                      size: 18,
                                    ),
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
                                        }
                                      });
                                    },
                                  ),

                                  // Campo cantidad
                                  Container(
                                    width: 60,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(6),
                                      color: Colors.white,
                                    ),
                                    child: TextField(
                                      controller:
                                          cantidadControllers[producto.id!],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide.none,
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 4),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d{0,3}(\.\d{0,1})?$')),
                                      ],
                                      onChanged: (value) {
                                        double newCantidad =
                                            double.tryParse(value) ?? 0;
                                        if (newCantidad > 999)
                                          newCantidad = 999;
                                        setState(() {
                                          cantidades[producto.id!] =
                                              newCantidad < 0
                                                  ? 0.0
                                                  : newCantidad;
                                        });
                                      },
                                    ),
                                  ),

                                  // Botón +
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.green,
                                      size: 18,
                                    ),
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
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Información de productos seleccionados
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total del pedido',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${cantidades.entries.where((e) => e.value > 0).map((e) {
                            final producto = productos.firstWhere(
                              (p) => p.id == e.key,
                              orElse: () =>
                                  throw Exception('Producto no encontrado'),
                            );
                            return producto.precio * e.value;
                          }).fold<double>(0.0, (a, b) => a + b).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Botón confirmar
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final seleccionados =
                        cantidades.entries.where((e) => e.value > 0).map((e) {
                      final producto = filteredProductos.firstWhere(
                        (p) => p.id == e.key,
                        orElse: () =>
                            productos.firstWhere((p) => p.id == e.key),
                      );
                      return ProductoSeleccionado(
                          producto: producto, cantidad: e.value);
                    }).toList();

                    Navigator.pop(context, seleccionados);
                  },
                  style: AppTheme.elevatedButtonStyle(Colors.green),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Confirmar Selección',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
