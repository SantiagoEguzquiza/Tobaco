import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema
import 'package:url_launcher/url_launcher.dart';
import 'preciosEspeciales_screen.dart';

class DetalleClienteScreen extends StatelessWidget {
  final Cliente cliente;

  const DetalleClienteScreen({super.key, required this.cliente});

  // Función para parsear correctamente los valores de deuda
  double _parsearDeuda(String? deuda) {
    if (deuda == null || deuda.isEmpty) return 0.0;
    print('DEBUG - Valor deuda recibido: "$deuda"');
    
    // Si contiene coma, tratar como separador decimal
    if (deuda.contains(',')) {
      List<String> partes = deuda.split(',');
      if (partes.length == 2) {
        String parteEntera = partes[0];
        String parteDecimal = partes[1];
        
        // Tomar máximo 2 decimales
        String decimalesFinales;
        if (parteDecimal.length >= 2) {
          decimalesFinales = parteDecimal.substring(0, 2);
        } else {
          decimalesFinales = parteDecimal.padRight(2, '0');
        }
        
        String numeroCorregido = '$parteEntera.$decimalesFinales';
        print('DEBUG - Formato corregido: "$deuda" -> "$numeroCorregido"');
        return double.tryParse(numeroCorregido) ?? 0.0;
      }
    }
    
    // Si no contiene coma, intentar parsear directamente
    String deudaLimpia = deuda.replaceAll(',', '');
    double? resultado = double.tryParse(deudaLimpia);
    print('DEBUG - Valor limpio: "$deudaLimpia" -> $resultado');
    return resultado ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Detalle del Cliente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del cliente
            _buildClienteHeader(),
            const SizedBox(height: 24),

            // Información del cliente
            _buildClienteInfo(),
            const SizedBox(height: 24),

            // Acciones de contacto
            _buildContactActions(context),
            const SizedBox(height: 20),

            // Acciones adicionales
            _buildAdditionalActions(context),
            const SizedBox(height: 20),

            // Botón volver
            _buildBackButton(context),
          ],
        ),
      ),
    );
  }

  // Header del cliente
  Widget _buildClienteHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            cliente.nombre,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _parsearDeuda(cliente.deuda) > 0
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _parsearDeuda(cliente.deuda) > 0 ? 'Tiene deuda' : 'Sin deuda',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _parsearDeuda(cliente.deuda) > 0
                    ? Colors.red.shade700
                    : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Información del cliente
  Widget _buildClienteInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información del Cliente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        
        // Dirección
        _buildInfoCard(
          icon: Icons.location_on,
          title: 'Dirección',
          content: cliente.direccion ?? 'No disponible',
          iconColor: Colors.blue,
        ),
        const SizedBox(height: 12),
        
        // Teléfono
        _buildInfoCard(
          icon: Icons.phone,
          title: 'Teléfono',
          content: cliente.telefono?.toString() ?? 'No disponible',
          iconColor: Colors.green,
        ),
        const SizedBox(height: 12),
        
        // Deuda
        _buildInfoCard(
          icon: Icons.account_balance_wallet,
          title: 'Deuda',
          content: '\$${_parsearDeuda(cliente.deuda).toStringAsFixed(2)}',
          iconColor: _parsearDeuda(cliente.deuda) > 0 ? Colors.red : Colors.grey,
        ),
      ],
    );
  }

  // Tarjeta de información
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Acciones de contacto
  Widget _buildContactActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contacto',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.phone,
                label: 'Llamar',
                color: Colors.blue,
                onTap: () async {
                  if (cliente.telefono != null) {
                    final Uri launchUri = Uri(scheme: 'tel', path: cliente.telefono.toString());
                    final success = await launchUrl(launchUri);
                    if (!success && context.mounted) {
                      AppTheme.showSnackBar(
                        context,
                        AppTheme.errorSnackBar('No se pudo abrir el teléfono'),
                      );
                    }
                  } else {
                    AppTheme.showSnackBar(
                      context,
                      AppTheme.warningSnackBar('No hay número de teléfono disponible'),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.message,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () async {
                  if (cliente.telefono != null) {
                    final Uri whatsappUri = Uri.parse('https://wa.me/${cliente.telefono}');
                    final success = await launchUrl(whatsappUri);
                    if (!success && context.mounted) {
                      AppTheme.showSnackBar(
                        context,
                        AppTheme.errorSnackBar('No se pudo abrir WhatsApp'),
                      );
                    }
                  } else {
                    AppTheme.showSnackBar(
                      context,
                      AppTheme.warningSnackBar('No hay número de teléfono disponible'),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Botón de acción
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Acciones adicionales
  Widget _buildAdditionalActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        _buildAdditionalActionButton(
          icon: Icons.price_change,
          label: 'Precios Especiales',
          description: 'Gestionar precios especiales para este cliente',
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreciosEspecialesScreen(cliente: cliente),
              ),
            );
          },
        ),
      ],
    );
  }

  // Botón de acción adicional
  Widget _buildAdditionalActionButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Botón volver
  Widget _buildBackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.grey.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Volver',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
