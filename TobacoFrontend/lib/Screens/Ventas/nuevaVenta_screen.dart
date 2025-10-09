import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Screens/Clientes/wizardNuevoCliente_screen.dart';
import 'package:tobaco/Screens/Ventas/metodoPago_screen.dart';
import 'package:tobaco/Screens/Ventas/seleccionarProducto_screen.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Services/PrecioEspecialService.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Theme/confirmAnimation.dart';
import 'package:tobaco/Screens/Ventas/resumenVenta_screen.dart';

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  Cliente? clienteSeleccionado;
  final TextEditingController _searchController = TextEditingController();
  List<Cliente> clientesFiltrados = [];
  List<Cliente> clientesIniciales = [];
  bool isSearching = true;
  bool isLoadingClientes = false;
  bool isLoadingClientesIniciales = false;
  bool isProcessingVenta = false;
  List<ProductoSeleccionado> productosSeleccionados = [];
  Map<int, double> preciosEspeciales = {};
  Timer? _debounceTimer;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _cargarClientesIniciales();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      buscarClientes(_searchController.text);
    });
  }

  Future<void> _cargarClientesIniciales() async {
    setState(() {
      isLoadingClientesIniciales = true;
    });

    try {
      final clientes = await ClienteProvider().obtenerClientes();
      if (mounted) {
        setState(() {
          clientesIniciales = clientes;
          isLoadingClientesIniciales = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingClientesIniciales = false;
        });
      }
      debugPrint('Error al cargar clientes iniciales: $e');
    }
  }

  void _filtrarClientesIniciales(String query) {
    final trimmedQuery = query.trim();
    
    if (trimmedQuery.isEmpty) {
      setState(() {
        clientesFiltrados = [];
        errorMessage = null;
      });
      return;
    }

    final filtrados = clientesIniciales.where((cliente) {
      return cliente.nombre.toLowerCase().contains(trimmedQuery.toLowerCase());
    }).toList();

    setState(() {
      clientesFiltrados = filtrados;
      if (filtrados.isEmpty) {
        errorMessage = 'No se encontraron clientes con ese nombre';
      } else {
        errorMessage = null;
      }
    });
  }

  Widget _buildClientesList(List<Cliente> clientes, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2F2F2F) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1E1E1E)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$title (${clientes.length})',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clientes.length.clamp(0, 4),
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              final isLast = index == clientes.length.clamp(0, 4) - 1;
              return Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? (index % 2 == 0
                          ? const Color(0xFF2F2F2F)
                          : const Color(0xFF1E1E1E))
                      : (index % 2 == 0
                          ? Colors.white
                          : AppTheme.primaryColor.withOpacity(0.05)),
                  borderRadius: isLast 
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        )
                      : null,
                  border: isLast ? null : Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? AppTheme.primaryColor.withOpacity(0.2)
                          : AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    cliente.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: cliente.direccion != null &&
                          cliente.direccion!.isNotEmpty
                      ? Text(
                          cliente.direccion!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: cliente.deuda != null &&
                          double.tryParse(cliente.deuda!.toString()) != null &&
                          double.parse(cliente.deuda!.toString()) > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Deuda: \$${cliente.deuda}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => _seleccionarCliente(cliente),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200,
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
                Icons.search_off,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro término de búsqueda',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _seleccionarCliente(Cliente cliente) {
    setState(() {
      clienteSeleccionado = cliente;
      isSearching = false;
      clientesFiltrados = [];
      _searchController.clear();
    });
    _cargarPreciosEspeciales();
  }

  Future<void> _cargarPreciosEspeciales() async {
    if (clienteSeleccionado == null) return;

    try {
      final precios = await PrecioEspecialService.getPreciosEspecialesByCliente(clienteSeleccionado!.id!);
      setState(() {
        preciosEspeciales.clear();
        for (var precio in precios) {
          preciosEspeciales[precio.productoId] = precio.precio;
        }
      });
    } catch (e) {
      print('Error cargando precios especiales: $e');
    }
  }

  void buscarClientes(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      setState(() {
        clientesFiltrados = [];
        errorMessage = null;
        isLoadingClientes = false;
      });
      return;
    }

    setState(() {
      isLoadingClientes = true;
      errorMessage = null;
    });

    try {
      final clientes = await ClienteProvider().buscarClientes(trimmedQuery);
      setState(() {
        clientesFiltrados = clientes;
        isLoadingClientes = false;
        if (clientes.isEmpty) {
          errorMessage = 'No se encontraron clientes con ese nombre';
        }
      });
    } catch (e) {
      debugPrint('Error al buscar clientes: $e');
      setState(() {
        clientesFiltrados = [];
        isLoadingClientes = false;
        errorMessage = 'Error al buscar clientes. Intente nuevamente.';
      });
    }
  }

  void seleccionarCliente(Cliente cliente) {
    setState(() {
      clienteSeleccionado = cliente;
      isSearching = false;
      errorMessage = null;
    });
    _searchController.clear();
    _cargarPreciosEspeciales();
  }

  void cambiarCliente() {
    setState(() {
      clientesFiltrados = [];
      clienteSeleccionado = null;
      isSearching = true;
      errorMessage = null;
      productosSeleccionados = [];
      preciosEspeciales.clear();
    });
    _searchController.clear();
  }

  void _eliminarProducto(int index) {
    setState(() {
      productosSeleccionados.removeAt(index);
    });
  }

  Future<void> _editarProducto(int index) async {
    try {
      final productoId = productosSeleccionados[index].id;
      
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeleccionarProductosScreen(
            productosYaSeleccionados: productosSeleccionados,
            cliente: clienteSeleccionado,
            scrollToProductId: productoId,
          ),
        ),
      );

      if (resultado != null && resultado is List<ProductoSeleccionado>) {
        setState(() {
          productosSeleccionados = resultado;
        });
      }
    } catch (e) {
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar('Error al editar productos: $e'),
      );
    }
  }

  double _calcularTotal() {
    return productosSeleccionados.fold(
        0.0, (sum, ps) => sum + (ps.precio * ps.cantidad));
  }

  double _calcularTotalConDescuento() {
    final subtotal = _calcularTotal();
    if (clienteSeleccionado != null && clienteSeleccionado!.descuentoGlobal > 0) {
      final descuento = subtotal * (clienteSeleccionado!.descuentoGlobal / 100);
      return subtotal - descuento;
    }
    return subtotal;
  }

  double _calcularDescuento() {
    if (clienteSeleccionado != null && clienteSeleccionado!.descuentoGlobal > 0) {
      final subtotal = _calcularTotal();
      return subtotal * (clienteSeleccionado!.descuentoGlobal / 100);
    }
    return 0.0;
  }

  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  }

  Widget _formatearPrecioConDecimales(double precio,
      {Color? color, double? fontSize}) {
    final precioStr = precio.toStringAsFixed(2);
    final partes = precioStr.split('.');
    final parteEntera = partes[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
    final parteDecimal = partes[1];

    final baseFontSize = fontSize ?? 14.0;
    final decimalFontSize = baseFontSize * 0.7;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '\$${parteEntera}',
            style: TextStyle(
              fontSize: baseFontSize,
              fontWeight: FontWeight.w500,
              color: color ?? Colors.grey.shade600,
            ),
          ),
          TextSpan(
            text: ',${parteDecimal}',
            style: TextStyle(
              fontSize: decimalFontSize,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  bool _puedeConfirmarVenta() {
    return clienteSeleccionado != null &&
        productosSeleccionados.isNotEmpty &&
        !isProcessingVenta;
  }

  Future<void> _confirmarVenta() async {
    if (!_puedeConfirmarVenta()) return;

    final confirmar = await AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Confirmar Venta',
      message: '¿Está seguro de que desea finalizar la venta por \$${_formatearPrecio(_calcularTotalConDescuento())}?',
      confirmText: 'Finalizar Venta',
      cancelText: 'Cancelar',
      icon: Icons.shopping_cart_checkout,
      iconColor: Colors.green,
    );

    if (confirmar != true) return;

    setState(() {
      isProcessingVenta = true;
    });

    try {
      final productos = productosSeleccionados
          .map((ps) => VentasProductos(
                productoId: ps.id,
                nombre: ps.nombre,
                precio: ps.precio,
                cantidad: ps.cantidad,
                categoria: ps.categoria,
                categoriaId: ps.categoriaId,
                precioFinalCalculado: ps.precio * ps.cantidad,
              ))
          .toList();

      final venta = Ventas(
        clienteId: clienteSeleccionado!.id!,
        cliente: clienteSeleccionado!,
        ventasProductos: productos,
        total: _calcularTotalConDescuento(),
        fecha: DateTime.now(),
      );

      final Ventas? ventaConPagos = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormaPagoScreen(venta: venta),
        ),
      );

      if (ventaConPagos == null ||
          ventaConPagos.pagos == null ||
          ventaConPagos.pagos!.isEmpty) {
        setState(() {
          isProcessingVenta = false;
        });
        return;
      }

      await VentasProvider().crearVenta(ventaConPagos);

      if (mounted) {
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 0),
          pageBuilder: (context, animation, secondaryAnimation) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.green,
                systemNavigationBarColor: Colors.green,
              ),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: VentaConfirmadaAnimacion(
                  onFinish: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => ResumenVentaScreen(),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        isProcessingVenta = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la venta: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _confirmarVenta,
            ),
          ),
        );
      }
    }
  }

  Widget _buildProductoItem(ProductoSeleccionado ps, int index) {
    final subtotal = ps.precio * ps.cantidad;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: index % 2 == 0
            ? (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : Colors.white)
            : (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : AppTheme.primaryColor.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF404040)
              : AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Slidable(
        key: ValueKey(ps.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.3,
          children: [
            SlidableAction(
              onPressed: (_) => _eliminarProducto(index),
              backgroundColor: Colors.red,
              icon: Icons.delete,
              label: 'Eliminar',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _editarProducto(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ps.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _formatearPrecioConDecimales(ps.precio),
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
                        ? const Color(0xFF1A1A1A)
                        : Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      ps.cantidad % 1 == 0
                          ? ps.cantidad.toInt().toString()
                          : ps.cantidad.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _formatearPrecioConDecimales(
                    subtotal,
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyProductState() {
    return SizedBox(
      height: 300,
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
                Icons.shopping_cart_outlined,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos seleccionados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca "Agregar productos" para comenzar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Nueva Venta'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (isSearching) ...[
                      // Barra de búsqueda
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: HeaderConBuscador(
                          leadingIcon: Icons.people,
                          title: 'Buscar Cliente',
                          subtitle: 'Selecciona un cliente para la venta',
                          controller: _searchController,
                          hintText: 'Buscar por nombre...',
                          onChanged: (value) {
                            setState(() {
                              if (value.trim().isEmpty) {
                                clientesFiltrados = [];
                                errorMessage = null;
                              } else {
                                _filtrarClientesIniciales(value);
                                buscarClientes(value);
                              }
                            });
                          },
                          onClear: () {
                            _searchController.clear();
                            setState(() {
                              clientesFiltrados = [];
                              errorMessage = null;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Lista de clientes
                      if (isLoadingClientesIniciales)
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                    Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Cargando clientes...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (clientesFiltrados.isNotEmpty)
                        _buildClientesList(clientesFiltrados, 'Clientes encontrados')
                      else if (clientesIniciales.isNotEmpty && _searchController.text.trim().isEmpty)
                        _buildClientesList(clientesIniciales, 'Clientes disponibles')
                      else if (_searchController.text.trim().isNotEmpty)
                        _buildEmptyState('No se encontraron clientes con ese nombre')
                      else
                        _buildEmptyState('No hay clientes disponibles'),
                    ] else ...[
                      // Cliente seleccionado
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: Theme.of(context).brightness == Brightness.dark
                                ? [
                                    const Color(0xFF2A2A2A),
                                    const Color(0xFF1A1A1A),
                                  ]
                                : [
                                    AppTheme.primaryColor.withOpacity(0.1),
                                    AppTheme.secondaryColor.withOpacity(0.3),
                                  ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF404040)
                                : AppTheme.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: Theme.of(context).brightness == Brightness.dark ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Column(
                          children: [
                            // Información del cliente
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          clienteSeleccionado!.nombre,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : AppTheme.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (clienteSeleccionado!.deuda != null &&
                                            double.tryParse(clienteSeleccionado!.deuda!.toString()) != null &&
                                            double.parse(clienteSeleccionado!.deuda!.toString()) > 0) ...[
                                          Text(
                                            'Deuda: \$${_formatearPrecio(double.parse(clienteSeleccionado!.deuda!.toString()))}',
                                            style: TextStyle(
                                              color: Colors.red.shade600,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            'Cliente Seleccionado',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                      onPressed: cambiarCliente,
                                      tooltip: 'Cambiar cliente',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Botón agregar productos
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.addGreenColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final resultado = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SeleccionarProductosScreen(
                                          productosYaSeleccionados: productosSeleccionados,
                                          cliente: clienteSeleccionado,
                                        ),
                                      ),
                                    );

                                    if (resultado != null &&
                                        resultado is List<ProductoSeleccionado>) {
                                      setState(() {
                                        productosSeleccionados = resultado;
                                      });
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al seleccionar productos: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.addGreenColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.add_shopping_cart,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                label: const Text(
                                  'Agregar Productos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lista de productos o estado vacío
                      const SizedBox(height: 16),
                      if (productosSeleccionados.isNotEmpty) ...[
                        ...productosSeleccionados.asMap().entries.map((entry) {
                          return _buildProductoItem(entry.value, entry.key);
                        }).toList(),
                      ] else ...[
                        _buildEmptyProductState(),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // Botones de acción rápida (solo cuando se está buscando)
            if (isSearching)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                          Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Función próximamente disponible',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.primaryColor,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.qr_code_scanner,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Escanear QR',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cliente frecuente',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final nuevoCliente = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WizardNuevoClienteScreen(),
                            ),
                          );
                          
                          if (nuevoCliente != null && nuevoCliente is Cliente) {
                            setState(() {
                              clientesIniciales.insert(0, nuevoCliente);
                            });
                            _seleccionarCliente(nuevoCliente);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.person_add,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nuevo Cliente',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                'Registrar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _puedeConfirmarVenta()
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A) // Fondo oscuro en modo oscuro
                    : Colors.white, // Fondo blanco en modo claro
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                        Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1),
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
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (clienteSeleccionado != null && clienteSeleccionado!.descuentoGlobal > 0) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_offer,
                                    size: 16,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Descuento ${clienteSeleccionado!.descuentoGlobal.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Subtotal: \$${_formatearPrecio(_calcularTotal())}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade400 // Texto más claro en modo oscuro
                                      : Colors.grey.shade600, // Texto gris en modo claro
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Descuento: -\$${_formatearPrecio(_calcularDescuento())}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.red.shade400 // Rojo más claro en modo oscuro
                                      : Colors.red.shade600, // Rojo normal en modo claro
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade300 // Texto más claro en modo oscuro
                                    : Colors.grey.shade600, // Texto gris en modo claro
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _formatearPrecioConDecimales(
                              _calcularTotalConDescuento(),
                              color: AppTheme.primaryColor,
                              fontSize: 22.0,
                            ),
                            Text(
                              '${productosSeleccionados.length} producto${productosSeleccionados.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade400 // Texto más claro en modo oscuro
                                    : Colors.grey.shade500, // Texto gris en modo claro
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: isProcessingVenta ? null : _confirmarVenta,
                          style: AppTheme.elevatedButtonStyle(AppTheme.addGreenColor),
                          icon: isProcessingVenta
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check_circle, color: Colors.white),
                          label: Text(
                            isProcessingVenta ? 'Procesando...' : 'Confirmar Venta',
                            style: const TextStyle(
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
            )
          : null,
    );
  }
}