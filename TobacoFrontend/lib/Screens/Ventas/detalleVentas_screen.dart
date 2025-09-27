import 'package:flutter/material.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';

class DetalleVentaScreen extends StatelessWidget {
  final Ventas venta;

  const DetalleVentaScreen({super.key, required this.venta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Venta #${venta.id}', style: AppTheme.appBarTitleStyle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(             
              children: [               
                // Header con información principal de la venta
                _buildHeaderSection(),
                const SizedBox(height: 20),

                // Información detallada de la venta
                _buildInfoCard(),
                const SizedBox(height: 20),

                // Lista de productos
                _buildProductsSection(),
                const SizedBox(height: 20),

                // Resumen de totales
                _buildSummarySection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  // Header principal con información de la venta
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
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
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 35,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalle de Venta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Venta #${venta.id}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
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
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    venta.cliente.nombre,
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
                      color: Colors.grey.shade600,
                    ),
                  ),
                  _formatearPrecioConDecimales(venta.total),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tarjeta con información detallada
  Widget _buildInfoCard() {
    return Container(
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
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Información de la Venta',
                  style: TextStyle(
                    color: Colors.black87,
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
                _buildInfoRow(Icons.calendar_today, 'Fecha', _formatFecha(venta.fecha)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.payment, 'Método de Pago', _getAllPaymentMethodsString(venta)),
                const SizedBox(height: 12),               
                _buildInfoRow(Icons.person, 'Usuario', venta.usuario?.userName ?? 'No disponible'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fila de información individual
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade600,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Sección de productos
  Widget _buildProductsSection() {
    return Container(
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
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [             
                Text(
                  'Productos (${venta.ventasProductos.length})',
                  style: const TextStyle(
                    color: Colors.black87,
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
            itemCount: venta.ventasProductos.length,
            itemBuilder: (context, index) {
              final producto = venta.ventasProductos[index];
              return Container(
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
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
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Cantidad: ${producto.cantidad}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: _formatearPrecioConDecimales(
                    producto.precio * producto.cantidad,
                    color: Colors.black87,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Sección de resumen
  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
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
          // Desglose de métodos de pago
          if (venta.pagos != null && venta.pagos!.isNotEmpty) ...[
            const Text(
              'Desglose de Pagos:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...venta.pagos!.map((pago) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getPaymentIcon(pago.metodo),
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getMetodoPagoString(pago.metodo),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  _formatearPrecioConDecimales(
                    pago.monto,
                    color: Colors.black87,
                  ),
                ],
              ),
            )).toList(),
            const Divider(height: 20),
          ],
          // Mostrar descuento si aplica
          if (venta.cliente.descuentoGlobal > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Descuento Global (${venta.cliente.descuentoGlobal.toStringAsFixed(1)}%):',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '-\$${_formatearPrecio(_calcularDescuento())}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          // Total de la venta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total de la Venta:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _formatearPrecioConDecimales(venta.total),
            ],
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
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Volver',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _confirmDelete(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
                child: const Text(
                  'Eliminar Venta',
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
      ),
    );
  }

  // Función para formatear precios
  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  }

  double _calcularDescuento() {
    if (venta.cliente.descuentoGlobal > 0) {
      // Calcular el subtotal sumando todos los productos
      final subtotal = venta.ventasProductos.fold(
        0.0, (sum, producto) => sum + (producto.precio * producto.cantidad));
      return subtotal * (venta.cliente.descuentoGlobal / 100);
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

  // Función para confirmar eliminación
  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AppTheme.confirmDialogStyle(
          title: 'Confirmar Eliminación',
          content: '¿Está seguro de que desea eliminar esta venta? Esta acción no se puede deshacer.',
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        );
      },
    );

    if (confirm == true) {
      try {
        await VentasProvider().eliminarVenta(venta.id!);
        if (context.mounted) {
          Navigator.of(context).pop(true); // Return true to indicate deletion
          AppTheme.showSnackBar(
            context,
            AppTheme.successSnackBar('Venta eliminada correctamente'),
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppTheme.showSnackBar(
            context,
            AppTheme.errorSnackBar('Error al eliminar venta: $e'),
          );
        }
      }
    }
  }

  // Función para obtener todos los métodos de pago separados por comas
  String _getAllPaymentMethodsString(Ventas venta) {
    List<String> metodos = [];
    
    // Agregar el método de pago principal si existe
    if (venta.metodoPago != null) {
      metodos.add(_getMetodoPagoString(venta.metodoPago));
    }
    
    // Agregar métodos de pago de la lista de pagos si existen
    if (venta.pagos != null && venta.pagos!.isNotEmpty) {
      for (var pago in venta.pagos!) {
        String metodo = _getMetodoPagoString(pago.metodo);
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

  // Función para convertir enum a string
  String _getMetodoPagoString(MetodoPago? metodoPago) {
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
}
