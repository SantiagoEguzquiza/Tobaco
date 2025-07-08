import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../Providers/currency_provider.dart';

class DolarUyuWidget extends StatelessWidget {
  const DolarUyuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CurrencyProvider>();

    return Card(
      elevation: 4, // Añade sombra para mejor aspecto visual
      margin: const EdgeInsets.all(12), // Margen uniforme
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Alinea a la izquierda
          children: [
            // Título con icono para mejor identificación
            const Row(
              children: [
                Icon(Icons.currency_exchange, size: 20),
                SizedBox(width: 8),
                Text('Cotización USD/UYU',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 16),

            // Estado de carga
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator()),

            // Estado de error
            if (provider.error.isNotEmpty && !provider.isLoading)
              Text(
                provider.error,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),

            // Estado con datos
            if (!provider.isLoading && provider.error.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1 USD = ${_formatCurrency(provider.currentRate)} UYU',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  const SizedBox(height: 8),

                  // Indicador de tendencia (podríamos implementarlo luego)
                  /* Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                      Text('+0.5%', style: TextStyle(color: Colors.green)),
                    ],
                  ), */
                ],
              ),

            const SizedBox(height: 12),

            // Fecha de actualización (siempre visible cuando existe)
            if (provider.lastUpdate != null)
              Text(
                'Actualizado: ${DateFormat('HH:mm:ss').format(provider.lastUpdate!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'es_UY',
      symbol: r'$U ',
      decimalDigits: 2,
    ).format(value);
  }
}
