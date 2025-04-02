import 'package:flutter/material.dart';

class EditarClienteScreen extends StatelessWidget {
  const EditarClienteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(    
      appBar: AppBar(
        title: const Text('Editar Cliente'),
        backgroundColor: Colors.blue,
      ),
      body: const SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'Pantalla de edición de cliente',
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