// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Screens/Clientes/detalleCliente_screen.dart';
import 'package:tobaco/Screens/Clientes/editarCliente_Screen.dart';
import 'package:tobaco/Screens/Clientes/nuevoCliente_screen.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema
import 'dart:developer';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  bool isLoading = true;
  String searchQuery = '';
  String? errorMessage;
  List<Cliente> clientes = [];

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final clienteProvider = ClienteProvider();
      final List<Cliente> fetchedClientes =
          await clienteProvider.obtenerClientes();

      setState(() {
        clientes = fetchedClientes; // Actualiza la lista de clientes
        isLoading = false; // Finaliza la carga
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar los clientes: $e';
      });
      log('Error al cargar los clientes: $e', level: 1000);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClientes = clientes
        .where((cliente) =>
            cliente.nombre.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList()
      ..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Clientes',
          style: AppTheme.appBarTitleStyle, // Usa el estilo del tema
        ),
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
                      builder: (context) => const NuevoClienteScreen(),
                    ),
                  );
                  _loadClientes();
                },
                style: AppTheme.elevatedButtonStyle(AppTheme.primaryColor), // Usa el estilo del tema
                child: const Text(
                  'Crear nuevo cliente',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              cursorColor: Colors.black,
              style: const TextStyle(fontSize: 15),
              decoration: AppTheme.searchInputDecoration, // Usa el tema
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: filteredClientes.length,
                itemBuilder: (context, index) {
                  final cliente = filteredClientes[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    color: index % 2 == 0
                        ? AppTheme.secondaryColor // Verde para impares
                        : AppTheme.greyColor, // Gris claro para pares
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetalleClienteScreen(cliente: cliente),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              'Assets/images/tienda.png',
                              height: 30,
                            ),
                            const SizedBox(width: 25),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cliente.nombre,
                                    style: AppTheme.cardTitleStyle, // Usa el tema
                                  ),
                                  Text(
                                    'Deuda: \$${cliente.deuda}',
                                    style: AppTheme.cardSubtitleStyle, // Usa el tema
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Image.asset(
                                'Assets/images/borrar.png',
                                height: 24,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar cliente'),
                                    content: const Text(
                                        '¿Estás seguro de que deseas eliminar este cliente?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await ClienteProvider()
                                              .eliminarCliente(cliente.id!);
                                          _loadClientes();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Image.asset(
                                'Assets/images/editar.png',
                                height: 24,
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditarClienteScreen(
                                      cliente: cliente,
                                    ),
                                  ),
                                );
                                _loadClientes();
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
