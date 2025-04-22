import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema
import 'package:url_launcher/url_launcher.dart';

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
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirmar eliminación'),
                              content: const Text(
                                  '¿Está seguro de que desea eliminar este cliente?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          await ClienteProvider().eliminarCliente(cliente.id!);
                          Navigator.of(context).pop();
                        }
                      },
                      style: AppTheme.elevatedButtonStyle(
                        const Color.fromARGB(255, 255, 141, 141),
                      ),
                      child:
                          Image.asset('Assets/images/borrar.png', height: 30),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: AppTheme.elevatedButtonStyle(
                        const Color.fromARGB(255, 251, 247, 135),
                      ),
                      child:
                          Image.asset('Assets/images/editar.png', height: 30),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        final Uri launchUri = Uri(
                            scheme: 'tel', path: cliente.telefono.toString());
                        launchUrl(launchUri).then((success) {
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Could not launch $launchUri')),
                            );
                          }
                        }).catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')),
                          );
                        });
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
                      onPressed: () {
                        final Uri whatsappUri =
                            Uri.parse('https://wa.me/${cliente.telefono}');
                        launchUrl(whatsappUri).then((success) {
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Could not launch $whatsappUri')),
                            );
                          }
                        }).catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')),
                          );
                        });
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
