import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema
import 'package:url_launcher/url_launcher.dart';
import 'preciosEspeciales_screen.dart';
import 'historialVentas_screen.dart';

class DetalleClienteScreen extends StatelessWidget {
  final Cliente cliente;

  const DetalleClienteScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null, // Usar el tema
        title: const Text(
          'Detalle del Cliente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF), // Blanco puro
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del cliente
            _buildClienteHeader(context),
            const SizedBox(height: 24),

            // Información del cliente
            _buildClienteInfo(context),
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
  Widget _buildClienteHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF2A2A2A),
                ]
              : [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.secondaryColor.withOpacity(0.3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : AppTheme.primaryColor.withOpacity(0.2),
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: double.tryParse(cliente.deuda ?? '0')! > 0
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              double.tryParse(cliente.deuda ?? '0')! > 0 ? 'Tiene deuda' : 'Sin deuda',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: double.tryParse(cliente.deuda ?? '0')! > 0
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
  Widget _buildClienteInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información del Cliente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        
        // Dirección
        _buildInfoCard(
          context: context,
          icon: Icons.location_on,
          title: 'Dirección',
          content: cliente.direccion ?? 'No disponible',
          iconColor: Colors.blue,
        ),
        const SizedBox(height: 12),
        
        // Teléfono
        _buildInfoCard(
          context: context,
          icon: Icons.phone,
          title: 'Teléfono',
          content: cliente.telefono?.toString() ?? 'No disponible',
          iconColor: Colors.green,
        ),
        const SizedBox(height: 12),
        
        // Deuda
        _buildInfoCard(
          context: context,
          icon: Icons.account_balance_wallet,
          title: 'Deuda',
          content: '\$${cliente.deuda ?? '0.00'}',
          iconColor: double.tryParse(cliente.deuda ?? '0')! > 0 ? Colors.red : Colors.grey,
        ),
      ],
    );
  }

  // Tarjeta de información
  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.primaryColor,
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
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
                context: context,
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
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        _buildAdditionalActionButton(
          context: context,
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
        const SizedBox(height: 12),
        _buildAdditionalActionButton(
          context: context,
          icon: Icons.history,
          label: 'Historial de Ventas',
          description: 'Ver todas las ventas realizadas a este cliente',
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistorialVentasScreen(cliente: cliente),
              ),
            );
          },
        ),
      ],
    );
  }

  // Botón de acción adicional
  Widget _buildAdditionalActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
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
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade400,
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
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Theme.of(context).dividerTheme.color,
          foregroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: Text(
          'Volver',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.secondaryColor
                : AppTheme.secondaryColor,
          ),
        ),
      ),
    );
  }
}
