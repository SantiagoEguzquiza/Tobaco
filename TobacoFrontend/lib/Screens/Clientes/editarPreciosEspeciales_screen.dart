import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Models/Categoria.dart';
import '../../Models/Producto.dart';
import '../../Models/Cliente.dart';
import '../../Models/PrecioEspecial.dart';
import '../../Services/Categoria_Service/categoria_provider.dart';
import '../../Services/Productos_Service/productos_provider.dart';
import '../../Services/PrecioEspecialService.dart';
import '../../Theme/app_theme.dart';
import '../../Helpers/api_handler.dart';
import '../../Theme/headers.dart';

class EditarPreciosEspecialesScreen extends StatefulWidget {
  final Cliente cliente;
  final bool isWizardMode;
  final bool isIndividualEdit;

  const EditarPreciosEspecialesScreen({
    super.key,
    required this.cliente,
    this.isWizardMode = false,
    this.isIndividualEdit = false,
  });

  @override
  State<EditarPreciosEspecialesScreen> createState() =>
      _EditarPreciosEspecialesScreenState();
}

class _EditarPreciosEspecialesScreenState
    extends State<EditarPreciosEspecialesScreen> {
  List<Producto> productos = [];
  List<Categoria> categorias = [];
  List<PrecioEspecial> preciosEspeciales = [];
  final Map<int, TextEditingController> precioControllers = {};
  /// Estado actual del campo (precio diferente al estándar) - para el badge/borde
  final Map<int, bool> tienePrecioEspecial = {};
  /// Estado guardado en servidor - solo se actualiza al cargar/guardar. Usado para ordenar
  /// la lista de forma estable y evitar que el producto salte al cambiar un dígito.
  final Map<int, bool> tienePrecioEspecialGuardado = {};
  String? selectedCategory;
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  String searchQuery = '';
  final ProductoProvider productoProvider = ProductoProvider();
  final CategoriasProvider categoriasProvider = CategoriasProvider();
  final TextEditingController _searchController = TextEditingController();

  // Mismo helper que en productos_screen para usar el color de cada categoría
  Color _parseColor(String colorHex) {
    try {
      if (colorHex.isEmpty || colorHex.length < 7) {
        return const Color(0xFF9E9E9E); // Gris por defecto
      }
      return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
    } catch (_) {
      return const Color(0xFF9E9E9E);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in precioControllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
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
      final List<PrecioEspecial> fetchedPrecios =
          await PrecioEspecialService.getPreciosEspecialesByCliente(
              widget.cliente.id!);

      setState(() {
        productos = fetchedProductos;
        categorias = fetchedCategorias;
        preciosEspeciales = fetchedPrecios;

        // Limpiar controladores anteriores que ya no existen
        final productosIds = productos.map((p) => p.id).toSet();
        precioControllers.removeWhere((key, controller) {
          if (!productosIds.contains(key)) {
            controller.dispose();
            return true;
          }
          return false;
        });

        // Inicializar controladores y estado
        for (var producto in productos) {
          final precioEspecial = preciosEspeciales.firstWhere(
            (p) => p.productoId == producto.id,
            orElse: () => PrecioEspecial(
              id: null,
              clienteId: widget.cliente.id!,
              productoId: producto.id!,
              precio: producto.precio,
              fechaCreacion: DateTime.now(),
            ),
          );

          // Si el controlador ya existe, actualizar su texto, si no, crear uno nuevo
          if (precioControllers.containsKey(producto.id!)) {
            precioControllers[producto.id!]!.text = precioEspecial.precio.toStringAsFixed(2);
          } else {
            precioControllers[producto.id!] = TextEditingController(
              text: precioEspecial.precio.toStringAsFixed(2),
            );
          }

          final tieneGuardado = preciosEspeciales.any(
            (p) => p.productoId == producto.id,
          );
          tienePrecioEspecial[producto.id!] = tieneGuardado;
          tienePrecioEspecialGuardado[producto.id!] = tieneGuardado;
        }

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      if (Apihandler.isConnectionError(e)) {
        setState(() {
          isLoading = false;
          // No establecer errorMessage para errores de conexión
        });
        await Apihandler.handleConnectionError(context, e);
      } else {
        setState(() {
          errorMessage = 'Error al cargar los datos: ${e.toString().replaceFirst('Exception: ', '')}';
          isLoading = false;
        });
      }
    }
  }

  List<Producto> get filteredProductos {
    var filtered = productos.where((producto) {
      final matchesSearch = searchQuery.isEmpty ||
          producto.nombre.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == null ||
          producto.categoriaNombre == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Ordenar por estado GUARDADO, no por edición actual. Así el producto no salta
    // cuando el usuario borra un dígito (tienePrecioEspecial cambiaría y reordenaría).
    filtered.sort((a, b) {
      final aTieneEspecial = tienePrecioEspecialGuardado[a.id!] ?? false;
      final bTieneEspecial = tienePrecioEspecialGuardado[b.id!] ?? false;

      if (aTieneEspecial && !bTieneEspecial) return -1;
      if (!aTieneEspecial && bTieneEspecial) return 1;

      return a.nombre.compareTo(b.nombre);
    });

    return filtered;
  }

  void _onPrecioChanged(int productoId, String value) {
    final precio = double.tryParse(value) ?? 0.0;
    final producto = productos.firstWhere((p) => p.id == productoId);

    setState(() {
      tienePrecioEspecial[productoId] = precio != producto.precio;
    });
  }

  Future<void> _guardarTodosLosPrecios() async {
    setState(() {
      isSaving = true;
    });

    try {
      for (var producto in productos) {
        final controller = precioControllers[producto.id!];
        if (controller == null) continue;

        final nuevoPrecio = double.tryParse(controller.text) ?? 0.0;
        final precioEstandar = producto.precio;

        if (nuevoPrecio != precioEstandar) {
          // Crear o actualizar precio especial
          await PrecioEspecialService.upsertPrecioEspecial(
            widget.cliente.id!,
            producto.id!,
            nuevoPrecio,
          );
        } else {
          // Eliminar precio especial si existe
          final precioExistente = preciosEspeciales.firstWhere(
            (p) => p.productoId == producto.id,
            orElse: () => PrecioEspecial(
                id: null,
                clienteId: 0,
                productoId: 0,
                precio: 0,
                fechaCreacion: DateTime.now()),
          );

          if (precioExistente.id != null) {
            await PrecioEspecialService.deletePrecioEspecial(
                precioExistente.id!);
          }
        }
      }

      // Recargar datos (esto actualiza tienePrecioEspecialGuardado)
      await _loadData();

      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Precios especiales guardados exitosamente'),
        );
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al guardar: $e'),
        );
      }
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Widget _buildEmptyStatePreciosEspeciales() {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 400 || size.height < 640;
    final contentPadding = isSmallPhone ? 20.0 : 40.0;
    final iconSize = isSmallPhone ? 56.0 : 80.0;
    final titleSize = isSmallPhone ? 16.0 : 18.0;
    final subtitleSize = isSmallPhone ? 13.0 : 14.0;
    final spacing1 = isSmallPhone ? 12.0 : 16.0;
    final spacing2 = isSmallPhone ? 6.0 : 8.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Padding abajo para poder hacer scroll y ver el mensaje sobre el botón "Guardar Todos"
    final bottomScrollPadding = 80.0;
    // Mismo margen que las cards del ListView (16)
    const cardMargin = 16.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(cardMargin, cardMargin, cardMargin, cardMargin),
      child: Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            contentPadding,
            contentPadding,
            contentPadding,
            contentPadding + bottomScrollPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: iconSize,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: spacing1),
              Text(
                selectedCategory != null
                    ? 'No hay productos en esta categoría'
                    : 'No hay productos disponibles',
                style: TextStyle(
                  fontSize: titleSize,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing2),
              Text(
                selectedCategory != null
                    ? 'Prueba con otra categoría o busca productos'
                    : 'Asigna precios especiales a los productos del cliente',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildPrecioInfo(Producto producto) {
    final tieneEspecial = tienePrecioEspecial[producto.id!] ?? false;
    final precioEstandar = producto.precio;
    final precioEspecial =
        double.tryParse(precioControllers[producto.id!]?.text ?? '0') ??
            precioEstandar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
            Text(
              '\$${precioEspecial.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : (tieneEspecial
                        ? Colors.green.shade700
                        : AppTheme.primaryColor),
              ),
            ),
            if (tieneEspecial)
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
          ),
        ),
        if (tieneEspecial) ...[
          const SizedBox(height: 2),
          Text(
            'Estándar: \$${precioEstandar.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isWizardMode
        ? _buildContent()
        : Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: widget.isIndividualEdit 
                ? AppBar(
                    title: const Text(
                      'Precios Especiales',
                      style: AppTheme.appBarTitleStyle,
                    ),
                    backgroundColor: null, // Usar el tema
                    foregroundColor: Colors.white,
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  )
                : AppBar(
                    title: const Text(
                      'Precios Especiales',
                      style: AppTheme.appBarTitleStyle,
                    ),
                    backgroundColor: null, // Usar el tema
                    foregroundColor: Colors.white,
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
            body: Stack(
              children: [
                SafeArea(child: _buildContent()),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFloatingActionButton(),
                ),
              ],
            ),
          );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Header (alineado visualmente a productos_screen)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderConBuscador(
                leadingIcon: Icons.price_change,
                title: 'Precios Especiales',
                subtitle:
                    'Cliente: ${widget.cliente.nombre} • ${filteredProductos.length} productos',
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
              const SizedBox(height: 15),
              // Filtros de categoría (Todos por defecto) - mismo estilo que en productos_screen
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Opción "Todos" (por defecto)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedCategory = null);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedCategory == null
                                ? AppTheme.primaryColor
                                : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedCategory == null
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Todos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selectedCategory == null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selectedCategory == null
                                  ? Colors.white
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Resto de categorías
                    ...categorias.map((categoria) {
                      final isSelected = selectedCategory == categoria.nombre;
                      final categoriaColor = _parseColor(categoria.colorHex);
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory =
                                  isSelected ? null : categoria.nombre;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? categoriaColor
                                  : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? categoriaColor
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              categoria.nombre[0].toUpperCase() +
                                  categoria.nombre.substring(1),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lista de productos
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                )
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
                      ? _buildEmptyStatePreciosEspeciales()
                      : ListView.builder(
                          // Padding extra abajo para la barra "Guardar Todos" + espacio
                          // para el teclado cuando se edita un precio (evita que tape el campo)
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            120 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          itemCount: filteredProductos.length,
                          itemBuilder: (context, index) {
                            final producto = filteredProductos[index];
                            final tieneEspecial =
                                tienePrecioEspecial[producto.id!] ?? false;

                            // Color de la categoría para estilizar el texto
                            final categoria = categorias.firstWhere(
                              (c) => c.nombre == producto.categoriaNombre,
                              orElse: () => Categoria(
                                nombre: 'Sin categoría',
                                colorHex: '#9E9E9E',
                              ),
                            );
                            final categoriaColor =
                                _parseColor(categoria.colorHex);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Pequeño espacio para separar la línea del borde izquierdo
                                  const SizedBox(width: 12),
                                  // Línea de color de la categoría (igual que en productos_screen)
                                  Container(
                                    width: 4,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: categoriaColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // Información del producto
                                            Expanded(
                                              flex: 4,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          producto.nombre,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Theme.of(context).brightness ==
                                                                    Brightness.dark
                                                                ? Colors.white
                                                                : AppTheme
                                                                    .primaryColor,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: categoriaColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      'Categoría: ${producto.categoriaNombre ?? 'Sin categoría'}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  _buildPrecioInfo(producto),
                                                ],
                                              ),
                                            ),

                                            // Campo de precio (mismo color que la card del producto)
                                            Builder(
                                              builder: (ctx) {
                                                final isDark = Theme.of(ctx).brightness == Brightness.dark;
                                                final inputBgColor = isDark
                                                    ? const Color(0xFF1A1A1A)
                                                    : Colors.white;
                                                return Container(
                                              width: 100,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: inputBgColor,
                                                border: Border.all(
                                                  color: tieneEspecial
                                                      ? Colors.green.shade400
                                                      : Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Theme(
                                                data: Theme.of(context)
                                                    .copyWith(
                                                  inputDecorationTheme:
                                                      InputDecorationTheme(
                                                    filled: true,
                                                    fillColor: inputBgColor,
                                                    border: InputBorder.none,
                                                    enabledBorder:
                                                        InputBorder.none,
                                                    focusedBorder:
                                                        InputBorder.none,
                                                    errorBorder:
                                                        InputBorder.none,
                                                    focusedErrorBorder:
                                                        InputBorder.none,
                                                    disabledBorder:
                                                        InputBorder.none,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Theme(
                                                    data: Theme.of(context)
                                                        .copyWith(
                                                      textSelectionTheme:
                                                          TextSelectionThemeData(
                                                        selectionColor:
                                                            AppTheme
                                                                .primaryColor
                                                                .withOpacity(
                                                                    0.3),
                                                        selectionHandleColor:
                                                            AppTheme
                                                                .primaryColor,
                                                        cursorColor: AppTheme
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                    child: TextField(
                                                      key: ValueKey('precio_${producto.id}'),
                                                      controller:
                                                          precioControllers[
                                                              producto.id!],
                                                      // TextInputType.text + formatter evita el bug del teclado
                                                      // numérico que no aparece en algunos emuladores
                                                      keyboardType: TextInputType.text,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                                      ],
                                                      scrollPadding: const EdgeInsets.only(bottom: 200),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isDark
                                                            ? Colors.white
                                                            : AppTheme
                                                                .textColor,
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        filled: true,
                                                        fillColor: inputBgColor,
                                                        hintText: '0.00',
                                                        border:
                                                            InputBorder.none,
                                                        enabledBorder:
                                                            InputBorder.none,
                                                        focusedBorder:
                                                            InputBorder.none,
                                                        errorBorder:
                                                            InputBorder.none,
                                                        focusedErrorBorder:
                                                            InputBorder.none,
                                                        disabledBorder:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        isDense: true,
                                                      ),
                                                      onChanged: (value) =>
                                                          _onPrecioChanged(
                                                              producto.id!,
                                                              value),
                                                    ),
                                                  ),
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
                                ],
                              ),
                            );
                          },
                        ),
        ),

        // Botón de guardar para modo wizard
        if (widget.isWizardMode) ...[
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: isSaving
                  ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusMainButtons),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _guardarTodosLosPrecios,
                      icon: const Icon(Icons.save_outlined, size: 24),
                      label: const Text(
                        'Guardar Precios Especiales',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMainButtons),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: isSaving
              ? Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMainButtons),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: _guardarTodosLosPrecios,
                  icon: const Icon(Icons.save_outlined, size: 24),
                  label: const Text(
                    'Guardar Todos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMainButtons),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
