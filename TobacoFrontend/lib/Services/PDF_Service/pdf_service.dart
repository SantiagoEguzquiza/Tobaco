import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/metodoPago.dart';

class PDFService {
  static const String _appName = 'Tobaco System';

  /// Genera y muestra un PDF de la venta
  static Future<void> generateAndShowVentaPDF(Ventas venta, BuildContext context) async {
    try {
      final pdf = await _generateVentaPDF(venta);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf,
        name: 'Venta_${venta.id}_${_formatDateForFilename(venta.fecha)}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Genera y guarda un PDF de la venta usando el sistema de archivos
  static Future<void> saveVentaPDF(Ventas venta, BuildContext context) async {
    try {
      final pdf = await _generateVentaPDF(venta);
      final fileName = 'Venta_${venta.id}_${_formatDateForFilename(venta.fecha)}.pdf';
      
      await Printing.sharePdf(
        bytes: pdf,
        filename: fileName,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Envía el PDF por WhatsApp al cliente
  static Future<void> sendPDFViaWhatsApp(Ventas venta, BuildContext context) async {
    try {
      // Verificar si el cliente tiene teléfono
      if (venta.cliente.telefono == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El cliente no tiene número de teléfono registrado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Generar el PDF
      final pdf = await _generateVentaPDF(venta);
      final fileName = 'Venta_${venta.id}_${_formatDateForFilename(venta.fecha)}.pdf';
      
      // Crear el mensaje para WhatsApp
      final message = _createWhatsAppMessage(venta);
      
      // Formatear el número de teléfono (remover espacios, guiones, etc.)
      String phoneNumber = venta.cliente.telefono.toString();
      phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // Agregar código de país si no lo tiene (asumiendo Argentina +54)
      if (!phoneNumber.startsWith('54')) {
        phoneNumber = '54$phoneNumber';
      }
      
      // Crear la URL de WhatsApp
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
      
      // Intentar abrir WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Después de abrir WhatsApp, compartir el PDF
        await Future.delayed(const Duration(seconds: 1));
        await Printing.sharePdf(
          bytes: pdf,
          filename: fileName,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp abierto. Adjunta el PDF generado.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir WhatsApp. Verifica que esté instalado.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar por WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Crea el mensaje para WhatsApp
  static String _createWhatsAppMessage(Ventas venta) {
    final total = _formatPrice(venta.total);
    final fecha = _formatDate(venta.fecha);
    
    return '''¡Hola ${venta.cliente.nombre}! 👋

📋 *Resumen de tu compra*
• Venta #${venta.id}
• Fecha: $fecha
• Total: \$${total}

Adjunto encontrarás el detalle completo de tu compra.

¡Gracias por elegirnos! 🙏''';
  }

  /// Genera el PDF de la venta
  static Future<Uint8List> _generateVentaPDF(Ventas venta) async {
    final pdf = pw.Document();

    // Cargar fuentes personalizadas si están disponibles
    final fontData = await _loadFontData();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(venta, fontData),
              pw.SizedBox(height: 24),
              
              // Información de la venta
              _buildVentaInfo(venta, fontData),
              pw.SizedBox(height: 24),
              
              // Detalle de productos
              _buildProductosTable(venta, fontData),
              pw.SizedBox(height: 24),
              
              // Resumen de pagos
              _buildPagosSection(venta, fontData),
              pw.SizedBox(height: 24),
              
              // Total
              _buildTotalSection(venta, fontData),
              pw.Spacer(),
              
              // Footer
              _buildFooter(fontData),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Construye el header del PDF
  static pw.Widget _buildHeader(Ventas venta, pw.Font? fontData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _appName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  font: fontData,
                ),
              ),
              pw.Text(
                'Factura de Venta',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey600,
                  font: fontData,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Venta #${venta.id}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: fontData,
                ),
              ),
              pw.Text(
                _formatDate(venta.fecha),
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                  font: fontData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye la información de la venta
  static pw.Widget _buildVentaInfo(Ventas venta, pw.Font? fontData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Cliente',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                    font: fontData,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  venta.cliente.nombre,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    font: fontData,
                  ),
                ),
                if (venta.cliente.telefono != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Tel: ${venta.cliente.telefono}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      font: fontData,
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Vendedor',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                    font: fontData,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  venta.usuario?.userName ?? 'No disponible',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    font: fontData,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la tabla de productos
  static pw.Widget _buildProductosTable(Ventas venta, pw.Font? fontData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Productos',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: fontData,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // Producto
            1: const pw.FlexColumnWidth(1), // Cantidad
            2: const pw.FlexColumnWidth(1.5), // Precio Unit.
            3: const pw.FlexColumnWidth(1.5), // Subtotal
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Producto', true, fontData),
                _buildTableCell('Cant.', true, fontData),
                _buildTableCell('Precio Unit.', true, fontData),
                _buildTableCell('Subtotal', true, fontData),
              ],
            ),
            // Productos
            ...venta.ventasProductos.map((producto) => pw.TableRow(
              children: [
                _buildTableCell(producto.nombre, false, fontData),
                _buildTableCell(producto.cantidad.toStringAsFixed(0), false, fontData),
                _buildTableCell('\$${_formatPrice(producto.precio)}', false, fontData),
                _buildTableCell('\$${_formatPrice(producto.precio * producto.cantidad)}', false, fontData),
              ],
            )),
          ],
        ),
      ],
    );
  }

  /// Construye la sección de pagos
  static pw.Widget _buildPagosSection(Ventas venta, pw.Font? fontData) {
    if (venta.pagos == null || venta.pagos!.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Formas de Pago',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: fontData,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: venta.pagos!.map((pago) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    _getMetodoPagoText(pago.metodo),
                    style: pw.TextStyle(
                      fontSize: 12,
                      font: fontData,
                    ),
                  ),
                  pw.Text(
                    '\$${_formatPrice(pago.monto)}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      font: fontData,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  /// Construye la sección de total
  static pw.Widget _buildTotalSection(Ventas venta, pw.Font? fontData) {
    double subtotal = venta.ventasProductos.fold(
      0.0, (sum, producto) => sum + (producto.precio * producto.cantidad));
    
    double descuento = 0.0;
    if (venta.cliente.descuentoGlobal > 0) {
      descuento = subtotal * (venta.cliente.descuentoGlobal / 100);
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          if (descuento > 0) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Subtotal:',
                  style: pw.TextStyle(fontSize: 14, font: fontData),
                ),
                pw.Text(
                  '\$${_formatPrice(subtotal)}',
                  style: pw.TextStyle(fontSize: 14, font: fontData),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Descuento (${venta.cliente.descuentoGlobal.toStringAsFixed(1)}%):',
                  style: pw.TextStyle(fontSize: 14, font: fontData),
                ),
                pw.Text(
                  '-\$${_formatPrice(descuento)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.red600,
                    font: fontData,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
          ],
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  font: fontData,
                ),
              ),
              pw.Text(
                '\$${_formatPrice(venta.total)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                  font: fontData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye el footer
  static pw.Widget _buildFooter(pw.Font? fontData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Gracias por su compra',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: fontData,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Este documento fue generado automáticamente por $_appName',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              font: fontData,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una celda de tabla
  static pw.Widget _buildTableCell(String text, bool isHeader, pw.Font? fontData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          font: fontData,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Formatea una fecha
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Formatea una fecha para el nombre del archivo
  static String _formatDateForFilename(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
  }

  /// Formatea un precio
  static String _formatPrice(double price) {
    return price.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  }

  /// Obtiene el texto del método de pago
  static String _getMetodoPagoText(MetodoPago metodo) {
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

  /// Carga datos de fuentes personalizadas
  static Future<pw.Font?> _loadFontData() async {
    try {
      // Aquí podrías cargar fuentes personalizadas si las tienes
      // Por ahora retornamos null para usar las fuentes por defecto
      return null;
    } catch (e) {
      return null;
    }
  }
}
