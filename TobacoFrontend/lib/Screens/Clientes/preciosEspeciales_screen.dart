import 'package:flutter/material.dart';
import '../../Models/Cliente.dart';
import '../../Models/Producto.dart';
import '../../Models/PrecioEspecial.dart';
import '../../Models/Categoria.dart';
import '../../Services/PrecioEspecialService.dart';
import '../../Services/Productos_Service/productos_provider.dart';
import '../../Services/Categoria_Service/categoria_provider.dart';
import '../../Theme/app_theme.dart';
import '../../Theme/dialogs.dart';
import '../../Helpers/api_handler.dart';
import '../../Theme/headers.dart';
import 'editarPreciosEspeciales_screen.dart';

class PreciosEspecialesScreen extends StatefulWidget {
  final Cliente cliente;

  const PreciosEspecialesScreen({super.key, required this.cliente});

  @override
  State<PreciosEspecialesScreen> createState() => _PreciosEspecialesScreenState();
}

class _PreciosEspecialesScreenState extends State<PreciosEspecialesScreen> {
  List<PrecioEspecial> preciosEspeciales = [];
  List<Producto> productos = [];
  List<Categoria> categorias = [];
  bool isLoading = true;
  String errorMessage = '';
  final ProductoProvider productoProvider = ProductoProvider();
  final CategoriasProvider categoriasProvider = CategoriasProvider();
  String? _selectedCategory;
  List<String> _availableCategories = [];

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

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Obtener precios especiales, productos y categorías en paralelo
      final results = await Future.wait([
        PrecioEspecialService.getPreciosEspecialesByCliente(widget.cliente.id!),
        productoProvider.obtenerProductos(),
        categoriasProvider.obtenerCategorias(),
      ]);

      final precios =
          results[0] as List<PrecioEspecial>;
      final productosData =
          results[1] as List<Producto>;
      final categoriasData =
          results[2] as List<Categoria>;

      if (!mounted) return;
      
      setState(() {
        preciosEspeciales = precios;
        productos = productosData;
        categorias = categoriasData;
        _availableCategories = _buildAvailableCategories();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isLoading = false;
      });
      
      // Verificar si es un error de conexión con el servidor
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else if (e.toString().contains('401')) {
        // Si es un error 401, el usuario necesita autenticarse
        _showAuthErrorDialog();
      } else {
        // Mostrar otros errores
        await AppDialogs.showErrorDialog(
          context: context,
          message: 'Error al cargar los datos: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  void _showAuthErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sesión Expirada'),
          content: const Text('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver a la pantalla anterior
                // Aquí podrías navegar al login si tienes una ruta configurada
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _agregarPrecioEspecial() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPreciosEspecialesScreen(cliente: widget.cliente),
      ),
    );
    _loadData(); // Recargar datos al volver
  }

  Future<void> _editarPrecioEspecial(PrecioEspecial precioEspecial) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPreciosEspecialesScreen(
          cliente: widget.cliente,
          isIndividualEdit: true,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _eliminarPrecioEspecial(PrecioEspecial precioEspecial) async {
    final confirmed = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Precio Especial',
      message: '¿Estás seguro de que quieres eliminar el precio especial para ${precioEspecial.productoNombre}?',
    );

    if (confirmed == true) {
      try {
        await PrecioEspecialService.deletePrecioEspecial(precioEspecial.id!);
        
        if (mounted) {
          AppTheme.showSnackBar(
            context,
            AppTheme.successSnackBar('Precio especial eliminado exitosamente'),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted && Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
        } else if (mounted) {
          await AppDialogs.showErrorDialog(
            context: context,
            message: 'Error al eliminar el precio especial: ${e.toString().replaceFirst('Exception: ', '')}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrecios = preciosEspeciales.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null, // Usar el tema
        title: const Text(
          'Precios Especiales',
          style: AppTheme.appBarTitleStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header estilo ProductosScreen (sin buscador)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: HeaderSimple(
              leadingIcon: Icons.price_change,
              title: 'Precios Especiales',
              subtitle:
                  'Cliente: ${widget.cliente.nombre} • $totalPrecios precios especiales',
            ),
          ),

          // Filtro por categoría (similar a chips de productos)
          _buildCategoryFilter(),

          // Contenido principal
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : preciosEspeciales.isEmpty
                        ? _buildEmptyState()
                        : _buildPreciosList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade800 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade300 
                    : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.price_change_outlined,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay precios especiales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Este cliente no tiene precios especiales configurados',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Usa el botón de gestión desde el detalle del cliente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreciosList() {
    final filtered = _getFilteredPrecios();

    if (filtered.isEmpty) {
      return _buildFilteredEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final precioEspecial = filtered[index];
        return _buildPrecioCard(precioEspecial, index);
      },
    );
  }

  Widget _buildPrecioCard(PrecioEspecial precioEspecial, int index) {
    final tieneDescuento = precioEspecial.precioEstandar != null &&
        precioEspecial.precio < precioEspecial.precioEstandar!;
    final porcentajeDescuento = precioEspecial.precioEstandar != null
        ? ((precioEspecial.precioEstandar! - precioEspecial.precio) /
                precioEspecial.precioEstandar! *
            100)
        : 0.0;

    final producto = _findProducto(precioEspecial.productoId);
    final categoriaNombre = producto?.categoriaNombre?.isNotEmpty == true
        ? producto!.categoriaNombre!
        : 'Sin categoría';
    final categoriaColor =
        _getCategoryColor(producto?.categoriaNombre ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Indicador lateral (como en ProductosScreen)
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: categoriaColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Información del producto (alineado al diseño de ProductosScreen)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      precioEspecial.productoNombre ?? 'Producto desconocido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Categoría: $categoriaNombre',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        if (tieneDescuento && precioEspecial.precioEstandar != null) ...[
                          // Precio original tachado
                          Text(
                            precioEspecial.precioEstandar!.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Precio con descuento (especial)
                          Text(
                            precioEspecial.precio.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ] else ...[
                          // Sin descuento: solo el precio especial
                          Text(
                            precioEspecial.precio.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (tieneDescuento && precioEspecial.precioEstandar != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${porcentajeDescuento.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Botones de acción
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      onPressed: () => _editarPrecioEspecial(precioEspecial),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _eliminarPrecioEspecial(precioEspecial),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers de categorías

  List<String> _buildAvailableCategories() {
    final seen = <String>{};
    final ordered = <String>[];

    // Usar la lista de categorías oficial y respetar su orden (creación)
    for (final c in categorias) {
      final name = c.nombre.trim();
      if (name.isNotEmpty && !seen.contains(name)) {
        seen.add(name);
        ordered.add(name);
      }
    }

    return ordered;
  }

  List<PrecioEspecial> _getFilteredPrecios() {
    if (_selectedCategory == null) {
      return preciosEspeciales;
    }

    return preciosEspeciales.where((precio) {
      final prod = _findProducto(precio.productoId);
      return prod?.categoriaNombre == _selectedCategory;
    }).toList();
  }

  Producto? _findProducto(int productoId) {
    try {
      return productos.firstWhere((p) => p.id == productoId);
    } catch (_) {
      return null;
    }
  }

  Color _getCategoryColor(String categoriaNombre) {
    if (categoriaNombre.trim().isEmpty) {
      return const Color(0xFF9E9E9E);
    }

    final cat = categorias.firstWhere(
      (c) => c.nombre == categoriaNombre,
      orElse: () => Categoria(
        nombre: '',
        colorHex: '#9E9E9E',
      ),
    );

    return _parseColor(cat.colorHex);
  }

  Widget _buildCategoryFilter() {
    if (isLoading ||
        preciosEspeciales.isEmpty ||
        _availableCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardTheme.color ??
        (isDark ? const Color(0xFF1A1A1A) : Colors.white);

    // Construimos una lista que incluye "Todas" + categorías disponibles
    final categories = ['Todas', ..._availableCategories];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 45,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final name = categories[index];
            final isAll = index == 0;
            final isSelected =
                isAll ? _selectedCategory == null : _selectedCategory == name;

            final baseColor =
                isAll ? AppTheme.primaryColor : _getCategoryColor(name);

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = isAll ? null : name;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? baseColor : cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? baseColor
                          : (isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    final baseColor =
        value == null ? AppTheme.primaryColor : _getCategoryColor(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? baseColor
              : baseColor.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.14,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: baseColor.withOpacity(0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null) ...[
              Icon(
                Icons.label_rounded,
                size: 14,
                color: isSelected ? Colors.white : baseColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : baseColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryLabel = _selectedCategory ?? 'Todas';

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 42,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin precios en esta categoría',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay precios especiales configurados para\nla categoría "$categoryLabel".',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}