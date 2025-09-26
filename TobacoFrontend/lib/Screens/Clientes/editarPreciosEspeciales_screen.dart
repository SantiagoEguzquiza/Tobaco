import 'package:flutter/material.dart';
import '../../Models/Categoria.dart';
import '../../Models/Producto.dart';
import '../../Models/Cliente.dart';
import '../../Models/PrecioEspecial.dart';
import '../../Services/Categoria_Service/categoria_provider.dart';
import '../../Services/Productos_Service/productos_provider.dart';
import '../../Services/PrecioEspecialService.dart';
import '../../Theme/app_theme.dart';

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
  final Map<int, bool> tienePrecioEspecial = {};
  String? selectedCategory;
  bool isLoading = true;
  bool isSaving = false;
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
    for (var controller in precioControllers.values) {
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
      final List<PrecioEspecial> fetchedPrecios =
          await PrecioEspecialService.getPreciosEspecialesByCliente(
              widget.cliente.id!);

      setState(() {
        productos = fetchedProductos;
        categorias = fetchedCategorias;
        preciosEspeciales = fetchedPrecios;

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

          precioControllers[producto.id!] = TextEditingController(
            text: precioEspecial.precio.toStringAsFixed(2),
          );

          tienePrecioEspecial[producto.id!] = preciosEspeciales.any(
            (p) => p.productoId == producto.id,
          );
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar los datos: $e';
        isLoading = false;
      });
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

    // Ordenar: primero los que tienen precio especial, luego por nombre
    filtered.sort((a, b) {
      final aTieneEspecial = tienePrecioEspecial[a.id!] ?? false;
      final bTieneEspecial = tienePrecioEspecial[b.id!] ?? false;

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

      // Recargar datos
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

  Widget _buildPrecioInfo(Producto producto) {
    final tieneEspecial = tienePrecioEspecial[producto.id!] ?? false;
    final precioEstandar = producto.precio;
    final precioEspecial =
        double.tryParse(precioControllers[producto.id!]?.text ?? '0') ??
            precioEstandar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '\$${precioEspecial.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: tieneEspecial
                    ? Colors.green.shade700
                    : AppTheme.primaryColor,
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
            'Estándar: \$${precioEstandar.toStringAsFixed(2)}',
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
    return widget.isWizardMode
        ? _buildContent()
        : Scaffold(
            backgroundColor: AppTheme.secondaryColor,
            appBar: widget.isIndividualEdit 
                ? AppBar(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  )
                : AppBar(
                    title: Text('Precios Especiales - ${widget.cliente.nombre}'),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
            body: SafeArea(child: _buildContent()),
            floatingActionButton: _buildFloatingActionButton(),
          );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Header
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
                      Icons.price_change,
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
                          'Precios Especiales',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'Configura precios especiales para ${widget.cliente.nombre}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person,
                                  size: 12, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Cliente: ${widget.cliente.nombre}',
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
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
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

              const SizedBox(height: 16),

              // Filtros de categoría
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categorias.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Todas'),
                          selected: selectedCategory == null,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = null;
                            });
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          checkmarkColor: AppTheme.primaryColor,
                        ),
                      );
                    }

                    final categoria = categorias[index - 1];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(categoria.nombre),
                        selected: selectedCategory == categoria.nombre,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory =
                                selected ? categoria.nombre : null;
                          });
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                      ),
                    );
                  },
                ),
              ),
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
                            final tieneEspecial =
                                tienePrecioEspecial[producto.id!] ?? false;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: tieneEspecial
                                      ? Colors.green.shade200
                                      : AppTheme.primaryColor.withOpacity(0.2),
                                  width: tieneEspecial ? 2 : 1,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      producto.nombre,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppTheme
                                                            .primaryColor,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (tieneEspecial)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: const Text(
                                                        'ESPECIAL',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
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

                                        // Campo de precio
                                        Container(
                                          width: 100,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: TextField(
                                            controller:
                                                precioControllers[producto.id!],
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: '0.00',
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8),
                                            ),
                                            onChanged: (value) =>
                                                _onPrecioChanged(
                                                    producto.id!, value),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : _guardarTodosLosPrecios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save),
                          SizedBox(width: 8),
                          Text(
                            'Guardar Precios Especiales',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: isSaving ? null : _guardarTodosLosPrecios,
      backgroundColor: AppTheme.primaryColor,
      icon: isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.save, color: Colors.white),
      label: Text(
        isSaving ? 'Guardando...' : 'Guardar Todos',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
