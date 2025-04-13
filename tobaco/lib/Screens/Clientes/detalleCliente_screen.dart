
import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DetalleClienteScreen extends StatelessWidget {
  
  
  

  final Cliente cliente;


  DetalleClienteScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(cliente.nombre,
            style: const TextStyle(
                fontSize: 35)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dirección:',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity, // Ocupa todo el ancho disponible
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 20), // Espaciado interno
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 1), // Fondo blanco
                borderRadius: BorderRadius.circular(30), // Bordes redondeados
                border: Border.all(
                  color:
                      const Color.fromRGBO(200, 200, 200, 1), // Color del borde
                  width: 1.0, // Grosor del borde
                ),
              ),
              child: Text(
                cliente.direccion?? 'No disponible',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Teléfono:',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity, // Ocupa todo el ancho disponible
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 20), // Espaciado interno
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 1), // Fondo blanco
                borderRadius: BorderRadius.circular(30), // Bordes redondeados
                border: Border.all(
                  color:
                      const Color.fromRGBO(200, 200, 200, 1), // Color del borde
                  width: 1.0, // Grosor del borde
                ),
              ),
              child: Text(
                cliente.telefono?.toString() ?? 'No disponible',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Deuda:',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity, // Ocupa todo el ancho disponible
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 20), // Espaciado interno
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 1), // Fondo blanco
                borderRadius: BorderRadius.circular(30), // Bordes redondeados
                border: Border.all(
                  color:
                      const Color.fromRGBO(200, 200, 200, 1), // Color del borde
                  width: 1.0, // Grosor del borde
                ),
              ),
              child: Text(
                cliente.deuda.toString()?? 'No disponible',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            const Spacer(), // Empuja los botones hacia el final de la pantalla
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirmar eliminación'),
                          content: const Text('¿Está seguro de que desea eliminar este cliente?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false); // Cancelar
                              },
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true); // Confirmar
                              },
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: const Color.fromARGB(255, 255, 141, 141),
                    elevation: 5, // Altura de la sombra
                  ),
                  child: Image.asset(
                    'Assets/images/borrar.png', // Ruta de la imagen en tus assets
                    height: 30, // Altura de la imagen
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: const Color.fromARGB(255, 251, 247, 135),
                    elevation: 5, // Altura de la sombra
                    shadowColor: Colors.black, // Color de la sombra
                  ),
                  child: Image.asset(
                    'Assets/images/editar.png', // Ruta de la imagen en tus assets
                    height: 30, // Altura de la imagen
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: cliente.telefono.toString(),
                    );
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: const Color.fromARGB(255, 104, 147, 255),
                    elevation: 5, // Altura de la sombra
                    shadowColor: Colors.black, // Color de la sombra
                  ),
                  child: Image.asset(
                    'Assets/images/ring-phone.png', // Ruta de la imagen en tus assets
                    height: 30, // Altura de la imagen
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final Uri whatsappUri = Uri.parse(
                        'https://wa.me/${cliente.telefono}'); // Formato para abrir WhatsApp con el número
                    launchUrl(whatsappUri).then((success) {
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Could not launch $whatsappUri')),
                        );
                      }
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $error')),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: const Color.fromARGB(255, 37, 211, 101),
                    elevation: 5, // Altura de la sombra
                    shadowColor: Colors.black, // Color de la sombra
                  ),
                  child: Image.asset(
                    'Assets/images/whatsapp.png', // Ruta de la imagen en tus assets
                    height: 30, // Altura de la imagen
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity, // Botón ocupa todo el ancho
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Regresa a la pantalla anterior
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor:  Colors.blue,
                  elevation: 5,
                  shadowColor: Colors.black,
                ),
                child: const Text(
                  'Volver',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
