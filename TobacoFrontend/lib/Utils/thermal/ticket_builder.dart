import 'dart:typed_data';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/metodoPago.dart';

class TicketBuilder {
  static const int width = 48; // Ancho del ticket en caracteres (GV-8001)
  
  
  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
  
  static String _formatCurrency(num value) {
    final isNegative = value < 0;
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    final withThousands = integerPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    
    final formatted = '$withThousands,$decimalPart';
    return isNegative ? '-$formatted' : formatted;
  }
  
  static String _centerText(String text) {
    if (text.length >= width) return text.substring(0, width);
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }
  
  static String _alignRight(String text) {
    if (text.length >= width) return text.substring(0, width);
    final padding = width - text.length;
    return ' ' * padding + text;
  }
  
  static String _alignLeftRight(String left, String right) {
    final totalLength = left.length + right.length;
    if (totalLength >= width) {
      // Si no cabe, truncar el texto de la derecha
      final availableSpace = width - left.length - 3; // -3 para "..."
      if (availableSpace <= 0) return left.substring(0, width);
      return left + right.substring(0, availableSpace) + '...';
    }
    final padding = width - totalLength;
    return left + (' ' * padding) + right;
  }
  
  static String _createSeparator(String char) => char * width;
  
  static Uint8List buildTicket(Ventas venta) {
    final List<String> lines = [];
    
    // // Encabezado del ticket
    // lines.add(_createSeparator('='));
    // lines.add(_centerText('COMPROBANTE DE VENTA'));
    // lines.add(_createSeparator('='));
    // lines.add('');
    
    // Información de la venta
    lines.add('VENTA #${venta.id ?? 'LOCAL'}');
    lines.add('FECHA: ${_formatDate(venta.fecha)}');
    lines.add(_createSeparator('-'));
    
    // Información del cliente
    lines.add(_alignLeftRight('CLIENTE:', venta.cliente.nombre.toUpperCase()));
    // if (venta.cliente.direccion != null && venta.cliente.direccion!.isNotEmpty) {
    //   lines.add('DIRECCION: ${venta.cliente.direccion!}');
    // }
    lines.add(_createSeparator('-'));
    lines.add(_centerText('PRODUCTOS'));
    
    // // Productos
    // lines.add(_centerText('DETALLE DE PRODUCTOS'));
    // lines.add(_createSeparator('-'));
    
    for (var producto in venta.ventasProductos) {
      final subtotal = producto.precioFinalCalculado > 0 
          ? producto.precioFinalCalculado 
          : producto.precio * producto.cantidad;
      
      lines.add('');
      
      // Nombre del producto (truncar si es muy largo)
      var nombreProducto = producto.nombre.toUpperCase();
      if (nombreProducto.length > width - 10) {
        nombreProducto = '${nombreProducto.substring(0, width - 13)}...';
      }
      lines.add(nombreProducto);
      
      // Cantidad y precio
      final cantidadStr = producto.cantidad.toStringAsFixed(2);
      final precioStr = _formatCurrency(producto.precio);
      final subtotalStr = _formatCurrency(subtotal);
      
      lines.add(_alignLeftRight('$cantidadStr x $precioStr', subtotalStr)); 
    }
    
    lines.add('');
    lines.add(_createSeparator('='));
    
    // Total
    final totalStr = _formatCurrency(venta.total);   
    lines.add(_alignLeftRight('TOTAL:', totalStr));
    lines.add('');
    lines.add(_centerText('Gracias por su compra'));
    lines.add('');

    if(venta.cliente.deuda != null && venta.cliente.deuda!.isNotEmpty) {
      lines.add(_centerText('DEUDA: ${venta.cliente.deuda}'));
    }
    
    
    // // Métodos de pago
    // lines.add(_centerText('FORMAS DE PAGO'));
    // lines.add(_createSeparator('-'));
    
    // if (venta.pagos != null && venta.pagos!.isNotEmpty) {
    //   for (var pago in venta.pagos!) {
    //     final metodoStr = _getMetodoPagoText(pago.metodo);
    //     final montoStr = _formatCurrency(pago.monto);
    //     lines.add('$metodoStr: $montoStr');
    //   }
    // }
    
    // lines.add('');
    // lines.add(_createSeparator('='));
    // lines.add('');
    // lines.add(_centerText('GRACIAS POR SU COMPRA'));
    // lines.add('');
    // lines.add(_createSeparator('='));
    // lines.add('');
    // lines.add('');
    
    // Convertir a bytes ASCII
    final content = lines.join('\n');
    return Uint8List.fromList(content.codeUnits);
  }
}

