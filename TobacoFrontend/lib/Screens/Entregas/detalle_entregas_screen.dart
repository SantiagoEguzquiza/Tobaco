import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';

class DetalleEntregasScreen extends StatefulWidget {
  const DetalleEntregasScreen({super.key, required this.venta});

  final Ventas venta;

  @override
  State<DetalleEntregasScreen> createState() => _DetalleEntregasScreenState();

}

class _ProductoUnidad {
  _ProductoUnidad({
    required this.productoIndex,
    required this.unidadNumero,
    required this.totalUnidades,
    required this.entregado,
    this.motivo,
    this.nota,
  });

  final int productoIndex;
  final int unidadNumero;
  final int totalUnidades;
  bool entregado;
  String? motivo;
  String? nota;
}

class _DetalleEntregasScreenState extends State<DetalleEntregasScreen> {
  static const Map<String, IconData> _motivosComunes = {
    'Sin stock': Icons.inventory_2_outlined,
    'Olvido': Icons.psychology_outlined,
    'Error de preparación': Icons.error_outline,
    'Producto dañado': Icons.broken_image_outlined,
    'Cliente no disponible': Icons.person_off_outlined,
    'Otro': Icons.more_horiz,
  };

  late List<VentasProductos> _productosEditables;
  late final List<_ProductoUnidad> _unidades;
  bool _hasChanges = false;
  bool _hasGuardadoCambios = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _productosEditables = widget.venta.ventasProductos
        .map(
          (p) => VentasProductos(
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
          ),
        )
        .toList();
    _unidades = _generarUnidades();
  }

  List<_ProductoUnidad> _generarUnidades() {
    final unidades = <_ProductoUnidad>[];

    for (var i = 0; i < _productosEditables.length; i++) {
      final producto = _productosEditables[i];
      final totalUnidades = _cantidadUnidades(producto);

      final motivosPorUnidad = _parseDetallePorUnidad(producto.motivo);
      final notasPorUnidad = _parseDetallePorUnidad(producto.nota);

      for (var unidad = 1; unidad <= totalUnidades; unidad++) {
        final motivoUnidad = motivosPorUnidad[unidad];
        final notaUnidad = notasPorUnidad[unidad];

        bool entregado;
        if (motivoUnidad != null) {
          // Esta unidad quedó explícitamente marcada como no entregada.
          entregado = false;
        } else if (producto.entregado) {
          // El backend indica que el producto completo está entregado.
          entregado = true;
        } else if (motivosPorUnidad.isNotEmpty) {
          // Hay motivos por unidad, las restantes se consideran entregadas.
          entregado = true;
        } else {
          // Sin información suficiente: asumir que ninguna unidad fue entregada.
          entregado = false;
        }

        unidades.add(
          _ProductoUnidad(
            productoIndex: i,
            unidadNumero: unidad,
            totalUnidades: totalUnidades,
            entregado: entregado,
            motivo: motivoUnidad,
            nota: notaUnidad,
          ),
        );
      }
    }

    return unidades;
  }

  @override
  Widget build(BuildContext context) {
    final fechaFormateada =
        DateFormat('dd/MM/yyyy – HH:mm').format(widget.venta.fecha);
    final estadoActual = _hasChanges
        ? _calcularEstadoEntrega(_productosEditables)
        : widget.venta.estadoEntrega;
    final unidadesPendientes =
        _unidades.where((unidad) => !unidad.entregado).toList();
    final unidadesEntregadas =
        _unidades.where((unidad) => unidad.entregado).toList();
    final unidadesSinMotivo = unidadesPendientes
        .where((unidad) => unidad.motivo == null || unidad.motivo!.isEmpty)
        .toList();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasGuardadoCambios ? 'updated' : null);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            widget.venta.id != null
                ? 'Entrega #${widget.venta.id}'
                : 'Entrega pendiente',
            style: AppTheme.appBarTitleStyle,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(
              context,
              _hasGuardadoCambios ? 'updated' : null,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderSection(
                    context,
                    estadoActual: estadoActual,
                    fechaFormateada: fechaFormateada,
                    pendientes: unidadesPendientes.length,
                    entregados: unidadesEntregadas.length,
                  ),
                  const SizedBox(height: 20),
                  _buildInfoSection(context),
                  const SizedBox(height: 20),
                  _buildProductosSection(context),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomActions(
          unidadesSinMotivo: unidadesSinMotivo,
        ),
      ),
    );
  }

  Map<int, String> _parseDetallePorUnidad(String? texto) {
    final resultado = <int, String>{};
    if (texto == null || texto.trim().isEmpty) {
      return resultado;
    }

    final lineas = texto.split('\n');
    final regex = RegExp(r'^Unidad\s+(\d+):\s*(.*)$');

    for (final linea in lineas) {
      final match = regex.firstMatch(linea.trim());
      if (match != null) {
        final numero = int.tryParse(match.group(1) ?? '');
        if (numero != null) {
          resultado[numero] = match.group(2)?.trim() ?? '';
        }
      }
    }

    return resultado;
  }

  Widget _buildHeaderSection(
    BuildContext context, {
    required EstadoEntrega estadoActual,
    required String fechaFormateada,
    required int pendientes,
    required int entregados,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F1F1F)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.08,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1F1F1F)
                      : Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalle de Entrega',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      widget.venta.id != null
                          ? 'Pedido #${widget.venta.id}'
                          : 'Entrega pendiente',
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
          const SizedBox(height: 18),
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
                    widget.venta.cliente.nombre,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fechaFormateada,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
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
                  Text(
                    _formatearPrecioTexto(widget.venta.total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildEstadoEntregaBadge(estadoActual),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildResumenChip(
                  icon: Icons.pending_actions_outlined,
                  label: pendientes == 1
                      ? '1 producto pendiente'
                      : '$pendientes productos pendientes',
                  color: Colors.orange.shade600,
                ),
                _buildResumenChip(
                  icon: Icons.check_circle_outline,
                  label: entregados == 1
                      ? '1 producto entregado'
                      : '$entregados productos entregados',
                  color: Colors.green.shade600,
                ),
                if (_hasChanges)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Cambios sin guardar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F1F1F)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
            width: double.infinity,
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
            child: Text(
              'Información de la Entrega',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.person,
                  'Cliente',
                  widget.venta.cliente.nombre,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_month,
                  'Fecha de creación',
                  DateFormat('dd/MM/yyyy – HH:mm').format(widget.venta.fecha),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.attach_money,
                  'Total venta',
                  _formatearPrecioTexto(widget.venta.total),
                ),
                if (widget.venta.usuarioAsignado?.userName != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.assignment_ind,
                    'Asignado a',
                    widget.venta.usuarioAsignado!.userName!,
                  ),
                ],
                if (widget.venta.usuarioCreador?.userName != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.person_outline,
                    'Registrado por',
                    widget.venta.usuarioCreador!.userName!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
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

  Widget _buildProductosSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F1F1F)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Productos (${_unidades.length})',
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
          if (_unidades.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Text(
                'No hay productos en esta entrega.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _unidades.length,
              itemBuilder: (context, index) {
                final unidad = _unidades[index];
                final isEntregado = unidad.entregado;
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
                  child: _buildUnidadItemInList(
                    context,
                    unidad,
                    isEntregado: isEntregado,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUnidadItemInList(
    BuildContext context,
    _ProductoUnidad unidad, {
    required bool isEntregado,
  }) {
    final productoBase = _productosEditables[unidad.productoIndex];
    final motivo = unidad.motivo ?? '';
    final nota = unidad.nota ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isEntregado,
                onChanged: (value) async {
                  if (value == null) return;
                  await _onToggleUnidad(unidad, value);
                },
                activeColor: AppTheme.primaryColor,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEntregado
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEntregado ? Icons.check_circle : Icons.inventory_2,
                  color: isEntregado
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
                      productoBase.cantidad > 1
                          ? '${productoBase.nombre} · Unidad ${unidad.unidadNumero} de ${unidad.totalUnidades}'
                          : productoBase.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        decoration:
                            isEntregado ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      productoBase.cantidad > 1
                          ? 'Cantidad: ${productoBase.cantidad} · Unidad ${unidad.unidadNumero}'
                          : 'Cantidad: ${productoBase.cantidad}',
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
                  Text(
                    _formatearPrecioTexto(
                      productoBase.precioFinalCalculado /
                          unidad.totalUnidades,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  if (!isEntregado) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _mostrarDialogoMotivoUnidad(unidad),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: motivo.isEmpty
                              ? Colors.red.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              motivo.isEmpty ? Icons.warning : Icons.edit,
                              size: 12,
                              color: motivo.isEmpty
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              motivo.isEmpty
                                  ? 'Agregar motivo'
                                  : 'Editar motivo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: motivo.isEmpty
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
          if (!isEntregado && motivo.isNotEmpty) ...[
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
                        'Motivo: $motivo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (nota.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Nota: $nota',
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
    );
  }

  Widget _buildProductosCard(
    BuildContext context, {
    required String titulo,
    required List<_ProductoUnidad> unidades,
    required String emptyMessage,
    required Color highlightColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F1F1F)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  titulo.contains('Pendientes')
                      ? Icons.pending_actions_outlined
                      : Icons.check_circle_outline,
                  color: titulo.contains('Pendientes')
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
                ),
                const SizedBox(width: 10),
                Text(
                  '$titulo (${unidades.length})',
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
          const SizedBox(height: 12),
          if (unidades.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            )
          else
            Column(
              children: unidades
                  .map(
                    (unidad) => _buildUnidadItem(
                      unidad,
                      highlightColor: highlightColor,
                      borderColor: borderColor,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildUnidadItem(
    _ProductoUnidad unidad, {
    required Color highlightColor,
    required Color borderColor,
  }) {
    final productoBase = _productosEditables[unidad.productoIndex];
    final isEntregado = unidad.entregado;
    final motivo = unidad.motivo ?? '';
    final nota = unidad.nota ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? (isEntregado
                ? const Color(0xFF1E2B22)
                : const Color(0xFF2B2420))
            : highlightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEntregado ? Colors.green.shade200 : borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isEntregado,
                onChanged: (value) async {
                  if (value == null) return;
                  await _onToggleUnidad(unidad, value);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productoBase.cantidad > 1
                          ? '${productoBase.nombre} · Unidad ${unidad.unidadNumero} de ${unidad.totalUnidades}'
                          : productoBase.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Producto #${unidad.unidadNumero}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.attach_money,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          _formatearPrecioTexto(
                            productoBase.precioFinalCalculado /
                                unidad.totalUnidades,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isEntregado)
                IconButton(
                  tooltip: 'Editar motivo',
                  icon: Icon(Icons.edit_note, color: Colors.orange.shade700),
                  onPressed: () => _mostrarDialogoMotivoUnidad(unidad),
                ),
            ],
          ),
          if (!isEntregado && motivo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3A2D2D)
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Motivo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    motivo,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  if (nota.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Nota: $nota',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions({
    required List<_ProductoUnidad> unidadesSinMotivo,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B1B1B)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasChanges && unidadesSinMotivo.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Agrega un motivo a los productos no entregados antes de guardar.',
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.pop(
                              context,
                              _hasGuardadoCambios ? 'updated' : null,
                            ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Volver',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !_hasChanges ||
                            _isSaving ||
                            widget.venta.id == null ||
                            unidadesSinMotivo.isNotEmpty
                        ? null
                        : _guardarEstadoEntrega,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSaving ? 'Guardando...' : 'Guardar cambios',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Future<void> _onToggleUnidad(
    _ProductoUnidad unidad,
    bool marcarEntregado,
  ) async {
    if (marcarEntregado) {
      setState(() {
        unidad.entregado = true;
        unidad.motivo = null;
        unidad.nota = null;
        _hasChanges = true;
        _sincronizarProductosDesdeUnidades();
      });
    } else {
      final confirmado = await _mostrarDialogoMotivoUnidad(unidad);
      if (!confirmado) {
        setState(() {
          unidad.entregado = true;
        });
      }
    }
  }

  Future<bool> _mostrarDialogoMotivoUnidad(_ProductoUnidad unidad) async {
    final motivoController = TextEditingController(text: unidad.motivo);
    final notaController = TextEditingController(text: unidad.nota);
    String? motivoSeleccionado =
        (unidad.motivo != null && unidad.motivo!.isNotEmpty)
            ? unidad.motivo
            : null;
    final productoBase = _productosEditables[unidad.productoIndex];

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        children: const [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Producto no entregado',
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
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_bag_outlined,
                                      size: 18,
                                      color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${productoBase.nombre} · Unidad ${unidad.unidadNumero} de ${unidad.totalUnidades}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  'Motivo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 4),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _motivosComunes.entries.map((entry) {
                                final isSelected =
                                    motivoSeleccionado == entry.key;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    setDialogState(() {
                                      motivoSeleccionado = entry.key;
                                      motivoController.text = entry.key;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey.shade800
                                              : Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          entry.value,
                                          size: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nota (opcional)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: notaController,
                              maxLines: 3,
                              maxLength: 120,
                              decoration: InputDecoration(
                                hintText: 'Agregar un comentario…',
                                filled: true,
                                fillColor:
                                    Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (motivoSeleccionado != null &&
                                    motivoSeleccionado!.isNotEmpty) {
                                  Navigator.of(dialogContext).pop(true);
                                } else {
                                  ScaffoldMessenger.of(dialogContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Seleccioná un motivo para continuar.',
                                      ),
                                      backgroundColor: Colors.red.shade600,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Confirmar',
                                style: TextStyle(
                                  color: Colors.white,
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
      },
    );

    if (result == true) {
      setState(() {
        unidad.entregado = false;
        unidad.motivo = motivoController.text.trim();
        unidad.nota =
            notaController.text.trim().isNotEmpty ? notaController.text.trim() : null;
        _hasChanges = true;
        _sincronizarProductosDesdeUnidades();
      });
      return true;
    }

    return false;
  }

  Future<void> _guardarEstadoEntrega() async {
    _sincronizarProductosDesdeUnidades();

    if (widget.venta.id == null) {
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar(
          'No se puede actualizar la entrega porque la venta aún no tiene ID.',
        ),
      );
      return;
    }

    final productosSinMotivo = _productosEditables
        .where((p) => !p.entregado && (p.motivo == null || p.motivo!.isEmpty))
        .toList();

    if (productosSinMotivo.isNotEmpty) {
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar(
          'Agrega un motivo a los productos no entregados antes de guardar.',
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      final ventasProvider = context.read<VentasProvider>();
      await ventasProvider.actualizarEstadoEntrega(
        widget.venta.id!,
        _productosEditables,
      );

      if (!mounted) return;

      for (int i = 0; i < widget.venta.ventasProductos.length; i++) {
        widget.venta.ventasProductos[i].entregado =
            _productosEditables[i].entregado;
        widget.venta.ventasProductos[i].motivo = _productosEditables[i].motivo;
        widget.venta.ventasProductos[i].nota = _productosEditables[i].nota;
      }
      widget.venta.estadoEntrega =
          _calcularEstadoEntrega(_productosEditables);

      setState(() {
        _hasChanges = false;
        _hasGuardadoCambios = true;
        _isSaving = false;
      });

      AppTheme.showSnackBar(
        context,
        AppTheme.successSnackBar('Estado de entrega actualizado correctamente.'),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar('Error al actualizar estado de entrega: $e'),
      );
    }
  }

  void _sincronizarProductosDesdeUnidades() {
    for (var i = 0; i < _productosEditables.length; i++) {
      final producto = _productosEditables[i];
      final unidadesProducto =
          _unidades.where((unidad) => unidad.productoIndex == i).toList();
      final todasEntregadas =
          unidadesProducto.every((unidad) => unidad.entregado);

      producto.entregado = todasEntregadas;

      if (todasEntregadas) {
        producto.motivo = null;
        producto.nota = null;
      } else {
        final motivos = unidadesProducto
            .where((unidad) => !unidad.entregado && unidad.motivo != null)
            .map((unidad) =>
                'Unidad ${unidad.unidadNumero}: ${unidad.motivo!.trim()}')
            .toList();
        final notas = unidadesProducto
            .where((unidad) => !unidad.entregado && unidad.nota != null)
            .map(
              (unidad) =>
                  'Unidad ${unidad.unidadNumero}: ${unidad.nota!.trim()}',
            )
            .toList();

        producto.motivo = motivos.isNotEmpty ? motivos.join('\n') : null;
        producto.nota = notas.isNotEmpty ? notas.join('\n') : null;
      }
    }
  }

  int _cantidadUnidades(VentasProductos producto) {
    if (producto.cantidad <= 1) return 1;
    if (producto.cantidad % 1 == 0) return producto.cantidad.toInt();
    return producto.cantidad.ceil();
  }

  EstadoEntrega _calcularEstadoEntrega(List<VentasProductos> productos) {
    if (productos.isEmpty) {
      return EstadoEntrega.noEntregada;
    }
    final total = productos.length;
    final entregados = productos.where((p) => p.entregado).length;
    if (entregados == 0) return EstadoEntrega.noEntregada;
    if (entregados == total) return EstadoEntrega.entregada;
    return EstadoEntrega.parcial;
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearPrecioTexto(double precio) {
    final precioStr = precio.toStringAsFixed(2);
    final partes = precioStr.split('.');
    final parteEntera =
        partes[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]}.');
    final parteDecimal = partes[1];
    return '\$$parteEntera,$parteDecimal';
  }
}

