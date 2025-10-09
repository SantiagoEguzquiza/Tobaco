import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/PricingResult.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Services/PrecioEspecialService.dart';
import 'package:tobaco/Services/PricingService.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Helpers/api_handler.dart';

class SeleccionarProductosScreen extends StatefulWidget {
  final List<ProductoSeleccionado> productosYaSeleccionados;
  final Cliente? cliente;
  final int? scrollToProductId; // ID del producto al que hacer scroll

  const SeleccionarProductosScreen({
    super.key,
    required this.productosYaSeleccionados,
    this.cliente,
    this.scrollToProductId,
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
  final Map<int, double> preciosEspeciales = {}; // Cache de precios especiales
  final Map<String, PricingResult> pricingResults = {}; // Cache de resultados de pricing
  List<Categoria> categorias = [];
  String? selectedCategory;
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _productKeys = {}; // Keys para cada producto

  @override
  void initState() {
    super.initState();
    loadProductos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    // Dispose de los controllers de cantidad
    for (var controller in cantidadControllers.values) {
      controller.dispose();
    }
    super.dispose();
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

      // Cargar precios especiales si hay un cliente seleccionado
      if (widget.cliente != null) {
        await _loadPreciosEspeciales();
      }

      setState(() {
        categorias = fetchedCategorias;
        productos = fetchedProductos;
        for (var ps in widget.productosYaSeleccionados) {
          cantidades[ps.id] = ps.cantidad;
        }
        
        // Si hay un producto al que hacer scroll, seleccionar su categoría
        if (widget.scrollToProductId != null) {
          final producto = fetchedProductos.firstWhere(
            (p) => p.id == widget.scrollToProductId,
            orElse: () => fetchedProductos.first,
          );
          selectedCategory = producto.categoriaNombre;
        }
        
        isLoading = false;
      });

      // Si hay un producto al que hacer scroll, hacerlo después de que se construya la UI
      if (widget.scrollToProductId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToProduct(widget.scrollToProductId!);
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Error al cargar los Productos: $e');
      
      if (Apihandler.isConnectionError(e)) {
        setState(() {
          isLoading = false;
          // No establecer errorMessage para errores de conexión
        });
        await Apihandler.handleConnectionError(context, e);
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Error al cargar los Productos: ${e.toString().replaceFirst('Exception: ', '')}';
        });
      }
    }
  }

  void _scrollToProduct(int productId) {
    try {
      final productKey = _productKeys[productId];
      if (productKey != null && productKey.currentContext != null) {
        // Hacer scroll al producto con animación
        Scrollable.ensureVisible(
          productKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.2, // Posicionar el producto en la parte superior (20% desde arriba)
        );
        
        // Opcional: Resaltar el producto brevemente
        Future.delayed(const Duration(milliseconds: 600), () {
          // Aquí podrías agregar un efecto visual si quieres
        });
      }
    } catch (e) {
      debugPrint('Error al hacer scroll al producto: $e');
    }
  }

  Future<void> _loadPreciosEspeciales() async {
    if (widget.cliente == null) return;

    try {
      final precios = await PrecioEspecialService.getPreciosEspecialesByCliente(widget.cliente!.id!);
      if (!mounted) return;
      setState(() {
        preciosEspeciales.clear();
        for (var precio in precios) {
          preciosEspeciales[precio.productoId] = precio.precio;
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        // Si hay error cargando precios especiales, continuar sin ellos
        print('Error cargando precios especiales: $e');
      }
    }
  }

  double _getPrecioFinal(Producto producto) {
    final cantidad = cantidades[producto.id] ?? 0;
    if (cantidad <= 0) {
      // Cuando no hay cantidad, devolver precio base (sin descuento global - se aplica en backend)
      return producto.precio;
    }
    
    final cacheKey = '${producto.id}_${cantidad.toInt()}';
    
    // Check cache first
    if (pricingResults.containsKey(cacheKey)) {
      return pricingResults[cacheKey]!.finalPrice;
    }
    
    // Calculate pricing using the new service
    try {
      final specialPrice = widget.cliente != null && preciosEspeciales.containsKey(producto.id)
          ? preciosEspeciales[producto.id]
          : null;
      
      // No pasar globalDiscount al PricingService - se maneja en el backend
      final pricingResult = PricingService.calculateOptimalPricing(
        producto,
        cantidad.toInt(),
        specialPrice: specialPrice,
        globalDiscount: null, // El backend se encarga del descuento global
      );
      
      // Cache the result
      pricingResults[cacheKey] = pricingResult;
      
      return pricingResult.finalPrice;
    } catch (e) {
      // Fallback to old logic if there's an error
      if (widget.cliente != null && preciosEspeciales.containsKey(producto.id)) {
        return preciosEspeciales[producto.id]! * cantidad;
      }
      return producto.precio * cantidad;
    }
  }

  bool _tienePrecioEspecial(Producto producto) {
    return widget.cliente != null && preciosEspeciales.containsKey(producto.id);
  }

  void _clearPricingCache() {
    pricingResults.clear();
  }

  double _getPrecioUnitarioReal(Producto producto) {
    // Este método devuelve el precio unitario base, considerando solo precios especiales
    // El descuento global se aplica en el backend al confirmar la venta
    if (widget.cliente != null && preciosEspeciales.containsKey(producto.id)) {
      return preciosEspeciales[producto.id]!;
    }
    return producto.precio;
  }

  double _getPrecioUnitarioPromedio(Producto producto) {
    // Este método devuelve el precio promedio por unidad basado en el cálculo optimizado
    final cantidad = cantidades[producto.id] ?? 0;
    if (cantidad <= 0) {
      // Si no hay cantidad, mostrar el precio base (considerando precio especial)
      return _getPrecioUnitarioReal(producto);
    }
    
    final precioTotal = _getPrecioFinal(producto);
    // El precioTotal ya incluye todos los descuentos (cantidad, precio especial, global)
    return precioTotal / cantidad;
  }

  // Función para formatear precios con decimales más pequeños y grises
  Widget _formatearPrecioConDecimales(double precio, {Color? color}) {
    final precioStr = precio.toStringAsFixed(2);
    final partes = precioStr.split('.');
    final parteEntera = partes[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
    final parteDecimal = partes[1];
    
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '\$${parteEntera}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : (color ?? Colors.grey.shade600),
            ),
          ),
          TextSpan(
            text: ',${parteDecimal}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // Función especial para el total del pedido
  Widget _formatearTotalPedido() {
    final total = cantidades.entries.where((e) => e.value > 0).map((e) {
      final producto = productos.firstWhere(
        (p) => p.id == e.key,
        orElse: () => throw Exception('Producto no encontrado'),
      );
      // _getPrecioFinal ya devuelve el precio total para la cantidad, no multiplicar de nuevo
      return _getPrecioFinal(producto);
    }).fold<double>(0.0, (a, b) => a + b);

    final totalStr = total.toStringAsFixed(2);
    final partes = totalStr.split('.');
    final parteEntera = partes[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
    final parteDecimal = partes[1];
    
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '\$${parteEntera}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          TextSpan(
            text: ',${parteDecimal}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarPacksDisponibles(Producto producto) {
    final tienePacks = producto.quantityPrices.isNotEmpty;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: null, // Usar el tema
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tienePacks ? 'Packs Disponibles' : 'Información del Producto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          producto.nombre,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Price unitario
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_basket,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Precio Unitario',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Text(
                            '\$${_getPrecioUnitarioReal(producto).toStringAsFixed(2)} c/u',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          cantidades[producto.id!] = 1;
                          cantidadControllers[producto.id!]!.text = '1';
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('x1'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Mensaje cuando no hay packs
              if (!tienePacks)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade600
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Este producto no tiene packs configurados. Solo se vende por unidad.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Lista de packs
              ...producto.quantityPrices.map((quantityPrice) {
                final precioUnitario = quantityPrice.totalPrice / quantityPrice.quantity;
                final precioBase = _getPrecioUnitarioReal(producto);
                final ahorro = precioBase - precioUnitario;
                final porcentajeAhorro = (ahorro / precioBase) * 100;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          cantidades[producto.id!] = quantityPrice.quantity.toDouble();
                          cantidadControllers[producto.id!]!.text = quantityPrice.quantity.toString();
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'x${quantityPrice.quantity}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Pack x',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : AppTheme.textColor,
                                        ),
                                      ),
                                      Text(
                                        '${quantityPrice.quantity}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${quantityPrice.totalPrice.toStringAsFixed(2)} total',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '\$${precioUnitario.toStringAsFixed(2)} c/u',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (ahorro > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '-${porcentajeAhorro.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ahorrás \$${ahorro.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si el teclado está visible
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
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
        resizeToAvoidBottomInset: false,
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
              
                // Barra de búsqueda usando HeaderConBuscador
                HeaderConBuscador(
                  leadingIcon: Icons.inventory_2,
                  title: 'Buscar Productos',
                  subtitle: '${productos.length} productos disponibles',
                  controller: _searchController,
                  hintText: 'Buscar productos por nombre...',
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      // Cuando hay búsqueda, limpiar la categoría seleccionada
                      if (value.isNotEmpty) {
                        selectedCategory = null;
                      } else {
                        // Cuando se limpia la búsqueda, restaurar la primera categoría
                        if (categorias.isNotEmpty) {
                          selectedCategory = categorias.first.nombre;
                        }
                      }
                    });
                  },
                  onClear: () {
                    setState(() {
                      searchQuery = '';
                      // Restaurar la primera categoría cuando se limpia la búsqueda
                      if (categorias.isNotEmpty) {
                        selectedCategory = categorias.first.nombre;
                      }
                    });
                    _searchController.clear();
                  },
                ),
                const SizedBox(height: 20),

                // Filtros de categorías mejorados (solo mostrar cuando NO hay búsqueda activa)
                if (searchQuery.isEmpty)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = categorias[index];
                      final isSelected = selectedCategory == categoria.nombre;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedCategory = categoria.nombre;
                            });
                          },
                          borderRadius: BorderRadius.circular(25),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.primaryColor.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF404040)
                                  : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : (Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade300),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  categoria.nombre[0].toUpperCase() +
                                      categoria.nombre.substring(1),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  ),
                if (searchQuery.isEmpty) const SizedBox(height: 20),

                // Indicador de búsqueda global o título normal
                if (filteredProductos.isNotEmpty) ...[
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
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Lista de productos mejorada
                if (filteredProductos.isEmpty)
                  Container(
                    height: 300,
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
                            searchQuery.isNotEmpty
                                ? 'Sin resultados'
                                : selectedCategory != null
                                    ? 'No hay productos en esta categoría'
                                    : 'No hay productos disponibles',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'No se encontraron productos que coincidan con "$searchQuery"'
                                : 'Intenta con otra categoría o término de búsqueda',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
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

                      // Crear o reutilizar GlobalKey para este producto
                      if (!_productKeys.containsKey(producto.id)) {
                        _productKeys[producto.id!] = GlobalKey();
                      }

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
                        key: _productKeys[producto.id],
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? (index % 2 == 0 ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A2A))
                                    : (index % 2 == 0 ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white),
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
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : AppTheme.primaryColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _formatearPrecioConDecimales(_getPrecioUnitarioPromedio(producto)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'c/u',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Controles de cantidad compactos
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                                          _clearPricingCache();
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
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(6),
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF2A2A2A)
                                          : Colors.white,
                                    ),
                                    child: TextField(
                                      controller:
                                          cantidadControllers[producto.id!],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
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
                                        if (newCantidad > 999) {
                                          newCantidad = 999;
                                        }
                                        setState(() {
                                          cantidades[producto.id!] =
                                              newCantidad < 0
                                                  ? 0.0
                                                  : newCantidad;
                                          _clearPricingCache();
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
                                          _clearPricingCache();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // Botón de 3 puntitos (alineado con los botones de cantidad)
                              IconButton(
                                icon: Icon(
                                  Icons.more_horiz,
                                  color: producto.quantityPrices.isNotEmpty 
                                      ? Colors.orange 
                                      : Colors.grey.shade400,
                                  size: 20,
                                ),
                                onPressed: producto.quantityPrices.isNotEmpty 
                                    ? () => _mostrarPacksDisponibles(producto)
                                    : null,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Ribbon "ESPECIAL" en la esquina superior derecha
                      if (_tienePrecioEspecial(producto))
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'ESPECIAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
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
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.only(
            bottom: isKeyboardVisible ? keyboardHeight : 0,
          ),
          child: SafeArea(
            top: false,
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _formatearTotalPedido(),
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
                      
                      // Calculate pricing for this specific quantity
                      final cantidad = e.value.toInt();
                      final cacheKey = '${producto.id}_${cantidad}';
                      final pricingResult = pricingResults[cacheKey];
                      
                      // El precio debe ser el promedio por unidad, no el total
                      final precioTotal = pricingResult?.finalPrice ?? _getPrecioFinal(producto);
                      final precioUnitarioPromedio = precioTotal / cantidad;
                      
                      return ProductoSeleccionado(
                          id: producto.id!,
                          nombre: producto.nombre,
                          precio: precioUnitarioPromedio,
                          cantidad: e.value,
                          categoria: producto.categoriaNombre ?? '',
                          categoriaId: producto.categoriaId);
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
      ),
    );
  }
}
