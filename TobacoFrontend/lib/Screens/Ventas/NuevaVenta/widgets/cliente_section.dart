import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Abonos_Service/abonos_provider.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';

/// Widget que muestra la sección del cliente seleccionado
/// Incluye el nombre, deuda (si tiene), y botón para cambiar cliente
class ClienteSection extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onCambiarCliente;
  final bool? mostrarDescuentoGlobal;

  /// Callback opcional invocado luego de registrar un abono exitosamente
  /// desde el botón rápido. Útil para refrescar la pantalla padre.
  final VoidCallback? onAbonoRegistrado;

  const ClienteSection({
    super.key,
    required this.cliente,
    required this.onCambiarCliente,
    this.mostrarDescuentoGlobal,
    this.onAbonoRegistrado,
  });

  double _parsearDeuda(String? deuda) {
    if (deuda == null || deuda.isEmpty) return 0.0;
    
    if (deuda.contains(',')) {
      List<String> partes = deuda.split(',');
      
      if (partes.length == 2) {
        String parteEntera = partes[0];
        String parteDecimal = partes[1];
        
        String decimalesFinales;
        if (parteDecimal.length >= 2) {
          decimalesFinales = parteDecimal.substring(0, 2);
        } else {
          decimalesFinales = parteDecimal.padRight(2, '0');
        }
        
        String numeroCorregido = '$parteEntera.$decimalesFinales';
        return double.tryParse(numeroCorregido) ?? 0.0;
      }
    }
    
    String deudaLimpia = deuda.replaceAll(',', '');
    return double.tryParse(deudaLimpia) ?? 0.0;
  }

  String _formatearPrecio(double precio) => precio.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tieneDeuda = _parsearDeuda(cliente.deuda) > 0;
    final tieneDescuento = cliente.descuentoGlobal > 0;
    final isSmallPhone = MediaQuery.of(context).size.width < 380;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.all(isSmallPhone ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
          ] : [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark 
            ? const Color(0xFF404040)
            : AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Ícono del cliente
              Container(
                padding: EdgeInsets.all(isSmallPhone ? 10 : 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: isSmallPhone ? 12 : 16),
              
              // Información del cliente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombre,
                      style: TextStyle(
                        fontSize: isSmallPhone ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.primaryColor,
                      ),
                      maxLines: isSmallPhone ? 2 : 1,
                      softWrap: true,
                    ),                                  
                    // Mostrar deuda si tiene
                    if (tieneDeuda) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Deuda: \$${_parsearDeuda(cliente.deuda).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Botón registrar abono (solo si tiene deuda)
              if (tieneDeuda) ...[
                SizedBox(width: isSmallPhone ? 8 : 12),
                IconButton(
                  onPressed: () => _mostrarModalRegistrarAbono(context),
                  icon: const Icon(Icons.payments_rounded),
                  color: Colors.green.shade700,
                  tooltip: 'Registrar abono',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.green.withOpacity(0.2)
                        : Colors.green.withOpacity(0.12),
                    padding: EdgeInsets.all(isSmallPhone ? 10 : 12),
                  ),
                ),
              ],

              // Botón cambiar cliente
              SizedBox(width: isSmallPhone ? 8 : 12),
              IconButton(
                onPressed: onCambiarCliente,
                icon: const Icon(Icons.swap_horiz),
                color: AppTheme.primaryColor,
                tooltip: 'Cambiar cliente',
                style: IconButton.styleFrom(
                  backgroundColor: isDark 
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  padding: EdgeInsets.all(isSmallPhone ? 10 : 12),
                ),
              ),
            ],
          ),
          
          // Banner de descuento global si aplica
          if (tieneDescuento && (mostrarDescuentoGlobal ?? true)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.discount,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Descuento global: ${cliente.descuentoGlobal}% aplicado',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _mostrarModalRegistrarAbono(BuildContext context) {
    final TextEditingController montoController = TextEditingController();
    final TextEditingController notaController = TextEditingController();
    String? errorMessage;
    bool procesando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bgDialog = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final cardBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50;
            final textColor = isDark ? Colors.white : Colors.black87;
            final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
            final fillField = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
            final borderColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

            final viewInsets = MediaQuery.viewInsetsOf(context);
            final maxContentHeight =
                MediaQuery.sizeOf(context).height - viewInsets.bottom - 160;

            final deudaActual = _parsearDeuda(cliente.deuda);

            return AlertDialog(
              backgroundColor: bgDialog,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Registrar abono',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxContentHeight.clamp(200.0, double.infinity),
                ),
                child: SingleChildScrollView(
                  child: TextSelectionTheme(
                    data: TextSelectionThemeData(
                      cursorColor: AppTheme.primaryColor,
                      selectionColor: AppTheme.primaryColor.withOpacity(0.3),
                      selectionHandleColor: AppTheme.primaryColor,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cliente y saldo (tappable para autocompletar monto)
                        Material(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: deudaActual > 0
                                ? () {
                                    final valor =
                                        deudaActual.toStringAsFixed(2);
                                    montoController.value = TextEditingValue(
                                      text: valor,
                                      selection: TextSelection.collapsed(
                                          offset: valor.length),
                                    );
                                    setState(() => errorMessage = null);
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cliente.nombre,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          deudaActual > 0
                                              ? 'Saldo: \$${_formatearPrecio(deudaActual)}'
                                              : deudaActual < 0
                                                  ? 'Saldo a favor: \$${_formatearPrecio(-deudaActual)}'
                                                  : 'Sin deuda actualmente',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: deudaActual > 0
                                                ? Colors.red.shade600
                                                : Colors.green.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (deudaActual > 0) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.touch_app_rounded,
                                      size: 20,
                                      color: Colors.red.shade600
                                          .withOpacity(0.7),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    color: Colors.red.shade600, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Text(
                          'Monto a abonar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: subColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: montoController,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          style: TextStyle(color: textColor, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixText: '\$ ',
                            prefixStyle:
                                TextStyle(color: subColor, fontSize: 16),
                            filled: true,
                            fillColor: fillField,
                            hintStyle: TextStyle(color: subColor),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
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
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'Nota (opcional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: subColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notaController,
                          maxLines: 2,
                          style: TextStyle(color: textColor, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Ej: Pago en efectivo',
                            filled: true,
                            fillColor: fillField,
                            hintStyle: TextStyle(color: subColor),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
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
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: procesando
                                    ? null
                                    : () => Navigator.of(dialogContext).pop(),
                                style: TextButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                  foregroundColor: isDark
                                      ? Colors.grey.shade200
                                      : Colors.grey.shade800,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.borderRadiusMainButtons),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: procesando
                                    ? null
                                    : () async {
                                        final monto = double.tryParse(
                                            montoController.text);
                                        setState(() => errorMessage = null);

                                        if (monto == null || monto <= 0) {
                                          setState(() => errorMessage =
                                              'Ingrese un monto válido');
                                          return;
                                        }

                                        setState(() => procesando = true);
                                        final ok = await _procesarAbono(
                                          context,
                                          monto,
                                          notaController.text,
                                        );
                                        if (!ok) {
                                          if (dialogContext.mounted) {
                                            setState(() {
                                              procesando = false;
                                              errorMessage =
                                                  'No se pudo registrar el abono';
                                            });
                                          }
                                          return;
                                        }

                                        if (dialogContext.mounted) {
                                          Navigator.of(dialogContext).pop();
                                        }
                                      },
                                icon: procesando
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded, size: 20),
                                label: Text(
                                  procesando ? 'Guardando...' : 'Guardar',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.borderRadiusMainButtons),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _procesarAbono(
      BuildContext context, double monto, String nota) async {
    try {
      final abonosProvider = AbonosProvider();
      final abonoCreado = await abonosProvider.saldarDeuda(
        cliente.id!,
        monto,
        DateTime.now(),
        nota.isEmpty ? null : nota,
        clienteNombre: cliente.nombre,
      );

      if (abonoCreado == null) return false;

      final deudaActual = _parsearDeuda(cliente.deuda);
      final nuevaDeuda = deudaActual - monto;
      cliente.deuda = nuevaDeuda.toStringAsFixed(2);

      if (context.mounted) {
        final clienteProvider =
            Provider.of<ClienteProvider>(context, listen: false);
        clienteProvider.actualizarDeudaCliente(cliente.id!, nuevaDeuda);

        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar(
            nuevaDeuda < 0
                ? 'Abono registrado. Saldo a favor: \$${_formatearPrecio(-nuevaDeuda)}'
                : nuevaDeuda == 0
                    ? 'Abono registrado. Cuenta corriente al día.'
                    : 'Abono registrado exitosamente',
          ),
        );
      }

      onAbonoRegistrado?.call();
      return true;
    } catch (e) {
      if (context.mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al procesar el abono: $e'),
        );
      }
      return false;
    }
  }
}
