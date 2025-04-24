import 'package:flutter/material.dart';

class NuevoVentasScreen extends StatelessWidget{

const NuevoVentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Nueva Venta'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Aquí puedes agregar los campos de entrada para la nueva venta
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }




}