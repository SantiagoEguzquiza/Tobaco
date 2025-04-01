import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';

class DetalleClienteScreen extends StatelessWidget {
  
  
  Cliente cliente = Cliente(
    id: 1,
    nombre: 'Ana',
    direccion: 'La Paz 123',
    telefono: 123456789,
    
    deuda: 100,
  );

  late String nombreCliente;
  late String direccion;
  late String telefono;
  late String deuda;

  DetalleClienteScreen({required Cliente cliente}) {
    nombreCliente = cliente.nombre;
    direccion = cliente.direccion!;
    telefono = cliente.telefono.toString();
    deuda = cliente.deuda.toString();
  }
    

 

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
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Teléfono:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              telefono,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
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
