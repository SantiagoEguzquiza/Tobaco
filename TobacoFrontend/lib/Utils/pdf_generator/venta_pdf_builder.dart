import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Models/ventasPago.dart';
import 'package:tobaco/Models/metodoPago.dart';

String _metodoPagoText(MetodoPago metodo) {
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

String _formatCurrency(num value) {
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final integerPart = parts[0];
  final decimalPart = parts[1];

  final withThousands = integerPart.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.'
  );

  final formatted = '$withThousands,$decimalPart';
  return isNegative ? '-$formatted' : formatted;
}

String _formatDate(DateTime date) {
  final formatter = DateFormat('dd/MM/yyyy HH:mm');
  return formatter.format(date);
}

pw.Widget _buildHeader(Ventas venta) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Comprobante de Venta', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(venta.id != null ? 'Venta #${venta.id}' : 'Venta (local)', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Text(_formatDate(venta.fecha), style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Divider(),
      pw.SizedBox(height: 8),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Cliente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(venta.cliente.nombre),
                if (venta.cliente.direccion != null && venta.cliente.direccion!.isNotEmpty)
                  pw.Text(venta.cliente.direccion!, style: const pw.TextStyle(fontSize: 10)),
                if (venta.cliente.telefono != null)
                  pw.Text('Tel: ${venta.cliente.telefono}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(_formatCurrency(venta.total), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          )
        ],
      ),
    ],
  );
}

pw.Widget _buildItemsTable(List<VentasProductos> items) {
  final headers = ['Producto', 'Cant.', 'Precio', 'Subtotal'];
  final data = items.map((e) {
    final subtotal = e.precioFinalCalculado > 0 ? e.precioFinalCalculado : e.precio * e.cantidad;
    return [
      e.nombre,
      e.cantidad.toStringAsFixed(2),
      _formatCurrency(e.precio),
      _formatCurrency(subtotal),
    ];
  }).toList();

  return pw.Table.fromTextArray(
    headers: headers,
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFEFEF)),
    cellAlignment: pw.Alignment.centerLeft,
    headerAlignment: pw.Alignment.centerLeft,
    data: data,
    cellStyle: const pw.TextStyle(fontSize: 10),
    columnWidths: {
      0: const pw.FlexColumnWidth(3),
      1: const pw.FlexColumnWidth(1),
      2: const pw.FlexColumnWidth(2),
      3: const pw.FlexColumnWidth(2),
    },
    border: null,
    rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
  );
}

pw.Widget _buildPagos(List<VentaPago>? pagos, MetodoPago? metodoPrincipal) {
  final rows = <pw.Widget>[];

  if (metodoPrincipal != null) {
    rows.add(pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Método principal:'),
        pw.Text(_metodoPagoText(metodoPrincipal), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    ));
  }

  if (pagos != null && pagos.isNotEmpty) {
    rows.add(pw.SizedBox(height: 6));
    rows.add(pw.Text('Pagos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
    for (final p in pagos) {
      rows.add(pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(_metodoPagoText(p.metodo)),
          pw.Text(_formatCurrency(p.monto)),
        ],
      ));
    }
  }

  if (rows.isEmpty) {
    rows.add(pw.Text('Sin información de pagos', style: const pw.TextStyle(fontSize: 10)));
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: rows,
  );
}

Future<Uint8List> buildVentaPdf(Ventas venta) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        _buildHeader(venta),
        pw.SizedBox(height: 16),
        pw.Text('Detalle de productos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _buildItemsTable(venta.ventasProductos),
        pw.SizedBox(height: 12),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(_formatCurrency(venta.total), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        _buildPagos(venta.pagos, venta.metodoPago),
      ],
      footer: (context) => pw.Center(
        child: pw.Text('Gracias por su compra', style: const pw.TextStyle(fontSize: 10)),
      ),
    ),
  );

  return pdf.save();
}


