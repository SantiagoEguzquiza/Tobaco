import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Screens/Clientes/nuevoCliente_screen.dart';
import 'package:tobaco/Screens/Ventas/metodoPago_screen.dart';
import 'package:tobaco/Screens/Ventas/seleccionarProducto_screen.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Theme/confirmAnimation.dart';

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  Cliente? clienteSeleccionado;
  final TextEditingController _searchController = TextEditingController();
  List<Cliente> clientesFiltrados = [];
  bool isSearching = true;
  bool isLoadingClientes = false;
  bool isProcessingVenta = false;
  List<ProductoSeleccionado> productosSeleccionados = [];
  Timer? _debounceTimer;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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
  }

  void cambiarCliente() {
    setState(() {
      clientesFiltrados = [];
      clienteSeleccionado = null;
      isSearching = true;
      errorMessage = null;
      productosSeleccionados = [];
    });
    _searchController.clear();
  }

  void _eliminarProducto(int index) {
    setState(() {
      productosSeleccionados.removeAt(index);
    });
  }

  void _actualizarCantidad(int index, double nuevaCantidad) {
    setState(() {
      productosSeleccionados[index].cantidad =
          nuevaCantidad.clamp(0.5, double.infinity);
    });
  }

  double _calcularTotal() {
    return productosSeleccionados.fold(
        0.0, (sum, ps) => sum + (ps.producto.precio * ps.cantidad));
  }

  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  }

  bool _puedeConfirmarVenta() {
    return clienteSeleccionado != null &&
        productosSeleccionados.isNotEmpty &&
        !isProcessingVenta;
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarVenta() async {
    if (!_puedeConfirmarVenta()) return;

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AppTheme.confirmDialogStyle(
          title: 'Confirmar Venta',
          content:
              '¿Está seguro de que desea finalizar la venta por \$${_formatearPrecio(_calcularTotal())}?',
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        );
      },
    );

    if (confirmar != true) return;

    setState(() {
      isProcessingVenta = true;
    });

    try {
      // Crear la venta
      final productos = productosSeleccionados
          .map((ps) => VentasProductos(
                productoId: ps.producto.id!,
                producto: ps.producto,
                cantidad: ps.cantidad,
              ))
          .toList();

      final venta = Ventas(
        clienteId: clienteSeleccionado!.id!,
        cliente: clienteSeleccionado!,
        ventasProductos: productos,
        total: _calcularTotal(),
        fecha: DateTime.now(),
      );

      // Navegar a selección de método de pago
      final List<dynamic>? resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormaPagoScreen(venta: venta),
        ),
      );

      // Si el usuario canceló o regresó sin confirmar, no procesar la venta
      if (resultado == null || resultado.isEmpty) {
        setState(() {
          isProcessingVenta = false;
        });
        return;
      }

      // Si hay múltiples métodos de pago, usar el primero como principal
      // En el futuro se puede expandir para manejar múltiples métodos
      final primerPago = resultado.first;
      if (primerPago is PagoParcial) {
        venta.metodoPago = primerPago.metodo;
      }

      // Guardar la venta en la base de datos
      await VentasProvider().crearVenta(venta);

      // Mostrar animación de confirmación solo si se guardó la venta
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
                    Navigator.of(context).pop(); // cerrar animación
                    Navigator.of(context).pop(); // volver atrás
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
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Nueva Venta'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 1. Sección de selección de cliente
                  if (isSearching) ...[
                    // Header con información y estadísticas
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
                                  Icons.person_add,
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
                                      'Nueva Venta',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      'Selecciona un cliente para comenzar',
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
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar por nombre...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey.shade400,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            clientesFiltrados = [];
                                            errorMessage = null;
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
                                errorText: errorMessage,
                              ),
                              cursorColor: AppTheme.primaryColor,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Resultados de búsqueda o estado vacío
                    if (isLoadingClientes)
                      Container(
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
                                'Buscando clientes...',
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
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
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
                                    'Clientes encontrados (${clientesFiltrados.length})',
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
                              itemCount: clientesFiltrados.length.clamp(0, 4),
                              itemBuilder: (context, index) {
                                final cliente = clientesFiltrados[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: index % 2 == 0
                                        ? Colors.white
                                        : AppTheme.secondaryColor
                                            .withOpacity(0.3),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primaryColor,
                                      radius: 20,
                                      child: Text(
                                        cliente.nombre.isNotEmpty
                                            ? cliente.nombre[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      cliente.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: cliente.direccion != null &&
                                            cliente.direccion!.isNotEmpty
                                        ? Text(
                                            cliente.direccion!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : null,
                                    trailing: cliente.deuda != null &&
                                            cliente.deuda! > 0
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Deuda: \$${_formatearPrecio(cliente.deuda!.toDouble())}',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                    onTap: () => seleccionarCliente(cliente),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    else if (_searchController.text.isNotEmpty &&
                        !isLoadingClientes)
                      Container(
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
                                'No se encontraron clientes',
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
                      )
                    else
                      // Estado inicial - Pantalla de bienvenida
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.storefront,
                                size: 60,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '¡Comienza una nueva venta!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Busca un cliente por nombre para comenzar a agregar productos',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickActionCard(
                                    icon: Icons.qr_code_scanner,
                                    title: 'Escanear QR',
                                    subtitle: 'Cliente frecuente',
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Función de escáner QR próximamente'),
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickActionCard(
                                    icon: Icons.person_add,
                                    title: 'Nuevo Cliente',
                                    subtitle: 'Registrar',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                NuevoClienteScreen()),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ] else ...[
                    // Cliente seleccionado
                    Container(
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
                          // Sección superior con información del cliente
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        clienteSeleccionado!.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (clienteSeleccionado!.deuda != null &&
                                          clienteSeleccionado!.deuda! > 0) ...[
                                        Text(
                                          'Deuda: \$${_formatearPrecio(clienteSeleccionado!.deuda!.toDouble())}',
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
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
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
                          // Botón de agregar productos integrado
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.addGreenColor.withOpacity(0.3),
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
                                      builder: (context) =>
                                          SeleccionarProductosScreen(
                                        productosYaSeleccionados:
                                            productosSeleccionados,
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
                                      content: Text(
                                          'Error al seleccionar productos: $e'),
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
                    // Lista de productos seleccionados
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 500,
                      child: productosSeleccionados.isEmpty
                          ? Center(
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
                            )
                          : ListView.builder(
                              itemCount: productosSeleccionados.length,
                              itemBuilder: (context, index) {
                                final ps = productosSeleccionados[index];
                                final subtotal =
                                    ps.producto.precio * ps.cantidad;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: index % 2 == 0
                                        ? Colors.white
                                        : AppTheme.primaryColor
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Slidable(
                                    key: ValueKey(ps.producto.id),
                                    endActionPane: ActionPane(
                                      motion: const DrawerMotion(),
                                      extentRatio: 0.3,
                                      children: [
                                        SlidableAction(
                                          onPressed: (_) =>
                                              _eliminarProducto(index),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  ps.producto.nombre,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '\$${ps.producto.precio.toStringAsFixed(0).replaceAllMapped(
                                                        RegExp(
                                                            r'(\d)(?=(\d{3})+(?!\d))'),
                                                        (match) =>
                                                            '${match[1]}.',
                                                      )} c/u',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Controles de cantidad compactos
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Botón menos
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.remove,
                                                  color: Colors.red,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  final nuevaCantidad =
                                                      ps.cantidad - 1;
                                                  if (nuevaCantidad >= 0.5) {
                                                    _actualizarCantidad(
                                                        index, nuevaCantidad);
                                                  } else {
                                                    _eliminarProducto(index);
                                                  }
                                                },
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 32,
                                                  minHeight: 32,
                                                ),
                                              ),

                                              // Campo cantidad
                                              Container(
                                                width: 60,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey.shade300),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  color: Colors.white,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    ps.cantidad % 1 == 0
                                                        ? ps.cantidad
                                                            .toInt()
                                                            .toString()
                                                        : ps.cantidad
                                                            .toStringAsFixed(1),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),

                                              // Botón más
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.add,
                                                  color: Colors.green,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  _actualizarCantidad(
                                                      index, ps.cantidad + 1);
                                                },
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 32,
                                                  minHeight: 32,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(width: 12),

                                          // Subtotal
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              '\$${subtotal.toStringAsFixed(0).replaceAllMapped(
                                                    RegExp(
                                                        r'(\d)(?=(\d{3})+(?!\d))'),
                                                    (match) => '${match[1]}.',
                                                  )}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppTheme.primaryColor,
                                              ),
                                              textAlign: TextAlign.right,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
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
                  ],
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _puedeConfirmarVenta()
            ? Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      // Información del total
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$${_formatearPrecio(_calcularTotal())}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              '${productosSeleccionados.length} producto${productosSeleccionados.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
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
                          onPressed: isProcessingVenta ? null : _confirmarVenta,
                          style: AppTheme.elevatedButtonStyle(
                              AppTheme.addGreenColor),
                          icon: isProcessingVenta
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check_circle,
                                  color: Colors.white),
                          label: Text(
                            isProcessingVenta
                                ? 'Procesando...'
                                : 'Confirmar Venta',
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
              )
            : null);
  }
}
