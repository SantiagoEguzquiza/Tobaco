import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Models/ventasPago.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Helpers/api_handler.dart';

class FormaPagoScreen extends StatefulWidget {
  final Ventas venta;

  const FormaPagoScreen({super.key, required this.venta});

  @override
  State<FormaPagoScreen> createState() => _FormaPagoScreenState();
}

class _MetodoPago {
  final MetodoPago metodo;
  final String nombre;
  final IconData icono;

  _MetodoPago(this.metodo, this.nombre, this.icono);
}

class PagoParcial {
  final MetodoPago metodo;
  final String nombre;
  final IconData icono;
  final double monto;

  PagoParcial({
    required this.metodo,
    required this.nombre,
    required this.icono,
    required this.monto,
  });
}

class _FormaPagoScreenState extends State<FormaPagoScreen> {
  final List<PagoParcial> pagosParciales = [];
  final TextEditingController _montoController = TextEditingController();

  final List<_MetodoPago> metodos = [
    _MetodoPago(MetodoPago.efectivo, 'Efectivo', Icons.payments),
    _MetodoPago(MetodoPago.transferencia, 'Transferencia', Icons.swap_horiz),
    //_MetodoPago(MetodoPago.tarjeta, 'Tarjeta', Icons.credit_card), Cuando tenga posnet lo agrego, un shotout al developer que lo haga :D
    _MetodoPago(MetodoPago.cuentaCorriente, 'Cuenta corriente', Icons.receipt_long),
  ];

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  double _calcularTotalPagado() {
    return pagosParciales.fold(0.0, (sum, pago) => sum + pago.monto);
  }

  double _calcularRestante() {
    return widget.venta.total - _calcularTotalPagado();
  }

  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
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

  bool _puedeConfirmarPago() {
    return pagosParciales.isNotEmpty && _calcularRestante() <= 0.01;
  }

  void _mostrarDialogoMonto(_MetodoPago metodo) {
    _montoController.clear();
    final restante = _calcularRestante();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppTheme.minimalAlertDialog(
          title: 'Monto a pagar con ${metodo.nombre}',
          content: Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              GestureDetector(
                onTap: () {
                  _montoController.text = restante.toStringAsFixed(2);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        metodo.icono,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Restante por pagar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            _formatearPrecioConDecimales(restante),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
                TextField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Monto',
                  hintText: 'Ingrese el monto',
                  prefixText: '\$ ',                 
                  focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  enabledBorder:  OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey),
                  ),
                  border:  OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardTheme.color,
                        side: const BorderSide(color: Colors.grey, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final monto = double.tryParse(_montoController.text);
                        if (monto != null && monto > 0 && monto <= restante) {
                          setState(() {
                            pagosParciales.add(PagoParcial(
                              metodo: metodo.metodo,
                              nombre: metodo.nombre,
                              icono: metodo.icono,
                              monto: monto,
                            ));
                          });
                          Navigator.of(context).pop();
                        } else {
                          AppTheme.showSnackBar(
                            context,
                            AppTheme.warningSnackBar(
                              monto == null || monto <= 0
                                  ? 'Ingrese un monto válido'
                                  : 'El monto no puede ser mayor al restante',
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Agregar',
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
              const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _eliminarPago(int index) {
    setState(() {
      pagosParciales.removeAt(index);
    });
  }

  Color _getPaymentMethodColor(MetodoPago metodo) {
    // color para los diferentes métodos de pago
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Métodos de Pago', style: AppTheme.appBarTitleStyle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header con información de la venta
                Container(
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.attach_money,
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
                                  'Total de la Venta',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                _formatearPrecioConDecimales(
                                  widget.venta.total,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Métodos de pago disponibles
                Container(
                  decoration: BoxDecoration(
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
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
                                'Seleccionar Método de Pago',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...metodos.asMap().entries.map((entry) => 
                        _buildMetodoPagoTile(entry.value, isLast: entry.key == metodos.length - 1)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Pagos parciales agregados
                if (pagosParciales.isNotEmpty) ...[
                  Container(
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
                                'Pagos Agregados ( ${pagosParciales.length} )',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pagosParciales.length,
                            itemBuilder: (context, index) {
                              final pago = pagosParciales[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? (index % 2 == 0 ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A2A))
                                      : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade200,
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
                                      color: _getPaymentMethodColor(pago.metodo).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      pago.icono,
                                      color: _getPaymentMethodColor(pago.metodo),
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    pago.nombre,
                                    style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                    ),
                                  ),
                                  subtitle: _formatearPrecioConDecimales(
                                    pago.monto,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    onPressed: () => _eliminarPago(index),
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
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
                  const SizedBox(height: 20),
                ],

                // Resumen de pagos
                Container(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total de la Venta:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.black,
                            ),
                          ),
                          Text(
                            '\$${_formatearPrecio(widget.venta.total)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pagado:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.black,
                            ),
                          ),
                          Text(
                            '\$${_formatearPrecio(_calcularTotalPagado())}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _calcularRestante() <= 0.01 ? 'Pago Completo' : 'Restante:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _calcularRestante() <= 0.01 ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            _calcularRestante() <= 0.01 
                                ? '✓' 
                                : '\$${_formatearPrecio(_calcularRestante())}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _calcularRestante() <= 0.01 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: pagosParciales.isNotEmpty
          ? Container(
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
                    // Información del pago
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _calcularRestante() <= 0.01 ? 'Pago Completo' : 'Restante',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _calcularRestante() <= 0.01 
                                ? '✓' 
                                : '\$${_formatearPrecio(_calcularRestante())}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _calcularRestante() <= 0.01 ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            '${pagosParciales.length} método${pagosParciales.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Botón confirmar
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: _puedeConfirmarPago() ? _confirmarPago : null,
                        style: AppTheme.elevatedButtonStyle(
                            _puedeConfirmarPago() ? AppTheme.addGreenColor : Colors.grey),
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text(
                           'Confirmar Pago',
                           
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMetodoPagoTile(_MetodoPago metodo, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getPaymentMethodColor(metodo.metodo).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            metodo.icono,
            color: _getPaymentMethodColor(metodo.metodo),
            size: 24,
          ),
        ),
        title: Text(
          metodo.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey.shade800,
          ),
        ),
        trailing: Icon(
          Icons.add_circle_outline,
          color: Colors.green.shade600,
          size: 24,
        ),
        onTap: () => _mostrarDialogoMonto(metodo),
      ),
    );
  }

  void _confirmarPago() async {
    if (!_puedeConfirmarPago()) return;

    // Mostrar diálogo de confirmación
    final confirmado = await AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Confirmar Pago',
      message: '¿Está seguro de que desea confirmar el pago con ${pagosParciales.length} método${pagosParciales.length != 1 ? 's' : ''}?',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      icon: Icons.payment,
      iconColor: Colors.green,
    );

    if (confirmado) {
      // Convertir pagosParciales a VentaPago y almacenar en la venta
      final ventaPagos = pagosParciales.map((pago) => 
        VentaPago(
          id: 0, // Asigna el valor adecuado para 'id'
          ventaId: widget.venta.id ?? 0, // Asegúrate de que 'widget.venta.id' existe y es correcto
          metodo: pago.metodo, 
          monto: pago.monto
        )
      ).toList();
      
      // Determinar el método de pago principal de la venta
      MetodoPago metodoPagoPrincipal;
      if (pagosParciales.length == 1) {
        // Si hay solo un pago, usar ese método
        metodoPagoPrincipal = pagosParciales.first.metodo;
      } else {
        // Si hay múltiples pagos, priorizar cuenta corriente si existe
        if (pagosParciales.any((pago) => pago.metodo == MetodoPago.cuentaCorriente)) {
          metodoPagoPrincipal = MetodoPago.cuentaCorriente;
        } else {
          // Si no hay cuenta corriente, usar el primer método
          metodoPagoPrincipal = pagosParciales.first.metodo;
        }
      }
      
      // Actualizar la venta con la lista de pagos y método principal
      widget.venta.pagos = ventaPagos;
      widget.venta.metodoPago = metodoPagoPrincipal;
      
      // Devolver la venta actualizada
      Navigator.pop(context, widget.venta);
    }
  }
}
