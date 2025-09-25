import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema
import 'package:url_launcher/url_launcher.dart';
import 'preciosEspeciales_screen.dart';
import 'editarPreciosEspeciales_screen.dart';

class DetalleClienteScreen extends StatelessWidget {
  final Cliente cliente;

  const DetalleClienteScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(cliente.nombre, style: AppTheme.appBarTitleStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dirección:', style: AppTheme.sectionTitleStyle),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: AppTheme.sectionBoxDecoration,
              child: Text(
                cliente.direccion ?? 'No disponible',
                style: AppTheme.sectionContentStyle,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Teléfono:', style: AppTheme.sectionTitleStyle),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: AppTheme.sectionBoxDecoration,
              child: Text(
                cliente.telefono?.toString() ?? 'No disponible',
                style: AppTheme.sectionContentStyle,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Deuda:', style: AppTheme.sectionTitleStyle),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: AppTheme.sectionBoxDecoration,
              child: Text(
                cliente.deuda.toString(),
                style: AppTheme.sectionContentStyle,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        final Uri launchUri = Uri(
                            scheme: 'tel', path: cliente.telefono.toString());
                        final success = await launchUrl(launchUri);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Could not launch $launchUri')),
                          );
                        }
                      },
                      style: AppTheme.elevatedButtonStyle(
                        const Color.fromARGB(255, 104, 147, 255),
                      ),
                      child: Image.asset('Assets/images/ring-phone.png',
                          height: 30),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        final Uri whatsappUri =
                            Uri.parse('https://wa.me/${cliente.telefono}');
                        final success = await launchUrl(whatsappUri);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Could not launch $whatsappUri')),
                          );
                        }
                      },
                      style: AppTheme.elevatedButtonStyle(
                        const Color.fromARGB(255, 37, 211, 101),
                      ),
                      child:
                          Image.asset('Assets/images/whatsapp.png', height: 30),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PreciosEspecialesScreen(cliente: cliente),
                    ),
                  );
                },
                icon: const Icon(Icons.price_change),
                label: const Text('Precios Especiales'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: AppTheme.outlinedButtonStyle,
                child: const Text(
                  'Volver',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
