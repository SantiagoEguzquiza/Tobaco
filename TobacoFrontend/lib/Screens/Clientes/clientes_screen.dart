import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Screens/Clientes/detalleCliente_screen.dart';
import 'package:tobaco/Screens/Clientes/editarCliente_Screen.dart';
import 'package:tobaco/Screens/Clientes/nuevoCliente_screen.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';


class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Cargar clientes al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().obtenerClientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final clienteProv = context.watch<ClienteProvider>(); // CHANGED
    final clientes = clienteProv.clientes;

    // Filtro en memoria sobre lo que ya está en provider
    final filteredClientes = clientes
        .where((c) => c.nombre.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Clientes', style: AppTheme.appBarTitleStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NuevoClienteScreen(),
                    ),
                  );
                  context.read<ClienteProvider>().obtenerClientes(); // CHANGED
                },
                style: AppTheme.elevatedButtonStyle(AppTheme.addGreenColor),
                child: const Text(
                  'Crear nuevo cliente',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              cursorColor: Colors.black,
              style: const TextStyle(fontSize: 15),
              decoration: AppTheme.searchInputDecoration,
              onChanged: (value) => setState(() => searchQuery = value),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: clienteProv.clientes.isEmpty
                  ? const Center(child: Text("No hay clientes"))
                  : ListView.builder(
                      itemCount: filteredClientes.length,
                      itemBuilder: (context, index) {
                        final cliente = filteredClientes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          color: index % 2 == 0
                              ? AppTheme.secondaryColor
                              : AppTheme.greyColor,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetalleClienteScreen(cliente: cliente),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Image.asset('Assets/images/tienda.png', height: 30),
                                  const SizedBox(width: 25),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(cliente.nombre,
                                            style: AppTheme.cardTitleStyle),
                                        Text('Deuda: \$${cliente.deuda}',
                                            style: AppTheme.cardSubtitleStyle),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Image.asset('Assets/images/borrar.png', height: 24),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AppTheme.alertDialogStyle(
                                          title: 'Eliminar cliente',
                                          content: '¿Estás seguro de que deseas eliminar este cliente?',
                                          onConfirm: () async {
                                            await context.read<ClienteProvider>()
                                                .eliminarCliente(cliente.id!); // CHANGED
                                            if (mounted) Navigator.of(ctx).pop();
                                          },
                                          onCancel: () => Navigator.of(ctx).pop(),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Image.asset('Assets/images/editar.png', height: 24),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditarClienteScreen(cliente: cliente),
                                        ),
                                      );
                                      context.read<ClienteProvider>().obtenerClientes(); // CHANGED
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

