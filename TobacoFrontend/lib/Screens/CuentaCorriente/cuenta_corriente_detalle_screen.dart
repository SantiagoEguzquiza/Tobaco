import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/Abono.dart';
import 'package:tobaco/Models/ProductoAFavor.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Services/Abonos_Service/abonos_provider.dart';
import 'package:tobaco/Services/ProductosAFavor_Service/producto_a_favor_service.dart';
import 'package:tobaco/Services/Cache/cuenta_corriente_cache_service.dart';
import 'package:tobaco/Models/cuenta_corriente_movimiento.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Screens/Ventas/detalleVentas_screen.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'dart:developer';

class CuentaCorrienteDetalleScreen extends StatefulWidget {
  final Cliente cliente;

  const CuentaCorrienteDetalleScreen({super.key, required this.cliente});

  @override
  State<CuentaCorrienteDetalleScreen> createState() => _CuentaCorrienteDetalleScreenState();
}

class _CuentaCorrienteDetalleScreenState extends State<CuentaCorrienteDetalleScreen> {
  
  int _selectedTabIndex = 0;
  bool isLoadingVentas = true;
  bool isLoadingAbonos = true;
  bool isLoadingDetalle = true;
  
  List<Ventas> ventasCC = [];
  List<Abono> abonos = [];
  List<ProductoAFavor> productosAFavor = [];
  List<CuentaCorrienteMovimiento> notasCredito = [];
  bool isLoadingProductos = true;
  bool isLoadingNotasCredito = true;
  Map<String, dynamic>? detalleDeuda;
  double? _saldoDetalle;
  final CuentaCorrienteCacheService _ccCacheService = CuentaCorrienteCacheService();
  
  String? errorMessage;
  
  // Variable para rastrear si hubo cambios (abonos creados/eliminados)
  bool _huboCambios = false;
  
  // Variables para paginación de ventas
  bool _isLoadingMoreVentas = false;
  bool _hasMoreVentas = true;
  int _currentPageVentas = 1;
  final int _pageSizeVentas = 20;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadDetalleDeuda(),
      _loadVentasCC(),
      _loadAbonos(),
      _loadProductosAFavor(),
      _loadNotasCredito(),
    ]);
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _loadDetalleDeuda() async {
    try {
      final clienteProvider = ClienteProvider();
      final detalle = await clienteProvider.obtenerDetalleDeuda(widget.cliente.id!);
      _safeSetState(() {
        detalleDeuda = detalle;
        _saldoDetalle = _obtenerSaldoDesdeDetalle(detalle);
        if (_saldoDetalle != null) {
          widget.cliente.deuda = _saldoDetalle!.toStringAsFixed(2);
        }
        isLoadingDetalle = false;
      });
    } catch (e) {
      log('Error al cargar cuenta corriente: $e', level: 1000);
      if (Apihandler.isConnectionError(e)) {
        try {
          final offlineDetalle =
              await _ccCacheService.obtenerDetalleDeudaOffline(widget.cliente.id!);
          if (offlineDetalle != null) {
            _safeSetState(() {
              detalleDeuda = offlineDetalle;
              _saldoDetalle = _obtenerSaldoDesdeDetalle(offlineDetalle);
              if (_saldoDetalle != null) {
                widget.cliente.deuda = _saldoDetalle!.toStringAsFixed(2);
              }
              isLoadingDetalle = false;
            });
            return;
          }
        } catch (cacheError) {
          log('Error leyendo detalle de CC offline: $cacheError', level: 1000);
        }
      }
      _safeSetState(() {
        errorMessage = 'Error al cargar cuenta corriente: $e';
        isLoadingDetalle = false;
      });
    }
  }

  double? _obtenerSaldoDesdeDetalle(Map<String, dynamic>? detalle) {
    if (detalle == null) return null;
    final raw = detalle['deudaActual'] ?? detalle['saldoActual'];
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final sanitized = raw.replaceAll(',', '.');
      return double.tryParse(sanitized) ?? _parsearDeuda(raw);
    }
    final formateada = detalle['deudaFormateada'];
    if (formateada is String) {
      return _parsearDeuda(formateada);
    }
    return null;
  }

  Future<void> _loadVentasCC() async {
    try {
      final ventasProvider = VentasProvider();
      final data = await ventasProvider.obtenerVentasCuentaCorrientePorClienteId(
        widget.cliente.id!, 
        _currentPageVentas, 
        _pageSizeVentas
      );
      
      _safeSetState(() {
        ventasCC = List<Ventas>.from(data['ventas']);
        _hasMoreVentas = data['hasNextPage'];
        isLoadingVentas = false;
      });
    } catch (e) {
      log('Error al cargar ventas: $e', level: 1000);
      if (Apihandler.isConnectionError(e)) {
        final offlineVentas = await _ccCacheService.obtenerVentasOffline(widget.cliente.id!);
        _safeSetState(() {
          ventasCC = offlineVentas;
          _hasMoreVentas = false;
          isLoadingVentas = false;
        });
        return;
      }
      _safeSetState(() {
        errorMessage = 'Error al cargar ventas: $e';
        isLoadingVentas = false;
      });
    }
  }

  Future<void> _loadAbonos() async {
    try {
      final abonosProvider = AbonosProvider();
      abonos = await abonosProvider.obtenerAbonosPorClienteId(widget.cliente.id!);
      _safeSetState(() {
        isLoadingAbonos = false;
      });
    } catch (e) {
      log('Error al cargar abonos: $e', level: 1000);
      if (Apihandler.isConnectionError(e)) {
        final offlineAbonos =
            await _ccCacheService.obtenerAbonosOffline(widget.cliente.id!);
        _safeSetState(() {
          abonos = offlineAbonos;
          isLoadingAbonos = false;
        });
        return;
      }
      _safeSetState(() {
        errorMessage = 'Error al cargar abonos: $e';
        isLoadingAbonos = false;
      });
    }
  }

  Future<void> _loadProductosAFavor() async {
    try {
      final productoService = ProductoAFavorService();
      final productos = await productoService.obtenerProductosAFavorByClienteId(
        widget.cliente.id!,
        soloNoEntregados: false,
      );
      await _ccCacheService.cacheProductosAFavor(widget.cliente.id!, productos);
      if (!mounted) return;
      _safeSetState(() {
        productosAFavor = productos;
        isLoadingProductos = false;
      });
    } catch (e) {
      if (!mounted) return;
      final esTimeout = e is TimeoutException;
      if (Apihandler.isConnectionError(e) || esTimeout) {
        final productos = await _ccCacheService.obtenerProductosAFavorOffline(widget.cliente.id!);
        _safeSetState(() {
          productosAFavor = productos;
          isLoadingProductos = false;
        });
      } else {
        _safeSetState(() {
          errorMessage = 'Error al cargar productos a favor: $e';
          isLoadingProductos = false;
        });
      }
      log('Error al cargar productos a favor: $e', level: 1000);
    }
  }

  Future<void> _loadNotasCredito() async {
    try {
      final movimientos = await _ccCacheService.obtenerMovimientosPorTipo(
        clienteId: widget.cliente.id!,
        tipo: TipoMovimientoCuentaCorriente.notaCredito,
      );
      if (!mounted) return;
      _safeSetState(() {
        notasCredito = movimientos;
        isLoadingNotasCredito = false;
      });
    } catch (e) {
      if (!mounted) return;
      _safeSetState(() {
        isLoadingNotasCredito = false;
      });
      log('Error al cargar notas de crédito: $e', level: 1000);
    }
  }

  Future<void> _cargarMasVentas() async {
    if (_isLoadingMoreVentas || !_hasMoreVentas) return;
    
    _safeSetState(() {
      _isLoadingMoreVentas = true;
    });

    try {
      final ventasProvider = VentasProvider();
      final data = await ventasProvider.obtenerVentasCuentaCorrientePorClienteId(
        widget.cliente.id!, 
        _currentPageVentas + 1, 
        _pageSizeVentas
      );
      
      _safeSetState(() {
        ventasCC.addAll(List<Ventas>.from(data['ventas']));
        _currentPageVentas++;
        _hasMoreVentas = data['hasNextPage'];
        _isLoadingMoreVentas = false;
      });
    } catch (e) {
      _safeSetState(() {
        _isLoadingMoreVentas = false;
      });
      log('Error al cargar más ventas: $e', level: 1000);
    }
  }

  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(2);
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  double _parsearDeuda(String? deuda) {
    if (deuda == null || deuda.isEmpty) return 0.0;
    
    // El backend envía formatos como "1000,000", "2500,250", etc.
    // Vamos a tratar TODOS los casos como si la coma fuera decimal
    // y solo convertir a formato estándar con 2 decimales
    
    if (deuda.contains(',')) {
      List<String> partes = deuda.split(',');
      
      if (partes.length == 2) {
        String parteEntera = partes[0];
        String parteDecimal = partes[1];
        
        // Siempre convertir la coma a punto decimal
        // Si tiene más de 2 dígitos, tomar solo los primeros 2
        String decimalesFinales;
        if (parteDecimal.length >= 2) {
          decimalesFinales = parteDecimal.substring(0, 2);
        } else {
          // Si tiene menos de 2, rellenar con ceros
          decimalesFinales = parteDecimal.padRight(2, '0');
        }
        
        String numeroCorregido = '$parteEntera.$decimalesFinales';
        return double.tryParse(numeroCorregido) ?? 0.0;
      }
    }
    
    // Para otros formatos, usar la lógica normal
    String deudaLimpia = deuda.replaceAll(',', '');
    return double.tryParse(deudaLimpia) ?? 0.0;
  }

  void _mostrarModalSaldarDeuda() {
    final TextEditingController montoController = TextEditingController();
    final TextEditingController notaController = TextEditingController();
    String? errorMessage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AppTheme.minimalAlertDialog(
              title: 'Registrar abono',
              content: TextSelectionTheme(
                data: TextSelectionThemeData(
                  cursorColor: AppTheme.primaryColor,
                  selectionColor: AppTheme.primaryColor.withOpacity(0.3),
                  selectionHandleColor: AppTheme.primaryColor,
                ),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                // Información del cliente y saldo actual
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.cliente.nombre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              _parsearDeuda(widget.cliente.deuda) > 0
                                  ? 'Saldo actual: \$${_formatearPrecio(_parsearDeuda(widget.cliente.deuda))}'
                                  : 'Sin deuda actualmente',
                              style: TextStyle(
                                fontSize: 14,
                                color: _parsearDeuda(widget.cliente.deuda) > 0 
                                    ? Colors.red.shade600 
                                    : Colors.green.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Mensaje de error
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Campo monto
                TextField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monto a abonar',
                    hintText: 'Ingrese el monto',
                    prefixText: '\$ ',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo nota
                TextField(
                  controller: notaController,
                  maxLines: 2,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nota (opcional)',
                    hintText: 'Ingrese una nota...',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                          side: BorderSide(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400, 
                            width: 1.5
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final monto = double.tryParse(montoController.text);
                          final deudaActual = _parsearDeuda(widget.cliente.deuda);
                          
                          // Limpiar error previo
                          setState(() {
                            errorMessage = null;
                          });
                          
                          if (monto == null || monto <= 0) {
                            setState(() {
                              errorMessage = 'Ingrese un monto válido';
                            });
                            return;
                          }
                          
                          if (monto > deudaActual) {
                            setState(() {
                              errorMessage = 'El monto no puede ser mayor al saldo actual';
                            });
                            return;
                          }
                          
                          Navigator.of(context).pop();
                          await _procesarAbono(monto, notaController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _procesarAbono(double monto, String nota) async {
    try {
      final abonosProvider = AbonosProvider();
      final abonoCreado = await abonosProvider.saldarDeuda(
        widget.cliente.id!, 
        monto, 
        DateTime.now(), 
        nota.isEmpty ? null : nota,
        clienteNombre: widget.cliente.nombre,
      );
      
      if (abonoCreado != null) {
        _huboCambios = true;
        
        // Actualizar la deuda del cliente localmente
        final deudaActual = _parsearDeuda(widget.cliente.deuda);
        final nuevaDeuda = deudaActual - monto;
        widget.cliente.deuda = nuevaDeuda.toStringAsFixed(2);
        
        // Recargar los datos para que ventas y abonos queden como historial (no se borran)
        await _loadData();
        
        if (!mounted) return;
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar(
            nuevaDeuda <= 0
                ? 'Abono registrado. Cuenta corriente al día.'
                : 'Abono registrado exitosamente',
          ),
        );
        // No hacer pop al saldar: el usuario se queda en el detalle y ve el historial
        // (ventas y abonos saldados siguen visibles como registro).
      }
    } catch (e) {
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar('Error al procesar el abono: $e'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_huboCambios);
        return false;
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey.shade50,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
        backgroundColor: null, // Usar el tema
        title: const Text(
          'Cuenta Corriente',
            style: AppTheme.appBarTitleStyle,
          ),
        ),
      body: isLoadingDetalle
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando detalles...',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header con información del cliente
                _buildHeaderSection(isDarkMode),
                
                // Tabs custom (chips + animación)
                _buildCustomTabRow(isDarkMode),
                
                // Contenido con animación fade/slide
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildTabContent(isDarkMode),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalSaldarDeuda,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.payment, color: Colors.white),
        label: const Text(
          'Registrar abono',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDarkMode) {
    final saldoActual = _saldoDetalle ?? _parsearDeuda(widget.cliente.deuda);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode ? [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ] : [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode 
            ? const Color(0xFF404040)
            : AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isDarkMode ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
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
                      widget.cliente.nombre,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      saldoActual > 0
                          ? 'Saldo actual: \$${_formatearPrecio(saldoActual)}'
                          : 'Sin deuda actualmente',
                      style: TextStyle(
                        fontSize: 16,
                        color: saldoActual > 0 ? Colors.red.shade600 : Colors.green.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.cliente.telefono != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tel: ${widget.cliente.telefono}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Cuenta Corriente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<({String label, IconData icon})> _tabItems = [
    (label: 'Ventas CC', icon: Icons.receipt_long),
    (label: 'Abonos', icon: Icons.payment),
    (label: 'Notas', icon: Icons.receipt),
    (label: 'Prod. a favor', icon: Icons.inventory_2),
  ];

  Widget _buildCustomTabRow(bool isDarkMode) {
    final counts = [ventasCC.length, abonos.length, notasCredito.length, productosAFavor.length];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final selected = _selectedTabIndex == i;
            final item = _tabItems[i];
            return Padding(
              padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedTabIndex = i),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryColor
                          : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: selected
                              ? Colors.white
                              : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.label} (${counts[i]})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDarkMode) {
    final Widget body;
    switch (_selectedTabIndex) {
      case 0:
        body = _buildVentasTab(isDarkMode);
        break;
      case 1:
        body = _buildAbonosTab(isDarkMode);
        break;
      case 2:
        body = _buildNotasCreditoTab(isDarkMode);
        break;
      case 3:
        body = _buildProductosAFavorTab(isDarkMode);
        break;
      default:
        body = _buildVentasTab(isDarkMode);
    }
    return KeyedSubtree(
      key: ValueKey<int>(_selectedTabIndex),
      child: body,
    );
  }

  Widget _buildVentasTab(bool isDarkMode) {
    if (isLoadingVentas) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (ventasCC.isEmpty) {
      return _buildEmptyState(
        isDarkMode: isDarkMode,
        icon: Icons.receipt_long,
        title: 'No hay ventas con cuenta corriente',
        subtitle: 'Este cliente no tiene ventas pendientes de pago',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ventasCC.length + (_isLoadingMoreVentas ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == ventasCC.length) {
          return _buildLoadingIndicator();
        }
        
        final venta = ventasCC[index];
        return _buildVentaCard(venta, isDarkMode);
      },
    );
  }

  Widget _buildAbonosTab(bool isDarkMode) {
    if (isLoadingAbonos) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (abonos.isEmpty) {
      return _buildEmptyState(
        isDarkMode: isDarkMode,
        icon: Icons.payment,
        title: 'No hay abonos registrados',
        subtitle: 'Este cliente aún no ha realizado ningún abono',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: abonos.length,
      itemBuilder: (context, index) {
        final abono = abonos[index];
        return _buildAbonoCard(abono, isDarkMode);
      },
    );
  }

  Widget _buildNotasCreditoTab(bool isDarkMode) {
    if (isLoadingNotasCredito) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (notasCredito.isEmpty) {
      return _buildEmptyState(
        isDarkMode: isDarkMode,
        icon: Icons.receipt,
        title: 'No hay notas de crédito',
        subtitle: 'Aún no se registraron notas de crédito para este cliente',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notasCredito.length,
      itemBuilder: (context, index) {
        final movimiento = notasCredito[index];
        return _buildNotaCreditoCard(movimiento, isDarkMode);
      },
    );
  }

  Widget _buildProductosAFavorTab(bool isDarkMode) {
    if (isLoadingProductos) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (productosAFavor.isEmpty) {
      return _buildEmptyState(
        isDarkMode: isDarkMode,
        icon: Icons.inventory_2_outlined,
        title: 'Sin productos a favor',
        subtitle: 'No hay entregas pendientes para este cliente',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: productosAFavor.length,
      itemBuilder: (context, index) {
        final producto = productosAFavor[index];
        return _buildProductoAFavorCard(producto, isDarkMode);
      },
    );
  }

  Widget _buildVentaCard(Ventas venta, bool isDarkMode) {
    // Calcular el monto específico pagado con cuenta corriente
    double montoCuentaCorriente = 0.0;
    if (venta.pagos != null && venta.pagos!.isNotEmpty) {
      // Si tenemos pagos cargados, calcular el monto de cuenta corriente
      montoCuentaCorriente = venta.pagos!
          .where((pago) => pago.metodo.index == MetodoPago.cuentaCorriente.index)
          .fold(0.0, (sum, pago) => sum + pago.monto);
    } else if (venta.metodoPago == MetodoPago.cuentaCorriente) {
      // Si no tenemos pagos cargados pero el método de pago es cuenta corriente,
      // usar el total de la venta como monto de cuenta corriente
      montoCuentaCorriente = venta.total;
    }

    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de detalle de venta
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleVentaScreen(venta: venta),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venta.id != null ? 'Venta #${venta.id}' : 'Venta Pendiente',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        _formatearFecha(venta.fecha),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                        ),
                      ),
                      if (venta.pagos != null && venta.pagos!.length > 1) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Total: \$${_formatearPrecio(venta.total)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${_formatearPrecio(montoCuentaCorriente)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
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

  void _mostrarDetalleAbono(Abono abono) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del modal
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(isDarkMode ? 0.2 : 0.1),
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
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.payment,
                          color: Colors.green.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Abono #${abono.id}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              _formatearFecha(abono.fecha),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenido scrolleable
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Monto del abono
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(isDarkMode ? 0.15 : 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(isDarkMode ? 0.3 : 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monto del Abono',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${_formatearPrecio(_parsearDeuda(abono.monto))}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Cliente
                        _buildDetalleItem(
                          icon: Icons.person,
                          label: 'Cliente',
                          value: abono.clienteNombre,
                          iconColor: AppTheme.primaryColor,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Fecha
                        _buildDetalleItem(
                          icon: Icons.calendar_today,
                          label: 'Fecha',
                          value: _formatearFecha(abono.fecha),
                          iconColor: Colors.blue,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Nota
                        if (abono.nota.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.note,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Nota',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(isDarkMode ? 0.15 : 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(isDarkMode ? 0.3 : 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              abono.nota,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(isDarkMode ? 0.15 : 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Sin nota adicional',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Footer con botón de cerrar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetalleItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAbonoCard(Abono abono, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _mostrarDetalleAbono(abono),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.payment,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abono #${abono.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        _formatearFecha(abono.fecha),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                        ),
                      ),
                      if (abono.nota.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          abono.nota,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${_formatearPrecio(_parsearDeuda(abono.monto))}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _mostrarConfirmacionEliminarAbono(abono),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildNotaCreditoCard(CuentaCorrienteMovimiento movimiento, bool isDarkMode) {
    final monto = movimiento.montoTotal != 0
        ? movimiento.montoTotal
        : movimiento.saldoDelta.abs();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_long,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movimiento.detalle ?? 'Nota de crédito',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatearFecha(movimiento.fecha),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  if (movimiento.observacion?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      movimiento.observacion ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '\$${_formatearPrecio(monto)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoAFavorCard(ProductoAFavor producto, bool isDarkMode) {
    final entregado = producto.entregado;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.producto?.nombre ?? 'Producto a favor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cantidad: ${producto.cantidad}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (entregado ? Colors.green : Colors.amber).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entregado ? 'Entregado' : 'Pendiente',
                    style: TextStyle(
                      fontSize: 13,
                      color: entregado ? Colors.green.shade700 : Colors.amber.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatearFecha(producto.fechaRegistro),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (producto.nota != null && producto.nota!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                producto.nota!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDarkMode, 
    required IconData icon, 
    required String title, 
    required String subtitle
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ),
    );
  }

  void _mostrarConfirmacionEliminarAbono(Abono abono) async {
    if (abono.id == null) {
      AppTheme.showSnackBar(
        context,
        AppTheme.warningSnackBar(
          'Este abono aún no se sincroniza. Conéctate para poder eliminarlo.',
        ),
      );
      return;
    }
    final confirmar = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Abono',
      message: '¿Está seguro de que desea eliminar este abono de \$${_formatearPrecio(_parsearDeuda(abono.monto))}?\n\nEsto actualizará el saldo del cliente.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
    );

    if (confirmar) {
      await _eliminarAbono(abono);
    }
  }

  Future<void> _eliminarAbono(Abono abono) async {
    try {
      final abonosProvider = AbonosProvider();
      final eliminado = await abonosProvider.eliminarAbono(abono.id!);
      
      if (eliminado) {
        _huboCambios = true;
        
        // Actualizar la deuda local del cliente
        final montoAbono = _parsearDeuda(abono.monto);
        final deudaActual = _parsearDeuda(widget.cliente.deuda);
        widget.cliente.deuda = (deudaActual + montoAbono).toStringAsFixed(2);
        
        // Recargar todos los datos
        await _loadData();
        
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Abono eliminado exitosamente'),
        );
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al eliminar el abono'),
        );
      }
    } catch (e) {
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar('Error al eliminar el abono: $e'),
      );
    }
  }
}
