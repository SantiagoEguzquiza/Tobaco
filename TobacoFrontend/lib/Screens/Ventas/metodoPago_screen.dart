import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/metodoPago.dart';
import 'package:tobaco/Models/ventasPago.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';

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

  double _parsearDeuda(String? deuda) {
    if (deuda == null || deuda.isEmpty) return 0.0;
    final s = deuda.replaceAll(',', '.');
    return double.tryParse(s) ?? 0.0;
  }

  /// Saldo a favor del cliente (crédito disponible). > 0 cuando deuda < 0.
  double get _saldoAFavor {
    final d = _parsearDeuda(widget.venta.cliente.deuda);
    return d < 0 ? -d : 0.0;
  }

  /// Crédito disponible para usar en esta venta (saldo a favor menos lo ya pagado con CC).
  double get _creditoDisponible {
    final ccYaUsado = pagosParciales
        .where((p) => p.metodo == MetodoPago.cuentaCorriente)
        .fold(0.0, (s, p) => s + p.monto);
    return (_saldoAFavor - ccYaUsado).clamp(0.0, double.infinity);
  }

  /// Métodos de pago disponibles. Cuenta Corriente solo si el cliente tiene hasCCTE.
  List<_MetodoPago> get metodos {
    final base = [
      _MetodoPago(MetodoPago.efectivo, 'Efectivo', Icons.payments),
      _MetodoPago(MetodoPago.transferencia, 'Transferencia', Icons.swap_horiz),
      //_MetodoPago(MetodoPago.tarjeta, 'Tarjeta', Icons.credit_card), Cuando tenga posnet lo agrego, un shotout al developer que lo haga :D
    ];
    if (widget.venta.cliente.hasCCTE) {
      base.add(_MetodoPago(MetodoPago.cuentaCorriente, 'Cuenta corriente', Icons.receipt_long));
    }
    return base;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _aplicarSaldoAFavorAutomatico());
  }

  /// Aplica automáticamente el saldo a favor del cliente al abrir la pantalla.
  /// Ej: cliente con $100 a favor y compra de $200 → se aplican $100, solo debe pagar $100.
  void _aplicarSaldoAFavorAutomatico() {
    if (pagosParciales.isNotEmpty) return;
    if (!widget.venta.cliente.hasCCTE) return;
    final saldo = _parsearDeuda(widget.venta.cliente.deuda);
    if (saldo >= 0) return;
    final credito = -saldo;
    if (credito <= 0 || widget.venta.total <= 0) return;
    final montoAplicar = credito < widget.venta.total ? credito : widget.venta.total;
    setState(() {
      pagosParciales.add(PagoParcial(
        metodo: MetodoPago.cuentaCorriente,
        nombre: 'Saldo a favor',
        icono: Icons.account_balance_wallet,
        monto: montoAplicar,
      ));
    });
  }

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
    final esCuentaCorriente = metodo.metodo == MetodoPago.cuentaCorriente;
    // Si usa saldo a favor: máximo = min(restante, creditoDisponible). Si no hay crédito: max = restante (agregar a deuda)
    final maxMonto = esCuentaCorriente && _creditoDisponible > 0
        ? (restante < _creditoDisponible ? restante : _creditoDisponible)
        : restante;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
            final bgDialog = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black87;
            final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
            final fillField = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
            final borderColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

            return AlertDialog(
          backgroundColor: bgDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  metodo.icono,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  esCuentaCorriente && _saldoAFavor > 0
                      ? 'Usar saldo a favor'
                      : 'Monto con ${metodo.nombre}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  _montoController.text = maxMonto.toStringAsFixed(2);
                  setDialogState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          metodo.icono,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              esCuentaCorriente && _saldoAFavor > 0
                                  ? 'Máximo a usar (saldo a favor)'
                                  : 'Restante por pagar',
                              style: TextStyle(
                                fontSize: 13,
                                color: subColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _formatearPrecioConDecimales(maxMonto),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.touch_app_rounded,
                        size: 20,
                        color: subColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Monto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(color: subColor, fontSize: 16),
                  filled: true,
                  fillColor: fillField,
                  hintStyle: TextStyle(color: subColor),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                        foregroundColor: textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final monto = double.tryParse(_montoController.text);
                        if (monto != null && monto > 0 && monto <= maxMonto) {
                          setState(() {
                            pagosParciales.add(PagoParcial(
                              metodo: metodo.metodo,
                              nombre: metodo.nombre,
                              icono: metodo.icono,
                              monto: monto,
                            ));
                          });
                          Navigator.of(dialogContext).pop();
                        } else {
                          AppTheme.showSnackBar(
                            dialogContext,
                            AppTheme.warningSnackBar(
                              monto == null || monto <= 0
                                  ? 'Ingrese un monto válido'
                                  : esCuentaCorriente && _saldoAFavor > 0
                                      ? 'El monto no puede superar el saldo a favor disponible (\$${maxMonto.toStringAsFixed(2)})'
                                      : 'El monto no puede ser mayor al restante',
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Agregar',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
            );
          },
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
                    borderRadius: BorderRadius.circular(8),
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
                              borderRadius: BorderRadius.circular(8),
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
                    borderRadius: BorderRadius.circular(8),
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
                    borderRadius: BorderRadius.circular(8),
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
                      borderRadius: BorderRadius.circular(8),
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
                    borderRadius: BorderRadius.circular(8),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _puedeConfirmarPago() ? AppTheme.addGreenColor : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: AppTheme.ventasButtonPadding(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                        ),
                        icon: Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: AppTheme.ventasButtonIconSize(context),
                        ),
                        label: Text(
                           'Confirmar Pago',

                          style: TextStyle(
                            fontSize: AppTheme.ventasButtonFontSize(context),
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
    final tieneSaldoAFavor = metodo.metodo == MetodoPago.cuentaCorriente && _saldoAFavor > 0;
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
        subtitle: tieneSaldoAFavor
            ? Text(
                _creditoDisponible > 0
                    ? 'Saldo a favor: \$${_creditoDisponible.toStringAsFixed(2)} disponible'
                    : 'Crédito usado. Puede agregar el restante a deuda',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
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
