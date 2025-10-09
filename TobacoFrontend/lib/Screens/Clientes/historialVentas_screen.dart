import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Models/ventasPago.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:intl/intl.dart';
import '../Ventas/detalleVentas_screen.dart';

class HistorialVentasScreen extends StatefulWidget {
  final Cliente cliente;

  const HistorialVentasScreen({super.key, required this.cliente});

  @override
  State<HistorialVentasScreen> createState() => _HistorialVentasScreenState();
}

class _HistorialVentasScreenState extends State<HistorialVentasScreen> {
  List<Ventas> _ventas = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalItems = 0;
  bool _hasNextPage = false;
  
  final int _pageSize = 20;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _cargarVentas();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cargarMasVentas();
    }
  }

  Future<void> _cargarVentas() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final ventasProvider = Provider.of<VentasProvider>(context, listen: false);
      final result = await ventasProvider.obtenerVentasPorCliente(
        widget.cliente.id!,
        pageNumber: _currentPage,
        pageSize: _pageSize,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

      if (mounted) {
        setState(() {
          _ventas = List<Ventas>.from(result['ventas']);
          _totalItems = result['totalItems'];
          _hasNextPage = result['hasNextPage'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
        } else {
          await AppDialogs.showErrorDialog(
            context: context,
            message: 'Error al cargar el historial: ${e.toString().replaceFirst('Exception: ', '')}',
          );
        }
      }
    }
  }

  Future<void> _cargarMasVentas() async {
    if (!mounted || _isLoadingMore || !_hasNextPage) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final ventasProvider = Provider.of<VentasProvider>(context, listen: false);
      final result = await ventasProvider.obtenerVentasPorCliente(
        widget.cliente.id!,
        pageNumber: _currentPage + 1,
        pageSize: _pageSize,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

      if (mounted) {
        setState(() {
          _ventas.addAll(List<Ventas>.from(result['ventas']));
          _currentPage = _currentPage + 1;
          _hasNextPage = result['hasNextPage'];
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        
        if (Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
        } else {
          await AppDialogs.showErrorDialog(
            context: context,
            message: 'Error al cargar más ventas: ${e.toString().replaceFirst('Exception: ', '')}',
          );
        }
      }
    }
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esFechaInicio) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esFechaInicio ? (_dateFrom ?? DateTime.now()) : (_dateTo ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esFechaInicio) {
          _dateFrom = fechaSeleccionada;
        } else {
          _dateTo = fechaSeleccionada;
        }
        _currentPage = 1; // Reset to first page when filter changes
      });
      await _cargarVentas();
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _currentPage = 1;
    });
    _cargarVentas();
  }


  String _formatearMetodosPago(List<dynamic>? pagos) {
    if (pagos == null || pagos.isEmpty) {
      return 'Sin información';
    }

    final Map<String, double> metodos = {};
    for (var pago in pagos) {
      // Verificar si pago es un VentaPago o un Map
      String metodoName;
      double monto;
      
      if (pago is VentaPago) {
        metodoName = _getMetodoPagoString(pago.metodo);
        monto = pago.monto;
      } else {
        // Si es un Map (del JSON)
        metodoName = _getMetodoPagoString(MetodoPago.values[pago['metodo']]);
        monto = (pago['monto'] as num).toDouble();
      }
      
      metodos[metodoName] = (metodos[metodoName] ?? 0) + monto;
    }

    return metodos.entries
        .map((e) => '${e.key}: \$${e.value.toStringAsFixed(2)}')
        .join(', ');
  }

  String _getMetodoPagoString(MetodoPago metodoPago) {
    switch (metodoPago) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.transferencia:
        return 'Transferencia';
      case MetodoPago.tarjeta:
        return 'Tarjeta';
      case MetodoPago.cuentaCorriente:
        return 'Cuenta Corriente';
      default:
        return 'No especificado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null, // Usar el tema
        title: const Text(
          'Historial de Ventas',
          style: AppTheme.appBarTitleStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filtros de fecha
          _buildFiltros(),
          
          // Información del cliente
          _buildClienteInfo(),
          
          // Lista de ventas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : _ventas.isEmpty
                    ? _buildEmptyState()
                    : _buildVentasList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateFilter(
                  'Desde',
                  _dateFrom,
                  () => _seleccionarFecha(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateFilter(
                  'Hasta',
                  _dateTo,
                  () => _seleccionarFecha(context, false),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _limpiarFiltros,
                icon: Icon(
                  Icons.clear,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
                tooltip: 'Limpiar filtros',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(String label, DateTime? fecha, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.white,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade600
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fecha != null
                  ? DateFormat('dd/MM/yyyy').format(fecha)
                  : 'Seleccionar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF2A2A2A),
                ]
              : [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.secondaryColor.withOpacity(0.3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
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
                  widget.cliente.nombre,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total de ventas: $_totalItems',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ventas registradas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dateFrom != null || _dateTo != null
                ? 'No se encontraron ventas en el período seleccionado'
                : 'Este cliente aún no tiene ventas registradas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVentasList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _ventas.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _ventas.length) {
          // Mostrar indicador de carga al final
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            ),
          );
        }
        final venta = _ventas[index];
        return _buildVentaCard(venta);
      },
    );
  }

  Widget _buildVentaCard(Ventas venta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleVentaScreen(venta: venta),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${venta.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Resumen de métodos de pago
                if (venta.pagos != null && venta.pagos!.isNotEmpty) ...[
                  Text(
                    'Métodos de pago:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatearMetodosPago(venta.pagos),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.primaryColor,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Método de pago: ${venta.metodoPago?.name ?? 'No especificado'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                
                // Información adicional
                Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${venta.ventasProductos.length} producto(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
