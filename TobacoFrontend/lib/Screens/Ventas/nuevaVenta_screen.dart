import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Screens/Ventas/metodoPago_screen.dart';
import 'package:tobaco/Screens/Ventas/seleccionarProducto_screen.dart'
    hide Container;
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';

import 'package:tobaco/Services/PrecioEspecialService.dart';
import 'package:tobaco/Services/VentaBorrador_Service/venta_borrador_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Theme/confirmAnimation.dart';
import 'package:tobaco/Screens/Ventas/resumenVenta_screen.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';
import 'package:tobaco/Helpers/api_handler.dart';

// Nuevos widgets modulares
import 'NuevaVenta/widgets/widgets.dart';

class NuevaVentaScreen extends StatefulWidget {
  final Cliente? clientePreSeleccionado;

  const NuevaVentaScreen({super.key, this.clientePreSeleccionado});

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
  final Map<int, TextEditingController> _cantidadControllers = {};
  final Set<int> _productosSeleccionadosExpandidos = {};
  Timer? _debounceTimer;
  String? errorMessage;
  VentaBorradorProvider? _borradorProvider; // Referencia al provider
  ClienteProvider? _clienteProvider; // Referencia al provider global de clientes
  bool _ventaCompletada = false; // Flag para saber si la venta se completó

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Si hay un cliente pre-seleccionado, usarlo inmediatamente
    if (widget.clientePreSeleccionado != null) {
      clienteSeleccionado = widget.clientePreSeleccionado;
      isSearching = false;
    }
    _cargarClientesIniciales();
    // Cargar borrador después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarYCargarBorrador();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Guardar referencia al provider de manera segura
    _borradorProvider ??=
        Provider.of<VentaBorradorProvider>(context, listen: false);

    // Suscribirse (una sola vez) al ClienteProvider global para reaccionar a
    // cambios de deuda (ej. tras un abono en cuenta corriente).
    if (_clienteProvider == null) {
      _clienteProvider = Provider.of<ClienteProvider>(context, listen: false);
      _clienteProvider!.addListener(_onClientesActualizados);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    for (final controller in _cantidadControllers.values) {
      controller.dispose();
    }
    _clienteProvider?.removeListener(_onClientesActualizados);
    // Solo guardar borrador si la venta NO se completó
    if (!_ventaCompletada) {
      _guardarBorradorAlSalir();
    }
    super.dispose();
  }

  /// Handler que se dispara cuando el ClienteProvider global cambia
  /// (ej. se registró un abono o se actualizó la deuda de un cliente).
  /// Actualiza `clientesIniciales` y re-filtra si hay búsqueda activa.
  void _onClientesActualizados() {
    if (!mounted) return;
    final provider = _clienteProvider;
    if (provider == null) return;

    final clientesProvider = provider.clientes;
    if (clientesProvider.isEmpty) return;

    final nuevosClientes = clientesProvider
        .where((c) => !_esConsumidorFinal(c))
        .toList()
      ..sort((a, b) =>
          a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    // Sincroniza también el cliente seleccionado (si corresponde) para que la
    // deuda mostrada en el resumen quede actualizada.
    Cliente? clienteSeleccionadoActualizado;
    if (clienteSeleccionado?.id != null) {
      final match = clientesProvider
          .where((c) => c.id == clienteSeleccionado!.id)
          .toList();
      if (match.isNotEmpty) clienteSeleccionadoActualizado = match.first;
    }

    setState(() {
      clientesIniciales = nuevosClientes;
      if (clienteSeleccionadoActualizado != null) {
        clienteSeleccionado = clienteSeleccionadoActualizado;
      }
      if (_searchController.text.trim().isNotEmpty) {
        _filtrarClientesIniciales(_searchController.text);
      }
    });
  }

  /// Verifica si existe un borrador y muestra diálogo para recuperarlo
  Future<void> _verificarYCargarBorrador() async {
    final borradorProvider =
        Provider.of<VentaBorradorProvider>(context, listen: false);
    await borradorProvider.cargarBorradorInicial();

    if (!mounted) return;

    final borrador = borradorProvider.borradorActual;
    if (borrador != null && borrador.tieneContenido) {
      _mostrarDialogoRecuperarBorrador(borrador, borradorProvider);
    }
  }

  /// Muestra diálogo preguntando si desea continuar con la venta en borrador
  Future<void> _mostrarDialogoRecuperarBorrador(
    dynamic borrador,
    VentaBorradorProvider borradorProvider,
  ) async {
    final tiempoTranscurrido = borradorProvider.getTiempoTranscurrido();

    final resultado = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final maxHeight = (screenHeight * 0.85).clamp(280.0, 500.0);
        return Dialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          child: Container(
            constraints: BoxConstraints(maxWidth: 380, maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Header con gradiente
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.restore,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Venta en Curso',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Shippori',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido scrollable para evitar overflow en pantallas pequeñas
                Flexible(
                  child: Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    child: SingleChildScrollView(
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tienes una venta sin completar.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Información del borrador con tarjetas
                      if (borrador.cliente != null) ...[
                        _buildInfoCard(
                          context,
                          Icons.person,
                          'Cliente',
                          borrador.cliente!.nombre,
                          AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (borrador.productosSeleccionados.isNotEmpty) ...[
                        _buildInfoCard(
                          context,
                          Icons.shopping_cart,
                          'Productos',
                          '${borrador.productosSeleccionados.length} producto${borrador.productosSeleccionados.length > 1 ? 's' : ''}',
                          Colors.blue.shade600,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildInfoCard(
                        context,
                        Icons.access_time,
                        'Última modificación',
                        tiempoTranscurrido,
                        Colors.orange.shade600,
                      ),

                      const SizedBox(height: 24),

                      // Pregunta
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800.withOpacity(0.5)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          '¿Deseas continuar con esta venta o empezar una nueva?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botones: en ancho chico se apilan para evitar texto truncado
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stackButtons = constraints.maxWidth < 280;

                      Widget nuevaVentaButton() {
                        return SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop('nueva'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              side: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Nueva Venta',
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      Widget continuarButton() {
                        return SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop('continuar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                const Flexible(
                                  child: Text(
                                    'Continuar',
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (stackButtons) {
                        return Column(
                          children: [
                            SizedBox(width: double.infinity, child: nuevaVentaButton()),
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: continuarButton()),
                          ],
                        );
                      }

                      return SizedBox(
                        height: 52,
                        child: Row(
                          children: [
                            Expanded(child: nuevaVentaButton()),
                            const SizedBox(width: 12),
                            Expanded(child: continuarButton()),
                          ],
                        ),
                      );
                    },
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
          ),
        );
      },
    );

    if (resultado == 'continuar') {
      _cargarDatosDesdeBorrador(borrador);
    } else if (resultado == 'nueva') {
      await borradorProvider.limpiarYCrearNuevo();
    }
  }

  /// Widget para mostrar información del borrador con tarjetas elegantes
  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carga los datos desde el borrador al estado actual
  void _cargarDatosDesdeBorrador(dynamic borrador) {
    setState(() {
      if (borrador.cliente != null) {
        clienteSeleccionado = borrador.cliente;
        isSearching = false;
      }
      productosSeleccionados = List.from(borrador.productosSeleccionados);
      preciosEspeciales = Map.from(borrador.preciosEspeciales);
    });
    _refreshCantidadControllers();
  }

  /// Guarda el estado actual al borrador al salir de la pantalla
  void _guardarBorradorAlSalir() {
    // Solo guardar si la venta no se completó y hay contenido
    if (!_ventaCompletada &&
        (clienteSeleccionado != null || productosSeleccionados.isNotEmpty) &&
        _borradorProvider != null) {
      // Usar un microtask para evitar problemas con el tree lock
      Future.microtask(() async {
        try {
          await _borradorProvider!.actualizarBorrador(
            cliente: clienteSeleccionado,
            productos: productosSeleccionados,
            preciosEspeciales: preciosEspeciales,
          );
        } catch (e) {
          debugPrint('Error al guardar borrador al salir: $e');
        }
      });
    }
  }

  /// Guarda el borrador actual
  Future<void> _guardarBorrador() async {
    if (_borradorProvider != null) {
      await _borradorProvider!.actualizarBorrador(
        cliente: clienteSeleccionado,
        productos: productosSeleccionados,
        preciosEspeciales: preciosEspeciales,
      );
    }
  }

  /// Elimina el borrador de forma segura sin bloquear la UI
  void _eliminarBorradorDeFormaSegura() {
    if (_borradorProvider != null) {
      // Usar un microtask para evitar bloquear el tree
      Future.microtask(() async {
        try {
          await _borradorProvider!.eliminarBorrador();
        } catch (e) {
          debugPrint('Error al eliminar borrador: $e');
        }
      });
    }
  }

  /// Muestra diálogo para cancelar la venta actual
  Future<void> _mostrarDialogoCancelarVenta() async {
    final confirmar = await AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Cancelar Venta',
      message:
          '¿Estás seguro de que deseas cancelar esta venta? Se perderán todos los datos ingresados.',
      confirmText: 'Cancelar Venta',
      cancelText: 'Volver',
      icon: Icons.cancel,
      iconColor: Colors.red,
    );

    if (confirmar == true) {
      _eliminarBorradorDeFormaSegura();

      if (mounted) {
        Navigator.of(context).pop();
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Venta cancelada'),
        );
      }
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      // Solo filtrar localmente, sin consultar API
      buscarClientesLocal(_searchController.text);
    });
  }

  /// Verifica si un cliente es "Consumidor Final"
  bool _esConsumidorFinal(Cliente cliente) {
    return cliente.nombre.trim().toLowerCase() == 'consumidor final';
  }

  Future<void> _cargarClientesIniciales() async {
    setState(() {
      isLoadingClientesIniciales = true;
    });

    final provider = Provider.of<ClienteProvider>(context, listen: false);

    // 1) Mostrar de inmediato lo que haya en caché (rápido, sin red).
    try {
      final clientesCache = await provider.obtenerClientesDelCache();
      if (mounted && clientesCache.isNotEmpty) {
        setState(() {
          clientesIniciales = clientesCache
              .where((c) => !_esConsumidorFinal(c))
              .toList()
            ..sort((a, b) =>
                a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
          isLoadingClientesIniciales = false;
        });
        debugPrint(
            '✅ Clientes iniciales cargados desde caché: ${clientesIniciales.length}');
      }
    } catch (e) {
      debugPrint('⚠️ Error leyendo caché de clientes: $e');
    }

    // 2) Revalidar SIEMPRE contra el servidor en background para captar
    // cambios hechos por otros usuarios (o desde otras pantallas). El
    // provider global grabará caché y notificará: el listener actualiza la
    // UI automáticamente.
    unawaited(_refrescarClientesEnBackground(provider));
  }

  /// Trae la lista de clientes desde el servidor sin bloquear la UI.
  /// El provider global grabará caché y notificará: el listener
  /// `_onClientesActualizados` se encarga de refrescar la UI.
  /// Solo maneja aquí el fallback de apagar el spinner si todavía no había
  /// datos al momento del error.
  Future<void> _refrescarClientesEnBackground(
      ClienteProvider provider) async {
    try {
      final clientes = await provider.obtenerClientes();
      if (!mounted) return;

      // Apagar spinner si no estaba apagado (caché estaba vacío y recién
      // llega el servidor). El listener ya habrá puesto la lista.
      if (isLoadingClientesIniciales) {
        setState(() {
          isLoadingClientesIniciales = false;
        });
      }

      debugPrint(
          '✅ Clientes revalidados desde servidor: ${clientes.length}');
    } catch (e) {
      debugPrint('⚠️ Error revalidando clientes en background: $e');
      if (!mounted) return;
      if (clientesIniciales.isEmpty) {
        setState(() {
          isLoadingClientesIniciales = false;
        });
      }
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
      // Excluir "Consumidor Final" de los resultados de búsqueda
      if (_esConsumidorFinal(cliente)) return false;
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
    bool tieneDeuda(String? deuda) {
      if (deuda == null) return false;
      return double.tryParse(deuda.toString()) != null &&
          double.parse(deuda.toString()) > 0;
    }

    // Filtrar "Consumidor Final" de la lista antes de mostrar
    final clientesFiltrados = clientes.where((c) => !_esConsumidorFinal(c)).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: clientesFiltrados.length, // Mostrar TODOS los clientes
      itemBuilder: (context, index) {
        final cliente = clientesFiltrados[index];
        final tieneDeudaCliente = tieneDeuda(cliente.deuda);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
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
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _seleccionarCliente(cliente),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Indicador lateral
                    Container(
                      width: 4,
                      height: 60,
                      decoration: BoxDecoration(
                        color: tieneDeudaCliente
                            ? Colors.red
                            : AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Información del cliente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente.nombre,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : AppTheme.textColor,
                            ),
                          ),
                          if (cliente.direccion != null &&
                              cliente.direccion!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    cliente.direccion!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (tieneDeudaCliente) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  size: 16,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Text(
                                    'Deuda: \$${cliente.deuda}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2F2F2F) : Colors.white,
        borderRadius: BorderRadius.circular(8),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 40,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro término de búsqueda',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Estado vacío cuando no hay clientes (igual que listado de clientes).
  /// El usuario puede deslizar hacia abajo para refrescar.
  Widget _buildEmptyStateConRefresh() {
    return Container(
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay clientes registrados',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade300
                      : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Crea tu primer cliente para comenzar',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sección de productos
  Widget _buildProductsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Productos ( ${productosSeleccionados.length} )',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.borderRadiusCards),
          bottomRight: Radius.circular(AppTheme.borderRadiusCards),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: productosSeleccionados.length,
          itemBuilder: (context, index) {
            final producto = productosSeleccionados[index];
            final precioFinal = _calcularPrecioFinalProducto(producto);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final backgroundColor = isDark
                ? (index.isEven
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF252525))
                : (index.isEven ? Colors.white : Colors.grey.shade50);
            final unitTextColor =
                isDark ? Colors.grey.shade300 : Colors.grey.shade700;
            final accentColor =
                isDark ? Colors.white : AppTheme.primaryColor;

            return Slidable(
              key: ValueKey(producto.id),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (_) async {
                      final confirm =
                          await AppDialogs.showDeleteConfirmationDialog(
                        context: context,
                        title: 'Eliminar Producto',
                        message:
                            '¿Está seguro de que desea eliminar ${producto.nombre}?',
                      );
                      if (confirm == true) {
                        final productoId = producto.id;
                        setState(() {
                          productosSeleccionados.removeAt(index);
                          _productosSeleccionadosExpandidos.remove(productoId);
                        });
                        _removeCantidadController(productoId);
                        _guardarBorrador();
                      }
                    },
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outline,
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
              child: SizedBox(
                height: 80,
                child: Stack(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_productosSeleccionadosExpandidos
                              .contains(producto.id)) {
                            _productosSeleccionadosExpandidos.remove(producto.id);
                          } else {
                            _productosSeleccionadosExpandidos.add(producto.id);
                          }
                        });
                      },
                      child: Container(
                        color: backgroundColor,
                        padding: EdgeInsets.only(
                          left: 16,
                          right: _productosSeleccionadosExpandidos
                                  .contains(producto.id)
                              ? (AppTheme.isCompactVentasButton(context)
                                  ? 128
                                  : 150)
                              : 16,
                          top: 10,
                          bottom: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    producto.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '\$ ${_formatearPrecio(precioFinal)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: unitTextColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'c/u',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                      if (producto.stock != null) ...[
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Expanded(
                                                child: _maxCantidadDisponible(producto) == 0
                                                    ? Text(
                                                        'Sin stock',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.orange.shade700,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      )
                                                    : Text(
                                                        'Disponible: ${_maxCantidadDisponible(producto).toStringAsFixed(0)}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isDark
                                                              ? Colors.grey.shade500
                                                              : Colors.grey.shade600,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                              ),
                                              if (producto.stock != null && producto.cantidad > _maxCantidadDisponible(producto))
                                                Icon(Icons.warning_amber_rounded,
                                                    size: 14, color: Colors.orange.shade700),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withOpacity(isDark ? 0.25 : 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'x${producto.cantidad % 1 == 0 ? producto.cantidad.toInt() : producto.cantidad.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '\$ ${_formatearPrecio(precioFinal * producto.cantidad)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _productosSeleccionadosExpandidos
                                      .contains(producto.id)
                                  ? Icons.keyboard_arrow_up
                                  : Icons.more_vert,
                              size: 22,
                              color: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: _productosSeleccionadosExpandidos
                                .contains(producto.id)
                            ? Container(
                                color: backgroundColor,
                                padding: EdgeInsets.only(
                                  right: AppTheme.isCompactVentasButton(context)
                                      ? 4
                                      : 8,
                                  left: AppTheme.isCompactVentasButton(context)
                                      ? 4
                                      : 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                        size: AppTheme.isCompactVentasButton(context)
                                            ? 22
                                            : 24,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(
                                        minWidth:
                                            AppTheme.isCompactVentasButton(context)
                                                ? 32
                                                : 40,
                                        minHeight:
                                            AppTheme.isCompactVentasButton(context)
                                                ? 32
                                                : 40,
                                      ),
                                      onPressed: () => _ajustarCantidadProducto(
                                          producto, -1),
                                    ),
                                    Container(
                                      width: AppTheme.isCompactVentasButton(context)
                                          ? 46
                                          : 55,
                                      height: AppTheme.isCompactVentasButton(context)
                                          ? 34
                                          : 36,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: isDark
                                            ? const Color(0xFF1F1F1F)
                                            : Colors.white,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: TextField(
                                          controller:
                                              _getCantidadController(producto),
                                          textAlign: TextAlign.center,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                  decimal: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d{0,3}(\.\d{0,1})?$'),
                                            ),
                                          ],
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder: InputBorder.none,
                                            isCollapsed: true,
                                            contentPadding: EdgeInsets.symmetric(
                                                vertical: 6),
                                          ),
                                          style: TextStyle(
                                            fontSize:
                                                AppTheme.isCompactVentasButton(
                                                        context)
                                                    ? 14
                                                    : 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          onChanged: (value) {
                                            final nuevaCantidad =
                                                double.tryParse(value) ?? 0;
                                            _actualizarCantidadProductoSeleccionado(
                                              producto,
                                              nuevaCantidad,
                                              actualizarController: false,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.green,
                                        size: AppTheme.isCompactVentasButton(context)
                                            ? 22
                                            : 24,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(
                                        minWidth:
                                            AppTheme.isCompactVentasButton(context)
                                                ? 32
                                                : 40,
                                        minHeight:
                                            AppTheme.isCompactVentasButton(context)
                                                ? 32
                                                : 40,
                                      ),
                                      onPressed: () => _ajustarCantidadProducto(
                                          producto, 1),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
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
    );
  }

  double _calcularPrecioFinalProducto(ProductoSeleccionado producto) {
    // El precio en ProductoSeleccionado ya incluye:
    // - Precio especial (si existe)
    // - Packs (si aplica)
    // - Descuento del producto (si está activo)
    // Solo falta aplicar el descuento global del cliente
    
    // IMPORTANTE: Asegurar que el precio base nunca sea 0
    double precio = producto.precio;
    
    if (precio <= 0) {
      debugPrint('⚠️ ADVERTENCIA: Precio 0 en ProductoSeleccionado ${producto.nombre}, intentando obtener precio del producto original');
      // Si el precio es 0, intentar obtenerlo del producto original
      // Esto no debería pasar, pero es una medida de seguridad
      precio = producto.precio > 0 ? producto.precio : 0.0;
    }

    // Aplicar descuento global si existe
    if (clienteSeleccionado?.descuentoGlobal != null &&
        clienteSeleccionado!.descuentoGlobal > 0) {
      precio = precio - (precio * (clienteSeleccionado!.descuentoGlobal / 100));
    }
    
    // Verificación final: asegurar que el precio nunca sea negativo
    if (precio < 0) {
      debugPrint('⚠️ ADVERTENCIA: Precio negativo después de descuento para ${producto.nombre}, usando precio base');
      precio = producto.precio > 0 ? producto.precio : 0.0;
    }

    return precio;
  }

  void _refreshCantidadControllers() {
    final idsActuales = <int>{};
    for (final producto in productosSeleccionados) {
      idsActuales.add(producto.id);
      final formatted = _formatearCantidadInput(producto.cantidad);
      if (_cantidadControllers.containsKey(producto.id)) {
        if (_cantidadControllers[producto.id]!.text != formatted) {
          _cantidadControllers[producto.id]!.text = formatted;
        }
      } else {
        _cantidadControllers[producto.id] =
            TextEditingController(text: formatted);
      }
    }

    final idsAEliminar = _cantidadControllers.keys
        .where((id) => !idsActuales.contains(id))
        .toList();
    for (final id in idsAEliminar) {
      _cantidadControllers[id]?.dispose();
      _cantidadControllers.remove(id);
      _productosSeleccionadosExpandidos.remove(id);
    }
  }

  TextEditingController _getCantidadController(ProductoSeleccionado producto) {
    if (!_cantidadControllers.containsKey(producto.id)) {
      _cantidadControllers[producto.id] = TextEditingController(
        text: _formatearCantidadInput(producto.cantidad),
      );
    }
    return _cantidadControllers[producto.id]!;
  }

  void _removeCantidadController(int productId) {
    _cantidadControllers[productId]?.dispose();
    _cantidadControllers.remove(productId);
    _productosSeleccionadosExpandidos.remove(productId);
  }

  String _formatearCantidadInput(double cantidad) {
    return cantidad % 1 == 0
        ? cantidad.toInt().toString()
        : cantidad.toStringAsFixed(1);
  }

  /// Stock efectivo: stock del producto menos lo ya reservado en ventas offline pendientes de sync.
  double _maxCantidadDisponible(ProductoSeleccionado producto) {
    final reservada = context.read<VentasProvider>().cantidadReservadaOfflinePorProducto;
    final base = producto.stock ?? 999.0;
    final reservado = reservada[producto.id] ?? 0.0;
    return (base - reservado).clamp(0.0, double.infinity);
  }

  void _ajustarCantidadProducto(
      ProductoSeleccionado producto, double delta) {
    final maxDisp = _maxCantidadDisponible(producto);
    final nuevaCantidad =
        (producto.cantidad + delta).clamp(0.0, maxDisp).toDouble();
    _actualizarCantidadProductoSeleccionado(producto, nuevaCantidad);
  }

  void _actualizarCantidadProductoSeleccionado(
    ProductoSeleccionado producto,
    double nuevaCantidad, {
    bool actualizarController = true,
  }) {
    final maxCantidad = _maxCantidadDisponible(producto);
    final cantidadNormalizada = nuevaCantidad.clamp(0.0, maxCantidad).toDouble();
    setState(() {
      producto.cantidad = cantidadNormalizada;
    });

    if (actualizarController) {
      final controller = _cantidadControllers[producto.id];
      if (controller != null) {
        final formatted = _formatearCantidadInput(cantidadNormalizada);
        if (controller.text != formatted) {
          controller.text = formatted;
        }
      }
    }

    _guardarBorrador();
  }

  void _seleccionarCliente(Cliente cliente) {
    setState(() {
      clienteSeleccionado = cliente;
      isSearching = false;
      clientesFiltrados = [];
      _searchController.clear();
    });
    _cargarPreciosEspeciales();
    _guardarBorrador(); // Guardar borrador al seleccionar cliente
  }

  Future<void> _cargarPreciosEspeciales() async {
    if (clienteSeleccionado == null) return;
    final clienteId = clienteSeleccionado!.id;
    if (clienteId == null || clienteId <= 0) {
      setState(() {
        preciosEspeciales.clear();
      });
      return;
    }

    try {
      final precios =
          await PrecioEspecialService.getPreciosEspecialesByCliente(clienteId);
      setState(() {
        preciosEspeciales.clear();
        for (var precio in precios) {
          preciosEspeciales[precio.productoId] = precio.precio;
        }
      });
      _guardarBorrador(); // Guardar borrador con precios especiales actualizados
    } catch (e) {
      print('Error cargando precios especiales: $e');
    }
  }

  /// Busca clientes solo en la lista local (caché), sin consultar API
  void buscarClientesLocal(String query) {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      setState(() {
        clientesFiltrados = [];
        errorMessage = null;
        isLoadingClientes = false;
      });
      return;
    }

    // Filtrar desde clientesIniciales (que ya están cargados del caché)
    final queryLower = trimmedQuery.toLowerCase();
    final filtrados = clientesIniciales.where((cliente) {
      // Excluir "Consumidor Final" de los resultados de búsqueda
      if (_esConsumidorFinal(cliente)) return false;
      return cliente.nombre.toLowerCase().contains(queryLower);
    }).toList();

    // Ordenar: primero los que empiezan con el query, luego los que lo contienen
    // Cada grupo ordenado alfabéticamente
    final empiezaCon = filtrados
        .where((c) => c.nombre.toLowerCase().startsWith(queryLower))
        .toList();
    empiezaCon.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    
    final contiene = filtrados
        .where((c) => !c.nombre.toLowerCase().startsWith(queryLower))
        .toList();
    contiene.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    setState(() {
      clientesFiltrados = [...empiezaCon, ...contiene];
      isLoadingClientes = false;
      
      if (clientesFiltrados.isEmpty) {
        errorMessage = 'No se encontraron clientes con ese nombre';
      } else {
        errorMessage = null;
      }
    });
  }

  /// Actualiza la lista de clientes desde el servidor (para pull-to-refresh)
  Future<void> actualizarClientesDesdeServidor() async {
    setState(() {
      isLoadingClientesIniciales = true;
    });

    try {
      final provider = Provider.of<ClienteProvider>(context, listen: false);
      
      // Obtener clientes del servidor y actualizar caché
      final clientes = await provider.obtenerClientes();
      
      if (mounted) {
        setState(() {
          // Filtrar "Consumidor Final" de la lista inicial
          clientesIniciales = clientes.where((c) => !_esConsumidorFinal(c)).toList();
          
          // Ordenar alfabéticamente por nombre
          clientesIniciales.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
          
          isLoadingClientesIniciales = false;
          
          // Si hay una búsqueda activa, re-filtrar con los nuevos datos
          if (_searchController.text.trim().isNotEmpty) {
            buscarClientesLocal(_searchController.text);
          }
        });
        
        debugPrint('✅ Clientes actualizados desde servidor: ${clientesIniciales.length}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingClientesIniciales = false;
        });
      }
      debugPrint('Error al actualizar clientes desde servidor: $e');

      if (!mounted) return;
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al actualizar clientes'),
        );
      }
    }
  }

  void buscarClientes(String query) async {
    final trimmedQuery = query.trim();
    final provider = Provider.of<ClienteProvider>(context, listen: false);

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
      // Mantener los resultados locales mientras se carga del servidor
    });

    try {
      await provider.buscarClientes(trimmedQuery);

      if (!mounted) return;

      // Obtener los resultados del provider después de la búsqueda
      final clientes = provider.clientes;

      setState(() {
        // Filtrar "Consumidor Final" de los resultados de búsqueda
        final resultadosServidor = clientes.where((c) => !_esConsumidorFinal(c)).toList();
        
        // Solo actualizar si hay resultados o si el filtro local también está vacío
        if (resultadosServidor.isNotEmpty) {
          clientesFiltrados = resultadosServidor;
          errorMessage = null;
        } else if (clientesFiltrados.isEmpty) {
          // Solo mostrar error si tampoco hay resultados locales
          errorMessage = 'No se encontraron clientes con ese nombre';
        }
        // Si hay resultados locales y el servidor devuelve vacío, mantener los locales
        
        isLoadingClientes = false;
      });
    } catch (e) {
      debugPrint('Error al buscar clientes: $e');
      if (!mounted) return;

      setState(() => isLoadingClientes = false);

      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        setState(() {
          if (clientesFiltrados.isEmpty) {
            errorMessage = 'Error al buscar clientes. Mostrando resultados locales.';
          }
        });
      }
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
    _guardarBorrador(); // Guardar borrador al seleccionar cliente
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
    _refreshCantidadControllers();
    _searchController.clear();
  }

  double _calcularTotal() {
    // El precio en ProductoSeleccionado ya incluye el descuento del producto
    // (se aplica en seleccionarProducto_screen cuando se crea el ProductoSeleccionado)
    // IMPORTANTE: Asegurar que se calcule correctamente incluso con cantidades decimales (0.5)
    return productosSeleccionados.fold(
        0.0, (sum, ps) {
          // Calcular el precio final del producto (con descuento global aplicado)
          final precioFinalUnitario = _calcularPrecioFinalProducto(ps);
          
          // Asegurar que el precio unitario no sea 0
          final precioUnitarioValido = precioFinalUnitario > 0 
              ? precioFinalUnitario 
              : (ps.precio > 0 ? ps.precio : 0.0);
          
          // Asegurar que la cantidad sea válida
          final cantidad = ps.cantidad > 0 ? ps.cantidad : 0.0;
          
          // Calcular el subtotal: precio unitario final * cantidad
          // Esto asegura que las mitades (0.5) se calculen correctamente
          final subtotal = precioUnitarioValido * cantidad;
          
          debugPrint('💰 _calcularTotal: ${ps.nombre}, cantidad=$cantidad, precioUnitario=$precioUnitarioValido, subtotal=$subtotal');
          
          return sum + subtotal;
        });
  }

  double _calcularTotalConDescuento() {
    final subtotal = _calcularTotal();
    if (clienteSeleccionado != null &&
        clienteSeleccionado!.descuentoGlobal > 0) {
      final descuento = subtotal * (clienteSeleccionado!.descuentoGlobal / 100);
      return subtotal - descuento;
    }
    return subtotal;
  }

  double _calcularDescuento() {
    if (clienteSeleccionado != null &&
        clienteSeleccionado!.descuentoGlobal > 0) {
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
      message:
          '¿Está seguro de que desea finalizar la venta por \$${_formatearPrecio(_calcularTotalConDescuento())}?',
      confirmText: 'Finalizar Venta',
      cancelText: 'Cancelar',
      icon: Icons.shopping_cart_checkout,
      iconColor: Colors.green,
    );

    if (confirmar != true) return;

    setState(() {
      isProcessingVenta = true;
    });

    bool procesandoOverlayCerrado = false;
    try {
      final productos = productosSeleccionados
          .map((ps) {
            // Calcular el precio final del producto (con descuento global aplicado)
            final precioFinalUnitario = _calcularPrecioFinalProducto(ps);
            
            // Asegurar que el precio unitario no sea 0
            final precioUnitarioValido = precioFinalUnitario > 0 
                ? precioFinalUnitario 
                : (ps.precio > 0 ? ps.precio : 0.0);
            
            // El precio final calculado es el precio unitario final multiplicado por la cantidad
            // Esto asegura que las mitades (0.5) se calculen correctamente
            final precioFinalCalculado = precioUnitarioValido * ps.cantidad;
            
            debugPrint('💰 VentasProductos: ${ps.nombre}, cantidad=${ps.cantidad}, precioUnitario=$precioUnitarioValido, precioFinalCalculado=$precioFinalCalculado');
            
            return VentasProductos(
              productoId: ps.id,
              nombre: ps.nombre,
              marca: ps.marca,
              precio: ps.precio,
              cantidad: ps.cantidad,
              categoria: ps.categoria,
              categoriaId: ps.categoriaId,
              precioFinalCalculado: precioFinalCalculado,
            );
          })
          .toList();

      // Calcular el total antes de crear la venta y verificar que no sea 0
      final totalCalculado = _calcularTotalConDescuento();
      
      debugPrint('💰 Total calculado de la venta: $totalCalculado');
      debugPrint('💰 Productos en la venta: ${productos.length}');
      for (var p in productos) {
        debugPrint('   - ${p.nombre}: cantidad=${p.cantidad}, precio=${p.precio}, precioFinalCalculado=${p.precioFinalCalculado}');
      }
      
      // Si el total es 0 o negativo, recalcular usando los precios finales calculados
      double totalFinal = totalCalculado;
      if (totalCalculado <= 0) {
        debugPrint('⚠️ ERROR CRÍTICO: El total de la venta es 0 o negativo. Recalculando...');
        // Recalcular sumando los precios finales calculados de cada producto
        final totalRecalculado = productos.fold(0.0, (sum, p) => sum + p.precioFinalCalculado);
        debugPrint('💰 Total recalculado: $totalRecalculado');
        totalFinal = totalRecalculado > 0 ? totalRecalculado : totalCalculado;
      }
      
      final venta = Ventas(
        clienteId: clienteSeleccionado!.id ?? 0,
        cliente: clienteSeleccionado!,
        ventasProductos: productos,
        total: totalFinal,
        fecha: DateTime.now().toUtc(), // Enviar siempre en UTC al backend
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

      // Obtener usuario actual y asignarlo como creador
      final usuario = await AuthService.getCurrentUser();
      if (usuario != null) {
        ventaConPagos.usuarioIdCreador = usuario.id;
        ventaConPagos.usuarioCreador = usuario;
      }

      // Crear la venta - el provider se encarga de intentar servidor primero y fallback a local
      final ventasProvider =
          Provider.of<VentasProvider>(context, listen: false);

      // Mostrar overlay de "Procesando..." de inmediato para que el usuario vea feedback
      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (ctx) => PopScope(
            canPop: false,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).dialogBackgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Procesando venta...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(ctx).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      final result = await ventasProvider.crearVenta(ventaConPagos);

      // Cerrar overlay de "Procesando..." antes de mostrar la animación verde
      if (mounted) {
        Navigator.of(context).pop();
        procesandoOverlayCerrado = true;
      }

      if (mounted) {
        if (!result['success']) {
          throw Exception(result['message']);
        }

        // Propagar el aumento de deuda al ClienteProvider global si la venta
        // incluyó pagos con cuenta corriente. Esto mantiene la lista de
        // clientes y el caché al día sin esperar al refresh periódico.
        final montoCC =
            VentasProvider.calcularMontoCuentaCorriente(ventaConPagos);
        if (montoCC > 0 && ventaConPagos.clienteId > 0) {
          final clienteProviderGlobal =
              Provider.of<ClienteProvider>(context, listen: false);
          clienteProviderGlobal.ajustarDeudaCliente(
              ventaConPagos.clienteId, montoCC);
        }

        // Mensaje offline: se muestra en ResumenVentaScreen como "Guardada localmente"

        // Marcar que la venta se completó exitosamente
        _ventaCompletada = true;

        // Eliminar borrador después de confirmar la venta (de forma segura) en background
        _eliminarBorradorDeFormaSegura();

        // Mostrar animación de confirmación
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
                        builder: (context) => ResumenVentaScreen(
                          venta: ventaConPagos,
                        ),
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
      // Cerrar overlay "Procesando..." solo si aún está abierto (excepción durante la API)
      if (mounted && !procesandoOverlayCerrado) {
        try {
          Navigator.of(context).pop();
        } catch (_) {}
      }
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
        actions: [
          // Botón para cancelar venta (solo mostrar si hay contenido)
          if (clienteSeleccionado != null || productosSeleccionados.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancelar Venta',
              onPressed: _mostrarDialogoCancelarVenta,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header fijo cuando se está buscando
            if (isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: HeaderConBuscador(
                  leadingIcon: Icons.people,
                  title: 'Buscar Cliente',
                  subtitle: 'Selecciona un cliente para la venta',
                  controller: _searchController,
                  hintText: 'Buscar por nombre...',
                  onChanged: (value) {
                    // Solo actualizar estado local, el debounce se maneja en _onSearchChanged
                    setState(() {
                      if (value.trim().isEmpty) {
                        clientesFiltrados = [];
                        errorMessage = null;
                      } else {
                        _filtrarClientesIniciales(value);
                        // NO llamar buscarClientes aquí, se hace en _onSearchChanged con debounce
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
            // Contenido principal
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return isSearching && isLoadingClientesIniciales
                      ? Column(
                          children: [
                            SizedBox(
                              height:
                                  AppTheme.isCompactVentasButton(context) ? 8 : 16,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final cliente = await VentasProvider
                                        .obtenerOCrearConsumidorFinal(
                                      context: context,
                                      clientesIniciales: clientesIniciales,
                                      clientesFiltrados: clientesFiltrados,
                                      clienteSeleccionado:
                                          clienteSeleccionado,
                                    );

                                    if (cliente != null) {
                                      _seleccionarCliente(cliente);

                                      if (!mounted) return;
                                      setState(() {
                                        clientesFiltrados = [];
                                        errorMessage = null;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: AppTheme.ventasButtonPadding(context),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: Icon(
                                    Icons.person_outline,
                                    color: Colors.white,
                                    size: AppTheme.ventasButtonIconSize(context),
                                  ),
                                  label: Text(
                                    'Consumidor Final',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: AppTheme.ventasButtonFontSize(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height:
                                  AppTheme.isCompactVentasButton(context) ? 8 : 16,
                            ),
                            // Estado de carga que ocupa el espacio restante
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.black.withOpacity(0.3)
                                            : Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
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
                                ),
                              ),
                            ),
                          ],
                        )
                      : RefreshIndicator(
                          color: AppTheme.primaryColor,
                          onRefresh: actualizarClientesDesdeServidor,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Column(
                              children: [
                                if (isSearching) ...[
                                SizedBox(
                                  height:
                                      AppTheme.isCompactVentasButton(context) ? 8 : 16,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final cliente = await VentasProvider
                                            .obtenerOCrearConsumidorFinal(
                                          context: context,
                                          clientesIniciales:
                                              clientesIniciales,
                                          clientesFiltrados:
                                              clientesFiltrados,
                                          clienteSeleccionado:
                                              clienteSeleccionado,
                                        );

                                        if (cliente != null) {
                                          _seleccionarCliente(cliente);

                                          if (!mounted) return;
                                          setState(() {
                                            clientesFiltrados = [];
                                            errorMessage = null;
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: AppTheme.ventasButtonPadding(context),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        elevation: 2,
                                      ),
                                      icon: Icon(
                                        Icons.person_outline,
                                        color: Colors.white,
                                        size: AppTheme.ventasButtonIconSize(context),
                                      ),
                                      label: Text(
                                        'Consumidor Final',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: AppTheme.ventasButtonFontSize(context),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      AppTheme.isCompactVentasButton(context) ? 8 : 16,
                                ),

                                // Lista de clientes
                                if (clientesFiltrados.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.zero,
                                    child: _buildClientesList(
                                        clientesFiltrados, 'Clientes encontrados'),
                                  )
                                else if (clientesIniciales.isNotEmpty &&
                                    _searchController.text.trim().isEmpty)
                                  Padding(
                                    padding: EdgeInsets.zero,
                                    child: _buildClientesList(
                                        clientesIniciales, 'Clientes disponibles'),
                                  )
                                else if (_searchController.text
                                    .trim()
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 16.0),
                                    child: _buildEmptyState(
                                        'No se encontraron clientes con ese nombre'),
                                  )
                                else
                                  // Estado vacío con altura mínima para centrar verticalmente
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: SizedBox(
                                      height: (MediaQuery.of(context).size.height - 320).clamp(200.0, 400.0),
                                      child: _buildEmptyStateConRefresh(),
                                    ),
                                  ),
                              ] else ...[
                                // Cliente seleccionado
                                ClienteSection(
                                  cliente: clienteSeleccionado!,
                                  onCambiarCliente: cambiarCliente,
                                ),

                                // Botón agregar productos
                                AgregarProductoButton(
                                  onPressed: () async {
                                    try {
                                      final resultado = await Navigator.of(
                                              context,
                                              rootNavigator: true)
                                          .push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SeleccionarProductosScreen(
                                            productosYaSeleccionados:
                                                productosSeleccionados,
                                            cliente: clienteSeleccionado,
                                          ),
                                        ),
                                      );

                                      if (resultado != null &&
                                          resultado
                                              is List<ProductoSeleccionado>) {
                                        setState(() {
                                          productosSeleccionados = resultado;
                                        });
                                        _refreshCantidadControllers();
                                        _guardarBorrador(); // Guardar borrador con productos actualizados
                                      }
                                    } catch (e) {
                                      AppTheme.showSnackBar(
                                        context,
                                        AppTheme.errorSnackBar(
                                            'Error al seleccionar productos: $e'),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Lista de productos o estado vacío

                                if (productosSeleccionados.isNotEmpty) ...[
                                  _buildProductsSection(),
                                ] else ...[
                                  SizedBox(
                                    height: (constraints.maxHeight - 220).clamp(200.0, 900.0),
                                    child: Center(
                                      child: const EmptyStateVenta(),
                                    ),
                                  ),
                                ],
                              ],
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
