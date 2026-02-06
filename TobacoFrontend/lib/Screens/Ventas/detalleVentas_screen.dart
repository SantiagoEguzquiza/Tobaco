import 'package:flutter/material.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:printing/printing.dart';
import 'package:tobaco/Utils/pdf_generator/venta_pdf_builder.dart';
import 'package:tobaco/Services/Printer_Service/bluetooth_printer_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DetalleVentaScreen extends StatefulWidget {
  final Ventas venta;

  const DetalleVentaScreen({super.key, required this.venta});

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            widget.venta.id != null ? 'Venta #${widget.venta.id}' : 'Venta Pendiente',
            style: AppTheme.appBarTitleStyle
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(             
                children: [               
                  // Header con información principal de la venta
                  _buildHeaderSection(context),
                  const SizedBox(height: 20),

                  // Información detallada de la venta
                  _buildInfoCard(context),
                  const SizedBox(height: 20),

                  // Lista de productos
                  _buildProductsSection(context),
                  const SizedBox(height: 20),

                  // Resumen de totales
                  _buildSummarySection(context),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomActions(context),
      );
  }

  // Header principal con información de la venta
  Widget _buildHeaderSection(BuildContext context) {
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
                child:  Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
                  size: 35,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalle de Venta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      widget.venta.id != null ? 'Venta #${widget.venta.id}' : 'Venta Pendiente',
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
                    widget.venta.cliente.nombre,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.primaryColor,
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
                  _formatearPrecioConDecimales(widget.venta.total, context: context),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tarjeta con información detallada
  Widget _buildInfoCard(BuildContext context) {
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
                _buildInfoRow(Icons.calendar_today, 'Fecha', _formatFecha(widget.venta.fecha)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.payment, 'Método de Pago', _getAllPaymentMethodsString(widget.venta)),
                const SizedBox(height: 12),               
                _buildInfoRow(Icons.person, 'Usuario', widget.venta.usuarioCreador?.userName ?? 'No disponible'),
                const SizedBox(height: 12),
                _buildEstadoEntregaRow(),
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
  Widget _buildProductsSection(BuildContext context) {
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
                Text(
                  'Productos (${widget.venta.ventasProductos.length})',
                  style:  TextStyle(
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.venta.ventasProductos.length,
            itemBuilder: (context, index) {
              final producto = widget.venta.ventasProductos[index];
              final isLast = index == widget.venta.ventasProductos.length - 1;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: producto.entregado
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              producto.entregado ? Icons.check_circle : Icons.inventory_2,
                              color: producto.entregado
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  producto.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                    decoration: producto.entregado ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cantidad: ${producto.cantidad}',
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildPrecioConDescuento(producto, context),
                            ],
                          ),
                        ],
                      ),
                      // Mostrar motivo y nota si no está entregado
                      if (!producto.entregado && producto.motivo != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Motivo: ${producto.motivo}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (producto.nota != null && producto.nota!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Nota: ${producto.nota}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
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
  Widget _buildSummarySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade200,
          width: 1,
        ),
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
        children: [
          // Desglose de métodos de pago
          if (widget.venta.pagos != null && widget.venta.pagos!.isNotEmpty) ...[
            Text(
              'Desglose de Pagos:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.venta.pagos!.map((pago) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getPaymentIcon(pago.metodo),
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    context: context,
                  ),
                ],
              ),
            )),
          ],
          // Mostrar descuento si aplica
          if (widget.venta.cliente.descuentoGlobal > 0) ...[
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
                      'Descuento Global (${widget.venta.cliente.descuentoGlobal.toStringAsFixed(1)}%):',
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
              _formatearPrecioConDecimales(widget.venta.total, context: context),
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
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor),
                                  title: const Text('Imprimir PDF'),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    try {
                                      final bytes = await buildVentaPdf(widget.venta);
                                      await Printing.layoutPdf(onLayout: (_) async => bytes);
                                    } catch (e) {
                                      // ignore: use_build_context_synchronously
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
                                    Navigator.of(context).pop();
                                    await _imprimirTicketTermico(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.share, color: AppTheme.primaryColor),
                                  title: const Text('Compartir PDF por WhatsApp'),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          );
                        },
                      );
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
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardTheme.color,
                      side: const BorderSide(color: Colors.grey, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Volver',
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
    if (widget.venta.cliente.descuentoGlobal > 0) {
      // Calcular el subtotal sumando todos los productos
      final subtotal = widget.venta.ventasProductos.fold(
        0.0, (sum, producto) => sum + (producto.precio * producto.cantidad));
      return subtotal * (widget.venta.cliente.descuentoGlobal / 100);
    }
    return 0.0;
  }



  // Verifica si un producto de la venta tenía descuento activo
  bool _tieneDescuentoActivoProducto(VentasProductos ventaProducto) {
    // Si no hay descuento, retornar false
    if (ventaProducto.descuento <= 0) {
      return false;
    }

    // Si el descuento es indefinido, está activo
    if (ventaProducto.descuentoIndefinido) {
      return true;
    }

    // Si tiene fecha de expiración, verificar si no venció
    if (ventaProducto.fechaExpiracionDescuento != null) {
      final ahora = DateTime.now();
      final fechaExpiracion = ventaProducto.fechaExpiracionDescuento!;
      return fechaExpiracion.isAfter(ahora);
    }

    // Si tiene descuento pero no es indefinido y no tiene fecha, considerar activo
    return true;
  }

  // Widget para mostrar precio con descuento si aplica
  Widget _buildPrecioConDescuento(VentasProductos ventaProducto, BuildContext context) {
    // Verificar si este producto específico tenía descuento activo en el momento de la venta
    final tieneDescuentoProducto = _tieneDescuentoActivoProducto(ventaProducto);
    
    if (tieneDescuentoProducto) {
      final porcentajeDescuento = ventaProducto.descuento;
      final precioOriginal = ventaProducto.precio * ventaProducto.cantidad;
      
      // Mostrar precio original tachado al lado del badge de descuento
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Precio original tachado + badge de descuento en la misma línea
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${_formatearPrecio(precioOriginal)}',
                style: TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-${porcentajeDescuento.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Precio final (solo una vez)
          Text(
            '\$${_formatearPrecio(ventaProducto.precioFinalCalculado)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      );
    } else {
      // Verificar si hay descuento global del cliente comparando precios
      final precioBaseEsperado = ventaProducto.precio * ventaProducto.cantidad;
      final tieneDescuentoGlobal = ventaProducto.precioFinalCalculado < precioBaseEsperado;
      
      if (tieneDescuentoGlobal) {
        // Solo descuento global del cliente (no descuento del producto)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${_formatearPrecio(precioBaseEsperado)}',
              style: TextStyle(
                fontSize: 14,
                decoration: TextDecoration.lineThrough,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '\$${_formatearPrecio(ventaProducto.precioFinalCalculado)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        );
      } else {
        // Sin descuentos
        return Text(
          '\$${_formatearPrecio(ventaProducto.precioFinalCalculado)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        );
      }
    }
  }


  // Widget para formatear precios con decimales más pequeños y grises
  Widget _formatearPrecioConDecimales(double precio, {Color? color, required BuildContext context}) {
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : (color ?? AppTheme.primaryColor),
            ),
          ),
          TextSpan(
            text: ',$parteDecimal',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade400,
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

  // Widget para mostrar el estado de entrega (misma estructura que _buildInfoRow: valor alineado con los de arriba)
  Widget _buildEstadoEntregaRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.local_shipping,
          color: Colors.grey.shade600,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Estado de',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              Text(
                'Entrega',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildEstadoEntregaBadge(widget.venta.estadoEntrega),
          ),
        ),
      ],
    );
  }

  // Badge del estado de entrega
  Widget _buildEstadoEntregaBadge(EstadoEntrega estado) {
    Color bgColor;
    Color textColor;
    IconData icon;
    
    switch (estado) {
      case EstadoEntrega.entregada:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case EstadoEntrega.parcial:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.access_time;
        break;
      case EstadoEntrega.noEntregada:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.local_shipping;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              estado.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _imprimirTicketTermico(BuildContext context) async {
    try {
      final printerService = BluetoothPrinterService.instance;

      // Verificar si ya está conectada una impresora
      if (printerService.isConnected) {
        // Imprimir directamente
        await printerService.printTicket(widget.venta);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket enviado a la impresora')),
        );
        return;
      }

      // Mostrar diálogo de selección de impresora
      if (!context.mounted) return;
      
      final selectedPrinter = await showDialog<BluetoothDevice>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _PrinterSelectionDialog(),
      );

      if (selectedPrinter == null) {
        return;
      }

      // Conectar e imprimir
      await printerService.connectToDevice(selectedPrinter);
      
      if (!context.mounted) return;
      
      await printerService.printTicket(widget.venta);
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket enviado a la impresora')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al imprimir ticket: $e')),
      );
    }
  }

}

// Diálogo para seleccionar impresora
class _PrinterSelectionDialog extends StatefulWidget {
  @override
  State<_PrinterSelectionDialog> createState() => _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<_PrinterSelectionDialog> {
  List<BluetoothDevice> printers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _scanForPrinters();
  }

  Future<void> _scanForPrinters() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final printerService = BluetoothPrinterService.instance;
      final foundPrinters = await printerService.scanForPrinters();

      if (!mounted) return;
      setState(() {
        printers = foundPrinters;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error al buscar impresoras: $e';
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _scanForPrinters,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  )
                : printers.isEmpty
                    ? const Text('No se encontraron impresoras')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: printers.length,
                        itemBuilder: (context, index) {
                          final printer = printers[index];
                          return ListTile(
                            leading: const Icon(Icons.print),
                            title: Text(printer.name.isEmpty ? 'Impresora desconocida' : printer.name),
                            subtitle: Text(printer.remoteId.toString()),
                            onTap: () => Navigator.of(context).pop(printer),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (!isLoading && printers.isEmpty)
          TextButton(
            onPressed: _scanForPrinters,
            child: const Text('Buscar de nuevo'),
          ),
      ],
    );
  }
}
