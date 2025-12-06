import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Theme/app_theme.dart';

/// Widget que muestra la sección del cliente seleccionado
/// Incluye el nombre, deuda (si tiene), y botón para cambiar cliente
class ClienteSection extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onCambiarCliente;
  final bool? mostrarDescuentoGlobal;

  const ClienteSection({
    super.key,
    required this.cliente,
    required this.onCambiarCliente,
    this.mostrarDescuentoGlobal,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tieneDeuda = _parsearDeuda(cliente.deuda) > 0;
    final tieneDescuento = cliente.descuentoGlobal > 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(12),
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
              const SizedBox(width: 16),
              
              // Información del cliente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombre,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
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
              
              // Botón cambiar cliente
              const SizedBox(width: 12),
              IconButton(
                onPressed: onCambiarCliente,
                icon: const Icon(Icons.swap_horiz),
                color: AppTheme.primaryColor,
                tooltip: 'Cambiar cliente',
                style: IconButton.styleFrom(
                  backgroundColor: isDark 
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
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
}

