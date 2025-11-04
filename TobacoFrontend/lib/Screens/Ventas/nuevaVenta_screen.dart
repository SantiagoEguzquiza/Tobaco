import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Screens/Clientes/wizardNuevoCliente_screen.dart';
import 'package:tobaco/Screens/Ventas/metodoPago_screen.dart';
import 'package:tobaco/Screens/Ventas/seleccionarProducto_screen.dart';
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
  Timer? _debounceTimer;
  String? errorMessage;
  VentaBorradorProvider? _borradorProvider; // Referencia al provider
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
    _borradorProvider ??= Provider.of<VentaBorradorProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    // Solo guardar borrador si la venta NO se completó
    if (!_ventaCompletada) {
      _guardarBorradorAlSalir();
    }
    super.dispose();
  }

  /// Verifica si existe un borrador y muestra diálogo para recuperarlo
  Future<void> _verificarYCargarBorrador() async {
    final borradorProvider = Provider.of<VentaBorradorProvider>(context, listen: false);
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
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
                
                // Contenido
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade700
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          '¿Deseas continuar con esta venta o empezar una nueva?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade300
                                : Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Botones
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop('nueva'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            Icons.add_circle_outline,
                            size: 20,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                          label: Text(
                            'Nueva Venta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop('continuar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Continuar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(10),
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

  /// Widget para mostrar información del borrador (método anterior - mantener por compatibilidad)
  Widget _buildBorradorInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
      message: '¿Estás seguro de que deseas cancelar esta venta? Se perderán todos los datos ingresados.',
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

  /// Muestra diálogo preguntando cómo quiere asignar la venta
  /// Retorna: 'a_mi', 'automatico', o null (cancelar)
  Future<String?> _mostrarDialogoAsignacionVenta(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.assignment, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Text('Asignar Venta'),
            ],
          ),
          content: const Text(
            '¿Cómo deseas asignar esta venta?\n\n'
            '• Asignarme a mí: La venta aparecerá en "Mis Entregas"\n'
            '• Asignar automáticamente: Se asignará a otro repartidor disponible\n'
            '• Cancelar: Dejar sin asignar',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('automatico'),
              child: Text(
                'Automático',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('a_mi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Asignarme a mí'),
            ),
          ],
        );
      },
    );
  }

  /// Asigna la venta automáticamente a otro repartidor
  Future<void> _asignarVentaAutomaticamente(
    VentasProvider ventasProvider,
    int ventaId,
    int usuarioIdExcluir,
  ) async {
    try {
      final resultado = await ventasProvider.asignarVentaAutomaticamente(ventaId, usuarioIdExcluir);
      
      if (mounted) {
        if (resultado['asignada'] == true) {
          final nombreAsignado = resultado['usuarioAsignadoNombre'];
          await AppDialogs.showSuccessDialog(
            context: context,
            title: 'Venta Asignada',
            message: nombreAsignado != null
                ? 'La venta se asignó automáticamente a: $nombreAsignado'
                : 'Venta asignada exitosamente',
            buttonText: 'Entendido',
          );
        } else {
          AppTheme.showSnackBar(
            context,
            AppTheme.errorSnackBar(resultado['message'] ?? 'No se pudo asignar la venta'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al asignar la venta: $e'),
        );
      }
    }
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
      final provider = Provider.of<ClienteProvider>(context, listen: false);
      final clientes = await provider.obtenerClientes();
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
    final tieneDeuda = (String? deuda) {
      if (deuda == null) return false;
      return double.tryParse(deuda.toString()) != null && double.parse(deuda.toString()) > 0;
    };
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: clientes.length.clamp(0, 4),
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        final tieneDeudaCliente = tieneDeuda(cliente.deuda);
        
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
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
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
                        borderRadius: BorderRadius.circular(2),
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
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : AppTheme.textColor,
                            ),
                          ),
                          if (cliente.direccion != null && cliente.direccion!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    cliente.direccion!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).brightness == Brightness.dark
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
                                  color: Theme.of(context).brightness == Brightness.dark
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
                                    border: Border.all(color: Colors.red.shade200),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 40,
                color: isDark 
                    ? Colors.grey.shade400 
                    : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: isDark 
                    ? Colors.grey.shade300 
                    : Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro término de búsqueda',
              style: TextStyle(
                color: isDark 
                    ? Colors.grey.shade400 
                    : Colors.grey.shade500,
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
    _guardarBorrador(); // Guardar borrador al seleccionar cliente
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
      _guardarBorrador(); // Guardar borrador con precios especiales actualizados
    } catch (e) {
      print('Error cargando precios especiales: $e');
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
    });

    try {
      await provider.buscarClientes(trimmedQuery);
      
      if (!mounted) return;
      
      // Obtener los resultados del provider después de la búsqueda
      final clientes = provider.clientes;
      
      setState(() {
        clientesFiltrados = clientes;
        isLoadingClientes = false;
        if (clientes.isEmpty) {
          errorMessage = 'No se encontraron clientes con ese nombre';
        }
      });
    } catch (e) {
      debugPrint('Error al buscar clientes: $e');
      if (!mounted) return;
      
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

      // Obtener usuario actual y asignarlo como creador
      final usuario = await AuthService.getCurrentUser();
      if (usuario != null) {
        ventaConPagos.usuarioIdCreador = usuario.id;
        ventaConPagos.usuarioCreador = usuario;
      }
      
      // Crear la venta
      final ventasProvider = Provider.of<VentasProvider>(context, listen: false);
      final result = await ventasProvider.crearVenta(ventaConPagos);

      if (mounted) {
        if (!result['success']) {
          throw Exception(result['message']);
        }

        // Mostrar mensaje offline INMEDIATAMENTE si aplica, antes de cualquier otra operación
        if (result['isOffline']) {
          // Usar un microtask para asegurar que el diálogo aparezca en el siguiente frame
          await Future.microtask(() async {
            if (mounted) {
              await AppDialogs.showWarningDialog(
                context: context,
                title: 'Venta guardada offline',
                message: 'Venta guardada localmente. Se sincronizará cuando haya conexión.',
                buttonText: 'Entendido',
                icon: Icons.cloud_off,
              );
            }
          });
        }

        // Manejar asignación según el tipo de empleado (en background si es offline)
        if (!result['isOffline'] && result['ventaId'] != null) {
          final usuario = await AuthService.getCurrentUser();
          if (usuario != null && (usuario.isEmployee || usuario.isAdmin)) {
            // RepartidorVendedor se asigna automáticamente a sí mismo sin diálogo
            if (usuario.esRepartidorVendedor) {
              try {
                await ventasProvider.asignarVenta(result['ventaId'], usuario.id);
                if (mounted) {
                  AppTheme.showSnackBar(
                    context,
                    AppTheme.successSnackBar('Venta asignada a ti exitosamente'),
                  );
                }
              } catch (e) {
                if (mounted) {
                  AppTheme.showSnackBar(
                    context,
                    AppTheme.errorSnackBar('Error al asignar la venta: $e'),
                  );
                }
              }
            } else if (usuario.esVendedor) {
              // Vendedor: mostrar diálogo informativo de que la venta queda pendiente de asignación
              if (mounted) {
                await AppDialogs.showWarningDialog(
                  context: context,
                  title: 'Venta Creada',
                  message: 'Queda la venta pendiente de asignación para repartir o entregar',
                  buttonText: 'Entendido',
                  icon: Icons.info_outline,
                );
              }
            } else {
              // Para otros tipos de empleados (Admin, Repartidor), mostrar el diálogo de asignación
              final opcionAsignacion = await _mostrarDialogoAsignacionVenta(context);
              
              if (mounted) {
                try {
                  if (opcionAsignacion == 'a_mi') {
                    // Asignarse a sí mismo
                    await ventasProvider.asignarVenta(result['ventaId'], usuario.id);
                    if (mounted) {
                      AppTheme.showSnackBar(
                        context,
                        AppTheme.successSnackBar('Venta asignada a ti exitosamente'),
                      );
                    }
                  } else if (opcionAsignacion == 'automatico') {
                    // Asignar automáticamente a otro repartidor
                    await _asignarVentaAutomaticamente(ventasProvider, result['ventaId'], usuario.id);
                  }
                  // Si es 'cancelar' o null, no hacer nada
                } catch (e) {
                  if (mounted) {
                    AppTheme.showSnackBar(
                      context,
                      AppTheme.errorSnackBar('Error al asignar la venta: $e'),
                    );
                  }
                }
              }
            }
          }
        }

        // Marcar que la venta se completó exitosamente
        _ventaCompletada = true;
        
        // Eliminar borrador después de confirmar la venta (de forma segura) en background
        _eliminarBorradorDeFormaSegura();

        // Mostrar animación de confirmación después del diálogo
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
                              _guardarBorrador(); // Guardar borrador con productos actualizados
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
                            _guardarBorrador(); // Guardar borrador al eliminar producto
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
                                _guardarBorrador(); // Guardar borrador con productos actualizados
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
                              const SizedBox(height: 4),
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