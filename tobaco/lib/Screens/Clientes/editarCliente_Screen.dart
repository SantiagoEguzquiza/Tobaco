import 'package:flutter/material.dart';

class EditarClienteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para toda la pantalla
      appBar: AppBar(
        title: const Text('Editar Cliente'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'Pantalla de edición de cliente',
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}