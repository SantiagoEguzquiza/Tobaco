import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';

class DetalleClienteScreen extends StatelessWidget {
  
  
  Cliente cliente = Cliente(
    id: 1,
    nombre: 'Ana',
    direccion: 'La Paz 123',
    telefono: 123456789,
    whatsapp: '987654321',
    deuda: 100,
  );

  final String nombreCliente;
  final String direccion;
  final String telefono;
  final String deuda;

  DetalleClienteScreen({
    Key? key,
    required this.nombreCliente,
    required this.direccion,
    required this.telefono,
    required this.deuda,
  }) : super(key: key);

  DetalleClienteScreen.empty({
    Key? key,
  })  : nombreCliente = 'Ana',
        direccion = 'La Paz 123',
        telefono = '012-345-6789',
        deuda = '100.00',
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombreCliente),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dirección:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              direccion,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            const Text(
              'Teléfono:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              telefono,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            const Text(
              'Deuda:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              deuda,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
