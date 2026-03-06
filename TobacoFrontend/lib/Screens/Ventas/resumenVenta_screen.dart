import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_service.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:printing/printing.dart';
import 'package:tobaco/Utils/pdf_generator/venta_pdf_builder.dart';
import 'package:tobaco/Services/Printer_Service/bluetooth_printer_service.dart';
import 'package:share_plus/share_plus.dart';

class ResumenVentaScreen extends StatefulWidget {
  final Ventas? venta; // Recibir la venta como parámetro opcional
  
  const ResumenVentaScreen({
    super.key,
    this.venta, // Si no se pasa, intentará obtenerla del servidor
  });

  @override
  State<ResumenVentaScreen> createState() => _ResumenVentaScreenState();
}

class _ResumenVentaScreenState extends State<ResumenVentaScreen> {
  final VentasService _ventasService = VentasService();
  Ventas? venta;
  Ventas? ventaCargadaBD;
  bool isLoading = true;
  String? errorMessage;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    
    // Si se pasó una venta como parámetro, usarla directamente (especialmente si es offline)
    if (widget.venta != null) {
      // Si la venta NO tiene ID, es una venta offline recién creada - usar directamente
      if (widget.venta!.id == null) {
        setState(() {
          venta = widget.venta;
          isLoading = false;
        });
        return; // No intentar cargar del servidor
      }
      
      // Si tiene ID pero es un ID local (empieza con "servidor_"), también es offline
      // Usar la venta directamente y opcionalmente intentar cargar del servidor en background
      setState(() {
        venta = widget.venta;
        isLoading = false;
      });
      
      // Intentar cargar del servidor en background solo si tiene ID numérico válido
      // Pero no bloquear la UI
      _cargarVentaPorIdEnBackground(widget.venta!.id!);
    } else {
      // Si no hay venta pasada, intentar obtener la última venta del servidor
      _cargarUltimaVenta();
    }
  }

  /// Carga la venta del servidor en background sin bloquear la UI
  Future<void> _cargarVentaPorIdEnBackground(int id) async {
    try {
      final ventaCargada = await _ventasService.obtenerVentaPorId(id)
          .timeout(const Duration(seconds: 3));
      
      if (!mounted) return;
      
      // Guardar el total de la venta local antes de actualizar
      final totalLocal = venta?.total ?? 0;
      final totalServidor = ventaCargada.total;
      
      debugPrint('💰 ResumenVenta: Total local=$totalLocal, Total servidor=$totalServidor');
      
      // Si el servidor devuelve un total válido (> 0), usar la venta del servidor
      // Si el servidor devuelve 0 pero la venta local tiene un total válido, mantener el total local
      if (totalServidor > 0) {
        setState(() {
          venta = ventaCargada;
          ventaCargadaBD = ventaCargada;
        });
        debugPrint('✅ ResumenVenta: Usando venta del servidor con total=$totalServidor');
      } else if (totalLocal > 0) {
        // El servidor devolvió 0 pero la venta local tiene un total válido
        // Actualizar la venta del servidor pero preservar el total local
        debugPrint('⚠️ ResumenVenta: Servidor devolvió total=0, preservando total local=$totalLocal');
        setState(() {
          ventaCargada.total = totalLocal;
          // También actualizar los precios finales calculados si es necesario
          if (venta != null && venta!.ventasProductos.isNotEmpty && ventaCargada.ventasProductos.isNotEmpty) {
            // Preservar los precios finales calculados de la venta local si el servidor los tiene en 0
            for (var i = 0; i < venta!.ventasProductos.length && i < ventaCargada.ventasProductos.length; i++) {
              final productoLocal = venta!.ventasProductos[i];
              final productoServidor = ventaCargada.ventasProductos[i];
              if (productoServidor.precioFinalCalculado <= 0 && productoLocal.precioFinalCalculado > 0) {
                productoServidor.precioFinalCalculado = productoLocal.precioFinalCalculado;
              }
            }
          }
          venta = ventaCargada;
          ventaCargadaBD = ventaCargada;
        });
      } else {
        // Ambos son 0, usar la venta del servidor de todas formas
        setState(() {
          venta = ventaCargada;
          ventaCargadaBD = ventaCargada;
        });
        debugPrint('⚠️ ResumenVenta: Ambos totales son 0, usando venta del servidor');
      }
    } on TimeoutException {
      // Si timeout, mantener la venta local sin error visible
      debugPrint('⚠️ Timeout al cargar venta del servidor en background, usando venta local');
    } catch (e) {
      // Silenciar error, mantener la venta local
      debugPrint('⚠️ No se pudo cargar venta del servidor en background: $e');
    }
  }

  Future<void> _cargarUltimaVenta() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Si tenemos un cliente en la venta actual, traer su última venta
      final clienteId = venta?.cliente.id;

      if (clienteId != null) {
        final data = await _ventasService.obtenerVentasPorCliente(
          clienteId,
          pageNumber: 1,
          pageSize: 1,
        );

        final List<Ventas> ventasCliente = (data['ventas'] as List<Ventas>);

        // Si no está garantizado el orden por fecha, ordenar localmente desc
        ventasCliente.sort((a, b) => b.fecha.compareTo(a.fecha));

        final ultimaDelCliente = ventasCliente.isNotEmpty ? ventasCliente.first : null;

        if (!mounted) return;
        setState(() {
          ventaCargadaBD = ultimaDelCliente;
          isLoading = false;
        });
      } else {
        // Sin cliente conocido, no podemos filtrar; no alterar 'venta'
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      if (Apihandler.isConnectionError(e)) {
        setState(() {
          isLoading = false;
          // No establecer errorMessage para errores de conexión
        });
        await Apihandler.handleConnectionError(context, e);
      } else {
        setState(() {
          errorMessage = 'Error al cargar la venta: ${e.toString().replaceFirst('Exception: ', '')}';
          isLoading = false;
        });
      }
    }
  }

  String _getMetodoPagoText(MetodoPago metodo) {
    switch (metodo) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.transferencia:
        return 'Transferencia';
      case MetodoPago.tarjeta:
        return 'Tarjeta';
      case MetodoPago.cuentaCorriente:
        return 'Cuenta Corriente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Resumen', style: AppTheme.appBarTitleStyle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: venta != null ? _buildBottomActions(context) : null,
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            SizedBox(height: 16),
            Text('Cargando información de la venta...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar la venta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarUltimaVenta,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (venta == null) {
      return const Center(
        child: Text('No se encontró información de la venta'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con información principal de la venta
          _buildHeaderSection(),
          const SizedBox(height: 20),

          // Información detallada de la venta
          _buildVentaInfoCard(),
          const SizedBox(height: 20),

          // Resumen de totales
          _buildSummarySection(),
          // Separación al final (parte del scroll, no genera franja)
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Header principal con información de la venta
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
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
                  Icons.check_circle,
                  color: Colors.white,
                  size: 35,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venta Completada',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      venta!.id != null 
                        ? 'Venta #${venta!.id}' 
                        : 'Guardada localmente',
                      style: TextStyle(
                        fontSize: 16,
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cliente',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    venta!.cliente.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  _formatearPrecioConDecimales(venta!.total),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tarjeta con información de la venta
  Widget _buildVentaInfoCard() {
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
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Información de la Venta',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.calendar_today, 'Fecha', _formatFecha(venta!.fecha)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.payment, 'Método de Pago', _getAllPaymentMethodsString(venta!)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person, 'Usuario', venta!.usuarioCreador?.userName ?? 'No disponible'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sección de resumen
  Widget _buildSummarySection() {
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
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Resumen de Pagos',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Desglose de métodos de pago
                if (venta!.pagos != null && venta!.pagos!.isNotEmpty) ...[
                  ...venta!.pagos!.map((pago) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildInfoRow(
                      _getPaymentIcon(pago.metodo),
                      _getMetodoPagoText(pago.metodo),
                      '\$${_formatearPrecio(pago.monto)}',
                    ),
                  )),
                  const Divider(height: 20),
                ],
                // Mostrar descuento si aplica
                if (venta!.cliente.descuentoGlobal > 0) ...[
                  _buildInfoRow(
                    Icons.local_offer,
                    'Descuento Global (${venta!.cliente.descuentoGlobal.toStringAsFixed(1)}%)',
                    '-\$${_formatearPrecio(_calcularDescuento())}',
                    valueColor: Colors.red.shade600,
                  ),
                  const SizedBox(height: 12),
                ],
                // Total de la venta
                _buildInfoRow(
                  Icons.receipt,
                  'Total de la Venta',
                  '\$${_formatearPrecio(venta!.total)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Botones de acción en la parte inferior
  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
      ),
      child: SafeArea(
        child: Row(
          children: [
                        Expanded(
              child: ElevatedButton.icon(
                onPressed: _isPrinting
                    ? null
                    : () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (sheetContext) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor),
                                    title: const Text('Imprimir PDF'),
                                    onTap: () async {
                                      Navigator.of(sheetContext).pop();
                                      try {
                                        final ventaParaPdf = ventaCargadaBD ?? venta;
                                        if (ventaParaPdf == null) return;
                                        final bytes = await buildVentaPdf(ventaParaPdf);
                                        await Printing.layoutPdf(onLayout: (_) async => bytes);
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error al generar PDF: $e')),
                                        );
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
                                    title: const Text('Imprimir ticket'),
                                    onTap: () async {
                                      Navigator.of(sheetContext).pop();
                                      await _imprimirTicketTermico(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.share, color: AppTheme.primaryColor),
                                    title: const Text('Compartir PDF por WhatsApp'),
                                    onTap: () {
                                      Navigator.of(sheetContext).pop();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            );
                          },
                        );
                      },
                icon: _isPrinting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.print, size: 20),
                label: Text(_isPrinting ? 'Imprimiendo...' : 'Imprimir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Navegación dentro del shell (navbar): ir a Inicio = primera ruta del navigator anidado
                  final nav = Navigator.of(context, rootNavigator: false);
                  if (nav.canPop()) {
                    nav.popUntil((route) => route.isFirst);
                  } else {
                    // Por si el contexto apuntara al navigator raíz, ir al menú por nombre
                    Navigator.of(context).pushNamedAndRemoveUntil('/menu', (_) => false);
                  }
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(context).cardTheme.color,
                  side: const BorderSide(color: Colors.grey, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Volver al Inicio',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fila de información individual
  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor, bool isTotal = false}) {
    return Row(
      children: [
        Icon(
          icon,
          color: isTotal ? AppTheme.primaryColor : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? (isTotal ? AppTheme.primaryColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
            ),
          ),
        ),
      ],
    );
  }

  // Función para formatear precios
  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  }

  double _calcularDescuento() {
    if (venta!.cliente.descuentoGlobal > 0) {
      // Calcular el subtotal sumando todos los productos
      final subtotal = venta!.ventasProductos.fold(
        0.0, (sum, producto) => sum + (producto.precio * producto.cantidad));
      return subtotal * (venta!.cliente.descuentoGlobal / 100);
    }
    return 0.0;
  }

  // Widget para formatear precios con decimales más pequeños y grises
  Widget _formatearPrecioConDecimales(double precio, {Color? color}) {
    final precioStr = precio.toStringAsFixed(2);
    final partes = precioStr.split('.');
    final parteEntera = partes[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
    final parteDecimal = partes[1];
    
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '\$$parteEntera',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
          TextSpan(
            text: ',$parteDecimal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // Función para formatear fecha manualmente
  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  // Función para obtener todos los métodos de pago separados por comas
  String _getAllPaymentMethodsString(Ventas venta) {
    List<String> metodos = [];
    
    // Agregar el método de pago principal si existe
    if (venta.metodoPago != null) {
      metodos.add(_getMetodoPagoText(venta.metodoPago!));
    }
    
    // Agregar métodos de pago de la lista de pagos si existen
    if (venta.pagos != null && venta.pagos!.isNotEmpty) {
      for (var pago in venta.pagos!) {
        String metodo = _getMetodoPagoText(pago.metodo);
        if (!metodos.contains(metodo)) {
          metodos.add(metodo);
        }
      }
    }
    
    // Si no hay métodos, mostrar mensaje por defecto
    if (metodos.isEmpty) {
      return 'No especificado';
    }
    
    return metodos.join(', ');
  }

  // Función para obtener el icono del método de pago
  IconData _getPaymentIcon(MetodoPago metodoPago) {
    switch (metodoPago) {
      case MetodoPago.efectivo:
        return Icons.money;
      case MetodoPago.transferencia:
        return Icons.account_balance;
      case MetodoPago.tarjeta:
        return Icons.credit_card;
      case MetodoPago.cuentaCorriente:
        return Icons.receipt_long;
    }
  }

  Future<void> _imprimirTicketTermico(BuildContext context) async {
    if (_isPrinting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impresión en curso, por favor esperá...')),
      );
      return;
    }

    setState(() => _isPrinting = true);

    try {
      final ventaParaImprimir = ventaCargadaBD ?? venta;
      if (ventaParaImprimir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No hay información de venta para imprimir')),
        );
        return;
      }

      final printerService = BluetoothPrinterService.instance;

      // Try the previously-known device first (probe verifies it's alive).
      if (printerService.connectedDevice != null) {
        try {
          await printerService.printTicket(ventaParaImprimir);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket enviado a la impresora')),
          );
          return;
        } catch (_) {
          // Known device unreachable — fall through to device selection
        }
      }

      // Show printer selection in a loop until success or cancel.
      while (true) {
        if (!context.mounted) return;

        final selectedPrinter = await showDialog<BluetoothDevice>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _PrinterSelectionDialog(),
        );

        if (selectedPrinter == null) return;

        try {
          await printerService.connectToDevice(selectedPrinter);
          await printerService.printTicket(ventaParaImprimir);

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket enviado a la impresora')),
          );
          return;
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo conectar. Verificá que la impresora esté encendida.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }
}

class _PrinterSelectionDialog extends StatefulWidget {
  @override
  State<_PrinterSelectionDialog> createState() =>
      _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<_PrinterSelectionDialog> {
  List<BluetoothDevice> devices = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBondedDevices();
  }

  Future<void> _loadBondedDevices() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final printerService = BluetoothPrinterService.instance;
      final bonded = await printerService.getBondedDevices();

      if (!mounted) return;
      setState(() {
        devices = bonded;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Impresora'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Asegurate de que la impresora esté encendida',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBondedDevices,
                    child: const Text('Reintentar'),
                  ),
                ],
              )
            else if (devices.isEmpty)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay dispositivos emparejados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Para vincular la impresora:\n'
                    '1. Andá a Ajustes > Bluetooth\n'
                    '2. Buscá y vinculá la impresora\n'
                    '3. Volvé a la app y tocá "Actualizar"',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(
                        (device.name?.isNotEmpty == true)
                            ? device.name!
                            : 'Dispositivo desconocido',
                      ),
                      subtitle: Text(device.address ?? ''),
                      onTap: () => Navigator.of(context).pop(device),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (!isLoading)
          TextButton(
            onPressed: _loadBondedDevices,
            child: const Text('Actualizar'),
          ),
      ],
    );
  }
}

