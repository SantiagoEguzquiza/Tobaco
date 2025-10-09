import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
// Nuevos widgets modulares
import 'NuevaVenta/widgets/widgets.dart';

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Nueva Venta', style: AppTheme.appBarTitleStyle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (isSearching) ...[
                      // Barra de búsqueda
                      Padding(
                        padding: const EdgeInsets.all(16.0),
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
                      ClienteSection(
                        cliente: clienteSeleccionado!,
                        onCambiarCliente: cambiarCliente,
                      ),

                      const SizedBox(height: 16),

                      // Botón agregar productos
                      AgregarProductoButton(
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

                            if (resultado != null && resultado is List<ProductoSeleccionado>) {
                              setState(() {
                                productosSeleccionados = resultado;
                              });
                            }
                          } catch (e) {
                            AppTheme.showSnackBar(
                              context,
                              AppTheme.errorSnackBar('Error al seleccionar productos: $e'),
                            );
                          }
                        },
                      ),

                      // Lista de productos o estado vacío
                      const SizedBox(height: 16),
                      if (productosSeleccionados.isNotEmpty) ...[
                        LineItemsList(
                          productos: productosSeleccionados,
                          onEliminar: (index) {
                            setState(() {
                              productosSeleccionados.removeAt(index);
                            });
                          },
                          onTap: (index) async {
                            // Navegar a seleccionar productos con scroll al producto específico
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
                          },
                          preciosEspeciales: preciosEspeciales,
                          descuentoGlobal: clienteSeleccionado?.descuentoGlobal,
                        ),
                      ] else ...[
                        const EmptyStateVenta(),
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
          ? ConfirmarVentaFooter(
              onConfirmar: isProcessingVenta ? () {} : _confirmarVenta,
              enabled: !isProcessingVenta,
              total: _calcularTotalConDescuento(),
              cantidadProductos: productosSeleccionados.length,
              descuento: _calcularDescuento() > 0 ? _calcularDescuento() : null,
            )
          : null,
    );
  }
}