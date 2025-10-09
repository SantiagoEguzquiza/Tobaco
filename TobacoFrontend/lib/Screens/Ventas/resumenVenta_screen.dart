import 'package:flutter/material.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_service.dart';
import 'package:tobaco/Helpers/api_handler.dart';

class ResumenVentaScreen extends StatefulWidget {
  const ResumenVentaScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<ResumenVentaScreen> createState() => _ResumenVentaScreenState();
}

class _ResumenVentaScreenState extends State<ResumenVentaScreen> {
  final VentasService _ventasService = VentasService();
  Ventas? venta;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarUltimaVenta();
  }

  Future<void> _cargarUltimaVenta() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final ultimaVenta = await _ventasService.obtenerUltimaVenta();
      
      if (!mounted) return;
      setState(() {
        venta = ultimaVenta;
        isLoading = false;
      });
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
          padding: const EdgeInsets.all(16.0),
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
                  borderRadius: BorderRadius.circular(12),
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
                      'Venta #${venta!.id}',
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
                _buildInfoRow(Icons.person, 'Usuario', venta!.usuario?.userName ?? 'No disponible'),
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
                  )).toList(),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar funcionalidad de impresión
                },
                icon: const Icon(Icons.print, size: 20),
                label: const Text('Imprimir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(context).cardTheme.color,
                  side: const BorderSide(color: Colors.grey, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
            text: '\$${parteEntera}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
          TextSpan(
            text: ',${parteDecimal}',
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
}
