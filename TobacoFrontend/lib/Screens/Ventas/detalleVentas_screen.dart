import 'package:flutter/material.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Helpers/api_handler.dart';

class DetalleVentaScreen extends StatefulWidget {
  final Ventas venta;

  const DetalleVentaScreen({super.key, required this.venta});

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  late List<VentasProductos> productosEditables;
  bool hasChanges = false;
  bool hasGuardadoCambios = false; // Flag para indicar si se guardaron cambios

  @override
  void initState() {
    super.initState();
    // Crear copias editables de los productos
    productosEditables = widget.venta.ventasProductos.map((p) => 
      VentasProductos(
        productoId: p.productoId,
        nombre: p.nombre,
        precio: p.precio,
        cantidad: p.cantidad,
        categoria: p.categoria,
        categoriaId: p.categoriaId,
        precioFinalCalculado: p.precioFinalCalculado,
        entregado: p.entregado,
        motivo: p.motivo,
        nota: p.nota,
        fechaChequeo: p.fechaChequeo,
        usuarioChequeoId: p.usuarioChequeoId,
      )
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop && hasGuardadoCambios) {
          // La pantalla ya se cerró, pero podemos usar el Navigator para pasar el resultado
          // Esto se maneja en el botón "Volver" explícito
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Venta #${widget.venta.id}', style: AppTheme.appBarTitleStyle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, hasGuardadoCambios ? 'updated' : null),
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
      ),
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
                      'Venta #${widget.venta.id}',
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
                _buildInfoRow(Icons.person, 'Usuario', widget.venta.usuario?.userName ?? 'No disponible'),
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
                  'Productos (${productosEditables.length})',
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
            itemCount: productosEditables.length,
            itemBuilder: (context, index) {
              final producto = productosEditables[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
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
                          // Checkbox para marcar como entregado
                          Checkbox(
                            value: producto.entregado,
                            onChanged: (value) async {
                              if (value == false) {
                                // Si se marca como no entregado, pedir motivo
                                await _mostrarDialogoMotivo(producto);
                              } else {
                                // Si se marca como entregado, actualizar directamente
                                setState(() {
                                  producto.entregado = true;
                                  producto.motivo = null;
                                  producto.nota = null;
                                  hasChanges = true;
                                });
                              }
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              producto.entregado ? Icons.check_circle : Icons.inventory_2,
                              color: producto.entregado ? Colors.green.shade700 : Colors.orange.shade700,
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
                              // Botón para agregar/editar motivo si no está entregado
                              if (!producto.entregado) ...[
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _mostrarDialogoMotivo(producto),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: producto.motivo == null 
                                          ? Colors.red.shade100 
                                          : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          producto.motivo == null ? Icons.warning : Icons.edit,
                                          size: 12,
                                          color: producto.motivo == null 
                                              ? Colors.red.shade700 
                                              : Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          producto.motivo == null ? 'Agregar motivo' : 'Editar motivo',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: producto.motivo == null 
                                                ? Colors.red.shade700 
                                                : Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
            )).toList(),
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
            // Botón de guardar estado de entrega (solo si hay cambios)
            if (hasChanges) ...[
              // Advertencia si hay productos sin motivo
              if (productosEditables.any((p) => !p.entregado && (p.motivo == null || p.motivo!.isEmpty)))
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Agrega motivo a los productos no entregados antes de guardar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: _guardarEstadoEntrega,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Guardar Estado de Entrega',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, hasGuardadoCambios ? 'updated' : null),
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



  // Widget para mostrar precio simple
  Widget _buildPrecioConDescuento(VentasProductos producto, BuildContext context) {
    // Usar directamente el precio final calculado del backend
    return Text(
      '\$${_formatearPrecio(producto.precioFinalCalculado)}',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
    );
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
            text: '\$${parteEntera}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : (color ?? AppTheme.primaryColor),
            ),
          ),
          TextSpan(
            text: ',${parteDecimal}',
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

  // Función para confirmar eliminación
  void _confirmDelete(BuildContext context) async {
    final confirm = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Venta',
      message: '¿Está seguro de que desea eliminar esta venta? Esta acción no se puede deshacer.',
    );

    if (confirm == true) {
      try {
        await VentasProvider().eliminarVenta(widget.venta.id!);
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

  // Widget para mostrar el estado de entrega
  Widget _buildEstadoEntregaRow() {
    // Calcular el estado actual basado en los productos editables
    final estadoActual = hasChanges 
        ? _calcularEstadoEntrega(productosEditables)
        : widget.venta.estadoEntrega;
    
    return Row(
      children: [
        Icon(
          Icons.local_shipping,
          color: Colors.grey.shade600,
          size: 20,
        ),
        const SizedBox(width: 12),
        const Expanded(
          flex: 2,
          child: Text(
            'Estado de Entrega',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEstadoEntregaBadge(estadoActual),
              if (hasChanges)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '(sin guardar)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
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
    );
  }

  // Diálogo para capturar motivo y nota cuando no se entrega
  Future<void> _mostrarDialogoMotivo(VentasProductos producto) async {
    final TextEditingController motivoController = TextEditingController(text: producto.motivo);
    final TextEditingController notaController = TextEditingController(text: producto.nota);
    String? motivoSeleccionado = producto.motivo;

    final Map<String, IconData> motivosComunes = {
      'Sin stock': Icons.inventory_2_outlined,
      'Olvido': Icons.psychology_outlined,
      'Error de preparación': Icons.error_outline,
      'Producto dañado': Icons.broken_image_outlined,
      'Cliente no disponible': Icons.person_off_outlined,
      'Otro': Icons.more_horiz,
    };

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header compacto
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Producto No Entregado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contenido
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Producto info compacto
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey.shade800 
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_bag, color: Colors.orange.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${producto.nombre} (${producto.cantidad})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Theme.of(context).brightness == Brightness.dark 
                                            ? Colors.white 
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Label de motivo
                            Row(
                              children: [
                                Text(
                                  'Motivo ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white 
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  '*',
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Grid de opciones compacto
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: motivosComunes.entries.map((entry) {
                                final isSelected = motivoSeleccionado == entry.key;
                                return InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      motivoSeleccionado = entry.key;
                                      motivoController.text = entry.key;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? AppTheme.primaryColor 
                                          : (Theme.of(context).brightness == Brightness.dark 
                                              ? Colors.grey.shade800 
                                              : Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected 
                                            ? AppTheme.primaryColor.withOpacity(0.8)
                                            : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          entry.value,
                                          size: 16,
                                          color: isSelected 
                                              ? Colors.white 
                                              : (Theme.of(context).brightness == Brightness.dark 
                                                  ? Colors.grey.shade300 
                                                  : Colors.grey.shade700),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: isSelected 
                                                ? Colors.white 
                                                : (Theme.of(context).brightness == Brightness.dark 
                                                    ? Colors.grey.shade300 
                                                    : Colors.grey.shade700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Campo de nota compacto
                            Text(
                              'Nota (opcional)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey.shade300 
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: notaController,
                              maxLines: 3,
                              maxLength: 100,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Agregar nota...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey.shade800 
                                    : Colors.white,
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.all(25),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Botones de acción compactos
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop(false);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey.shade300 
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (motivoSeleccionado != null && motivoSeleccionado!.isNotEmpty) {
                                  Navigator.of(dialogContext).pop(true);
                                } else {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    SnackBar(
                                      content: const Text('Debes seleccionar un motivo'),
                                      backgroundColor: Colors.red.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: AppTheme.primaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Confirmar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
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
      },
    );

    if (result == true) {
      setState(() {
        // Asegurar que el producto esté marcado como no entregado
        producto.entregado = false;
        producto.motivo = motivoController.text;
        producto.nota = notaController.text.isNotEmpty ? notaController.text : null;
        hasChanges = true;
      });
    } else {
      // Si se cancela el diálogo, revertir el estado del checkbox
      setState(() {
        producto.entregado = true; // Volver al estado anterior
        hasChanges = false;
      });
    }
  }

  // Función para guardar el estado de entrega
  Future<void> _guardarEstadoEntrega() async {
    // Validar que todos los productos no entregados tengan motivo
    final productosNoEntregadosSinMotivo = productosEditables
        .where((p) => !p.entregado && (p.motivo == null || p.motivo!.isEmpty))
        .toList();

    if (productosNoEntregadosSinMotivo.isNotEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar(
          'Debes agregar un motivo a los ${productosNoEntregadosSinMotivo.length} producto(s) no entregado(s)'
        ),
      );
      return;
    }

    try {
      final ventasProvider = VentasProvider();
      await ventasProvider.actualizarEstadoEntrega(
        widget.venta.id!,
        productosEditables,
      );

      if (!mounted) return;

      setState(() {
        hasChanges = false;
        hasGuardadoCambios = true; // Marcar que se guardaron cambios
        // Actualizar la venta original con los nuevos estados
        for (int i = 0; i < widget.venta.ventasProductos.length; i++) {
          widget.venta.ventasProductos[i].entregado = productosEditables[i].entregado;
          widget.venta.ventasProductos[i].motivo = productosEditables[i].motivo;
          widget.venta.ventasProductos[i].nota = productosEditables[i].nota;
        }
        
        // Calcular y actualizar el estado de entrega de la venta
        widget.venta.estadoEntrega = _calcularEstadoEntrega(productosEditables);
      });

      // Mostrar snackbar de éxito
      AppTheme.showSnackBar(
        context,
        AppTheme.successSnackBar('Estado de entrega actualizado correctamente'),
      );
    } catch (e) {
      if (!mounted) return;
      
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar('Error al actualizar estado de entrega: $e'),
      );
    }
  }

  // Calcular el estado de entrega basado en los productos
  EstadoEntrega _calcularEstadoEntrega(List<VentasProductos> productos) {
    if (productos.isEmpty) {
      return EstadoEntrega.noEntregada;
    }

    final totalItems = productos.length;
    final itemsEntregados = productos.where((p) => p.entregado).length;

    if (itemsEntregados == 0) {
      return EstadoEntrega.noEntregada;        // 🔴 Ninguno entregado
    } else if (itemsEntregados == totalItems) {
      return EstadoEntrega.entregada;          // 🟢 Todos entregados
    } else {
      return EstadoEntrega.parcial;            // 🟠 Algunos entregados
    }
  }
}

