// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Proveedor.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Screens/Compras/nuevo_proveedor_screen.dart';
import 'package:tobaco/Screens/Compras/proveedor_section.dart';
import 'package:tobaco/Screens/Ventas/NuevaVenta/widgets/widgets.dart';
import 'package:tobaco/Screens/Ventas/seleccionarProducto_screen.dart';
import 'package:tobaco/Services/Compras_Service/compras_service.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Theme/dialogs.dart';

class _CompraItemLine {
  int productoId;
  String productoNombre;
  double cantidad;
  double costoUnitario;

  _CompraItemLine({
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.costoUnitario,
  });

  double get subtotal => cantidad * costoUnitario;
}

class NuevaCompraScreen extends StatefulWidget {
  const NuevaCompraScreen({super.key});

  @override
  _NuevaCompraScreenState createState() => _NuevaCompraScreenState();
}

class _NuevaCompraScreenState extends State<NuevaCompraScreen> {
  final _comprasService = ComprasService();
  List<Proveedor> _proveedores = [];
  bool _loadingProveedores = true;
  DateTime _fecha = DateTime.now();
  int? _proveedorId;
  final _searchControllerProveedor = TextEditingController();
  final _comprobanteController = TextEditingController();
  final _observacionesController = TextEditingController();
  final List<_CompraItemLine> _items = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadProveedores();
  }

  @override
  void dispose() {
    _searchControllerProveedor.dispose();
    _comprobanteController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadProveedores() async {
    setState(() => _loadingProveedores = true);
    try {
      final list = await _comprasService.getProveedores();
      if (mounted) {
        setState(() {
          _proveedores = list;
          _loadingProveedores = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProveedores = false);
    }
  }

  double get _total => _items.fold(0, (s, e) => s + e.subtotal);

  /// Sección de productos: header "Productos ( N )" + cards individuales con el
  /// mismo patrón del resto de la app (ícono cuadrado + info + subtotal + eliminar).
  Widget _buildProductosSectionCompra(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Productos ( ${_items.length} )',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return _buildCompraItemCard(_items[index], index, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompraItemCard(
      _CompraItemLine line, int index, bool isDark) {
    final isCompact = AppTheme.isCompactVentasButton(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 14 : 16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppTheme.borderRadiusCards),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 8 : 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.primaryColor,
                  size: isCompact ? 24 : 28,
                ),
              ),
              SizedBox(width: isCompact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      line.productoNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isCompact ? 15 : 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: isCompact ? 2 : 4),
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: isCompact ? 13 : 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_formatearCantidad(line.cantidad)} × \$${line.costoUnitario.toStringAsFixed(2)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isCompact ? 13 : 14,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Text(
                '\$${line.subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 14 : 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _removeItem(index),
                  child: Container(
                    width: isCompact ? 36 : 40,
                    height: isCompact ? 36 : 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade600,
                      size: isCompact ? 18 : 20,
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

  String _formatearCantidad(double cantidad) {
    if (cantidad == cantidad.truncateToDouble()) {
      return cantidad.toInt().toString();
    }
    return cantidad.toString();
  }

  /// Barra Total + Confirmar compra (reutilizada en scroll cuando hay productos).
  Widget _buildConfirmarCompraBar(bool isDark) {
    final isCompact = AppTheme.isCompactVentasButton(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    ),
                  ),
                  _buildPrecioTotalFormateado(_total),
                  Text(
                    '${_items.length} producto${_items.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 10,
              child: _isSubmitting
                  ? Container(
                      height: isCompact ? 48 : 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
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
                      onPressed: _items.isEmpty ? null : _confirmar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: AppTheme.ventasButtonPadding(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                      ),
                      icon: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: AppTheme.ventasButtonIconSize(context),
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Confirmar compra',
                          style: TextStyle(
                            fontSize: AppTheme.ventasButtonFontSize(context),
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formato igual que en nueva venta: parte entera grande, decimales con coma más chicos.
  Widget _buildPrecioTotalFormateado(double total) {
    final partes = total.toStringAsFixed(2).split('.');
    const fontSize = 22.0;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '\$${partes[0]}',
            style: const TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          TextSpan(
            text: ',${partes[1]}',
            style: TextStyle(
              fontSize: fontSize * 0.7,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        DateTime selectedDate = _fecha;
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final isCompactDialog = screenWidth < 380;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppTheme.primaryColor,
                    onPrimary: Colors.white,
                    surface: const Color(0xFF1A1A1A),
                    onSurface: Colors.white,
                    surfaceContainerHighest: const Color(0xFF2A2A2A),
                  )
                : ColorScheme.light(
                    primary: AppTheme.primaryColor,
                    onPrimary: Colors.white,
                    onSurface: Colors.black87,
                  ), dialogTheme: DialogThemeData(backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: isCompactDialog ? 12 : 24,
                  vertical: 24,
                ),
                backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                content: SizedBox(
                  width: isCompactDialog ? screenWidth - 48 : 300,
                  child: CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    onDateChanged: (date) {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                  ),
                ),
                actionsPadding: EdgeInsets.symmetric(
                  horizontal: isCompactDialog ? 12 : 24,
                  vertical: 12,
                ),
                actions: [
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompactDialog ? 18 : 24,
                              vertical: 12,
                            ),
                            minimumSize: Size(isCompactDialog ? 110 : 120, 44),
                          ),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(selectedDate),
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompactDialog ? 18 : 24,
                              vertical: 12,
                            ),
                            minimumSize: Size(isCompactDialog ? 110 : 120, 44),
                          ),
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _fecha = picked);
    }
  }

  Future<void> _irANuevoProveedor() async {
    final creado = await Navigator.push<Proveedor>(
      context,
      MaterialPageRoute(builder: (context) => const NuevoProveedorScreen()),
    );
    if (creado != null && mounted) {
      setState(() {
        _proveedores = [..._proveedores, creado];
        _proveedorId = creado.id;
      });
    }
  }

  void _addItemWith(Producto product, double cantidad, double costoUnitario) {
    setState(() {
      _items.add(_CompraItemLine(
        productoId: product.id!,
        productoNombre: product.nombre,
        cantidad: cantidad,
        costoUnitario: costoUnitario,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  List<ProductoSeleccionado> _itemsToProductoSeleccionado() {
    final productoProvider = context.read<ProductoProvider>();
    return _items.map((line) {
      Producto? p;
      try {
        p = productoProvider.productos.firstWhere((x) => x.id == line.productoId);
      } catch (_) {}
      return ProductoSeleccionado(
        id: line.productoId,
        nombre: line.productoNombre,
        precio: line.costoUnitario,
        cantidad: line.cantidad,
        categoria: p?.categoriaNombre ?? '',
        categoriaId: p?.categoriaId ?? 0,
      );
    }).toList();
  }

  Future<bool> _ensureProductosDisponiblesParaCompra() async {
    final productoProvider = context.read<ProductoProvider>();
    final categoriasProvider = context.read<CategoriasProvider>();

    if (productoProvider.productos.isNotEmpty) {
      return true;
    }

    try {
      final productosCache = await productoProvider.obtenerProductosDelCache();
      if (productosCache.isNotEmpty) {
        return true;
      }
    } catch (e) {
      debugPrint('Error verificando productos en caché para compras: $e');
    }

    try {
      final productosServidor = await productoProvider.obtenerProductos();
      try {
        await categoriasProvider.obtenerCategorias(silent: true);
      } catch (e) {
        debugPrint('Error cargando categorías para compras: $e');
      }

      if (productosServidor.isNotEmpty) {
        return true;
      }

      if (!mounted) return false;
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar('No existen productos disponibles.'),
      );
      return false;
    } catch (e) {
      if (!mounted) return false;

      final mensaje = e.toString().replaceFirst('Exception: ', '');
      final lowerMessage = mensaje.toLowerCase();
      final isOfflineWithoutCache = lowerMessage.contains('offline') ||
          lowerMessage.contains('sin conexión') ||
          lowerMessage.contains('sincronizar');

      AppTheme.showSnackBar(
        context,
        isOfflineWithoutCache
            ? AppTheme.warningSnackBar('Sin conexión y sin productos en caché.')
            : AppTheme.errorSnackBar(mensaje),
      );
      return false;
    }
  }

  Future<void> _openAddItem() async {
    final canContinue = await _ensureProductosDisponiblesParaCompra();
    if (!canContinue || !mounted) {
      return;
    }

    final resultado = await Navigator.of(context, rootNavigator: true)
        .push<List<ProductoSeleccionado>>(
      MaterialPageRoute(
        builder: (context) => SeleccionarProductosScreen(
          productosYaSeleccionados: _itemsToProductoSeleccionado(),
          cliente: null,
          appBarTitle: 'Agregar productos',
          modoCompra: true,
        ),
      ),
    );
    if (resultado == null || resultado.isEmpty || !mounted) return;
    setState(() {
      _items.clear();
      for (final ps in resultado) {
        _items.add(_CompraItemLine(
          productoId: ps.id,
          productoNombre: ps.nombre,
          cantidad: ps.cantidad,
          costoUnitario: ps.precio,
        ));
      }
    });
  }

  void _cambiarProveedor() {
    setState(() => _proveedorId = null);
  }

  Future<void> _confirmar() async {
    if (_proveedorId == null) {
      AppTheme.showSnackBar(context, AppTheme.warningSnackBar('Selecciona un proveedor'));
      return;
    }
    if (_proveedores.isEmpty) {
      AppTheme.showSnackBar(context, AppTheme.warningSnackBar('Crea al menos un proveedor'));
      return;
    }
    if (_items.isEmpty) {
      AppTheme.showSnackBar(context, AppTheme.warningSnackBar('Agrega al menos un producto'));
      return;
    }
    final confirm = await AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Confirmar compra',
      message: '¿Registrar la compra por \$${_total.toStringAsFixed(2)}? Se actualizará el stock y los costos de los productos.',
      confirmText: 'Confirmar',
    );
    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final itemsJson = _items.map((e) => {
        'productoId': e.productoId,
        'cantidad': e.cantidad,
        'costoUnitario': e.costoUnitario,
      }).toList();
      final fechaUtc = DateTime.utc(_fecha.year, _fecha.month, _fecha.day);
      await _comprasService.crearCompra(
        proveedorId: _proveedorId!,
        fecha: fechaUtc,
        numeroComprobante: _comprobanteController.text.trim().isEmpty ? null : _comprobanteController.text.trim(),
        observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
        items: itemsJson,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppTheme.showSnackBar(context, AppTheme.successSnackBar('Compra registrada'));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        AppTheme.showSnackBar(context, AppTheme.errorSnackBar(msg));
      }
    }
  }

  Proveedor? get _proveedorSeleccionado {
    if (_proveedorId == null) return null;
    try {
      return _proveedores.firstWhere((p) => p.id == _proveedorId);
    } catch (_) {
      return null;
    }
  }

  List<Proveedor> get _proveedoresFiltrados {
    final q = _searchControllerProveedor.text.trim().toLowerCase();
    if (q.isEmpty) return _proveedores;
    return _proveedores.where((p) => p.nombre.toLowerCase().contains(q)).toList();
  }

  /// Card con fecha, Nº comprobante y observaciones integrados.
  Widget _buildDatosCompraCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(
                'Datos de la compra',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comprobanteController,
            decoration: _inputDeco(isDark).copyWith(
              labelText: 'Nº comprobante / factura',
              hintText: 'Opcional',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _observacionesController,
            decoration: _inputDeco(isDark).copyWith(
              labelText: 'Observaciones',
              hintText: 'Opcional',
              alignLabelWithHint: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            maxLines: 2,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildProveedorCard(Proveedor p, bool isDark) {
    final isCompact = AppTheme.isCompactVentasButton(context);
    final String? contacto =
        (p.contacto != null && p.contacto!.trim().isNotEmpty)
            ? p.contacto!.trim()
            : (p.email != null && p.email!.trim().isNotEmpty
                ? p.email!.trim()
                : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
          onTap: () => setState(() => _proveedorId = p.id),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 14 : 16),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(AppTheme.borderRadiusCards),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 8 : 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: AppTheme.primaryColor,
                    size: isCompact ? 24 : 28,
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isCompact ? 15 : 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: isCompact ? 2 : 4),
                      Row(
                        children: [
                          Icon(
                            contacto == null
                                ? Icons.badge_outlined
                                : (p.contacto != null &&
                                        p.contacto!.trim().isNotEmpty
                                    ? Icons.phone_outlined
                                    : Icons.email_outlined),
                            size: isCompact ? 13 : 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              contacto ?? 'Sin contacto',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isCompact ? 13 : 14,
                                fontStyle: contacto == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isCompact ? 6 : 8),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  size: isCompact ? 20 : 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateProveedores(bool sinFiltro, bool isDark) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;
    final titulo = sinFiltro ? 'No hay proveedores. Crea uno.' : 'No se encontraron proveedores';
    final subtitulo = sinFiltro ? 'Usa el botón de arriba para agregar uno' : 'Intenta con otro término de búsqueda';

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(40, 40, 40, 40 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proveedor = _proveedorSeleccionado;
    final bool isBuscandoProveedor = proveedor == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva compra', style: AppTheme.appBarTitleStyle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isBuscandoProveedor) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: HeaderConBuscador(
                  leadingIcon: Icons.business_rounded,
                  title: 'Buscar proveedor',
                  subtitle: 'Selecciona un proveedor para la compra',
                  controller: _searchControllerProveedor,
                  hintText: 'Buscar por nombre...',
                  onChanged: (_) => setState(() {}),
                  onClear: () {
                    _searchControllerProveedor.clear();
                    setState(() {});
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _irANuevoProveedor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: AppTheme.ventasButtonPadding(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusMainButtons),
                      ),
                      elevation: 2,
                    ),
                    icon: Icon(
                      Icons.add_business_rounded,
                      color: Colors.white,
                      size: AppTheme.ventasButtonIconSize(context),
                    ),
                    label: Text(
                      'Nuevo proveedor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTheme.ventasButtonFontSize(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loadingProveedores
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      )
                    : _proveedoresFiltrados.isEmpty
                        ? _buildEmptyStateProveedores(
                            _searchControllerProveedor.text.trim().isEmpty,
                            isDark,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _proveedoresFiltrados.length,
                            itemBuilder: (_, i) {
                              final p = _proveedoresFiltrados[i];
                              return _buildProveedorCard(p, isDark);
                            },
                          ),
              ),
            ] else ...[
              Expanded(
                child: _items.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ProveedorSection(
                              proveedor: proveedor,
                              onCambiarProveedor: _cambiarProveedor,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildDatosCompraCard(isDark),
                            ),
                            const SizedBox(height: 12),
                            AgregarProductoButton(onPressed: _openAddItem, fullWidth: false),
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: EmptyStateVenta(),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProveedores,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ProveedorSection(
                                proveedor: proveedor,
                                onCambiarProveedor: _cambiarProveedor,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildDatosCompraCard(isDark),
                              ),
                              const SizedBox(height: 12),
                              AgregarProductoButton(onPressed: _openAddItem, fullWidth: false),
                              const SizedBox(height: 12),
                              _buildProductosSectionCompra(isDark),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: proveedor != null
          ? _buildConfirmarCompraBar(isDark)
          : null,
    );
  }

  void _showSelectorProveedor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final fillField = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final borderColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final searchController = TextEditingController();
        return StatefulBuilder(
          builder: (ctx2, setSheetState) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? _proveedores
                : _proveedores.where((p) => p.nombre.toLowerCase().contains(query)).toList();
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (_, scrollController) => Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Text(
                        'Buscar proveedor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setSheetState(() {}),
                        autofocus: true,
                        style: TextStyle(color: textColor, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Escribe para filtrar...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                          filled: true,
                          fillColor: fillField,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.business_rounded, size: 20, color: AppTheme.primaryColor),
                            ),
                            title: Text(
                              p.nombre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            onTap: () {
                              setState(() => _proveedorId = p.id);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDeco(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isDark ? const Color(0xFF404040) : Colors.grey.shade300),
      ),
    );
  }

  Widget _section({
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
