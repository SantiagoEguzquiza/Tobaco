import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:printing/printing.dart';
import 'package:tobaco/Utils/pdf_generator/venta_pdf_builder.dart';
import 'package:tobaco/Services/Printer_Service/bluetooth_printer_service.dart';

class DetalleVentaScreen extends StatefulWidget {
  final Ventas venta;

  const DetalleVentaScreen({super.key, required this.venta});

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  bool _isPrinting = false;

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                  // Margen inferior para que los botones no queden pegados al Desglose de Pagos
                  const SizedBox(height: 24),
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
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusCards),
                topRight: Radius.circular(AppTheme.borderRadiusCards),
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
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusCards),
                topRight: Radius.circular(AppTheme.borderRadiusCards),
              ),
            ),
            child: Row(
              children: [             
                Text(
                  'Productos',
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
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
                    onPressed: _isPrinting
                        ? null
                        : () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (sheetContext) {
                                final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
                                final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
                                final cardBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8);
                                final textColor = isDark ? Colors.white : Colors.black87;
                                final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
                                final maxHeight = MediaQuery.of(sheetContext).size.height * 0.7;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, -4),
                                      ),
                                    ],
                                  ),
                                  child: SafeArea(
                                    top: false,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(maxHeight: maxHeight),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: subColor,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Text(
                                                'Opciones de impresión',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              _PrintOptionTile(
                                            icon: Icons.picture_as_pdf_rounded,
                                            title: 'Imprimir PDF',
                                            subtitle: 'Vista previa e impresión del comprobante',
                                            backgroundColor: cardBg,
                                            onTap: () async {
                                              Navigator.of(sheetContext).pop();
                                              try {
                                                final bytes = await buildVentaPdf(widget.venta);
                                                await Printing.layoutPdf(onLayout: (_) async => bytes);
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error al generar PDF: $e')),
                                                );
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          _PrintOptionTile(
                                            icon: Icons.receipt_long_rounded,
                                            title: 'Imprimir ticket',
                                            subtitle: 'Enviar a impresora térmica por Bluetooth',
                                            backgroundColor: cardBg,
                                            onTap: () async {
                                              Navigator.of(sheetContext).pop();
                                              await _imprimirTicketTermico(context);
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          _PrintOptionTile(
                                            icon: Icons.share_rounded,
                                            title: 'Compartir PDF',
                                            subtitle: 'Enviar por WhatsApp, correo o otras apps',
                                            backgroundColor: cardBg,
                                            onTap: () async {
                                              Navigator.of(sheetContext).pop();
                                              try {
                                                final bytes = await buildVentaPdf(widget.venta);
                                                final dir = await getTemporaryDirectory();
                                                final ventaLabel = widget.venta.id != null
                                                    ? 'Venta_${widget.venta.id}'
                                                    : 'Venta_pendiente';
                                                final file = File('${dir.path}/$ventaLabel.pdf');
                                                await file.writeAsBytes(bytes);
                                                await Share.shareXFiles(
                                                  [XFile(file.path)],
                                                  text: 'Comprobante de venta - $ventaLabel',
                                                );
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error al compartir PDF: $e')),
                                                );
                                              }
                                            },
                                          ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
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
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
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
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
    if (_isPrinting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impresión en curso, por favor esperá...')),
      );
      return;
    }

    setState(() => _isPrinting = true);

    try {
      final printerService = BluetoothPrinterService.instance;

      // Try the previously-known device first (probe verifies it's alive).
      if (printerService.connectedDevice != null) {
        try {
          await printerService.printTicket(widget.venta);
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
          await printerService.printTicket(widget.venta);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.print_rounded, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'Seleccionar impresora',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asegurate de que la impresora esté encendida.',
              style: TextStyle(fontSize: 14, color: subColor),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              )
            else if (errorMessage != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 40, color: Colors.red.shade400),
                  const SizedBox(height: 12),
                  Text(errorMessage!, style: TextStyle(color: textColor), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadBondedDevices,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons)),
                    ),
                  ),
                ],
              )
            else if (devices.isEmpty)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bluetooth_disabled_rounded, size: 48, color: subColor),
                  const SizedBox(height: 12),
                  Text(
                    'No hay dispositivos emparejados',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Para vincular la impresora:\n'
                    '1. Andá a Ajustes > Bluetooth\n'
                    '2. Buscá y vinculá la impresora\n'
                    '3. Volvé a la app y tocá "Actualizar"',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: subColor),
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
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(device),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.print_rounded, color: AppTheme.primaryColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      (device.name?.isNotEmpty == true) ? device.name! : 'Dispositivo desconocido',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
                                    ),
                                    if (device.address != null && device.address!.isNotEmpty)
                                      Text(
                                        device.address!,
                                        style: TextStyle(fontSize: 12, color: subColor),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: subColor, size: 22),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
            foregroundColor: isDark ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
            ),
          ),
          child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ),
        if (!isLoading)
          TextButton(
            onPressed: _loadBondedDevices,
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
              ),
            ),
            child: const Text('Actualizar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
      ],
    );
  }
}

class _PrintOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _PrintOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: subColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}