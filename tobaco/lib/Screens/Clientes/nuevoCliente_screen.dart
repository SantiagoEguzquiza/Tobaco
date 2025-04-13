import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';

class NuevoClienteScreen extends StatelessWidget {
  const NuevoClienteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controladores para los campos de texto
    final nombreController = TextEditingController();
    final direccionController = TextEditingController();
    final telefonoController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Nuevo Cliente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nombre:',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nombreController,
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese el nombre...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dirección:',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: direccionController,
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese la dirección...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Teléfono:',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: telefonoController,
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese el teléfono...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Spacer(),
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
                  backgroundColor: const Color.fromARGB(255, 255, 141, 141),
                  elevation: 5,
                  shadowColor: Colors.black,
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity, // Botón ocupa todo el ancho
              child: ElevatedButton(
                onPressed: () async {
                  // Datos del cliente
                  final Cliente cliente = Cliente(
                    id: null, // ID se asignará automáticamente en el servidor
                    nombre: nombreController.text,
                    direccion: direccionController.text,
                    telefono: int.tryParse(telefonoController.text) ?? 0,
                    deuda: 0 // Inicializa la deuda en 0
                  );

                  try {
                    // Llama al método para guardar el cliente
                    await Provider.of<ClienteProvider>(context, listen: false)
                        .crearCliente(cliente);

                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Cliente guardado con éxito')),
                    );
                    
                    // Regresa a la pantalla anterior
                    Navigator.pop(context);
                  } catch (e) {
                    // Muestra un mensaje de error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color(0xFFAAEDAA),
                  elevation: 5,
                  shadowColor: Colors.black,
                ),
                child: const Text(
                  'Guardar',
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
