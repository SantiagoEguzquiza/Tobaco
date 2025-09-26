import 'package:flutter/material.dart';
import '../../Models/Categoria.dart';
import '../../Models/Producto.dart';
import '../../Models/ProductoSeleccionado.dart';
import '../../Models/Cliente.dart';
import '../../Services/Categoria_Service/categoria_provider.dart';
import '../../Services/Productos_Service/productos_provider.dart';
import '../../Services/PrecioEspecialService.dart';
import '../../Theme/app_theme.dart';

class SeleccionarProductosConPreciosEspecialesScreen extends StatefulWidget {
  final List<ProductoSeleccionado> productosYaSeleccionados;
  final Cliente? cliente;

  const SeleccionarProductosConPreciosEspecialesScreen({
    super.key,
    required this.productosYaSeleccionados,
    this.cliente,
  });

  @override
  State<SeleccionarProductosConPreciosEspecialesScreen> createState() =>
      _SeleccionarProductosConPreciosEspecialesScreenState();
}

class _SeleccionarProductosConPreciosEspecialesScreenState
    extends State<SeleccionarProductosConPreciosEspecialesScreen> {
  List<Producto> productos = [];
  final Map<int, double> cantidades = {};
  final Map<int, TextEditingController> cantidadControllers = {};
  final Map<int, double> preciosEspeciales = {}; // Cache de precios especiales
  List<Categoria> categorias = [];
  String? selectedCategory;
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  final ProductoProvider productoProvider = ProductoProvider();
  final CategoriasProvider categoriasProvider = CategoriasProvider();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in cantidadControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final List<Producto> fetchedProductos =
          await productoProvider.obtenerProductos();
      final List<Categoria> fetchedCategorias =
          await categoriasProvider.obtenerCategorias();

      // Cargar precios especiales si hay un cliente seleccionado
      if (widget.cliente != null) {
        await _loadPreciosEspeciales();
      }

      setState(() {
        productos = fetchedProductos;
        categorias = fetchedCategorias;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar los datos: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadPreciosEspeciales() async {
    if (widget.cliente == null) return;

    try {
      final precios = await PrecioEspecialService.getPreciosEspecialesByCliente(widget.cliente!.id!);
      setState(() {
        preciosEspeciales.clear();
        for (var precio in precios) {
          preciosEspeciales[precio.productoId] = precio.precio;
        }
      });
    } catch (e) {
      // Si hay error cargando precios especiales, continuar sin ellos
      print('Error cargando precios especiales: $e');
    }
  }

  double _getPrecioFinal(Producto producto) {
    if (widget.cliente != null && preciosEspeciales.containsKey(producto.id)) {
      return preciosEspeciales[producto.id]!;
    }
    return producto.precio;
  }

  bool _tienePrecioEspecial(Producto producto) {
    return widget.cliente != null && preciosEspeciales.containsKey(producto.id);
  }

  List<Producto> get filteredProductos {
    var filtered = productos.where((producto) {
      final matchesSearch = searchQuery.isEmpty ||
          producto.nombre.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == null ||
          producto.categoriaNombre == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Ordenar por nombre
    filtered.sort((a, b) => a.nombre.compareTo(b.nombre));
    return filtered;
  }

  void _addProducto(Producto producto, double cantidad) {
    if (cantidad > 0) {
      final precioFinal = _getPrecioFinal(producto);
      final productoSeleccionado = ProductoSeleccionado(
        id: producto.id!,
        nombre: producto.nombre,
        precio: precioFinal,
        cantidad: cantidad,
        categoria: producto.categoriaNombre ?? '',
        categoriaId: producto.categoriaId,
      );

      final existingIndex = widget.productosYaSeleccionados
          .indexWhere((p) => p.id == producto.id);

      if (existingIndex >= 0) {
        widget.productosYaSeleccionados[existingIndex] = productoSeleccionado;
      } else {
        widget.productosYaSeleccionados.add(productoSeleccionado);
      }

      // Mostrar mensaje de éxito
      AppTheme.showSnackBar(
        context,
        AppTheme.successSnackBar(
          '${producto.nombre} agregado a la venta${_tienePrecioEspecial(producto) ? ' (precio especial aplicado)' : ''}',
        ),
      );

      setState(() {
        cantidades[producto.id!] = 0;
        cantidadControllers[producto.id!]?.text = '0';
      });
    }
  }

  List<ProductoSeleccionado> _getProductosSeleccionados() {
    return widget.productosYaSeleccionados;
  }

  Widget _formatearPrecioConDecimales(double precio) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
        children: [
          TextSpan(text: '\$${precio.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildPrecioInfo(Producto producto) {
    final tieneEspecial = _tienePrecioEspecial(producto);
    final precioFinal = _getPrecioFinal(producto);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _formatearPrecioConDecimales(precioFinal),
            const SizedBox(width: 4),
            Text(
              'c/u',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (tieneEspecial) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ESPECIAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (tieneEspecial) ...[
          const SizedBox(height: 2),
          Text(
            'Estándar: \$${producto.precio.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, widget.productosYaSeleccionados),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header mejorado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                            if (widget.cliente != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person, size: 12, color: Colors.blue.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Cliente: ${widget.cliente!.nombre}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Barra de búsqueda
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
                        });
                      },
                    ),
                  ),

                  // Filtro de categorías
                  if (categorias.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('Todas', null),
                          const SizedBox(width: 8),
                          ...categorias.map((categoria) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildCategoryChip(categoria.nombre, categoria.nombre),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Lista de productos
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : filteredProductos.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 60,
                                        color: AppTheme.primaryColor,
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
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredProductos.length,
                              itemBuilder: (context, index) {
                                final producto = filteredProductos[index];
                                final cantidad = cantidades[producto.id] ?? 0;

                                if (!cantidadControllers.containsKey(producto.id)) {
                                  cantidadControllers[producto.id!] = TextEditingController(
                                    text: cantidad % 1 == 0
                                        ? cantidad.toInt().toString()
                                        : cantidad.toStringAsFixed(1),
                                  );
                                } else {
                                  cantidadControllers[producto.id!]!.text = cantidad % 1 == 0
                                      ? cantidad.toInt().toString()
                                      : cantidad.toStringAsFixed(1);
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _tienePrecioEspecial(producto)
                                          ? Colors.green.shade200
                                          : AppTheme.primaryColor.withOpacity(0.2),
                                      width: _tienePrecioEspecial(producto) ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            // Información del producto
                                            Expanded(
                                              flex: 4,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          producto.nombre,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppTheme.primaryColor,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (_tienePrecioEspecial(producto))
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Text(
                                                            'ESPECIAL',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  _buildPrecioInfo(producto),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Categoría: ${producto.categoriaNombre ?? 'Sin categoría'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Controles de cantidad
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Botón -
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.remove,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      double current = cantidades[producto.id!] ?? 0;
                                                      if (current > 0) {
                                                        current -= 1;
                                                        cantidades[producto.id!] = current;
                                                        cantidadControllers[producto.id!]!.text =
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
                                                    border: Border.all(color: Colors.grey.shade300),
                                                    borderRadius: BorderRadius.circular(6),
                                                    color: Colors.white,
                                                  ),
                                                  child: TextField(
                                                    controller: cantidadControllers[producto.id!],
                                                    keyboardType: TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    decoration: InputDecoration(
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(6),
                                                        borderSide: BorderSide.none,
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      final cantidad = double.tryParse(value) ?? 0;
                                                      setState(() {
                                                        cantidades[producto.id!] = cantidad;
                                                      });
                                                    },
                                                  ),
                                                ),

                                                // Botón +
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.add,
                                                    color: Colors.green,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      double current = cantidades[producto.id!] ?? 0;
                                                      current += 1;
                                                      if (current > 999) current = 999;
                                                      cantidades[producto.id!] = current;
                                                      cantidadControllers[producto.id!]!.text =
                                                          current % 1 == 0
                                                              ? current.toInt().toString()
                                                              : current.toStringAsFixed(1);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        // Botón agregar
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: cantidad > 0
                                                ? () => _addProducto(producto, cantidad)
                                                : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryColor,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              cantidad > 0
                                                  ? 'Agregar ${cantidad.toStringAsFixed(cantidad % 1 == 0 ? 0 : 1)} unidad${cantidad == 1 ? '' : 'es'}'
                                                  : 'Seleccionar cantidad',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final productosSeleccionados = _getProductosSeleccionados();
          Navigator.pop(context, productosSeleccionados);
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.check, color: Colors.white),
        label: Text(
          'Continuar (${_getProductosSeleccionados().length})',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = selectedCategory == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
