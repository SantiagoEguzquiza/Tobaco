import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';

class EditarClienteScreen extends StatefulWidget {
  final Cliente cliente;

  const EditarClienteScreen({super.key, required this.cliente});

  @override
  _EditarClienteScreenState createState() => _EditarClienteScreenState();
}

class _EditarClienteScreenState extends State<EditarClienteScreen> {
  late TextEditingController nombreController;
  late TextEditingController direccionController;
  late TextEditingController telefonoController;
  late TextEditingController deudaController;

  @override
  void initState() {
    super.initState();
    // Inicializa los controladores con los valores actuales del cliente
    nombreController = TextEditingController(text: widget.cliente.nombre);
    direccionController = TextEditingController(text: widget.cliente.direccion);
    telefonoController =
        TextEditingController(text: widget.cliente.telefono.toString());
    deudaController =
        TextEditingController(text: widget.cliente.deuda.toString());
  }

  @override
  void dispose() {
    nombreController.dispose();
    direccionController.dispose();
    telefonoController.dispose();
    deudaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Cliente'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true, // Ajusta la pantalla al teclado
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nombre:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nombreController,
                    style: AppTheme.inputTextStyle,
                    cursorColor: Colors.black,
                    decoration: AppTheme.inputDecoration,
                    onChanged: (value) {
                      setState(() {
                        widget.cliente.nombre = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dirección:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: direccionController,
                    style: AppTheme.inputTextStyle,
                    cursorColor: Colors.black,
                    decoration: AppTheme.inputDecoration,
                    onChanged: (value) {
                      setState(() {
                        widget.cliente.direccion = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Teléfono:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: telefonoController,
                    style: AppTheme.inputTextStyle,
                    cursorColor: Colors.black,
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.inputDecoration,
                    onChanged: (value) {
                      setState(() {
                        widget.cliente.telefono = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deuda:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: deudaController,
                    style: AppTheme.inputTextStyle,
                    cursorColor: Colors.black,
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.inputDecoration,
                    onChanged: (value) {
                      setState(() {
                        widget.cliente.deuda = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 80), // Espacio para los botones
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: AppTheme.elevatedButtonStyle(
                          AppTheme.confirmButtonColor,
                        ),
                        onPressed: () async {
                          try {
                            await ClienteProvider()
                                .editarCliente(widget.cliente);

                            Navigator.of(context).pop();

                            // Acción para confirmar los cambios
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cambios confirmados'),
                              ),
                            );
                          } catch (e) {
                            // Manejo de errores
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        },
                        child: const Text(
                          'Confirmar',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
