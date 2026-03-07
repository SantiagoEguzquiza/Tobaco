import 'package:flutter/material.dart';
import 'package:tobaco/Models/Proveedor.dart';
import 'package:tobaco/Theme/app_theme.dart';

/// Muestra la sección del proveedor seleccionado (nombre + botón cambiar).
/// Mismo estilo que ClienteSection en Nueva venta.
class ProveedorSection extends StatelessWidget {
  final Proveedor proveedor;
  final VoidCallback onCambiarProveedor;

  const ProveedorSection({
    super.key,
    required this.proveedor,
    required this.onCambiarProveedor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A1A), const Color(0xFF2A2A2A)]
              : [
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
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Ícono del proveedor (igual que cliente: ícono en contenedor)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Información (Column como en ClienteSection)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proveedor.nombre,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Botón cambiar proveedor
              const SizedBox(width: 12),
              IconButton(
                onPressed: onCambiarProveedor,
                icon: const Icon(Icons.swap_horiz),
                color: AppTheme.primaryColor,
                tooltip: 'Cambiar proveedor',
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
